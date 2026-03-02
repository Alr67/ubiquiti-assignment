# SLplanner

A SwiftUI app for checking real-time train and transit departures from Stockholm (SL) stations.

## How to Run

**Prerequisites:**
- Xcode 16+
- iOS 17.0+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

**Steps:**
```bash
cd "SL planner"
xcodegen generate
open SLplanner.xcodeproj
```
Build and run on a simulator or device (Cmd+R).

No API keys required. No third-party dependencies.

## Chosen API

**SL Transport API** — [trafiklab.se/api/our-apis/sl/transport](https://www.trafiklab.se/api/our-apis/sl/transport/)

Base URL: `https://transport.integration.sl.se/v1`

| Endpoint | Purpose | Cache Strategy |
|----------|---------|----------------|
| `GET /sites?expand=true` | All 6497 stations with stop area IDs | Permanent (synced on launch) |
| `GET /stop-points` | 14k stop points with transport types (BUSTERM, METROSTN, etc.) | Permanent (synced on launch) |
| `GET /sites/{id}/departures?forecast=1200` | Real-time departures for a station (up to 20h ahead) | 2-minute TTL + stale fallback |

The API requires no authentication. The `forecast=1200` parameter is the highest accepted value (found via testing, not documented). The API caps at 3 departures per line+direction regardless of forecast window.

## Architecture

**MVVM** with `@Observable` (iOS 17), SwiftData for persistence, async/await for networking.

```
SLplanner/
├── Models/          — Codable structs (Site, Departure, FavoriteStation)
├── Networking/      — APIClient (generic fetch<T>) + Endpoint enum
├── Cache/           — SwiftDataCache actor + CachedEntry model
├── Utilities/       — Paginator<T> (reusable client-side pagination)
├── ViewModels/      — StationListViewModel, DeparturesViewModel
└── Views/
    ├── Shared/      — SearchBar, FilterChip, TransportModeLabel, ErrorView, StyleExtensions
    ├── StationListView + StationRow
    ├── DeparturesView + DepartureRow
    └── DepartureDetailView
```

**Data flow:**
1. ViewModels load from SwiftData cache (instant) then sync from API in background
2. Views bind to `@Observable` ViewModels — no Combine, no `@Published`
3. `Paginator<T>` handles infinite scroll for both station list and departures (30 items/page)
4. `NWPathMonitor` detects offline state and filters the station list to only show stations with fresh cached departures (must test on real device — unreliable on simulator)

## Key Tradeoffs and Assumptions

**Client-side pagination:** The SL API returns all data in a single response (no `offset`/`limit` support). We fetch everything once and paginate locally via `Paginator<T>` to keep List rendering performant.

**First launch cost:** ~3 seconds to download 1.6 MB (sites) + 8 MB (stop points) in parallel. This is unavoidable since the API doesn't support chunked/paginated fetching. After first launch, data loads instantly from cache.

**Transport mode resolution:** The sites endpoint doesn't include transport types. We cross-reference site `stop_areas` IDs with the stop-points endpoint to derive which modes (bus, metro, train, etc.) each station serves. This mapping is cached permanently.

**Offline behavior:** Stations are cached permanently and synced on each launch. Departures use a 2-minute TTL — expired departures are not shown to avoid displaying outdated times. When offline, only stations with fresh (non-expired) cached departures are visible, with a banner explaining why. `NWPathMonitor` is unreliable on the iOS Simulator; test offline behavior on a real device.

**SwiftData over FileManager:** Initially implemented with FileManager for caching. Migrated to SwiftData to support both blob caching (via `CachedEntry`) and user data (via `FavoriteStation`) in a single persistence layer.

**No third-party dependencies:** All functionality uses native frameworks only — Foundation, SwiftUI, SwiftData, Network.
