# Service Manager

A terminal-based service management application built with Go and tview.

## Features

- **Service Discovery**: Automatically scans `/etc/init.d/` for available services
- **Interactive UI**: Terminal user interface with navy blue background and terminal yellow text
- **Service Management**: Start, stop, restart, and check status of services
- **Real-time Status**: Shows current status of selected services
- **Keyboard Shortcuts**: Quick access to common operations

## Color Scheme

- Background: Navy Blue
- Text: Terminal Yellow (Giallo terminale)
- Selected items: Black text on yellow background

## Installation

1. Make sure you have Go 1.21+ installed
2. Clone or download this project
3. Install dependencies:
   ```bash
   go mod tidy
   ```

## Usage

Run the application:
```bash
go run main.go
```

For full functionality (service management), run with sudo:
```bash
sudo go run main.go
```

### Controls

- **Arrow Keys**: Navigate through service list
- **Enter**: Open action menu for selected service
- **s**: Start selected service
- **t**: Stop selected service  
- **r**: Restart selected service
- **c**: Check status of selected service
- **q**: Quit application

### Interface

The application displays:
- Left panel: List of available services from `/etc/init.d/`
- Right panel: Information about the selected service including status, path, and available commands

## Requirements

- Go 1.21+
- Linux system with `/etc/init.d/` directory
- sudo privileges for service management operations

## Dependencies

- `github.com/rivo/tview` - Terminal UI framework
- `github.com/gdamore/tcell/v2` - Terminal cell interface

## Building

To build a standalone executable:
```bash
go build -o service-manager main.go
```

Then run:
```bash
sudo ./service-manager
```
