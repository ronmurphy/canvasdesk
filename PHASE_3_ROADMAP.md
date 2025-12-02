# CanvasDesk Phase 3+ Feature Roadmap

## Current State ✅
- [x] Editor with drag-and-drop
- [x] Live Preview mode
- [x] Basic components: Clock, Taskbar, AppGrid, WorkspaceSwitcher, FileManager, Button
- [x] Save/Load layouts
- [x] Real system integration (apps, files)
- [x] Wayland window management (RE-ENABLED)

## Immediate Priorities

### 1. Test Wayland Taskbar (Just Completed!)
**Status:** Ready to test
**Action:** Open editor, click Preview, verify Dolphin/Kate/GIMP/Ghostty show in taskbar

### 2. Unified Binary Architecture ⭐ HIGH PRIORITY
**Why:** Makes everything else easier - one codebase, shared rendering
**Benefits:**
- ✅ Preview and Runtime use identical component rendering
- ✅ Anything added to editor automatically works in runtime
- ✅ Single binary to distribute
- ✅ No subprocess QML loading issues

**Implementation:**
```bash
canvasdesk              # Editor mode (default)
canvasdesk --runtime    # Runtime-only mode
canvasdesk --preview    # Direct to preview with layout
```

**Files to change:**
- Create unified `src/main.cpp`
- Update root `CMakeLists.txt`
- Merge editor and runtime builds

**Estimate:** 1-2 hours

---

## Component Properties System

### Properties UI Design
```
┌─────────────────────────────────┐
│ Properties                      │
├─────────────────────────────────┤
│ Component: Clock                │
├─────────────────────────────────┤
│ Position                        │
│   X: [650]  Y: [20]            │
│                                 │
│ Appearance                      │
│   ☑ Transparent Background      │
│   Background Color: [#2a2a2a]  │
│   Border Color: [#555555]      │
│   Border Width: [1]            │
│                                 │
│ Component-Specific              │
│   Time Format: [HH:MM:SS ▼]    │
│   Font Size: [16]              │
│   Font Color: [#ffffff]        │
└─────────────────────────────────┘
```

### Common Properties (All Components)
- Position: x, y
- Size: width, height
- Appearance:
  - Transparent background (boolean)
  - Background color
  - Border color/width/radius
  - Opacity
- Behavior:
  - Visible (boolean)
  - Enabled (boolean)
  - Z-index (layer ordering)

### Component-Specific Properties

#### Clock
- Time format (HH:MM:SS, HH:MM, custom)
- Date format
- Font family/size/color
- Update interval

#### Taskbar
- Orientation (horizontal/vertical)
- Icon size
- Show window titles (boolean)
- Show only current workspace (boolean)
- Group similar windows (boolean)

#### FileManager
- **Role:**
  - `all-files` - Show all files/folders
  - `apps-only` - Show only .desktop files (app launcher)
  - `documents` - Filter for documents
  - `images` - Filter for images
  - `custom` - Custom filter
- Start path
- Show hidden files (boolean)
- Icon view vs List view
- Thumbnail size

#### AppGrid
- **Role:**
  - `all-apps` - All installed apps
  - `favorites` - Favorited apps only
  - `recent` - Recently used apps
  - `category` - Specific category (Games, Office, etc.)
- Grid columns
- Icon size
- Show app names (boolean)
- Sort by: name/usage/category

#### WorkspaceSwitcher
- Show workspace names (boolean)
- Compact mode (just numbers vs full buttons)
- Vertical/horizontal orientation

#### WebView (NEW!)
- URL
- Allow navigation (boolean)
- Show address bar (boolean)
- JavaScript enabled (boolean)
- Initial zoom level

---

## New Components

### 1. WebView Component 🌐
**Description:** Embed web content anywhere
**Properties:**
- URL (string)
- Allow navigation (bool)
- Show controls (bool)
- JS enabled (bool)

**Use Cases:**
- Claude.ai in a panel
- Dashboard widgets
- System monitoring web UIs
- Streaming music players
- Weather widgets

**Implementation:**
```qml
import QtWebEngine

WebEngineView {
    url: "https://claude.ai"
    width: 400
    height: 600
}
```

### 2. Docked Panel Component 📌
**Description:** Container that can dock to edges and auto-hide
**Properties:**
- Dock position: left/right/top/bottom/floating
- Auto-hide (boolean)
- Hide delay (milliseconds)
- Panel width/height
- Background transparency
- Accepts child components

**Behavior:**
- Drag components INTO the panel
- Panel becomes their parent container
- Children inherit panel properties
- Panel can slide in/out on hover

