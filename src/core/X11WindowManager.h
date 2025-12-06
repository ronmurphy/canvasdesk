#pragma once

#include <QHash>
#include <QObject>
#include <QSocketNotifier>
// #include <QTimer>  // DISABLED: Compositing disabled for now
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QVariantMap>
#include <X11/Xft/Xft.h>
#include <X11/Xlib.h>
#include <X11/extensions/Xrandr.h>

// Undefine X11 macros that conflict with Qt
#undef True
#undef False

// DISABLED: Compositing extensions disabled for now
// #include <X11/extensions/Xcomposite.h>
// #include <X11/extensions/Xdamage.h>
// #include <X11/extensions/Xrender.h>

// Frame constants
#define BORDER_WIDTH 2
#define TITLE_HEIGHT 24
#define BUTTON_SIZE 16
#define PADDING 4
#define RESIZE_BORDER 5 // Size of resize grab area at edges

// Forward declaration
struct X11Frame;

// Monitor information
struct Monitor {
  QString name;
  int x, y;
  int width, height;
  bool primary;
};

class X11Window : public QObject {
  Q_OBJECT
public:
  enum State { Normal, Minimized, Maximized };

  Window window;
  QString title;
  QString appId;
  bool mapped = false;
  int workspace = 0;
  State state = Normal;
  X11Frame *frame = nullptr; // Associated frame (if any)

  explicit X11Window(QObject *parent = nullptr) : QObject(parent) {}
};

// Button structure for titlebar buttons
struct X11Button {
  Window window;
  int x, y;
  unsigned int width, height;
  unsigned long color;
  enum Type { Close, Maximize, Minimize } type;

  // Xft resources for button icon
  XftDraw *xftDraw = nullptr;
};

// Dock/Panel support
struct X11Strut {
  long left = 0;
  long right = 0;
  long top = 0;
  long bottom = 0;

  // Partial struts (start/end coordinates)
  long left_start_y = 0;
  long left_end_y = 0;
  long right_start_y = 0;
  long right_end_y = 0;
  long top_start_x = 0;
  long top_end_x = 0;
  long bottom_start_x = 0;
  long bottom_end_x = 0;
};

// Frame structure - wraps client windows with decorations
struct X11Frame {
  Window frame;    // Outer container window
  Window titleBar; // Title bar window
  Window client;   // The actual client window
  GC gc;           // Graphics context for drawing

  // Xft resources for Unicode text rendering
  XftFont *xftFont = nullptr;
  XftDraw *xftDraw = nullptr;
  XftColor xftTextColor;

  QList<X11Button> buttons; // Titlebar buttons

  // App icon
  Pixmap iconPixmap = None;
  int iconWidth = 0;
  int iconHeight = 0;

  int x, y;          // Current position
  int width, height; // Current size (includes titlebar)

  // Saved dimensions for fullscreen restore
  int savedX = 0, savedY = 0;
  int savedWidth = 0, savedHeight = 0;
  bool isFullscreen = false;
  bool isFloating = false;

  // Dock/Strut support
  bool isDock = false;
  X11Strut strut;

  ~X11Frame() {
    // GC and Xft resources will be freed in X11WindowManager cleanup
  }
};

// DISABLED: Compositing disabled for now
// struct CompositedWindow {
//   Window window;
//   Damage damage = 0;
//   XWindowAttributes attrs;
// };

class X11WindowManager : public QObject {
  Q_OBJECT
public:
  explicit X11WindowManager(QObject *parent = nullptr);
  ~X11WindowManager();

  bool initialize();
  QList<X11Window *> windows() const { return m_windows.values(); }
  Window activeWindow() const { return m_activeWindow; }
  QList<Monitor> monitors() const { return m_monitors; }
  Display *display() const { return m_display; }

  // Custom struts for internal QML panels
  void setManualStrut(int top, int bottom, int left, int right);

  void activateWindow(Window window);
  void minimizeWindow(Window window);
  void closeWindow(Window window);
  void setFocus(Window window);
  void updateMonitors();

