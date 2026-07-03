# Chemie

A pool chemical tracker, dosage calculator, and inventory manager for iOS, built with SwiftUI and SwiftData (with iCloud/CloudKit sync).

## Features

- **Water testing** — log readings for a fully customizable set of metrics (Free Chlorine, pH, Total Alkalinity, Calcium Hardness, Cyanuric Acid, Salt, Bromine, Phosphates, TDS, or any metric you add yourself), each with its own ideal range.
- **Treatment plans** — after logging a test, Chemie generates an ordered, step-by-step plan to rebalance the water: which chemical, how much, in what order, and how long to wait before the next step. Chemicals already in your inventory are recommended first; otherwise you get general guidance with multiple product options (liquid, powder, granular, tablet).
- **Custom units** — define your own measurement units (the app ships with a "Scoops" unit sized to a 24oz measuring cup) so dosage suggestions read the way you actually measure chemicals.
- **Inventory tracking** — track chemicals on hand, get low-stock and expiration alerts, and let the treatment planner check your shelf before suggesting a generic chemical.
- **Safety-aware sequencing** — the planner sequences steps (alkalinity → pH → hardness → stabilizer → salt → sanitizer) and flags chemical combinations that should never be added together or need a waiting period (e.g. acid and chlorine, algaecide and shock).
- **Reminders** — local notifications fire when a treatment step's wait time is up, when inventory runs low, and (optionally) on a recurring schedule to remind you to test.
- **History & trends** — every test and treatment plan is saved, with a Swift Charts trend view per metric over time.
- **iCloud sync** — data is stored in SwiftData backed by CloudKit, so your pool, inventory, and history sync across your devices. If CloudKit isn't available (no iCloud account, no team configured), the app automatically falls back to local-only storage.

## Project Structure

```
Chemie/
  App/                 App entry point
  Models/              SwiftData models + shared enums
  ChemistryEngine/      Dosage constants, calculator, unit conversion,
                        compatibility rules, and treatment plan generation
                        (pure Swift, no SwiftData — easy to unit test)
  Services/             Persistence (SwiftData/CloudKit), notifications,
                        inventory monitoring, default data seeding
  Theme/                 The "poolside" dark color palette and shared styles
  Views/                 SwiftUI screens, organized by feature area
  Resources/             Info.plist, entitlements, asset catalog
ChemieTests/             XCTest unit tests for the chemistry engine and
                        persistence layer
```

## Building

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate `Chemie.xcodeproj` from `project.yml`, so the `.xcodeproj` isn't hand-edited directly.

```sh
brew install xcodegen   # if you don't already have it
xcodegen generate
open Chemie.xcodeproj
```

Then in Xcode:
1. Select the **Chemie** target → **Signing & Capabilities** and choose your development team (needed for the iCloud/CloudKit entitlement).
2. Build and run on a simulator or device (iOS 17+).

If you change `project.yml` or add/remove files, re-run `xcodegen generate` to refresh the Xcode project.

## Testing

```sh
xcodebuild -project Chemie.xcodeproj -scheme Chemie \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Chemistry guidance disclaimer

Dosage calculations use standard, widely-published pool chemistry rules of thumb (e.g. "1.5 lb baking soda per 10,000 gallons raises total alkalinity by 10 ppm"). They're approximations — actual results vary with water chemistry, product concentration, and equipment — so always retest after treating and adjust as needed.
