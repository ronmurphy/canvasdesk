# Changelog

All notable changes to CanvasDesk will be documented in this file.

## [Unreleased]

### Fixed
- CanvasDesk no longer appears in alt-tab window switcher when running as a login session
  - Added `CANVASDESK_SESSION_MODE` environment variable detection
  - When running via `canvasdesk-session` (login manager), window is flagged as `Qt::Tool` and `Qt::WindowStaysOnBottomHint` to exclude it from window switchers
  - In development mode (e.g., running in Plasma), window behaves normally for easier testing
  - **Files modified:**
    - `canvasdesk-session`: Sets `CANVASDESK_SESSION_MODE=1` environment variable
    - `src/main.cpp`: Reads environment variable and passes `isSessionMode` to QML
    - `src/editor/qml/DesktopMode.qml`: Conditionally applies window flags based on session mode

## [0.1] - Initial Release

### Added
- Visual desktop environment editor
- Runtime mode for actual desktop usage
- Component system (Panel, Taskbar, Clock, WorkspaceSwitcher, AppGrid, etc.)
- Integration with labwc compositor
- Layout save/load functionality
- Window management via KWayland and wlr-foreign-toplevel protocols
