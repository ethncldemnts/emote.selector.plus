<br />
<div align="center">
  <a href="https://github.com/leeineian/kMoji">
    <img src="./LOGO.svg" alt="kMoji" width="80" height="80">
  </a>

  <h3 align="center">kMoji</h3>

  <p align="center">
    A panel-integrated emote selector for KDE Plasma 6.
    <br />
  </p>
</div>

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/leeineian/kMoji/master/scripts/get.sh | bash

# With options:
curl -fsSL https://raw.githubusercontent.com/leeineian/kMoji/master/scripts/get.sh | bash -s -- --verbose
```

## Run in a window

```fish
plasmawindowed org.kmoji.plasma
```

## Notes
- Requires Plasma 6 (KF6) and Qt 6.
- Clipboard uses KDE KQuickControlsAddons. Ensure the `org.kde.kquickcontrolsaddons` QML module is present.
- Emoji data is loaded from `assets/emoji-list.js`