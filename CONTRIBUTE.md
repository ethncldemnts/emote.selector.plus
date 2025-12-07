# Contributing to kMoji

Thank you for your interest in contributing to kMoji! This document provides guidelines for contributing to the project.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Create a new branch for your feature or bugfix
4. Make your changes
5. Test thoroughly
6. Submit a pull request

## Development Setup

### Prerequisites

- KDE Plasma 6 development packages
- Qt 6.5+ development tools
- `kpackagetool6` (usually part of plasma-framework or plasma-desktop packages)
- `plasmawindowed` (optional, for testing in a window)

### Testing

You can test the plasmoid without installing it by running:

```bash
# Run in a standalone window
cd plasmoid
plasmawindowed org.kmoji.plasma
```

To install your changes locally for testing in the panel:

```bash
# Upgrade the existing installation
kpackagetool6 --type Plasma/Applet --upgrade plasmoid
```

## Code Style

### QML & JavaScript

- Follow KDE QML coding style
- Use consistent indentation (4 spaces)
- Prefer declarative style over imperative
- Keep components focused and reusable
- JavaScript files (in `contents/assets`) should be clean and efficient

## Directory Structure

- `plasmoid/`: The main package source
    - `contents/ui/`: QML user interface files
    - `contents/assets/`: JavaScript data (emoji lists) and other assets
    - `contents/config/`: Configuration definitions
    - `metadata.json`: Package metadata
- `scripts/`: Helper scripts for installation/uninstallation

## Submitting Changes

1. **Commit Messages**

   - Use clear, descriptive commit messages
   - Reference issue numbers when applicable
   - Keep commits focused and atomic

2. **Pull Requests**
   - Describe what changes you've made
   - Explain why the changes are necessary
   - Include screenshots for UI changes (if applicable)

## Reporting Issues

- Use the GitHub issue tracker
- Include system information (Plasma version, distro, etc.)
- Provide steps to reproduce
- If the widget crashes or fails to load, run `plasmawindowed org.kmoji.plasma` in a terminal and provide the output.

## Code of Conduct

- Be respectful and constructive
- Welcome newcomers and help them get started
- Focus on what is best for the community
- Show empathy towards other community members

## Questions?

Feel free to open an issue for any questions about contributing.
