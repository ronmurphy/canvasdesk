# Next Session Plan - Multi-Monitor Support & QML Component Enhancement

## Recent Completion: Multi-Monitor Support (2025-12-04)

✅ **COMPLETED** - Multi-monitor support with XRandR integration
✅ **COMPLETED** - Control Center with monitor management UI
✅ **READY FOR DOGFOODING** - Full-time CanvasDesk session testing enabled

### What Was Implemented:
- XRandR library integration for multi-monitor detection and configuration
- MonitorManager C++ backend with full CRUD operations
- Control Center floating panel (similar to Editor panel)
- Monitor enable/disable functionality
- Primary monitor selection
- Configuration apply/save/load system
- Real-time monitor detection and updates

See `Docs/X11.txt` for detailed technical documentation.

---

## Session Goals
Improve QML components with "atom" versions (minimal, icon-only) and enhance "all-in-one" components for better user experience. Focus on making the desktop environment more customizable and user-friendly.

## Priority Tasks

### 1. Taskbar Icon Display
- [ ] Update TaskbarComponent.qml to show app icons alongside window titles
- [ ] Get icon from WindowManager (matching what's shown in titlebars)
- [ ] Handle missing icons gracefully

### 2. Taskbar Atom Component
- [ ] Create TaskbarAtomComponent.qml
- [ ] Icon-only display (no window title text)
- [ ] No border outline
- [ ] Same functionality as regular taskbar (click to focus/minimize, middle-click to close)
- [ ] Detect panel orientation (horizontal vs vertical)
- [ ] Adjust layout based on orientation
- [ ] Dockable in panels

### 3. Panel Orientation Awareness
- [ ] Make PanelComponent.qml aware of horizontal vs vertical orientation
- [ ] Add orientation property to panels
- [ ] Update layout behavior based on orientation
- [ ] Ensure all docked components respect panel orientation

## Additional Component Ideas

### Atom Components (Minimal, Function-Focused)
- [ ] SessionAtomComponent.qml - Icon-only session controls
- [ ] VolumeAtomComponent.qml - Icon-only volume slider - mouse wheel for volume adjustment?
- [ ] ClockAtomComponent.qml - Time-only display
- [ ] CalendarAtomComponent.qml - Date display with popup

### All-In-One Components (Feature-Rich)
- [ ] Improve AppLauncherComponent.qml - Better app discovery, search, categories
- [ ] Improve FileBrowserComponent.qml - Better file navigation, icons, preview
- [ ] VolumeComponent.qml - Volume slider with app mixer -  
- [ ] CalendarComponent.qml - Full calendar view with events
- [ ] Improve ClockComponent.qml - time format choice, click to chow Calendar


## Design Philosophy

**Atom Components:**
- Minimal visual footprint (icon-only or very compact)
- Single focused function
- No borders/decorations
- Panel-aware (horizontal/vertical)
- Building blocks for custom layouts

**All-In-One Components:**
- Feature-rich
- Self-contained
- Good defaults
- For users who want quick setup

## Implementation Notes

### Icon Handling
- Icons should come from WindowManager (use _NET_WM_ICON)
- Fallback to generic icon if app icon not available
- Consider using system icon theme for atom components

### Panel Orientation Detection
```qml
// Suggested approach in PanelComponent.qml
property string orientation: width > height ? "horizontal" : "vertical"
```

### Component Communication
- Atom components should use same WindowManager API
- Keep components independent and reusable
- Use Qt signals/slots for panel-component communication

## Testing Strategy

### Dogfooding Plan
- Use previous day's build as daily DE
- Document bugs and usability issues as they're encountered
- Fix issues found through real-world usage
- Track pain points for prioritization

### Test Cases
- [ ] Horizontal panel with atoms
- [ ] Vertical panel with atoms
- [ ] Mixed atom + all-in-one components
- [ ] Window icon display in taskbar
- [ ] Icon-only taskbar with many windows
- [ ] Panel resizing with orientation change

## Current Status

### Working Features (Window Manager)
✓ Minimize/Maximize/Close buttons
✓ Window state tracking (normal/minimized/maximized)
✓ Click-to-focus
✓ Window dragging
✓ Window resizing (edges and corners)
✓ Cursor feedback on resize
✓ App icons in titlebars
✓ Taskbar toggle (minimize/restore)
✓ Middle-click to close from taskbar
✓ Titlebar gradient themes
✓ Unicode text rendering

### Current QML Components
- TaskbarComponent.qml - Shows windows, no icons yet
- SessionComponent.qml - Session controls
- ClockComponent.qml - Date/time display
- AppLauncherComponent.qml - App launcher (basic)
- FileBrowserComponent.qml - File browser (basic)
- PanelComponent.qml - Container panel

## Notes for Next Session

- Window manager is now "super useable on a daily basis"
- Focus shifts from window manager to QML/UI polish
- Goal: Make components modular and customizable
- Support both minimal users (atoms) and convenience users (all-in-one)
- Real-world dogfooding will drive bug fixes and improvements

## Timeline
Expected session start: ~4-5 hours from now (around evening)

## Brad updates, to keep from being forgotten...

## ✅ COMPLETED - Multi-Monitor Support (2025-12-04)
~~X11 shows "no display" on external monitors when logged in to CanvasDesk, need multiple monitor support.~~
- **DONE** - Implemented full XRandR-based multi-monitor support
- **DONE** - Control Center for monitor management
- **READY** - Week-long dogfooding session can now begin!

## Control Center - In Progress
✅ Control Center floating panel implemented (similar to Editor)
✅ Monitors tab with enable/disable and primary selection
⏳ Appearance settings (to be migrated from Editor Settings tab)
⏳ System settings tab (keyboard, mouse, icons, cursors)

### Future Control Center Features:
 - Figure out how both KDE and Gnome assign themed icon sets
 - Migrate the Theme area to Control Center Appearance tab
 - Figure out assigning Cursor sets, like Gnome and KDE
 - Make use of KDE and Gnome Icons and Cursors
 - Visual drag-and-drop monitor layout editor
