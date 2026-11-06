# Serve the catalog as static files

Use the same `/v2/campaigns.json` contract on one chosen HTTPS origin. The app receives an explicit catalog URL; it does not need Cloudflare, Firebase, Firestore, Remote Config, or advertising SDKs.

These files are templates. They have not been deployed or used to create an account, project, billing connection, domain, DNS record, or live campaign.

## Cloudflare: primary template

[Workers Static Assets](https://developers.cloudflare.com/workers/static-assets/get-started/) can serve a directory without a Worker script. Static asset requests and asset storage have no separate charge under the documented static-assets model; Worker code requests have a different billing model. Check the selected account's actual plan before deployment. [Billing and limits](https://developers.cloudflare.com/workers/static-assets/billing-and-limitations/)

Use [Hosting/wrangler.jsonc](../Hosting/wrangler.jsonc) with [Hosting/public](../Hosting/public). Choose an unused, approved Worker name. No script, storage database, account ID, custom domain, or paid settings are declared. The supplied catalog is disabled.

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

1. Keep `campaigns.json` disabled until target registry, dates, image rights, destination and reporting are ready.
2. Prepare copy against [CATALOG](CATALOG.md) and [the schema](../Schemas/catalog-v2.schema.json). Never put user or device data in it.
3. For images, publish small PNG/JPEG files under their exact SHA-256 filenames. The maximum download size is 96 KiB. A changed image needs a changed digest/path.
4. Publish catalog and referenced assets together. Preserve older content-addressed assets while unexpired clients may still use them.
5. Give the consuming app the approved canonical catalog URL. Redirects and URL query tokens are not supported.
6. Stop by publishing a new disabled catalog. A previously read snapshot may remain usable for at most five minutes, bounded further by catalog expiry. Suspended/offline apps cannot be contacted instantly.
7. Roll back only to a compatible and unexpired version with still-approved material. A rollout or rollback is a server operation and is not implied by publishing this Swift package.

Neither raw GitHub file URLs nor a source-code repository are the default production content origin. Git stores reviewable source; the selected static host serves the catalog and images.

## Separate operational responsibilities

App Store product IDs must be verified by the app owner and supplied through the local target registry. The SDK does not scrape or invent them. The app also owns ad disclosure, applicable age/content rules, the explanation of targeting, and a working reporting route. These have to match the app's actual behavior before enabling a live placement.
