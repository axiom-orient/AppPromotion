# Catalog v2

The catalog is public, static content. Client configuration chooses the exact catalog URL, host app ID, and approved target registry. A catalog cannot add a new approved target, choose a user account, supply a destination URL, or enable tracking.

The [JSON Schema](../Schemas/catalog-v2.schema.json) describes the wire shape. Runtime validation also enforces byte limits, Swift `Character` copy limits, safe content-addressed image paths, date ordering, local target approval, and active-campaign conflicts. Passing a JSON Schema check alone is not a runtime or advertising-policy approval.

## Envelope

| Field | Meaning |
| --- | --- |
| `schemaVersion` | Integer `2`; other schema versions are not silently reinterpreted |
| `revision` | 1–64 lowercase ASCII letters, digits or hyphens; an operator revision, not a monotonic user counter |
| `enabled` | Global catalog switch |
| `validUntil` | UTC ISO 8601 expiry |
| `campaigns` | At most 12 campaigns; campaign IDs must be unique |

Use whole-second UTC timestamps such as `2030-01-01T00:00:00Z`. End instants are exclusive. The disabled template is intentionally valid for a long period but contains no campaigns.

## Campaign

| Field | Meaning |
| --- | --- |
| `id` | Public campaign ID; 1–128 characters from `[a-z0-9._-]` |
| `host` | App ID that may display the campaign; same ID syntax |
| `target` | App ID being promoted; same ID syntax, distinct from the host |
| `startsAt`, `endsAt` | Campaign interval, with `startsAt < endsAt` |
| `description.ko`, `description.en` | Plain copy, each 1–60 Swift `Character` values; no whitespace-only text, controls, formatting controls, angle-bracket markup or line breaks |
| `icon` | Optional content-addressed image reference |

App titles and verified App Store IDs come from the client's `PromotionTarget` registry. A campaign ID is not a user, device, original-record, operation, or receipt ID. Do not put personal data in catalog IDs or URLs.

```json
{
  "schemaVersion": 2,
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
      "description": {
        "ko": "아이디어를 한 장의 그림으로 남겨요.",
        "en": "Keep an idea as a sketch."
      }
    }
  ]
}
```

This fixture is not an actual app advertisement and has no destination or image. Its date must not be mistaken for an active production schedule.

## Optional icon

An icon object contains the required reference fields below; the consuming transport also checks the same-origin URL and downloaded digest.
Malformed optional icon metadata is discarded while a valid text campaign remains eligible.

```text
path:   /v2/assets/<64 lowercase hexadecimal SHA-256>.png
sha256: <the same 64-character digest>
```

JPEG uses `.jpg` instead. Publish the file under that path after computing its digest. Do not modify bytes without changing the digest and path. The download cap is 96 KiB. The iOS artwork decoder accepts one PNG/JPEG frame, with each dimension from 1 to 256 pixels. Do not use tracking pixels, third-party image hosts, data URLs, redirects, credentials, or query strings. Files should be small static PNG/JPEG images suitable for the card; strip unnecessary metadata before publication.

## Local target registry

The app supplies each target's `PromotionAppID`, localized title and optional verified numeric App Store ID. Duplicate target IDs disable the rotation. Invalid IDs, blank/oversized titles and malformed numeric product IDs are configuration errors. The catalog does not override the title or destination.

Omitting an App Store ID is useful for a noninteractive preview. It is not permission to show an install button without a destination. Reporting is still an app-owned action; the catalog must not invent or replace its endpoint.

## Selection and expiry

1. A disabled or expired catalog supplies no card.
2. Only the current host and locally approved targets are eligible. The host app is always excluded from its own targets.
3. A campaign is active when `startsAt <= now < endsAt` and the overall catalog and feed snapshot are still valid.
4. Multiple distinct eligible targets rotate in catalog order, one per UTC minute. One target stays visible. No target produces no row.
5. Two simultaneously active campaigns for the same host and target hide that host's card rather than selecting an arbitrary winner.
6. Future start, campaign end, catalog expiry, and snapshot expiry can occur between minute boundaries. The next update follows the earliest actual transition. No per-second polling is needed.

Every card retains its campaign ID and target. Its tap action must use that displayed value. Do not select again using the clock when the action runs.

## Failure and rollback

Malformed envelopes, unsupported versions, duplicate IDs, oversized responses, invalid endpoints, or transport failures are errors, not a successful empty fetch. The app may omit the placement while retaining the diagnostic internally; it must not change the person's work or retry a generation/save operation.

A valid catalog may legitimately have no eligible card. Invalid per-campaign material cannot grant new approval or a guessed destination. Do not serve a fallback image or another advertiser as if it were the requested result.

For emergency stop, publish an enabled-false catalog with an empty campaign array. Existing snapshots expire within their five-minute lease; do not promise instant removal on suspended/offline devices. Only roll back to a compatible, unexpired and still approved catalog. Revisions do not have to increase, so a deliberate safe rollback remains possible.
