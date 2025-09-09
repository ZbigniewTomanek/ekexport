# ekexport

**A simple acOS command-line tool for exporting calendar events and reminders to various formats.**

`ekexport` provides a clean, scriptable interface to access your macOS Calendar and Reminders data, supporting both iCalendar (.ics) and JSON export formats. Built with Swift and designed for automation, the tool respects macOS privacy controls and provides stable, reliable access to your calendar data across multiple accounts (iCloud, Google, Exchange, etc.).

## Features

- **Multi-format Export**: Export to iCalendar (.ics) or structured JSON
- **Universal Account Support**: Works with iCloud, Google, Exchange, CalDAV, and local calendars
- **Flexible Date Ranges**: Export specific time periods or all historical data
- **Calendar Filtering**: Export from specific calendars or all accessible calendars
- **Reminders Support**: Include reminders in exports alongside calendar events
- **Privacy-First**: Respects macOS TCC (Transparency, Consent, and Control) framework
- **Script-Friendly**: Clean stdout output perfect for pipes and automation
- **Production Ready**: Comprehensive error handling and user guidance

## Motivation

I built ekexport after running into limitations with AppleScript-based approaches. In my setup, AppleScript could only reliably export events stored locally and struggled to access events from cloud-synced calendars. Having a single tool that exports everything visible in the Apple Calendar app is far more convenient because macOS manages access to all accounts (iCloud, Google, etc.) under one permissions model—no need to juggle separate access tokens for each provider. This makes automation straightforward and dependable, which is especially useful for my AI agent running on a Mac mini server.

## Requirements

- **macOS 13.0+** (Ventura or later)
- **Xcode Command Line Tools** or Swift toolchain
- **Calendar/Reminders Access**: The tool will request permission on first run

## Installation

### Quick Install (macOS arm64)

Install the latest prebuilt binary (Apple Silicon, macOS 13+):

```bash
curl -fsSL https://raw.githubusercontent.com/ZbigniewTomanek/ekexport/main/install.sh | sh
```

The script verifies your macOS version (13+) and Apple Silicon (arm64) architecture, downloads the latest GitHub release, and installs `ekexport` to `/usr/local/bin`.

### Option 1: Build from Source

```bash
# Clone the repository
git clone <repository-url>
cd ekexport

# Build release binary
swift build -c release

# Install to /usr/local/bin (requires sudo)
make install

# Or install to custom location
make install PREFIX=~/bin
```

### Option 2: Development Build

```bash
# Build debug version
swift build

# Run directly with Swift
swift run ekexport --help
```

## Usage

### Quick Start

```bash
# List all available calendars
ekexport list-calendars

# Export all events to iCalendar format
ekexport export --output my-calendar.ics

# Export specific date range to JSON
ekexport export --format json --start-date 2024-01-01 --end-date 2024-12-31 --output events-2024.json

# Include reminders in the export
ekexport export --include-reminders --format json
```

### Commands

#### `list-calendars`

List all accessible calendars with their identifiers, which can be used to filter exports.

**Usage:**
```bash
ekexport list-calendars [--verbose] [--format <table|json>]
```

**Options:**
- `--verbose`: Show additional details including color and permissions
- `--format <table|json>`: Output format (default: table)

**Examples:**
```bash
# Basic calendar listing
ekexport list-calendars

# Detailed view with colors and permissions
ekexport list-calendars --verbose

# JSON output for scripting
ekexport list-calendars --format json
```

#### `export`

Export calendar events and optionally reminders to various formats.

**Usage:**
```bash
ekexport export [options]
```

**Options:**
- `--calendars <IDs>`: Comma-separated list of calendar identifiers (default: all calendars)
- `--start-date <YYYY-MM-DD>`: Start date for export range (default: unbounded)
- `--end-date <YYYY-MM-DD>`: End date for export range (default: unbounded)
- `--include-reminders`: Include reminders in addition to events
- `--output <path>` / `-o <path>`: Output file path (default: stdout)
- `--format <ics|json>`: Export format (default: ics)

