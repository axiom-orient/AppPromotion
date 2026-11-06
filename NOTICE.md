# Code and brand assets

The library source code is distributed under the MIT license in [LICENSE](LICENSE).

The optional `AppPromotionExamples` product contains first-party preview configuration and app artwork. App names, logos, icons, and other brand material are **not licensed under MIT**. Their owners retain their rights. The code license does not grant a trademark license or permission to promote, impersonate, or redistribute another product's brand assets outside an authorized use.

The generic catalog schema and Hosting examples do not require any particular app, publisher, Firebase project, Cloudflare account, or private setting.

## Optional example artwork provenance

The example image files originate from the native AppIcon sets of their respective first-party apps. The small bundled files were copied unchanged from existing native app build outputs (`AppIcon76x76@2x~ipad.png`), not generated as replacement brands:

- `sumday.png`: Sumday native `AppIcon.appiconset/AppIcon.png`
- `daypage.png`: DayPage native `AppIcon.appiconset/DayPageIcon-DayNight-Oil.png`
- `caseboard.png`: Caseboard native `AppIcon.appiconset/AppIcon.png`

These optional names are example integration material, not hardcoded identifiers in the public SDK or server schema. A consumer using its own apps should omit `AppPromotionExamples` and provide its own approved targets and authorized artwork.
