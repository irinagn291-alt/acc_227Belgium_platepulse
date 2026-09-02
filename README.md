# PlatePulse

Readable by everyone, always. PlatePulse is an offline-first calorie and macro log for people who want food data as clear as a vital-sign monitor. There is no account, no ads, and no medical advice — only a personal reading of what you ate.

Open Food Facts supplies product data. Nutrition credit belongs to that public database.

Sources (in-app, on Today, Goals, onboarding and Detail): Open Food Facts, USDA / HHS Dietary Guidelines for Americans 2020–2025, FDA Daily Values, and National Academies Dietary Reference Intakes (AMDR). Each row opens the official page. Starting 2,000 kcal / macro grams follow those references and are not medical advice.

## Who it is for

Anyone who wants to log energy and macros without typing every field, including VoiceOver users, large-type users, and anyone who prefers swipe over deep navigation stacks.

## Architecture

**Passive View MVP + Coordinator.**

Each `UIViewController` implements a `View` protocol and forwards actions to a `Presenter`. The presenter holds a weak view, talks to `PulseMgr` / `FoodSvc`, and pushes fully formatted strings. Coordinators own navigation as a parent/child tree with `didFinish` callbacks.

This fits PlatePulse because the product is a sequence of readings (today, log, plan, a four-step logging journey). Presenters stay testable; views stay mute; coordinators keep swipe pages and modal flows from leaking into business rules.

## Access Mode (the twist)

Accessibility is the marketed feature, not a settings afterthought.

- VoiceOver labels, hints and traits on every control
- Dynamic Type through AX5 on a six-step SF Pro Rounded scale
- Persisted high-contrast theme (`a11y.plist`, `A11yPrefs`)
- Reduce Motion: fades instead of motion
- 44×44 pt hit targets

Today exposes **Access**. The dedicated Access Mode screen is the twist surface. High contrast swaps the muted token to ink (`A11yLogic`).

## Design

Medical monitor / vital signs. Dark only.

| Token | Hex |
| --- | --- |
| background | `#00363A` |
| surface | `#014D52` |
| ink | `#F0FBFC` |
| accent | `#FF5A5F` |
| muted | `#6FA0A4` |

Slots: Dawn Reading, Noon Reading, Dusk Reading, Interval. Interval cannot be planned; a future date remaps it to Dusk Reading (Evening).

Plan horizon: **14 days**.

Persistence: `PropertyListEncoder` files in Application Support — `entries.plist`, `targets.plist`, `wishlist.plist` (+ `a11y.plist`). Atomic writes, `schemaVersion`, off the main thread, flush on background.

Search: `https://world.openfoodfacts.org/cgi/search.pl` with `page_size=18`.

User-Agent: `PlatePulse/1.0 (iOS; +https://platepulse.pro)`

Day key: `DateComponents` year / month / day.

Scanner: live `AVCaptureMetadataOutput`, large Lock reading trigger, high-contrast reticle, VoiceOver announcement on each read. Simulator falls back to sample chips + manual entry.

Then is vendored in `Vendor/Then/` (MIT). No SPM entry.

## How this app differs

Four swipe pages (Today / Log / Plan / Goals) plus a separate four-step modal (Search / Scan / Detail / Assign) with its own page control. UIKit + XIBs only. Short abbreviated type names (`PulseMgr`, `FoodSvc`, `DayPrsntr`). Flat sources. No shared code with the rest of the 21AUG batch.

## Build

```bash
cd App05_PlatePulse
/Users/belzephyrus/Documents/gambling/21AUG/tools/xcodegen/bin/xcodegen generate
xcodebuild -scheme PlatePulse -destination 'generic/platform=iOS' build
```

Tests: `PlatePulseTests`.

Bundle ID: `com.platepulse.pulse`. Domain: https://platepulse.pro — contact https://platepulse.pro/contact-us.

Demo seed runs only on Simulator, once, behind `plp.demo.v1`.

## AI art

Style: neon outline / glowing line art.

Base prompt reused for every asset:

```
neon outline line art, glowing coral stroke on deep teal, medical monitor aesthetic, minimal vector glow, dark background
```

Exact prompt per image set:

**plp_AppIcon** — neon outline line art, glowing coral stroke on deep teal, medical monitor aesthetic, minimal vector glow, dark background, the app's single emblem, centred, filling the canvas edge to edge

**plp_Splash** — … a vertical hero composition with a calm, uncluttered centre band

**plp_Onboarding1** — … a person or object representing discovering what is in packaged food

**plp_Onboarding2** — … a scanning or measuring motif showing a product being identified

**plp_Onboarding3** — … a goal or target motif showing daily progress being met

**plp_EmptyLog** — … an empty vessel, surface or container waiting to be filled

**plp_EmptySearch** — … a search motif that has come back with nothing found

**plp_EmptyPlan** — … an empty schedule, grid or horizon with nothing scheduled

**plp_EmptyWish** — … an empty basket, list or shelf

**plp_SlotDawnReading** — … a morning motif appropriate to the theme

**plp_SlotNoonReading** — … a midday motif appropriate to the theme

**plp_SlotDuskReading** — … an evening motif appropriate to the theme

**plp_SlotInterval** — … a small extra or in-between motif appropriate to the theme

**plp_MacroProtein** — … a symbol standing for protein, rendered as a single clear emblem

**plp_MacroCarbs** — … a symbol standing for carbohydrate, rendered as a single clear emblem

**plp_MacroFat** — … a symbol standing for dietary fat, rendered as a single clear emblem

**plp_ProductPlaceholder** — … a generic packaged grocery item with no readable branding

**plp_CardBackdrop** — … an abstract backdrop suitable for sitting behind a product card

**plp_Texture** — … a seamless repeating surface pattern

**plp_ControlFace** — … the face of a single physical control such as a dial, key or slider handle

**plp_ScanOverlay** — … a framing reticle or targeting bracket, open in the middle

**plp_TwistHero** — … an emblem representing this app's signature feature

**plp_SuccessMark** — … a confirmation mark or celebratory emblem

**plp_HeaderDecor** — … a wide decorative band or ornament
