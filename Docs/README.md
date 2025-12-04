# 📘 **CanvasDesk — Project Summary, Architecture, and Workflow**

## **1. Project Overview**

**CanvasDesk** is a next-generation **no-code desktop environment builder** and **runtime shell** for Linux.
It allows users to visually construct a fully functional desktop environment using a drag-and-drop interface—no programming required.

Users design:

* Panels / taskbars
* Start menus
* Application launchers
* File manager panels
* Web panels
* Widgets
* Custom HUD layouts
* Workspace switchers
* Notification trays
* Anything they can imagine

The design happens on a **canvas**, and these designs become the **desktop environment itself**.

CanvasDesk combines:

* **Qt Quick (QML)** for user interface rendering
* **C++ backend** for system integrations (window manager, app indexing, file systems)
* A **component + role system** that binds visual elements to system functions

---

# ⭐ 2. Project Philosophy

CanvasDesk is built on three core principles:

### **1. Design Your Desktop Like a UI Scene**

The desktop is no longer a fixed shell—it's a scene the user builds visually, like:

* Unity Editor
* Godot Engine
* Visual Basic Form Designer

### **2. Components, Not Code**

Everything the user places on the screen is a **component**:

* Bar
* Button
* IconGrid
* Modal
* WebView
* FileList
* Dock

Users assign a **role** to components:

* “Show taskbar apps”
* “Toggle start menu”
* “Open app: Firefox”
* “Display all installed applications”

No code is written — logic is attached declaratively.

### **3. Runtime Loads Your Layout**

CanvasDesk layouts are saved to a JSON or QML-based format.
The **CanvasDesk Runtime** loads this layout on startup and becomes the user’s desktop.

---

# 🧩 3. High-Level Architecture

```
+-----------------------------------------------------+
|                 CanvasDesk Editor                    |
|   Drag & Drop Designer · Property Inspector · Save   |
+-----------------------------------------------------+
                 │ Exports layout
                 ▼
+-----------------------------------------------------+
|                CanvasDesk Layout File                |
|  JSON or QML-based · Contains component tree & roles |
+-----------------------------------------------------+
                 │ Loaded at runtime
                 ▼
+-----------------------------------------------------+
|                CanvasDesk Runtime Shell              |
|     QML engine + C++ backend components + WM API     |
+-----------------------------------------------------+
                 │ Talks to system
                 ▼
+-----------------------------------------------------+
|                Linux System Integrations             |
|   Window Manager · Process List · DBus · FileSystem  |
+-----------------------------------------------------+
```

---

# ⚙️ 4. Core Technologies

### **Frontend**

* **Qt Quick (QML)**
* GPU-accelerated scenegraph
* Declarative UI
* Dynamic component loading
* Native WebEngine support

### **Backend**

* **C++** (Qt/C++ classes)
* Exposes system APIs into QML via Qt’s object/model system

### **System APIs**

* App listing
* Running processes
* Window management
* File system
* DBus integrations
* Notifications
* Power functions
* Webviews

---

# 🧱 5. Components & Roles System

CanvasDesk defines a set of **UI components**. Users place them visually.

Example components:

* `Bar`
* `Panel`
* `Modal`
* `Icon`
* `IconGrid`
* `WebView`
* `FileList`
* `Clock`
* `TaskList`
* `SearchBox`
* `Button`
* `AppLauncher`
* `WorkspaceSwitcher`

Each component has:

1. **Visual properties** (size, anchors, color, etc.)
2. **Custom data** (tooltip, icon, etc.)
3. **Role assignment** (this connects it to system logic)

### Example role assignments:

```
role: "runningApps"
role: "toggleStartMenu"
role: "installedApps"
role: "openApp:firefox"
role: "searchBar"
role: "workspaceSwitcher"
role: "showWebPanel"
```

Roles are just metadata in the QML object:

```qml
property string role: "runningApps"
```

Backend binds roles to logic at runtime.

---

# 🧠 6. How the Runtime Works

Upon startup:

1. Load the saved layout file (JSON or QML).
2. Build the component tree in QML.
3. Scan components for `role` properties.
4. Connect each role to the corresponding backend C++ API.
5. Initialize system models (running apps, installed apps, file system).
6. Display the user’s custom desktop environment.

CanvasDesk then becomes a fully operational DE:

* Taskbar updates when apps open/close
* Web panels load URLs
* File manager panels browse directories
* Start menu opens when the user presses its icon
* Workspaces switch, windows move, etc.

---

# 🖌️ 7. The Editor Workflow (Drag & Drop Designer)

The editor functions like a mini game engine editor:

### **CanvasDesk Editor UI Layout**

```
+---------------------------------------------------+
|                    Toolbar                         |
+----------------------+-----------------------------+
| Component List       |   Canvas (live preview)     |
| (drag from here)     |   (QML rendered area)       |
|                      |                             |
+----------------------+-----------------------------+
|        Properties Inspector · Roles Panel          |
+---------------------------------------------------+
```

### **Editor workflow**

1. User drags a **Bar** onto the canvas.
2. They anchor it to the bottom.
3. They drop an **IconList** inside the bar.
4. They open the Properties panel → assign role `runningApps`.
5. They create a **Modal** (start menu).
6. They add an **IconGrid** with role `installedApps`.
7. They add a button to the bar → assign role `toggle:startMenu`.
8. Save layout.
9. Launch CanvasDesk Runtime.
10. Desktop is now fully functional.

---

# 💾 8. Layout Format

A JSON-like layout file:

```json
{
  "type": "Bar",
  "id": "MainBar",
  "anchors": { "bottom": "parent" },
  "children": [
    {
      "type": "IconList",
      "role": "runningApps"
    },
    {
      "type": "Button",
      "role": "toggle:startMenu",
      "icon": "start.png"
    }
  ]
}
```

