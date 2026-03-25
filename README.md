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

### User Interface
- **Modern card-based notification list** with hover effects
- **Settings window** with tabbed interface (Server, Topics, Notifications, General)
- **System notification permission management**

### Notification Features
- **Badge count** in menu bar

## Installation

1. Go to the [Releases](https://github.com/yourusername/ntfy-tray/releases) page
2. Download the latest `NtfyTray.dmg` file
3. Open the DMG and drag `Ntfy Tray.app` to your Applications folder

## Configuration

1. Click the **bell icon** in the menu bar
2. Go to Settings
3. Configure the following:

### Server Tab
- **Server URL**: Your ntfy server address (e.g., `ntfy.sh` or `your-server.com`)
- **Authentication**: Enable and enter username/password if required

### Topics Tab
- Add one or more topics to subscribe to
- Remove topics by clicking the X button

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
