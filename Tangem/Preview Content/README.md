# Preview Content

Resources in this folder are for SwiftUI previews and test builds only — they must
never ship in a release build.

They are **not** stripped from release automatically: `DEVELOPMENT_ASSET_PATHS` is not
honoured for the file-system-synchronized `Tangem/` group in Xcode 16, so files placed
here would otherwise be copied into the production IPA.

If you add a JSON or other resource here that must not ship in release, add its filename
to `EXCLUDED_SOURCE_FILE_NAMES` in the `Release(production)` configuration in
`TangemApp.xcodeproj/project.pbxproj`. A folder glob does **not** work for this folder
(unlike `CardMocks/`, which is covered by `*/CardMocks/*`), so each file has to be listed
by its exact name.