**Examples:**
```bash
# Export everything to stdout
ekexport export

# Export specific calendars for this year
ekexport export --calendars "CAL-ID-1,CAL-ID-2" --start-date 2024-01-01 --end-date 2024-12-31

# Export with reminders to JSON file
ekexport export --include-reminders --format json --output backup.json

# Pipe to other tools
ekexport export --format json | jq '.events | length'
```

## Output Formats

### iCalendar (.ics)

Standard iCalendar format compatible with most calendar applications:

```
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//ekexport//EN
BEGIN:VEVENT
UID:unique-event-id
DTSTART:20240101T100000Z
DTEND:20240101T110000Z
SUMMARY:Meeting with Team
LOCATION:Conference Room A
END:VEVENT
END:VCALENDAR
```

### JSON

Structured JSON with metadata and comprehensive event/reminder data:

```json
{
  "exportInfo": {
    "timestamp": "2024-01-15T10:30:00Z",
    "eventCount": 150,
    "reminderCount": 25,
    "exportedBy": "ekexport"
  },
  "events": [
    {
      "id": "unique-event-id",
      "calendarId": "calendar-identifier",
      "title": "Meeting with Team",
      "startDate": "2024-01-01T10:00:00Z",
      "endDate": "2024-01-01T11:00:00Z",
      "isAllDay": false,
      "location": "Conference Room A",
      "notes": "Discuss project timeline",
      "timeZone": "America/New_York",
      "recurrenceRules": []
    }
  ],
  "reminders": []
}
```

## Development

### Build Commands

```bash
# Debug build
make build
swift build

# Release build
make release
swift build -c release

# Run with arguments
make run ARGS="list-calendars --verbose"
swift run ekexport list-calendars --verbose

# Clean build artifacts
make clean
```

## Binary Releases

- Precompiled binaries are published on the GitHub Releases page for Apple Silicon (arm64) macOS 13+.
- Asset name: `ekexport-vX.Y.Z-macos-arm64.tar.gz` with accompanying `SHA256SUMS`.
- Manual install: download and extract the archive, then copy `ekexport` to `/usr/local/bin/ekexport`.

## Architecture

The tool follows a clean, layered architecture:

- **CLI Layer**: Swift ArgumentParser-based command interface
- **Logic Layer**: Export orchestration and business logic
- **Data Access Layer**: EventKit framework abstraction with permission handling
- **Serialization Layer**: Pluggable format converters (iCalendar, JSON)

Key design principles:
- **Protocol-oriented**: Abstractions enable comprehensive testing
- **Security-focused**: Proper TCC permission handling and code signing support
- **Maintainable**: Clear separation of concerns and dependency management
- **Production-ready**: Robust error handling and user feedback

## Privacy and Security

`ekexport` respects macOS privacy protections:

- **Permission Requests**: Prompts for Calendar/Reminders access on first run
- **TCC Integration**: Permissions persist across app updates with proper code signing
- **Data Protection**: No data is transmitted or stored outside your system
- **Minimal Access**: Only requests permissions for explicitly used features

On first run, you'll see system dialogs requesting access to:
- **Calendars** (always required)
- **Reminders** (only when using `--include-reminders`)

Grant access in System Settings > Privacy & Security if needed.

## Troubleshooting

### Permission Issues

If you see permission errors:

1. Check System Settings > Privacy & Security > Calendars/Reminders
2. Ensure `ekexport` is listed and enabled
3. Try removing and re-adding the permission
4. Restart the application if permissions were recently changed

### Common Issues

**"No calendars found"**: Verify calendar access permissions are granted.

**"Invalid date format"**: Ensure dates follow `YYYY-MM-DD` format (e.g., `2024-01-15`).

**"Calendar ID not found"**: Use `list-calendars` to get current calendar identifiers.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following the existing code style
4. Add tests for new functionality
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

Built with:
- [Swift ArgumentParser](https://github.com/apple/swift-argument-parser) for CLI interface
- EventKit framework for calendar/reminder access
- Swift Package Manager for dependency management
