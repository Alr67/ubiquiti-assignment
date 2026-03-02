# AI Usage

## Tools Used

I used **Claude Code** (Anthropic's CLI tool) as the sole AI assistant throughout the project. No other AI tools (Copilot, ChatGPT, etc.) were used.

## Example Prompts and Outcomes

### 1. Transport mode icons for stations
**Prompt:** "The icon next to the name doesn't add much info does it? What kind of info do we have in that model? Can we somehow reflect if it's a bus/train/metro station, or a mixed one?"

Claude investigated the API, found that `/sites?expand=true` returns `stop_areas` IDs and `/stop-points` returns transport types per stop area. Cross-referencing these gives each station its transport modes — a non-obvious solution that required understanding two separate endpoints.

### 2. API limitation discovery
**Prompt:** "Why do the next departures stop after a certain point?"

Claude tested the API with curl, discovered the undocumented `forecast` parameter (max 1200 minutes), and found the documented 3-per-line-direction cap. This led to adding `forecast=1200` to the endpoint.

### 3. DRY analysis
**Prompt:** "Analyzing all the codebase, is it DRY? What architecture did you use? Is it maintainable?"

Claude read every file, identified 4 concrete DRY violations (duplicated pagination, search bar, status colors, error messages), and proposed fixes. I approved and it extracted `Paginator<T>`, `SearchBar`, `StyleExtensions`, and moved `userFacingMessage` to `APIError`.

### 4. Offline behavior
**Prompt:** "If I'm offline, I will have a list of stations and most of them will be empty bc I have not accessed them before. Can we only show those that have cached data?"

Claude implemented `NWPathMonitor` for connectivity detection, tracked cached site IDs in SwiftData, and added offline filtering with an informational banner.

## Rejected / Modified AI Suggestions

### FileManager-based caching (replaced)
The initial cache implementation used FileManager with JSON files and TTL. When I asked about adding favorites, Claude evaluated FileManager vs SwiftData and acknowledged that having two persistence mechanisms (FileManager for cache + SwiftData for favorites) was unnecessary complexity. We migrated the cache to SwiftData, consolidating everything into one persistence layer.

## Verification

- **API responses**: Verified by curling endpoints directly and comparing against model structures. This caught the missing `lat`/`lon` fields (5 stations) and the undocumented `forecast` parameter limit (1200).
- **Build verification**: Every change was compiled with `xcodebuild` before confirming. Build failures were caught and fixed immediately (e.g., naming conflicts like duplicate `StopPoint` structs, `.accent` vs `Color.accentColor`).
- **Manual testing**: Ran the app on simulator after each feature — tested search, pagination scroll, transport mode filters, favorites, offline mode (airplane mode toggle), pull-to-refresh, and navigation between screens.
- **Offline scenarios**: Tested by loading stations + departures, enabling airplane mode, force-quitting and relaunching to verify cache persistence and the offline station filter. Discovered that `NWPathMonitor` is unreliable on the iOS Simulator (reports incorrect status after WiFi toggle) — confirmed working correctly on a real device.
- **Unit tests**: 13 tests covering model decoding (Site with all/missing fields, Departure with all states, TransportMode mapping) and cache behavior (TTL expiry, stale fallback, save/load/remove round-trips).
