# Installation Guide

## Prerequisites

- KDE Plasma 6 or later
- Plasma SDK (provides `kpackagetool6` for widget installation)
- `org.kde.kquickcontrolsaddons` QML module (usually installed by default with Plasma)

## Quick Install Script

For convenience, use the provided install script:

```bash
./scripts/install.sh
```

This will install the plasmoid automatically.

## Manual Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/leeineian/kMoji.git
   cd kMoji
   ```

2. **Install the Plasmoid**

   ```bash
   kpackagetool6 --type Plasma/Applet --install plasmoid
   ```

   If you are updating from a previous version, use `--upgrade` instead of `--install`.

## Verifying Installation

1. **Add widget to panel**
   - Right-click on your Plasma panel
   - Select "Add Widgets"
   - Search for "kMoji"
   - Drag to panel

## Troubleshooting

### Widget not showing up

- Ensure you have `kpackagetool6` installed.
- Try restarting the Plasma shell:
  ```bash
  systemctl --user restart plasma-plasmashell
  ```
- Check for errors by running the widget in a window:
  ```bash
  plasmawindowed org.kmoji.plasma
  ```

### Missing dependencies

- If you see errors about missing QML modules, ensure you have the full KDE Plasma 6 desktop installed.

## Uninstalling

### Automated Uninstall

The easiest way is to use the installer script:

```bash
./scripts/install.sh --uninstall
```

### Manual Uninstall

If you need to manually remove kMoji:

```bash
kpackagetool6 --type Plasma/Applet --remove org.kmoji.plasma
```
