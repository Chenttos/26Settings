# 26Settings (com.meowly.26settings)

Brings iOS 26's Settings design to iOS 15–16: banner card on the root pane,
circular tinted icons, card-style grouped backdrop, and an injected
"Liquid Glass" pane (Clear/Tinted — decorative switches, like the real ones).

## Layout
- `Tweak.xm` — all hooks (PSTableCell icons, PSListController banner + pane injection)
- `26SettingsPrefs/` — PreferenceLoader bundle (the "26Settings" row in Settings)
- `icons/` — sample white glyphs installed to `Library/26Settings/Icons.bundle`
  (rootless builds get `/var/jb/` automatically via `THEOS_PACKAGE_SCHEME=rootless`)

## Build
    make package                                   # rootful
    make package THEOS_PACKAGE_SCHEME=rootless     # Dopamine / palera1n rootless

## Custom icons
iOS 26's real glyphs are Apple's artwork — don't redistribute them. Draw or
extract your own white-on-transparent PNGs (120x120) named after each row's
specifier identifier (e.g. `General.png`, `Accessibility.png`) and drop them
in `Icons.bundle`. The tweak templates them white and sits them on the tinted
circle. Stock system icons are used as fallback.

## Notes
- Only `com.apple.Preferences` is injected, so the hooks don't leak elsewhere.
- The banner/card/injection code keys off the root pane (`self.specifier == nil`
  and title == "Settings"). Exact PSTableCell/PSListController internals vary a
  bit per iOS version — if something doesn't show on your version, class-dump
  Preferences.framework and adjust selectors.
- The Liquid Glass switches are cosmetic (they persist and could drive other
  tweaks via the `com.meowly.26settings` suite / Darwin notification).
