# Decisions

## Networking

- **async/await with generic `APIClient`**: Single `fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T` method handles all API calls. Three explicit error cases (`networkError`, `invalidResponse`, `decodingFailed`) with `userFacingMessage` for toast display.
- **No third-party HTTP libraries**: URLSession is sufficient for GET-only JSON endpoints. No auth, no complex request building needed.
- **`Endpoint` enum**: Centralizes URL construction. `forecast=1200` for departures is the highest value the API accepts (found via curl testing — returns HTTP 400 for values above 1200).

## Caching

- **SwiftData (`SwiftDataCache` actor)**: Started with FileManager (file-per-key with TTL). Migrated to SwiftData when favorites were added — having both blob cache and user data in one persistence layer is cleaner than mixing FileManager + SwiftData.
- **`CachedEntry` model**: Generic blob storage — key (unique), data (JSON-encoded), expiresAt. The cache doesn't know about the domain types it stores.
- **TTL strategy**: Stations use a 365-day TTL (effectively permanent, synced on every launch). Departures use 2-minute TTL. Expired departures are not shown — stations with stale cache are hidden in offline mode to avoid displaying outdated times.
- **No `URLCache`**: Requirement specified custom caching. SwiftData gives us TTL control, offline fallback, and queryable storage that `URLCache` doesn't.

## Pagination

- **Client-side via `Paginator<T>`**: The SL API has no pagination support — `/sites` returns all 6497 stations in one response, `/departures` returns all departures in one response. `Paginator<T>` is a generic `@Observable` class that slices the full dataset into 30-item pages, triggered by `onAppear` on a `ProgressView` at the list bottom.
- **Why not server-side**: The API simply doesn't support it. Attempting to chunk requests (e.g., alphabetical ranges) would require multiple round trips with no performance benefit since the server computes the full result regardless.

## Offline Behavior

- **`NWPathMonitor`**: Monitors network reachability. When offline, the station list and favorites bar filter to only show stations with fresh (non-expired) cached departures. An informational banner appears explaining the reduced list. Note: `NWPathMonitor` is unreliable on the iOS Simulator — test offline behavior on a real device.
- **No stale data**: When departures TTL expires (2 min) and the network is unavailable, the station is not accessible. This prevents showing outdated departure times (e.g. "Now" for a train that left 20 minutes ago). Only stations with fresh cache appear in offline mode.
- **Cached site ID tracking**: A set of site IDs with cached departures is persisted in SwiftData. When a station's departures load successfully, its ID is added to this set. This allows the offline filter to work across app restarts.
- **Background sync for stations**: On each launch, stations load from cache immediately (instant UI), then sync from the API in the background. The UI only updates if the data actually changed (comparing site ID arrays).
