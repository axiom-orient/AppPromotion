# Renewal research decisions

Reviewed on 2026-11-06 against the package's one-card scope. These are source/document comparisons, not runtime qualification of the referenced projects. No third-party code or package dependency was copied into AppPromotion.

| Primary source | Relevant approach | Decision |
| --- | --- | --- |
| [CrossPromoKit](https://github.com/yoonhg84/CrossPromoKit) | Remote JSON, simple configuration and a SwiftUI entry point | Adopt the simple connection. Exclude its settings-list focus, tracking hooks, long-lived cache and overlay state |
| [TNCrossPromo](https://github.com/frederik-jacques/TNCrossPromo) | Hosted catalog with web and App Store destinations | Adopt HTTPS destinations. Exclude carousel, full catalog screen and loading space |
| [MoPromoteKit](https://github.com/mkhasson97/MoPromoteKit) | Developer-app discovery and Store metadata | Exclude automatic discovery and regional rating aggregation; the operator approves ads explicitly |
| [SBAppPortfolio](https://github.com/slowbrewedmacchiato/SBAppPortfolio) | Separate metadata core and native presentation; self-exclusion | Retain separate Core/I/O/UI targets and self-exclusion. Exclude the extra portfolio sheet and live metadata lookup |
| [App Friends](https://github.com/Parra-Inc/app-friends) | Cross-promotion network and SDK | Exclude network matching and popup/full-screen formats; they exceed one operator-managed card |
| [EthicalAds client](https://github.com/readthedocs/ethical-ad-client) | Small text/image placement | Retain a restrained native composition. Exclude JavaScript and event collection |
| [Ethical Ad Server](https://github.com/readthedocs/ethical-ad-server) | Campaign serving and operational reporting | Exclude its server/database stack; static content is sufficient here |
| [Revive Adserver](https://github.com/revive-adserver/revive-adserver) | Advertising administration and reporting platform | Exclude a campaign-management server, targeting and click reporting |
| [Nuke](https://github.com/kean/Nuke), [Kingfisher](https://github.com/onevcat/Kingfisher) | General image pipelines, caching and processing | Keep bounded URLSession, SHA-256 and ImageIO for one small static icon; no dependency is needed |

## Chosen implementation

One Foundation selector, one bounded HTTPS client and one optional SwiftUI receiving boundary. The receiving boundary supplies an optional advertisement to the existing container. It does not add an app Store, loading screen, advertiser list, retry UI, persistent cache, metrics or HTML rendering.

v3 makes routine configuration a catalog edit: the trusted operator supplies localized titles, copy, schedules and approved HTTPS destinations. The v2 local registry remains available for clients that require local approval. Neither trust model silently substitutes for the other.

The platform's [`OpenURLAction`](https://developer.apple.com/documentation/swiftui/openurlaction) handles an explicit tap on the displayed destination. [`SKOverlay`](https://developer.apple.com/documentation/storekit/skoverlay) is unnecessary for the default one-card flow because it introduces a separate presentation lifetime and failure path. HTTPS also covers normal web pages and Universal Links without app probing or custom-scheme routing.

Keep the ad label and information/reporting callback. Apple's [App Review Guidelines, 2.5.18](https://developer.apple.com/app-store/review/guidelines/#software-requirements) require access to ad-targeting information and a way to report inappropriate ads. In this package, selection uses public host ID, order and schedule; the SDK supplies no personal targeting data. The consuming app owns the actual information and report flow.

Use [Cloudflare Workers Static Assets](https://developers.cloudflare.com/workers/static-assets/) as the primary hosting template. [Firebase Hosting](https://firebase.google.com/docs/hosting) can serve the same files. Neither a database nor a provider runtime SDK is required for static JSON/images. Actual account limits and any deployment still require separate operational approval; this renewal does not change them.