**Example:**
```
┌─────────────────────────────────┐
│ Docked Panel (left)            │
│                                 │
│  ┌───────────────────────────┐ │
│  │ WebView: claude.ai        │ │
│  │                           │ │
│  └───────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐ │
│  │ Clock                     │ │
│  └───────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐ │
│  │ AppGrid: Favorites        │ │
│  └───────────────────────────┘ │
└─────────────────────────────────┘
```

### 3. MPD/Music Player Component 🎵
**Description:** Music player daemon controller
**Properties:**
- MPD host/port
- Show album art (boolean)
- Show playlist (boolean)
- Compact mode (just controls vs full player)

**Features:**
- Play/pause/skip/volume
- Current track info
- Playlist management
- Album art display

### 4. System Monitor Component 📊
**Description:** CPU/RAM/Disk usage
**Properties:**
- What to monitor: CPU/RAM/Disk/Network/All
- Update interval
- Graph vs numeric display
- Warning thresholds

### 5. Notification Center Component 🔔
**Description:** Shows system notifications
**Properties:**
- Max notifications shown
- Auto-dismiss timeout
- Show icons (boolean)
- History depth

### 6. Search Bar Component 🔍
**Description:** App/file launcher
**Properties:**
- Search scope: apps/files/both
- Show recent (boolean)
- Max results
- Fuzzy search (boolean)

### 7. Custom HTML Component 📝
**Description:** Embed custom HTML/CSS/JS
**Properties:**
- HTML content (text editor)
- CSS styles
- JavaScript code
- Sandbox level

---

## Container/Nesting System

### Parent-Child Awareness
Components need to know:
1. **Am I in a container?** (parent !== root)
2. **What type of container?** (Panel, Grid, etc.)
3. **Container constraints** (docking rules, sizing)

### Implementation
```json
{
  "type": "DockedPanel",
  "x": 0,
  "y": 0,
  "dock": "left",
  "width": 300,
  "autoHide": true,
  "children": [
    {
      "type": "WebView",
      "url": "https://claude.ai",
      "height": 400
    },
    {
      "type": "Clock",
      "height": 50
    }
  ]
}
```

### Visual Indicators
- Drop zones highlight when dragging
- Container outlines in edit mode
- Parent-child connections visible
- Snap-to-container guides

---

## Property Editor Implementation

### Phase 1: Basic Properties
1. Text inputs for x, y, width, height
2. Color pickers for colors
3. Checkboxes for booleans
4. Number spinners for numeric values

### Phase 2: Component-Specific
1. Detect selected component type
2. Show relevant property fields
3. Live preview as properties change
4. Save properties to layout JSON

### Phase 3: Advanced
1. Property binding (link properties)
2. Expressions (calculate from other values)
3. Animations (property transitions)
4. Themes (preset property sets)

---

## Technical Architecture

### Unified Component Rendering
```cpp
// In unified binary main.cpp
QQmlComponent *ComponentFactory::create(QString type, QVariantMap props) {
    // This code is used by BOTH preview and runtime
    if (type == "Clock") return createClock(props);
    if (type == "WebView") return createWebView(props);
    // ... etc
}
```

### Property System
```cpp
class ComponentProperties {
    QVariantMap commonProps;    // x, y, width, height, etc.
    QVariantMap specificProps;  // component-specific

    void apply(QQuickItem *item);
    void save(QJsonObject &json);
    void load(QJsonObject &json);
};
```

---

## Next Steps Priority Order

1. **Test Wayland Taskbar** (5 min)
   - Open editor, Preview mode
   - Verify Dolphin/Kate/GIMP/Ghostty appear

2. **Unified Binary** (1-2 hours)
   - Single main.cpp
   - Shared component rendering
   - Command-line mode switching

3. **Basic Properties Panel** (2-3 hours)
   - x, y, width, height inputs
   - Color picker
   - Live update preview

4. **Docked Panel Component** (3-4 hours)
   - Container component
   - Child nesting
   - Docking behavior

5. **WebView Component** (1-2 hours)
   - QtWebEngine integration
   - Basic properties
   - URL loading

6. **Enhanced Properties** (ongoing)
   - Component-specific properties
   - Role system
   - Transparency controls

---

## Long-term Vision

### CanvasDesk as a Platform
- Plugin system for custom components
- Theme marketplace
- Layout sharing community
- Scripting API (QML/JS/Python)
- Wayland compositor integration
- Multi-monitor support
- Per-workspace layouts

### Distribution
- Flatpak/AppImage
- AUR package
- NixOS package
- Official repos for major distros

---

**You're absolutely right** - with the unified binary, anything added to preview automatically works in runtime. The rendering code is 100% shared! 🚀
