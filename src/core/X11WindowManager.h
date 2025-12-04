#pragma once

#include <QHash>
#include <QObject>
#include <QSocketNotifier>
// #include <QTimer>  // DISABLED: Compositing disabled for now
#include <QVariantMap>
#include <X11/Xlib.h>
// DISABLED: Compositing extensions disabled for now
// #include <X11/extensions/Xcomposite.h>
// #include <X11/extensions/Xdamage.h>
// #include <X11/extensions/Xrender.h>

// Frame constants
#define BORDER_WIDTH 2
#define TITLE_HEIGHT 24
#define BUTTON_SIZE 16
#define PADDING 4

// Forward declaration
struct X11Frame;

class X11Window : public QObject {
  Q_OBJECT
public:
  Window window;
  QString title;
  QString appId;
  bool mapped = false;
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
};

// Frame structure - wraps client windows with decorations
struct X11Frame {
  Window frame;    // Outer container window
  Window titleBar; // Title bar window
  Window client;   // The actual client window
  GC gc;           // Graphics context for drawing

  QList<X11Button> buttons; // Titlebar buttons

  int x, y;          // Saved position (for fullscreen restore)
  int width, height; // Saved size (for fullscreen restore)
  bool isFullscreen = false;

  ~X11Frame() {
    // GC will be freed in X11WindowManager cleanup
  }
};

// DISABLED: Compositing disabled for now
// struct CompositedWindow {
//   Window window;
//   Picture picture = 0;
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

signals:
  void windowAdded(X11Window *window);
  void windowRemoved(Window window);
  void windowChanged(X11Window *window);

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

  // Frame management
  X11Frame *createFrame(Window client, int x, int y, int width, int height);
  void destroyFrame(X11Frame *frame);
  X11Frame *findFrame(Window window); // Find frame by any of its windows
  void drawTitleBarText(X11Frame *frame, const QString &title);
  void createTitleBarButtons(X11Frame *frame);
  void drawTitleBarButton(X11Frame *frame, const X11Button &button);

  // DISABLED: Compositing disabled for now
  // void paint();
  // void requestPaint(); // Queue a paint request with rate limiting
  // void damageWindow(X11Frame *frame);

  Display *m_display = nullptr;
  Window m_root;
  QSocketNotifier *m_notifier = nullptr;
  QHash<Window, X11Window *> m_windows;
  QHash<Window, X11Frame *> m_frames; // Maps frame/titlebar/client to frame

  // Drag state
  bool m_dragging = false;
  X11Frame *m_dragFrame = nullptr;
  int m_dragStartX = 0;
  int m_dragStartY = 0;
  int m_dragFrameStartX = 0;
  int m_dragFrameStartY = 0;

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
};