Or directly a QML file generated by the editor.

---

# 🔌 9. Backend Responsibilities (C++)

Backend provides modules:

* `AppManager`
* `WindowManager`
* `FileManager`
* `SettingsManager`
* `WebviewManager`
* `WorkspaceManager`

Each module exposes:

* Properties
* Signals
* Slots

Example:

```cpp
class AppManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList runningApps READ runningApps NOTIFY runningAppsChanged)
public:
    QVariantList runningApps();
    Q_INVOKABLE void launch(QString appId);
};
```

Connected in QML:

```qml
ListView {
    model: AppManager.runningApps
}
```

---

# 🚀 10. Current Status & Features

## **✅ Implemented Features**

### **Unified Binary System**
- Single executable with multiple modes:
  - **Editor Mode** (default): Visual designer with live desktop preview
  - **Runtime Mode** (`--runtime`): Production desktop environment
  - **Preview Mode** (`--preview`): Quick layout testing

### **Visual Editor**
- ✅ **Drag-and-drop component placement** from side panel
- ✅ **Live canvas** showing actual desktop with editable components
- ✅ **Component selection** with visual feedback (orange border)
- ✅ **Resize handles** (top-left, top-right, bottom-left, bottom-right)
- ✅ **Delete button** on selected components
- ✅ **Properties panel** with real-time editing:
  - Position & Size (X, Y, Width, Height)
  - Component-specific settings (Panel, Clock, AppLauncher)
  - TextField inputs with Enter-to-apply
- ✅ **Dock/Undock system** - Pin components to screen edges
- ✅ **Layout persistence** - Saves to JSON, restores on restart

### **Working Components**
- ✅ **Panel** - Customizable bar/panel with configurable edges
- ✅ **Clock** - System clock display
- ✅ **AppLauncher** - Application grid launcher
- ✅ **Taskbar** - Window list with minimize/activate
- ✅ **FileManager** - Simple file browser with navigation

### **System Integration**
- ✅ **Window Management** - Track open windows via Wayland protocols
- ✅ **Window Activation** - Click taskbar items to activate windows
- ✅ **Application Indexing** - Scan and display installed apps
- ✅ **App Launching** - Launch applications from AppLauncher
- ✅ **File System** - Browse directories in FileManager

### **Backend Architecture**
- ✅ **AppManager** - Application listing and launching
- ✅ **WindowManager** - Window tracking and control (Wayland)
- ✅ **LayoutManager** - Save/load layout configurations
- ✅ **Component System** - Dynamic component loading
- ✅ **EditableComponent** - Wrapper providing editor functionality

## **🔄 In Progress**

### **Phase 3 — Desktop Integration Enhancement**
- 🔄 Window thumbnails in taskbar
- 🔄 Advanced window operations (minimize, maximize, close)
- 🔄 System tray integration
- 🔄 Notification system
- 🔄 More component types (WebView, Widgets, etc.)

### **Phase 4 — Workspace & Advanced Features**
- 🔄 Multi-workspace support
- 🔄 Window snapping and tiling
- 🔄 Advanced property editing
- 🔄 Keyboard shortcuts

### **Phase 5 — Polishing**
- 🔄 Theming system
- 🔄 Component templates gallery
- 🔄 Layout backup/sync
- 🔄 Plugin API
- 🔄 Release packaging

## **🛠️ Build & Run**

### **Requirements**
- Qt 6.5+
- CMake 3.16+
- Wayland development libraries
- KDE Frameworks (for window management)

### **Build**
```bash
./build.sh
```

### **Run**
```bash
# Editor mode (design your desktop)
./build/canvasdesk

# Runtime mode (use your desktop)
./build/canvasdesk --runtime

# Preview mode (test layout)
./build/canvasdesk --preview
```

### **Layout Files**
Layouts are saved to `~/.config/canvasdesk/layouts/`
- `layout.json` - Main layout file
- Component configurations stored with position, size, and properties

---

# 🏁 11. Technical Details

## **Project Structure**

```
canvasdesk/
├── src/
│   ├── app/           # Runtime mode entry point
│   ├── core/          # C++ backend (managers, system integration)
│   ├── editor/        # Editor mode UI and components
│   └── qml/           # Runtime QML components
├── build/
│   └── canvasdesk     # Unified binary
├── layouts/           # Example layout files
└── CMakeLists.txt     # Build configuration
```

## **Key Files**

- `src/editor/qml/DesktopMode.qml` - Main editor window with properties panel
- `src/editor/qml/EditableComponent.qml` - Component wrapper for editor interactions
- `src/editor/qml/components/` - Available component types
- `src/core/LayoutManager.cpp` - Layout save/load logic
- `src/core/WindowManager.cpp` - Wayland window management
- `src/core/AppManager.cpp` - Application indexing and launching

## **Component Development**

To create a new component:

1. Create QML file in `src/editor/qml/components/`
2. Define `componentType` property
3. Add visual elements
4. Register in component list
5. Add property editor section in DesktopMode.qml

Example:
```qml
Rectangle {
    id: root
    property string componentType: "MyComponent"
    property bool editorOpen: false
    
    // Your component UI here
}
```

---

# 🏁 12. Final Thoughts

**CanvasDesk** is a functional, working desktop environment builder that demonstrates:
- ✔ Visual desktop design is possible and practical
- ✔ Qt/QML provides excellent tools for custom DE development
- ✔ No-code approach makes desktop customization accessible
- ✔ Modular component system enables unlimited creativity
- ✔ Real system integration works on modern Wayland

The project continues to evolve with new components, better editor features, and deeper system integration.