  void cycleLayout();
  void toggleTilingMode();
  bool isTilingMode() const;
  void tile(int workspace = -1);

signals:
  void windowAdded(X11Window *window);
  void windowRemoved(Window window);
  void windowChanged(X11Window *window);
  void monitorsChanged();

private slots:
  void processXEvents();

private:
  void handleMapRequest(XMapRequestEvent *event);
  void handleUnmapNotify(XUnmapEvent *event);
  void handleDestroyNotify(XDestroyWindowEvent *event);
  void handleConfigureRequest(XConfigureRequestEvent *event);
  // DISABLED: Compositing disabled for now
  // void handleMapNotify(XMapEvent *event);
  void handleButtonPress(XButtonEvent *event);
  void handleButtonRelease(XButtonEvent *event);
  void handleMotionNotify(XMotionEvent *event);
  void updateWindowProperties(X11Window *win);

  // Theme updates
  void updateThemeColors();

  // Frame management
  X11Frame *createFrame(Window client, int x, int y, int width, int height);
  void destroyFrame(X11Frame *frame);
  X11Frame *findFrame(Window window); // Find frame by any of its windows
  void drawTitleBar(X11Frame *frame); // Draw gradient titlebar
  void drawTitleBarText(X11Frame *frame, const QString &title);
  void createTitleBarButtons(X11Frame *frame);
  void drawTitleBarButton(X11Frame *frame, const X11Button &button);

  // Icon management
  void loadWindowIcon(X11Frame *frame, Window client);
  void drawTitleBarIcon(X11Frame *frame);

  // Resize helpers
  int detectResizeEdge(X11Frame *frame, int x, int y);

  // DISABLED: Compositing disabled for now
  // void paint();
  // void requestPaint(); // Queue a paint request with rate limiting
  // void damageWindow(X11Frame *frame);

  Display *m_display = nullptr;
  Window m_root;
  QSocketNotifier *m_notifier = nullptr;
  QHash<Window, X11Window *> m_windows;
  QHash<Window, X11Frame *> m_frames; // Maps frame/titlebar/client to frame

  // Monitor tracking
  QList<Monitor> m_monitors;
  int m_randrEventBase = 0;

  // Focus tracking
  Window m_activeWindow = None;

  // Resize cursors
  Cursor m_cursorNormal = None;
  Cursor m_cursorResizeH = None; // Horizontal resize (left-right)
  Cursor m_cursorResizeV = None; // Vertical resize (top-bottom)
  Cursor m_cursorResizeNWSE =
      None; // Diagonal resize (top-left to bottom-right)
  Cursor m_cursorResizeNESW =
      None; // Diagonal resize (top-right to bottom-left)

  // Drag state
  bool m_dragging = false;
  X11Frame *m_dragFrame = nullptr;
  int m_dragStartX = 0;
  int m_dragStartY = 0;
  int m_dragFrameStartX = 0;
  int m_dragFrameStartY = 0;

  // Resize state
  bool m_resizing = false;
  X11Frame *m_resizeFrame = nullptr;
  int m_resizeEdge = 0; // Bitmask: 1=left, 2=right, 4=top, 8=bottom
  int m_resizeStartX = 0;
  int m_resizeStartY = 0;
  int m_resizeStartWidth = 0;
  int m_resizeStartHeight = 0;
  int m_resizeStartFrameX = 0;
  int m_resizeStartFrameY = 0;

  // DISABLED: Compositing disabled for now
  // // Extension bases
  // int m_compositeEventBase = 0;
  // int m_compositeErrorBase = 0;
  // int m_renderEventBase = 0;
  // int m_renderErrorBase = 0;
  // int m_damageEventBase = 0;
  // int m_damageErrorBase = 0;
  //
  // QHash<Window, CompositedWindow *> m_compositedWindows;
  //
  // // Paint rate limiting (60 FPS)
  // QTimer *m_paintTimer = nullptr;
  // bool m_paintRequested = false;

  // Dock Management
  void updateGlobalStruts();
  void getWindowTypeAndStrut(Window w, X11Frame *frame);
  void applyDockGeometry(X11Frame *frame);
  void handlePropertyNotify(XPropertyEvent *event);

  void restoreDecorations(int workspace);

  // Reserved screen areas (from docks + manual)
  int m_reservedTop = 0;
  int m_reservedBottom = 0;
  int m_reservedLeft = 0;
  int m_reservedRight = 0;

  int m_manualTop = 0;
  int m_manualBottom = 0;
  int m_manualLeft = 0;
  int m_manualRight = 0;

  // Tiling state
  int m_currentWorkspace = 0;
  int m_masterCount = 1;
  float m_masterFactor = 0.55f;
  int m_gapSize = 10;
  QMap<int, bool> m_workspaceTilingMode;
};
