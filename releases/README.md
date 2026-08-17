# Ganzo App Releases

## Structure

```
releases/
├── install.sh          # Linux install script (curl | bash)
├── latest.json         # Tauri auto-updater manifest
├── macos/              # macOS .dmg + .tar.gz + .sig
├── linux-x86/          # Linux x86_64 .deb
└── linux-arm64/        # Linux ARM64 .deb
```

## Install

### macOS

Download the .dmg from [GitHub Releases](https://github.com/ganzoai/ganzo/releases):

```
https://github.com/ganzoai/ganzo/releases/latest/download/Ganzo_aarch64.dmg
```

### Linux (x86_64 and ARM64)

```bash
curl -fsSL https://raw.githubusercontent.com/ganzoai/ganzo/main/releases/install.sh | bash
```

The script detects the architecture, downloads the correct .deb, installs it,
and sets up a systemd service.

### Android

Install from Google Play Store (coming soon).

### iOS

Install from Apple App Store (coming soon).

## Tauri Auto-Updater

The app checks `latest.json` on startup for updates. When a new version is
available, the in-app overlay prompts the user to update.

- Endpoint: `https://raw.githubusercontent.com/ganzoai/ganzo/main/releases/latest.json`
- Signing key: `~/.tauri/ganzo-updater.key` (password: ganzo2024)

## Release Process

1. Bump version in Cargo.toml, tauri.conf.json, ganzo-config*.json
2. Build on each platform:
   - macOS: `npx tauri build` (produces .dmg + .tar.gz + .sig)
   - Linux: `cargo build --release` (produces .deb via `cargo-deb`)
3. Upload binaries to GitHub Release on ganzoai/ganzo
4. Update `latest.json` with new version + signatures
5. Commit and push
6. Tag: `git tag v<version> && git push --tags`