# Window Frame Implementation Reference

**Source:** NoteWM (https://github.com/masonarmand/NoteWM)
**Purpose:** Guide for implementing window reparenting and decorations in CanvasDesk
**Date:** 2025-12-03

---

## Key Concepts

### Window Hierarchy (Reparenting)
NoteWM creates a 3-level hierarchy for each client window:

```
Frame Window (outer container)
├── Title Bar Window
│   ├── Title String Window (for text rendering)
│   └── Button Windows (close, maximize, minimize, etc.)
└── Client Window (the actual app - reparented into frame)
```

### The Reparenting Process

1. **Create Frame Window** - Container that holds everything
2. **Create Title Bar** - Header with window title and buttons
3. **Reparent Client** - Move client window to be child of frame
4. **Position Client** - Move client below title bar (y = TITLE_HEIGHT + BORDER_WIDTH)
5. **Map Everything** - Show frame, title bar, and client

---

## NoteWM Data Structures

### Frame Structure
```c
struct NoteWM_Frame {
    Window frame;                    // Outer container window
    Window title_bar;                // Title bar window
    Window title_string_window;      // Window for rendering title text
    NoteWM_ButtonList* button_list;  // Close/max/min buttons
    Window child_window;             // The actual client app
    GC gc;                           // Graphics context for drawing
    unsigned short workspace_id;     // Virtual desktop ID
    int x, y, w, h;                  // Saved geometry (for fullscreen restore)
    bool is_fullscreen;              // Fullscreen state
    bool ignore_configure_events;    // Flag for resize handling
    struct NoteWM_Frame* next;       // Linked list pointer
};
```

### Button Structures
```c
typedef struct {
    Window window;           // X11 window for the button
    ButtonClickFunc on_click; // Callback function pointer
} NoteWM_Button;

typedef struct {
    NoteWM_Button* buttons;  // Dynamic array of buttons
    unsigned int count;      // Current button count
    unsigned int capacity;   // Allocated capacity
} NoteWM_ButtonList;
```

### Constants
```c
#define BORDER_WIDTH 2
#define TITLE_HEIGHT 16
#define BUTTON_SIZE 8
#define PADDING 4
#define TITLE_STRING_X 10
#define TITLE_STRING_Y (TITLE_HEIGHT / 2) + 2
```

---

## Key Functions from frame.c

### create_frame()
**Purpose:** Main frame creation function
**Steps:**
1. Get window attributes and size hints
2. Calculate frame dimensions (client width x client height + TITLE_HEIGHT)
3. Allocate frame structure
4. Create frame window using XCreateSimpleWindow()
5. Create title bar (calls create_title_bar())
6. Reparent client into frame: `XReparentWindow(display, window, frame->frame, 0, 0)`
7. Map frame and client windows
8. Position client below title bar: `XMoveWindow(display, window, 0, TITLE_HEIGHT + BORDER_WIDTH)`

### create_title_bar()
**Purpose:** Create title bar with text and buttons
**Steps:**
1. Create title_bar window at top of frame (-BORDER_WIDTH, -BORDER_WIDTH)
2. Create title_string_window for rendering text
3. Create GC (Graphics Context) for drawing
4. Set up event masks (ButtonPressMask, ExposureMask)
5. Create buttons (close, expand, split, etc.)
6. Update title text

### resize_frame()
**Purpose:** Resize frame and update all child windows
**Steps:**
1. Resize frame window
2. Resize client window (height - TITLE_HEIGHT)
3. Resize title bar
4. Reposition buttons (they're anchored to top-right)

### update_frame_text()
**Purpose:** Draw window title in title bar
**Steps:**
1. Get window name from client (_NET_WM_NAME or WM_NAME property)
2. Clear title_string_window
3. Draw text using XDrawString()

---

## Integration Strategy for CanvasDesk

### Phase 1: Basic Frame Structure
1. Add frame data structure to X11WindowManager
2. Modify MapRequest handler to create frame instead of directly mapping client
3. Implement basic reparenting (no decorations yet)
4. Test that windows still appear and track correctly

### Phase 2: Title Bar
1. Add title bar window creation
2. Implement text rendering (window title)
3. Style with Qt/theme colors (not hardcoded)

### Phase 3: Buttons
1. Add close button
2. Wire up button click to send WM_DELETE_WINDOW message
3. Add maximize/minimize buttons
4. Implement button callbacks

### Phase 4: Mouse Interaction
1. Detect mouse press on title bar
2. Implement window dragging (update frame position)
3. Add resize handles at edges/corners
4. Update cursor shapes at edges

### Phase 5: Focus & Styling
1. Track active/focused frame
2. Change border color for active window
3. Update taskbar to highlight active window

---

## Important X11 Calls

### Window Creation
```c
Window XCreateSimpleWindow(
    Display* display,
    Window parent,
    int x, int y,
    unsigned int width, unsigned int height,
    unsigned int border_width,
    unsigned long border,
    unsigned long background
);
```

### Reparenting
```c
XReparentWindow(Display* display, Window child, Window new_parent, int x, int y);
```

### Event Selection
```c
XSelectInput(Display* display, Window window, long event_mask);
```

Key masks:
- `SubstructureRedirectMask` - Required on root for WM
- `StructureNotifyMask` - ConfigureNotify, MapNotify, etc.
- `ButtonPressMask` - Mouse button clicks
- `ExposureMask` - Window needs redraw
- `EnterWindowMask` - Mouse enter events
- `PropertyChangeMask` - Property updates (_NET_WM_NAME, etc.)

---

## Differences for CanvasDesk

### Use Qt Where Possible
- Consider using QWindow/QWidget for frame windows (easier text rendering)
- Or stick with pure X11 and use Xft for text rendering
- Qt's event loop already integrated via QSocketNotifier

### Styling
- Use theme colors from QML instead of hardcoded values
- Make TITLE_HEIGHT, BORDER_WIDTH configurable
- Support dynamic themes

### Integration with Existing Code
Current X11WindowManager.cpp has:
- Window tracking in `m_windows` map
- Event handling in `handleXEvents()`
- QML property `windows()` for taskbar

Need to:
- Add frame tracking alongside window tracking
- Update handleXEvents() to handle title bar/button events
- Expose active window state to QML

---

## Testing Strategy

1. **Start Simple:** Just create frame and reparent, no decorations
2. **Add Title Bar:** Static title bar, no text yet
3. **Add Text:** Render window title
4. **Add Close Button:** Single button that works
5. **Add Dragging:** Make title bar draggable
6. **Add More Features:** Maximize, minimize, resize, etc.

---

## References

- NoteWM frame.c: https://github.com/masonarmand/NoteWM/blob/master/frame.c
- NoteWM notewm.h: https://github.com/masonarmand/NoteWM/blob/master/notewm.h
- X11 Programming Manual: https://tronche.com/gui/x/xlib/
- Xlib reparenting: https://tronche.com/gui/x/xlib/window/XReparentWindow.html

---

## Notes for Implementation

- **Event Handling:** Need to differentiate events from frame window vs client window
- **Configure Requests:** Client might request resize/move, WM must approve
- **ICCCM Compliance:** Send ConfigureNotify to client after move/resize
- **Error Handling:** Check if windows are valid before operations
- **CSD Detection:** Some apps use client-side decorations (Alacritty) - don't double-decorate
- **Unmapped Windows:** Hidden windows should keep their frames (for minimize/restore)

---

END OF REFERENCE
