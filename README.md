# 26Settings (com.meowly.26settings)

Brings iOS 26's Settings design to iOS 15–16, modelled on the real iOS 26
screenshots in Apple's iPhone User Guide: 22pt continuous-corner group cards,
taller rows, sentence-case section headers, 29pt squircle glyphs, a translucent
navigation bar, a pill search field, an account/quick-glance banner on the root
pane, and rounded glass notification banners in SpringBoard.

Every piece is individually toggleable (and the metrics are sliders) from the
`26Settings` row in Settings, plus an injected "Liquid Glass" pane.

## Layout
- `Tweak/Settings.xm` — Settings-app hooks (group cards, icons, headers, search,
  switches, navigation bar, root banner, Liquid Glass pane injection)
- `Tweak/Banners.xm` — SpringBoard notification banner rounding
- `Tweak/MLYPrefs.{h,m}` — typed preference access + Darwin-notification reload
- `Tweak/MLYStyle.{h,m}` — shared geometry/tint helpers
- `Tweak/MLYBannerView.{h,m}` — the root-pane account card
- `26SettingsPrefs/` — PreferenceLoader bundle (the "26Settings" row in Settings)
- `icons/` — sample white glyphs installed to `Library/26Settings/Icons.bundle`
  (rootless builds get `/var/jb/` automatically via `THEOS_PACKAGE_SCHEME=rootless`)

## Build
    make package                                   # rootful
    make package THEOS_PACKAGE_SCHEME=rootless     # Dopamine / palera1n rootless

## Custom icons
iOS 26's real glyphs are Apple's artwork — don't redistribute them. Draw or
extract your own white-on-transparent PNGs (120x120) named after each row's
specifier identifier or its title (e.g. `General.png`, `Accessibility.png`) and
drop them in `Icons.bundle`. The tweak templates them white and sits them on the
tinted squircle. Stock system icons are used as fallback.

## Notes
- Only `com.apple.Preferences` and `com.apple.springboard` are injected, and each
  `%ctor` bails out unless it is in the process it targets.
- PSTableCell/PSListController internals vary per iOS version, so the icon view
  is located defensively (`imageView`, `iconImageView`, `iconImage`, or the
  leading image view) and the row/footer height overrides are only installed when
  `PSListController` actually implements them.
- The root banner is (re)installed from `viewWillAppear`/`viewDidLayoutSubviews`,
  because the stock root pane assigns its own `tableHeaderView` after the view
  has loaded and would otherwise drop it.
- Preferences live in the `com.meowly.26settings` suite and every change posts
  `com.meowly.26settings.prefschanged`, so other tweaks can follow along.
