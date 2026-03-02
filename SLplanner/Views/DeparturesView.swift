import SwiftUI
import SwiftData

struct DeparturesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DeparturesViewModel
    @State private var isFavorite: Bool
    let onToggleFavorite: (Site) -> Void

    init(site: Site, isFavorite: Bool, onToggleFavorite: @escaping (Site) -> Void) {
        _viewModel = State(wrappedValue: DeparturesViewModel(site: site))
        _isFavorite = State(wrappedValue: isFavorite)
        self.onToggleFavorite = onToggleFavorite
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle where viewModel.allDepartures == nil,
                 .loading where viewModel.allDepartures == nil:
                ProgressView("Loading departures...")

            case .error(let message):
                ErrorView(message: message) {
                    Task { await viewModel.loadDepartures() }
                }

            default:
                departuresList
            }
        }
        .navigationTitle(viewModel.site.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isFavorite.toggle()
                    onToggleFavorite(viewModel.site)
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? .yellow : .secondary)
                }
            }
        }
        .task {
            viewModel.configure(modelContainer: modelContext.container)
            if viewModel.state == .idle {
                await viewModel.loadDepartures()
            }
        }
        .overlay(alignment: .bottom) {
            if let message = viewModel.toastMessage {
                Text(message)
                    .font(.subheadline)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        Task {
                            try? await Task.sleep(for: .seconds(3))
                            withAnimation { viewModel.toastMessage = nil }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: viewModel.toastMessage)
    }

    private var departuresList: some View {
        List {
            Section {
                SearchBar(text: $viewModel.searchText, placeholder: "Line or destination", showsClearButton: false)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
            }

            if !viewModel.stopDeviations.isEmpty {
                Section("Station Notices") {
                    ForEach(viewModel.stopDeviations) { deviation in
                        Label {
                            Text(deviation.message)
                                .font(.caption)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            if viewModel.availableModes.count > 1 {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.availableModes, id: \.self) { mode in
                                FilterChip(label: mode.label, isSelected: viewModel.selectedMode == mode) {
                                    withAnimation {
                                        viewModel.selectedMode = viewModel.selectedMode == mode ? nil : mode
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Departures") {
                if viewModel.paginator.items.isEmpty && viewModel.state == .loaded {
                    ContentUnavailableView(
                        "No departures",
                        systemImage: "clock",
                        description: Text("There are no upcoming departures from this station.")
                    )
                } else {
                    ForEach(viewModel.paginator.items) { departure in
                        NavigationLink {
                            DepartureDetailView(departure: departure, stationName: viewModel.site.name)
                        } label: {
                            DepartureRow(departure: departure)
                        }
                    }

                    if viewModel.paginator.hasMorePages {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .onAppear {
                                viewModel.paginator.loadNextPage()
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.refresh()
        }
    }
}
