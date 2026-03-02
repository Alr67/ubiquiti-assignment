import Foundation

/// Client-side infinite scroll: the API returns all data at once (no pagination support),
/// so we paginate locally to keep List rendering performant.
@MainActor
@Observable
final class Paginator<T> {
    private(set) var items: [T] = []
    private var currentPage = 0
    private let pageSize: Int

    var source: () -> [T] = { [] }

    var hasMorePages: Bool {
        items.count < source().count
    }

    init(pageSize: Int = 30) {
        self.pageSize = pageSize
    }

    func loadNextPage() {
        let all = source()
        let start = currentPage * pageSize
        guard start < all.count else { return }
        let end = min(start + pageSize, all.count)
        items.append(contentsOf: all[start..<end])
        currentPage += 1
    }

    func reset() {
        currentPage = 0
        items = []
        loadNextPage()
    }
}
