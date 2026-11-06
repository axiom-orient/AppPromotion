# AppPromotion

A small Swift package for promoting your own apps and approved partner apps. Serve one public JSON catalog from Cloudflare, Firebase Hosting, or another HTTPS static host. No advertising network SDK, account, cookies, device identifiers, impression events, or click tracking is included.

Requires Swift 6, iOS 17 or macOS 14 for the supported Apple products. The core model uses Foundation; iOS card rendering stays in a separate target.

## Products

| Product | Responsibility |
| --- | --- |
| `AppPromotion` | Catalog decoding, approved targets, schedules and one-card selection |
| `AppPromotionRemote` | Bounded HTTPS catalog/image reads and short-lived feed snapshots |
| `AppPromotionUI` | Native card styling and a lazy timeline for actual content changes |
| `AppPromotionExamples` | Optional first-party preview data and branded artwork; not needed by SDK consumers |

The remote product uses Apple URLSession APIs; the native card and image renderer are iOS-only. Do not import these products into a portable domain target.

Your app owns its Store, navigation, design tokens, consent, reporting, and persistence. The package does not write application records or own an app-wide state container.

## Swift Package Manager

Use the `0.1.0` version with an exact dependency:

```swift
.package(
    url: "https://github.com/axiom-orient/AppPromotion.git",
    exact: "0.1.0"
)
```

Add only the products used by your target:

```swift
.product(name: "AppPromotion", package: "AppPromotion"),
.product(name: "AppPromotionRemote", package: "AppPromotion"),
.product(name: "AppPromotionUI", package: "AppPromotion")
```

## Read a catalog

The URL is deployment configuration supplied by your app. It is not an address returned by an advertisement.

```swift
import Foundation
import AppPromotion
import AppPromotionRemote

let host = PromotionAppID(rawValue: "notes")
let target = try PromotionTarget(
    id: PromotionAppID(rawValue: "sketch"),
    title: "Drawing app"
)
let endpoint = try PromotionEndpoint(
    url: URL(string: "https://promotions.example.net/v2/campaigns.json")!
)
let feed = try await PromotionFeedClient(endpoint: endpoint).fetch()
let rotation = feed.rotation(host: host, targets: [target], language: "en")
let card = rotation.card(at: Date())
```

The hostname above is a reserved documentation example. Replace it with your approved deployed URL. A target without a verified numeric App Store ID has no App Store destination. Do not substitute a guessed product ID or treat a preview as a working install action.

The transport accepts HTTPS without credentials, query parameters, fragments, or redirects. The HTTPS/CDN provider still receives normal connection metadata such as IP addresses. Catalogs are capped at 32 KiB. Snapshots last at most five minutes and never outlive the catalog's own expiry. Fetch errors are returned to the app; no provider fallback, automatic retry, stale disk cache, or background refresh is added.

For an optional icon, call `fetchImage` with the selected card's `PromotionAsset`, then pass the verified bytes to `PromotionArtwork.image(data:)` in the iOS UI boundary. Images use the catalog origin and `/v2/assets/<sha256>.png` or `.jpg`, are capped at 96 KiB, and must match their SHA-256. Image download does not authorize continued display of an expired card.

## Present one native card

Use `PromotionTimeline(rotation:content:)` around the existing list or scroll content, then insert an actual row only when its optional card exists. Do not put an empty timeline inside a permanent list row: the row could retain its own height.

`PromotionCardView` takes the app's semantic colors, fonts, inset, and corner radius. Its preview presentation has no fake install button. Use its advertisement presentation only after supplying a verified local App Store destination and explicit open and ad-information/reporting callbacks. Those callbacks receive the exact displayed card, not a card selected again at tap time.

Keep writing, review and saving controls in their existing positions. Hide the placement when its screen is covered or inactive. A catalog fetch or card rotation must not cancel, resubmit, or clear the person's work. UI scheduling is not a guarantee that the operating system runs your app while it is suspended.

## Server format and hosting

- [Wire contract](docs/CATALOG.md) and [JSON Schema](Schemas/catalog-v2.schema.json)
- [Cloudflare and Firebase static hosting](docs/HOSTING.md)
- [Disabled catalog](Hosting/public/v2/campaigns.json) and [future-dated example](Hosting/public/v2/catalog.example.json)

Cloudflare Workers Static Assets is the primary template. Firebase Hosting serves the same files with a different deployment configuration. Neither requires an SDK in the consuming app. The templates create no account, project, paid resource, domain, or credentials on their own.

## License and status

Library code is MIT; see [LICENSE](LICENSE). Optional app icons and brand names are excluded from the code license; see [NOTICE](NOTICE.md).

This source was prepared without running new package/app builds, tests, type checks, or live endpoint requests. Source review, package publication, a successful runtime fetch, and app submission readiness are separate results. No Cloudflare/Firebase deployment is included in the repository publication.

### 운영 요약

앱이 승인한 게시 URL과 광고 대상만 사용합니다. 서버는 JSON과 선택 이미지만 제공합니다. 자기 앱·미승인 대상·기간이 끝난 광고는 표시하지 않습니다. 유효 대상이 여러 개면 한 장씩 순환하고, 없으면 광고 행과 여백도 만들지 않습니다. 계정·사용자 식별자·기록·receipt·자동 공유 데이터는 광고 모듈로 보내지 않습니다. 운영 서버 게시와 실제 상품·신고 연결은 별도 승인된 구성으로 진행합니다.
