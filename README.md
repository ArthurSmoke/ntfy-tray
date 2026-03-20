# Ntfy Tray

A native macOS menu bar application for receiving notifications from [ntfy](https://ntfy.sh) servers.

![macOS](https://img.shields.io/badge/macOS-12%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.7-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

### Core Features
- **Real-time notifications** via WebSocket connection
- **Native macOS notifications** with system integration
- **Menu bar icon** with connection status indicator
- **Notification history** with message list
- **Multiple topic subscriptions** - subscribe to many topics at once
- **Username/password authentication** support for protected servers
- **Auto-reconnect** on connection loss
- **Launch at login** option

### User Interface
- **Modern card-based notification list** with hover effects
- **Priority indicators** (Urgent/High priority markers)
- **Topic badges** when subscribed to multiple topics
- **Clickable links** in notifications
- **Settings window** with tabbed interface (Server, Topics, Notifications, General)
- **System notification permission management**

### Notification Features
- **Priority-based interruption levels** (Time Sensitive, Active, Passive)
- **Sound notifications** (configurable)
- **Badge count** in menu bar
- **Click to open** URLs from notifications

## Installation

### Option 1: Download from GitHub Releases

1. Go to the [Releases](https://github.com/yourusername/ntfy-tray/releases) page
2. Download the latest `NtfyTray.dmg` file
3. Open the DMG and drag `Ntfy Tray.app` to your Applications folder

### Option 2: Build from Source

#### Prerequisites
- macOS 12 (Monterey) or later
- Xcode Command Line Tools

#### Build Steps

```bash
git clone https://github.com/yourusername/ntfy-tray.git
cd ntfy-tray

# Generate app icon (requires librsvg)
brew install librsvg
./scripts/generate-icon.sh

# Build the app
mkdir -p NtfyTray.app/Contents/MacOS
mkdir -p NtfyTray.app/Contents/Resources

swiftc Sources/*.swift Sources/Views/*.swift \
  -o NtfyTray.app/Contents/MacOS/NtfyTray \
  -framework SwiftUI \
  -framework UserNotifications \
  -framework AppKit

cp Info.plist NtfyTray.app/Contents/
cp AppIcon.icns NtfyTray.app/Contents/Resources/
chmod +x NtfyTray.app/Contents/MacOS/NtfyTray
```

### Option 3: Using GitHub Actions

This repository includes a GitHub Actions workflow that automatically builds the app.

#### Automatic Builds
- Every push to `main` or `develop` branches triggers a build
- Pull requests to `main` trigger builds

#### Manual Build
1. Go to the **Actions** tab in your repository
2. Select **Build macOS App** workflow
3. Click **Run workflow**
4. Select the branch and click **Run workflow**
5. Wait for the build to complete
6. Download the artifact containing `NtfyTray.dmg`

#### Creating a Release
1. Create and push a tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. The workflow will automatically create a draft release with the DMG file
3. Go to the Releases page to publish the release

## Configuration

1. Click the **bell icon** in the menu bar
2. Click the **gear icon** to open Settings
3. Configure the following:

### Server Tab
- **Server URL**: Your ntfy server address (e.g., `ntfy.sh` or `your-server.com`)
- **Authentication**: Enable and enter username/password if required

### Topics Tab
- Add one or more topics to subscribe to
- Remove topics by clicking the X button

### Notifications Tab
- Check notification permission status
- Grant permission if needed
- Enable/disable notification sounds
- Enable/disable badge count

### General Tab
- Enable/disable auto-reconnect
- Enable/disable launch at login
- Reset all settings

## Usage

### Basic Usage
1. Launch the app - a bell icon appears in the menu bar
2. **Green bell** = connected, **Red bell** = disconnected
3. Click the bell to view recent notifications
4. Notifications appear as native macOS notifications

### Testing
Send a test notification to your topic:

```bash
curl -d "Hello from ntfy!" ntfy.sh/your-topic-name
```

### Multiple Topics
Subscribe to multiple topics and messages will show which topic they came from:

```bash
curl -d "Alert from monitoring" ntfy.sh/alerts
curl -d "Message from team" ntfy.sh/team-chat
```

### Authentication
For protected servers, use the Settings window to enter your credentials:

```bash
curl -u username:password -d "Private message" ntfy.yourserver.com/protected-topic
```

## Project Structure

```
ntfy-tray/
├── Package.swift              # Swift Package Manager config
├── Info.plist                 # macOS app metadata
├── icon.svg                   # App icon (SVG source)
├── scripts/
│   └── generate-icon.sh      # Icon generation script
├── .github/
│   └── workflows/
│       └── build.yml         # GitHub Actions workflow
├── Sources/
│   ├── NtfyTrayApp.swift     # Main app entry point
│   ├── NtfyClient.swift      # WebSocket client for ntfy
│   ├── NotificationManager.swift  # macOS notification handler
│   ├── SettingsManager.swift # Settings persistence
│   ├── StatusBarController.swift  # Menu bar controller
│   ├── SettingsWindowManager.swift # Settings window manager
│   └── Views/
│       ├── NotificationListView.swift  # Notification list UI
│       └── SettingsView.swift          # Settings UI
└── README.md
```

## Requirements

- macOS 12 (Monterey) or later
- Swift 5.7+

## License

MIT License

## Acknowledgments

- Inspired by [gotify-tray](https://github.com/seird/gotify-tray)
- Built with [ntfy](https://ntfy.sh)
- Uses SF Symbols for icons

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Support

If you encounter any issues, please [open an issue](https://github.com/yourusername/ntfy-tray/issues) on GitHub.
