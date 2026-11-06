# 0.2.0 renewal record

## Actual changes

- Added a validated HTTPS destination shared by locally approved v2 targets and operator-approved v3 campaigns. Existing App Store ID and `appStoreURL` APIs remain available.
- Added explicit v3 remote titles/destinations and a matching selection overload. v2 still uses its local registry; the modes never merge or fall back.
- Added `PromotionConfiguration` and `PromotionPlacement` to own transient receiving, successful feed renewal, verified optional artwork and the displayed card's system open action.
- Kept the existing host container stable across loading, absence and expiry. No ad creates no row; no loading/retry screen or permanent cache was added.
- Added system styling and locale-prefix handling. Native card/artwork are available on iOS 17+ and macOS 14+.
- Added v3 schema, disabled/example catalogs and matching static-host JSON headers. Existing v2 catalogs, schema and immutable asset path remain available.
- Recorded research decisions and the operator/local approval boundaries. MIT code and separate brand-material terms remain unchanged.

## Evidence and scope

Independent source review covered Core/Remote trust boundaries and UI state identity, cancellation, expiry, exact-card interactions and optional-artwork handling. The discovered early-cancel artwork state-clear issue was corrected before the package check.

One approved package check was executed with Apple Swift 6.4.2 (`swiftlang-6.4.2.1.9`) on an arm64 macOS host:

```sh
swift test --filter PromotionRiskTests
```

Result: Core, Remote, UI and Examples compiled; the two new-risk tests passed. Build time was 6.60 seconds; each test completed in 0.004 seconds. The checks use fixed dates and local JSON, with no endpoint requests:

1. HTTPS destination validation, v2/v3 trust separation, locale selection, invalid advertisements and self-exclusion.
2. Feed lease bounds, precise campaign transitions, minute rotation and duplicate-target conflict recovery.

These checks establish only the compiled package and deterministic selection risks. No app build/test, iOS runtime or visual capture, live catalog/image request, App Store availability check, Cloudflare/Firebase deployment, account/DNS/billing change or app data access was performed. Existing data, IDs, receipts and automatic sharing were outside the package changes.

GitHub tag/release publication is a separate manual delivery step. Source publication does not establish live hosting or app submission readiness.
