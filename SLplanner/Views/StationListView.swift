import SwiftUI
import SwiftData

struct StationListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StationListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .navigationBarHidden(true)
        .navigationDestination(for: Site.self) { site in
            DeparturesView(site: site, isFavorite: viewModel.isFavorite(site)) { site in
                viewModel.toggleFavorite(site)
            }
        }
        .task {
            viewModel.configure(modelContext: modelContext)
            if viewModel.state == .idle {
                await viewModel.loadStations()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Stations")
                    .font(.largeTitle.bold())
                Spacer()
            }

            SearchBar(text: $viewModel.searchText, placeholder: "Where are you going?")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransportMode.allCases, id: \.self) { mode in
                        FilterChip(
                            label: mode.label,
                            isSelected: viewModel.selectedModes.contains(mode)
                        ) {
                            withAnimation { viewModel.toggleMode(mode) }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle where viewModel.paginator.items.isEmpty,
             .loading where viewModel.paginator.items.isEmpty:
            Spacer()
            ProgressView("Fetching stations for the first time...")
            Spacer()

        case .error(let message):
            ErrorView(message: message) {
                Task { await viewModel.loadStations() }
            }

        default:
            VStack(spacing: 0) {
                if !viewModel.favoriteStations.isEmpty {
                    favoritesBar
                    Divider()
                }
                stationList
            }
        }
    }

    // MARK: - Favorites

    private var favoritesBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Favorites")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.favoriteStations) { site in
                        NavigationLink(value: site) {
                            Text(site.name)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    // MARK: - List

    private var stationList: some View {
        List {
            ForEach(viewModel.paginator.items) { site in
                NavigationLink(value: site) {
                    StationRow(site: site, transportModes: viewModel.transportModes(for: site))
                }
            }

            if viewModel.paginator.hasMorePages {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        viewModel.paginator.loadNextPage()
                    }
            }

            if viewModel.paginator.items.isEmpty && viewModel.state == .loaded {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
        .listStyle(.plain)
    }
}
