# AppPromotion

Read README.md and docs/CATALOG.md before editing contracts. Work in English; reply in Korean when requested.
Keep Foundation selection values, URLSession transport, SwiftUI UI and optional branded examples in separate targets.
The SDK accepts generic local app IDs and a public HTTPS catalog URL. Do not hardcode customer apps in core/transport/UI.
Keep trust modes explicit: v2 uses the app-owned target registry; opt-in v3 uses operator-approved remote titles and
HTTPS destinations. Never merge approvals or silently fall back between versions. Changing the selected catalog is a
trust decision. Keep the old v2 URL and asset paths usable for existing consumers.
Preserve campaign identity and the displayed card during interactions. Ads must never own app records, user IDs, receipts,
authentication, tracking, automatic retries or persistent app state.
The optional SwiftUI placement owns scene-scoped, transient retrieval and successful lease renewal only. No retry on a
failed request, stale persistent cache, extra loading screen or empty row. Preserve host view identity and cancel late work.
Catalog/image privacy and destination-site privacy are separate; never promise the latter is tracking-free.
Never publish keys, private URLs, device material or customer data. The optional example brand assets are excluded from MIT.
Do not create/modify/suggest GitHub Actions, CI/CD, release automation or .github/workflows.
Run compilation/tests only when the current user permits them. Publication is not proof of runtime correctness.
