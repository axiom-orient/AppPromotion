# AppPromotion

One small native ad card, supplied by a public HTTPS JSON catalog. Promote your own apps or approved partners with a web, Universal Link or App Store destination. No advertising network SDK, account, device identifier, impression event or click-tracking service is included.

Swift 6 · iOS 17+ · macOS 14+ · no external package dependencies.

## Add the package

```swift
.package(
    url: "https://github.com/axiom-orient/AppPromotion.git",
    exact: "0.2.0"
)
```

Link these products in the UI/composition target for the example below:

```swift
.product(name: "AppPromotion", package: "AppPromotion"),
.product(name: "AppPromotionRemote", package: "AppPromotion"),
.product(name: "AppPromotionUI", package: "AppPromotion")
```

Keep only the Foundation-only `AppPromotion` product in a domain target that needs catalog values. `AppPromotionExamples` is optional branded preview material; it is not required for production.

## Receive and show one card

Choose a catalog you operate or trust. The v3 operator approves the advertised titles, copy and HTTPS destinations. Set its URL and the host app's public ID once:

```swift
import Foundation
import AppPromotionRemote

let promotion = try PromotionConfiguration(
    catalogURL: URL(string: "https://promotions.example.net/v3/campaigns.json")!,
    host: "notes"
)
```

The example hostname is reserved for documentation. Replace it with your approved deployed URL.

Wrap the existing screen container. Insert the optional advertisement only when it exists:

```swift
import AppPromotion
import AppPromotionRemote
import AppPromotionUI
import SwiftUI

struct HomeScreen: View {
    let promotion: PromotionConfiguration
    let showAdInformation: (PromotionCard) -> Void
    let recordFailure: (any Error) -> Void

    var body: some View {
        PromotionPlacement(
            configuration: promotion,
            about: showAdInformation,
            onFailure: recordFailure
        ) { advertisement in
            ScrollView {
                VStack(spacing: 16) {
                    Text("Your existing screen content")
                    if let advertisement { advertisement }
                }
                .padding()
            }
        }
    }
}
```

The callbacks connect to the app's existing ad information/reporting flow and internal diagnostics. Provide useful ad information and a working report action before enabling production ads. The information flow must explain that selection uses the host app, catalog order and schedule, without personal targeting.

`PromotionPlacement` owns transient ad retrieval, the five-minute feed lease and optional icon loading. It shows only one eligible card, excludes the host app, rotates distinct targets once per UTC minute and opens the exact displayed HTTPS destination with the system `openURL` action. A failed open is reported through `onFailure`.

No loading placeholder, empty ad row, retry button or additional ad screen is created. The wrapper remains the same when a card appears or disappears. Wrap the whole `List` or `ScrollView`; putting the placement inside a permanent row can preserve the row's height even when no ad exists.

Use `isEnabled: false` while the host screen is covered, editing, generating or saving. Inactive scenes do not display or fetch ads. A successful live feed is renewed when its lease expires; a failed fetch is reported and is not automatically retried. Re-enabling the placement, changing its configuration or re-entering an active scene starts a new request. Expired catalogs remain hidden until another such request. No disk cache or background refresh is added.

The default `.standard` style uses system colors and fonts. Pass your `PromotionCardView.Style` to keep the card consistent with your design system. Korean language identifiers such as `ko-KR` and `ko_KR` select Korean copy; other catalog languages use English. Card controls also support Japanese.

## Change ads on the server

Edit the v3 JSON to change titles, descriptions, HTTPS destinations, schedules, order or the global `enabled` switch. This does not require a client release while the schema remains compatible. Review every new destination and creative before publishing it.

- [Catalog contract and v2 compatibility](docs/CATALOG.md)
- [v3 schema](Schemas/catalog-v3.schema.json), [disabled catalog](Hosting/public/v3/campaigns.json), [future-dated example](Hosting/public/v3/catalog.example.json)
- [Cloudflare primary template and Firebase alternative](docs/HOSTING.md)
- [Research and adoption decisions](docs/RESEARCH.md)
- [Renewal changes and verification scope](docs/RENEWAL.md)

Cloudflare Workers Static Assets can serve the JSON and optional images without a Worker script or database. Firebase Hosting can serve the same files. Neither requires a provider SDK in the app. These are source templates; no account, billing, domain, DNS or deployment is configured by adding this package.

## Existing v2 integrations

The existing `PromotionTarget`, `PromotionFeedClient`, `PromotionTimeline`, `PromotionCardView` and `PromotionCard.read` APIs remain available. The v2 path still takes an app-owned registry; remote title and destination fields never override it. A locally approved `PromotionDestination` can now supply a web link as well as the existing numeric App Store ID.

The new `PromotionPlacement` explicitly requires v3. A v2 response is reported as an unsupported schema; it is never silently treated as v3 or merged with local approvals. Keep `/v2/campaigns.json` in place for existing clients and use a separate `/v3/campaigns.json` URL when opting in.

For custom state ownership, use `PromotionFeedClient.fetch()` and `feed.rotation(host:language:)` for v3, or `feed.rotation(host:targets:language:)` for v2. `PromotionTimeline` and `PromotionCardView` remain presentation-only alternatives to the ready-made connection.

## Boundaries and privacy

Catalog and image requests contain no app/user IDs, locale, authentication, cookies, records, receipts or telemetry. The selected HTTPS/CDN origin still receives normal connection metadata, including IP addresses. The destination website or store has its own privacy behavior after the person opens it; the SDK does not guarantee that site's analytics policy.

Transport rejects redirects and caps catalogs at 32 KiB. Optional icons use the catalog origin and the existing `/v2/assets/<sha256>.png` or `.jpg` path, at most 96 KiB. Bytes must match the digest and decode as one static PNG/JPEG frame up to 256×256 pixels. Invalid artwork is reported and omitted; the same valid text card remains. A verified image never extends an expired card's lease.

Your app owns its Store, navigation, consent, reporting, design tokens and persistence. The package cannot alter application data, IDs, receipts, generation recovery or automatic sharing.

## License and status

Library code is MIT; see [LICENSE](LICENSE). Optional app icons and brand names are excluded; see [NOTICE](NOTICE.md).

The 0.2.0 source renewal is a prerelease. Package compilation and the two approved new-risk checks passed; their scope is recorded in [RENEWAL](docs/RENEWAL.md). No live catalog request, three-app build/test or hosting deployment is part of this renewal.

### 운영 요약

v3는 승인한 서버 URL과 현재 앱 ID만 설정합니다. 광고명·문구·목적지·일정은 JSON에서 바꾸고, 앱에는 카드 한 장만 표시합니다. 자기 앱과 만료 광고는 제외하며 광고가 없으면 행과 여백도 만들지 않습니다. 기존 v2 로컬 승인과 앱 데이터·ID·receipt·자동 공유는 그대로 보존합니다.
