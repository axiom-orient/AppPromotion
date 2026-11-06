# Catalog contracts

Catalogs are public static content, not remote code or UI definitions. The app chooses an exact HTTPS catalog URL and host app ID. Two explicit trust modes share the same scheduling and transport rules:

| Mode | Approval owner | Selection API |
| --- | --- | --- |
| v3 | The trusted catalog operator approves localized titles and HTTPS destinations | `rotation(host:language:)` and `PromotionPlacement` |
| v2 | The app owns a local `PromotionTarget` registry | `rotation(host:targets:language:)` |

The modes never merge or fall back to each other. Choosing v3 delegates advertiser and destination review to the operator of the selected catalog. This is not independent verification of arbitrary advertisers. Keep existing v2 URLs and local registries when that approval boundary is required.

## Common envelope

| Field | Meaning |
| --- | --- |
| `schemaVersion` | Integer `2` or `3`; selection must use the matching API |
| `revision` | 1–64 lowercase ASCII letters, digits or hyphens; not a monotonic user counter |
| `enabled` | Global catalog switch |
| `validUntil` | Catalog expiry |
| `campaigns` | At most 12 campaigns, with unique campaign IDs |

Publish whole-second UTC timestamps such as `2030-01-01T00:00:00Z`. Runtime uses Foundation ISO 8601 decoding; the schemas describe the canonical producer format. End instants are exclusive. A catalog is at most 32 KiB.

## v3 campaign

| Field | Meaning |
| --- | --- |
| `id` | Public campaign ID; 1–128 characters from `[a-z0-9._-]` |
| `host` | App ID allowed to display this campaign; same ID syntax |
| `target` | Promoted app or partner ID; same syntax and distinct from the host |
| `startsAt`, `endsAt` | Interval with `startsAt < endsAt` |
| `title.ko`, `title.en` | Localized advertiser/product name |
| `description.ko`, `description.en` | One short, useful description |
| `destination` | Publisher-approved absolute HTTPS URL |
| `icon` | Optional content-addressed image reference |

Each title and description must contain 1–60 Swift `Character` values and nonblank plain text. Controls, format controls, angle brackets and line breaks are rejected. The schemas cannot express the Swift grapheme limit or all runtime relationships.

```json
{
  "schemaVersion": 3,
  "revision": "example-01",
  "enabled": true,
  "validUntil": "2030-02-01T00:00:00Z",
  "campaigns": [
    {
      "id": "notes-to-sketch-01",
      "host": "notes",
      "target": "sketch",
      "startsAt": "2030-01-01T00:00:00Z",
      "endsAt": "2030-01-15T00:00:00Z",
      "title": {"ko": "그림 앱", "en": "Drawing app"},
      "description": {
        "ko": "아이디어를 그림으로 남겨요.",
        "en": "Keep an idea as a sketch."
      },
      "destination": "https://example.com/sketch"
    }
  ]
}
```

This is a future-dated format example with a reserved domain, not a live advertisement. Replace its dates, copy and destination with reviewed material before publication. [v3 schema](../Schemas/catalog-v3.schema.json)

### Destinations

`PromotionDestination` validates an absolute HTTPS URL up to 2048 UTF-8 bytes. It rejects credentials, non-443 explicit ports, control/format characters and backslashes, including percent-decoded forms. Custom schemes, JavaScript, relative URLs and HTTP are not accepted. The scheme and host are normalized to lowercase.

Static query parameters and fragments are allowed for ordinary landing pages. Do not place user/device data or secrets in them. Only the exact `apps.apple.com` host receives App Store accessibility wording; other destinations use web wording. A Universal Link may be handled by the destination app through normal system behavior. The SDK never probes an installation or invents a product ID.

The transport's stricter catalog URL rules are separate: catalog endpoints permit no credentials, query, fragment or redirects. Destination sites can have their own redirects and analytics after an explicit tap; their behavior is the operator's responsibility.

## v2 compatibility

v2 uses the common envelope and campaign fields except that `title` and `destination` come from the local `PromotionTarget` registry. Adding remote fields to v2 cannot replace local approval. `PromotionTarget(id:title:appStoreID:)` retains the numeric-ID contract; the added `destination:` initializer accepts a validated `PromotionDestination` for a locally approved web link. A target with no destination is a noninteractive preview, not permission for a fake action.

Duplicate local target IDs disable v2 rotation. Invalid IDs, blank/oversized local titles and malformed numeric product IDs are configuration errors. The registry selection overload produces no v3 card; the v3 overload produces no v2 card. `PromotionPlacement` reports a v2 response as `unsupportedSchema` rather than treating it as a legitimate empty v3 feed. [v2 schema](../Schemas/catalog-v2.schema.json)

## Optional icon

Both versions intentionally retain the same immutable asset contract:

```text
path:   /v2/assets/<64 lowercase hexadecimal SHA-256>.png
sha256: <the same 64-character digest>
```

JPEG uses `.jpg`. Keep bytes under 96 KiB, with one static PNG/JPEG frame and dimensions 1–256 pixels per side. Strip unnecessary metadata. The transport uses the catalog origin, rejects redirects and verifies the downloaded SHA-256 before the UI decoder reads the bytes.

Malformed optional references are omitted while a valid text campaign remains eligible. In the ready-made placement, a download/decode failure is reported through `onFailure`; only that icon is omitted. Publish changed image bytes under a changed digest/path. Keep older assets available while unexpired clients may use them. No fallback advertiser or image is substituted.

## Selection and lease

1. Disabled or expired catalogs provide no card.
2. A campaign must match the host. The host is always excluded from its own targets. v2 additionally requires local target approval; v3 requires valid remote title and destination.
3. Active means `startsAt <= now < endsAt`, within catalog and feed lease bounds.
4. Distinct eligible targets rotate in catalog order, one per UTC minute. One target stays visible; no target means no row.
5. Simultaneously active campaigns for the same host/target hide that host's card until the conflict ends.
6. Future starts, campaign ends, catalog expiry and feed expiry can occur between minute boundaries. The next update follows the earliest transition without per-second polling.

`PromotionFeed` is in-memory only and expires at the earlier of catalog expiry and five minutes after receipt. The ready-made placement receives only in an enabled, active scene and renews a successfully received live lease. Failed requests do not retry automatically. Re-enable, configuration change or active scene re-entry starts a new request. An already expired catalog stops the renewal loop. UI scheduling does not guarantee execution while the OS suspends the app.

Every card keeps its campaign ID, target and destination during interaction. Open and information actions use the displayed immutable card, never another clock-based selection.

## Failure and emergency stop

Malformed envelopes, unsupported versions, duplicate campaign IDs, oversized responses, invalid endpoints and transport failures are errors. Invalid per-campaign copy, schedules or v3 destination metadata make that campaign ineligible. A valid catalog can legitimately have no eligible card. A schema check alone is neither runtime validation nor advertising-policy approval.

For emergency stop, publish `enabled: false` and an empty campaign array. Existing feed leases expire within five minutes, further bounded by catalog expiry. Instant removal on suspended/offline devices is not guaranteed. Roll back only to a compatible, unexpired and still-approved catalog; revisions need not increase.

Campaign IDs are public advertising keys, never user, installation, original-record, operation or receipt IDs. Catalog changes must not clear work, resubmit a generation/save or alter automatic sharing.
