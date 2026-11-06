# Serve the catalog as static files

Serve `/v3/campaigns.json` on one chosen HTTPS origin for the ready-made placement. Keep `/v2/campaigns.json` for existing local-registry consumers. The app receives an explicit catalog URL; it does not need Cloudflare, Firebase, Firestore, Remote Config, or advertising SDKs.

These files are templates. They have not been deployed or used to create an account, project, billing connection, domain, DNS record, or live campaign.

## Cloudflare: primary template

[Workers Static Assets](https://developers.cloudflare.com/workers/static-assets/get-started/) can serve a directory without a Worker script. Static asset requests and asset storage have no separate charge under the documented static-assets model; Worker code requests have a different billing model. Check the selected account's actual plan before deployment. [Billing and limits](https://developers.cloudflare.com/workers/static-assets/billing-and-limitations/)

Use [Hosting/wrangler.jsonc](../Hosting/wrangler.jsonc) with [Hosting/public](../Hosting/public). Choose an unused, approved Worker name. No script, storage database, account ID, custom domain, or paid settings are declared. Both supplied `campaigns.json` catalogs are disabled. The `catalog.example.json` files are future-dated examples with reserved domains or no destination; they are not production ads.

After the operator authorizes the actual account and host, the manual deployment command from `Hosting` is:

```sh
wrangler deploy --config wrangler.jsonc
```

This command is documentation, not an action performed by this repository. It publishes static files to the selected Cloudflare account. Keep the default `workers.dev` address unless a separate domain change is authorized. Do not put account credentials in the repository or catalog.

`public/_headers` sets JSON to `no-store` and content-addressed image files to an immutable cache policy. [Cloudflare headers](https://developers.cloudflare.com/workers/static-assets/headers/)

## Firebase Hosting: alternative

[Firebase Hosting](https://firebase.google.com/docs/hosting) can serve the same files from its HTTPS CDN. This is Hosting, not Cloud Storage for Firebase. Its storage and monthly transfer quotas apply even to cached traffic. [Hosting quotas](https://firebase.google.com/docs/hosting/usage-quotas-pricing)

[Hosting/firebase.json](../Hosting/firebase.json) supplies Hosting headers and the public directory. No `.firebaserc`, project ID, authentication, function, database, storage bucket, or billing plan is configured.

After the operator authorizes an actual existing project, the manual command from `Hosting` is:

```sh
firebase deploy --config firebase.json --project YOUR_FIREBASE_PROJECT_ID --only hosting
```

Replace `YOUR_FIREBASE_PROJECT_ID` with the approved project ID. The command publishes files; it does not establish that the account is free or authorize a paid-plan change. Use the existing plan and stop if the intended free configuration is unavailable. [Firebase cache headers](https://firebase.google.com/docs/hosting/manage-cache)

## Publication rules

1. Keep `campaigns.json` disabled until operator approval (v3) or the app's target registry (v2), dates, image rights, destinations and reporting are ready.
2. Prepare copy against [CATALOG](CATALOG.md) and the matching [v3 schema](../Schemas/catalog-v3.schema.json) or [v2 schema](../Schemas/catalog-v2.schema.json). Never put user or device data in it.
3. For images, publish small PNG/JPEG files under their exact SHA-256 filenames. The maximum download size is 96 KiB. A changed image needs a changed digest/path.
4. Publish catalog and referenced assets together. Preserve older content-addressed assets while unexpired clients may still use them.
5. Give the consuming app the approved canonical catalog URL. Catalog redirects and query tokens are not supported. v3 destinations may contain static query parameters/fragments, but never credentials, secrets or user/device data.
6. Stop by publishing a new disabled catalog. A previously read snapshot may remain usable for at most five minutes, bounded further by catalog expiry. Suspended/offline apps cannot be contacted instantly.
7. Roll back only to a compatible and unexpired version with still-approved material. A rollout or rollback is a server operation and is not implied by publishing this Swift package.

Neither raw GitHub file URLs nor a source-code repository are the default production content origin. Git stores reviewable source; the selected static host serves the catalog and images.

## Separate operational responsibilities

For v3, the catalog operator reviews every title, destination, content change and advertiser before publication. A new approved partner or destination can then be published without changing the client. For v2, the app owner supplies and updates the local target registry. Do not replace a v2 catalog with v3 in place: use the separate URL to opt in.

Verify actual App Store product links before publication; the SDK does not scrape, invent or establish the availability of a product. The app also owns ad disclosure, applicable age/content rules, an in-app explanation of selection, and a working report route. These have to match actual behavior before enabling a live placement. The destination site may have its own analytics; catalog/image request privacy does not certify that site.
