#include "ThemeManager.h"
#include "X11WindowManager.h"
#include <QDebug>
#include <QSet>
// #include <QTimer>  // DISABLED: Compositing disabled for now
#include <X11/Xatom.h>
#include <X11/Xutil.h>
#include <X11/cursorfont.h>

X11WindowManager::X11WindowManager(QObject *parent) : QObject(parent) {}

X11WindowManager::~X11WindowManager() {
  // Clean up frames first
  for (X11Frame *frame : m_frames.values()) {
    if (frame->gc) {
      XFreeGC(m_display, frame->gc);
    }
    delete frame;
  }
  m_frames.clear();

  qDeleteAll(m_windows);
  if (m_notifier) {
    delete m_notifier;
  }
  if (m_display) {
    XCloseDisplay(m_display);
  }
}

bool X11WindowManager::initialize() {
  qInfo() << "[X11] Initializing X11 window manager...";

  // Open connection to X server
  m_display = XOpenDisplay(nullptr);
  if (!m_display) {
    qWarning() << "[X11] Failed to open X display";
    return false;
  }
  qInfo() << "[X11] Connected to X display";

  m_root = DefaultRootWindow(m_display);

  // Try to become the window manager by selecting SubstructureRedirect
  XSetWindowAttributes attrs;
  attrs.event_mask =
      SubstructureRedirectMask | SubstructureNotifyMask | PropertyChangeMask;

  XSync(m_display, False);
  XSetErrorHandler([](Display *, XErrorEvent *) -> int {
    qCritical() << "[X11] Another window manager is already running!";
    return 0;
  });

  XSelectInput(m_display, m_root, attrs.event_mask);
  XSync(m_display, False);

  // Enable XRandR screen change notifications
  int randrErrorBase;
  if (XRRQueryExtension(m_display, &m_randrEventBase, &randrErrorBase)) {
    XRRSelectInput(m_display, m_root, RRScreenChangeNotifyMask | RROutputChangeNotifyMask);
    qInfo() << "[X11] XRandR events enabled (event base:" << m_randrEventBase << ")";
  }

  // Restore default error handler
  XSetErrorHandler(nullptr);

  qInfo() << "[X11] Successfully registered as window manager";

  // Create resize cursors
  m_cursorNormal = XCreateFontCursor(m_display, XC_left_ptr);
  m_cursorResizeH = XCreateFontCursor(m_display, XC_sb_h_double_arrow);
  m_cursorResizeV = XCreateFontCursor(m_display, XC_sb_v_double_arrow);
  m_cursorResizeNWSE = XCreateFontCursor(m_display, XC_bottom_right_corner);
  m_cursorResizeNESW = XCreateFontCursor(m_display, XC_bottom_left_corner);
  qInfo() << "[X11] Created resize cursors";

  // Connect to ThemeManager for color updates
  if (auto theme = ThemeManager::instance()) {
      connect(theme, &ThemeManager::uiColorsChanged, this, &X11WindowManager::updateThemeColors);
  }

  // DISABLED: Compositing disabled for now
  // // Initialize Extensions
  // if (!XCompositeQueryExtension(m_display, &m_compositeEventBase,
  //                               &m_compositeErrorBase)) {
  //   qCritical() << "[X11] XComposite extension not found!";
  //   return false;
  // }
  // if (!XRenderQueryExtension(m_display, &m_renderEventBase,
  //                            &m_renderErrorBase)) {
  //   qCritical() << "[X11] XRender extension not found!";
  //   return false;
  // }
  // if (!XDamageQueryExtension(m_display, &m_damageEventBase,
  //                            &m_damageErrorBase)) {
  //   qCritical() << "[X11] XDamage extension not found!";
  //   return false;
  // }
  //
  // // Redirect all subwindows of root (Manual Compositing)
  // XCompositeRedirectSubwindows(m_display, m_root, CompositeRedirectManual);
  // qInfo() << "[X11] Enabled Manual Compositing";
  //
  // // Initialize existing windows
  // Window root_return, parent_return;
  // Window *children;
  // unsigned int nchildren;
  // if (XQueryTree(m_display, m_root, &root_return, &parent_return, &children,
  //                &nchildren)) {
  //   for (unsigned int i = 0; i < nchildren; i++) {
  //     XWindowAttributes attrs;
  //     if (XGetWindowAttributes(m_display, children[i], &attrs) &&
  //         attrs.map_state == IsViewable) {
  //       // Create composited window wrapper
  //       auto *cw = new CompositedWindow;
  //       cw->window = children[i];
  //       cw->attrs = attrs;
  //
  //       XRenderPictFormat *format =
  //           XRenderFindVisualFormat(m_display, attrs.visual);
  //       cw->picture =
  //           XRenderCreatePicture(m_display, cw->window, format, 0, nullptr);
  //       cw->damage =
  //           XDamageCreate(m_display, cw->window, XDamageReportNonEmpty);
  //
  //       m_compositedWindows.insert(cw->window, cw);
  //     }
  //   }
  //   if (children)
  //     XFree(children);
  // }

  // Set up Qt integration for X event processing
  int x11_fd = ConnectionNumber(m_display);
  m_notifier = new QSocketNotifier(x11_fd, QSocketNotifier::Read, this);
  connect(m_notifier, &QSocketNotifier::activated, this,
          &X11WindowManager::processXEvents);

  // DISABLED: Compositing disabled for now
  // // Set up paint rate limiting (60 FPS = ~16ms interval)
  // m_paintTimer = new QTimer(this);
  // m_paintTimer->setInterval(16); // 60 FPS
  // m_paintTimer->start();
  // connect(m_paintTimer, &QTimer::timeout, this, [this]() {
  //   if (m_paintRequested) {
  //     m_paintRequested = false;
  //     paint();
  //   }
  // });

  // Detect monitors
  updateMonitors();

  qInfo() << "[X11] ✓ X11 window manager initialized successfully";

  // DISABLED: Compositing disabled for now
  // // Initial paint
  // requestPaint();

  return true;
}

void X11WindowManager::processXEvents() {
  while (XPending(m_display)) {
    XEvent event;
    XNextEvent(m_display, &event);

    switch (event.type) {
    case MapRequest:
      handleMapRequest(&event.xmaprequest);
      break;
    // DISABLED: Compositing disabled for now
    // case MapNotify:
    //   handleMapNotify(&event.xmap);
    //   break;
    case UnmapNotify:
      handleUnmapNotify(&event.xunmap);
      break;
    case DestroyNotify:
      handleDestroyNotify(&event.xdestroywindow);
      break;
    case ConfigureRequest:
      handleConfigureRequest(&event.xconfigurerequest);
      break;
    case ButtonPress:
      handleButtonPress(&event.xbutton);
      break;
    case ButtonRelease:
      handleButtonRelease(&event.xbutton);
      break;
    case MotionNotify:
      handleMotionNotify(&event.xmotion);
      break;
    case PropertyNotify:
      // Window property changed (title, etc.)
      if (m_windows.contains(event.xproperty.window)) {
        updateWindowProperties(m_windows[event.xproperty.window]);
      }
      break;
    case Expose:
      if (m_frames.contains(event.xexpose.window)) {
          X11Frame* frame = m_frames[event.xexpose.window];
          // Only redraw if it's the titlebar that was exposed
          if (frame && frame->titleBar == event.xexpose.window) {
              drawTitleBar(frame);
          }
      }
      break;
    // DISABLED: Compositing disabled for now
    // case CreateNotify:
    //   // Track new windows for compositing
    //   // (We might want to wait for MapNotify, but tracking here is safe)
    //   break;
    // case ConfigureNotify: {
    //   // Update window attributes for compositing
    //   Window w = event.xconfigure.window;
    //   if (m_compositedWindows.contains(w)) {
    //     m_compositedWindows[w]->attrs.x = event.xconfigure.x;
    //     m_compositedWindows[w]->attrs.y = event.xconfigure.y;
    //     m_compositedWindows[w]->attrs.width = event.xconfigure.width;
    //     m_compositedWindows[w]->attrs.height = event.xconfigure.height;
    //     requestPaint(); // Queue repaint on move/resize
    //   }
    //   break;
    // }
    default:
      // Check for XRandR events (monitor changes)
      if (m_randrEventBase && event.type == m_randrEventBase + RRScreenChangeNotify) {
        qInfo() << "[X11] Screen configuration changed, updating monitors";
        updateMonitors();
      } else if (m_randrEventBase && event.type == m_randrEventBase + RRNotify) {
        // More specific RandR event (output change, etc.)
        qInfo() << "[X11] Monitor configuration changed, updating monitors";
        updateMonitors();
      }
      // DISABLED: Compositing disabled for now
      // // Check for Damage events
      // if (event.type == m_damageEventBase + XDamageNotify) {
      //   XDamageNotifyEvent *de = (XDamageNotifyEvent *)&event;
      //   XDamageSubtract(m_display, de->damage, None, None);
      //   requestPaint(); // Queue repaint on damage
      // }
      break;
    }
  }
}

// DISABLED: Compositing disabled for now
// void X11WindowManager::requestPaint() {
//   if (!m_paintRequested) {
//     m_paintRequested = true;
//   }
// }

// void X11WindowManager::paint() {
//   int screenWidth = DisplayWidth(m_display, 0);
//   int screenHeight = DisplayHeight(m_display, 0);
//   int depth = DefaultDepth(m_display, 0);
//
//   // Create back buffer pixmap for double buffering (ELIMINATES FLICKERING!)
//   Pixmap backBuffer = XCreatePixmap(m_display, m_root, screenWidth, screenHeight, depth);
//
//   // Create pictures for rendering
//   XRenderPictFormat *format = XRenderFindVisualFormat(
//       m_display, DefaultVisual(m_display, DefaultScreen(m_display)));
//   Picture backPicture = XRenderCreatePicture(m_display, backBuffer, format, 0, nullptr);
//   Picture rootPicture = XRenderCreatePicture(m_display, m_root, format, 0, nullptr);
//
//   // Fill background (Dark Gray) - render to back buffer
//   XRenderColor color = {0x2b2b, 0x2b2b, 0x2b2b, 0xffff};
//   XRenderFillRectangle(m_display, PictOpSrc, backPicture, &color, 0, 0,
//                        screenWidth, screenHeight);
//
//   // Get windows in stacking order
//   Window root_return, parent_return;
//   Window *children;
//   unsigned int nchildren;
//   if (XQueryTree(m_display, m_root, &root_return, &parent_return, &children,
//                  &nchildren)) {
//     for (unsigned int i = 0; i < nchildren; i++) {
//       Window w = children[i];
//       if (m_compositedWindows.contains(w)) {
//         CompositedWindow *cw = m_compositedWindows[w];
//         // Composite window onto BACK BUFFER (not directly to screen)
//         XRenderComposite(m_display, PictOpOver, cw->picture, None, backPicture,
//                          0, 0, 0, 0, cw->attrs.x, cw->attrs.y, cw->attrs.width,
//                          cw->attrs.height);
//       }
//     }
//     if (children)
//       XFree(children);
//   }
//
//   // NOW copy the complete back buffer to the screen in ONE OPERATION
//   // This is what eliminates flickering - the screen updates atomically
//   XRenderComposite(m_display, PictOpSrc, backPicture, None, rootPicture,
//                    0, 0, 0, 0, 0, 0, screenWidth, screenHeight);
//
//   // Clean up
//   XRenderFreePicture(m_display, backPicture);
//   XRenderFreePicture(m_display, rootPicture);
//   XFreePixmap(m_display, backBuffer);
//
//   XFlush(m_display);
// }

void X11WindowManager::handleMapRequest(XMapRequestEvent *event) {
  Window w = event->window;

  qInfo() << "[X11] 🪟 New window map request:" << w;

  // Get window attributes
  XWindowAttributes attrs;
  if (!XGetWindowAttributes(m_display, w, &attrs)) {
    qWarning() << "[X11] Failed to get window attributes";
    return;
  }

  // Skip windows that want to be unmanaged (override_redirect)
  if (attrs.override_redirect) {
    XMapWindow(m_display, w);
    return;
  }

  // Create our window object
  auto *window = new X11Window(this);
  window->window = w;
  window->mapped = true;

  // Get window properties (title, class)
  updateWindowProperties(window);

  // Skip CanvasDesk's own desktop window - don't frame it
  if (window->appId.toLower() == "canvasdesk") {
    qInfo() << "[X11] Skipping frame for CanvasDesk desktop window";
    m_windows.insert(w, window);
    XMapWindow(m_display, w);
    emit windowAdded(window);
    return;
  }

  m_windows.insert(w, window);

  // Determine initial size
  int width = attrs.width > 0 ? attrs.width : 800;
  int height = attrs.height > 0 ? attrs.height : 600;

  // Get size hints if available
  XSizeHints hints;
  long supplied;
  if (XGetWMNormalHints(m_display, w, &hints, &supplied)) {
    if ((hints.flags & PSize) && hints.width > 0) {
      width = hints.width;
      height = hints.height;
    }
  }

  // Create frame and reparent window
  X11Frame *frame = createFrame(w, 100, 100, width, height);
  window->frame = frame;

  // Load window icon
  loadWindowIcon(frame, w);

  // Create titlebar buttons
  createTitleBarButtons(frame);

  // Draw initial titlebar (gradient + text)
  drawTitleBar(frame);

  emit windowAdded(window);

  qInfo() << "[X11] Window added:" << window->title << "(" << window->appId
          << ")";
}

// DISABLED: Compositing disabled for now
// void X11WindowManager::handleMapNotify(XMapEvent *event) {
//   Window w = event->window;
//
//   // Skip frame windows (they have override_redirect and aren't composited)
//   if (m_frames.contains(w)) {
//     return;
//   }
//
//   // Create composited window if not exists
//   if (!m_compositedWindows.contains(w)) {
//     XWindowAttributes attrs;
//     if (XGetWindowAttributes(m_display, w, &attrs)) {
//       // Skip override_redirect windows (like our frames)
//       if (attrs.override_redirect) {
//         return;
//       }
//
//       auto *cw = new CompositedWindow;
//       cw->window = w;
//       cw->attrs = attrs;
//
//       XRenderPictFormat *format =
//           XRenderFindVisualFormat(m_display, attrs.visual);
//       cw->picture =
//           XRenderCreatePicture(m_display, cw->window, format, 0, nullptr);
//       cw->damage = XDamageCreate(m_display, cw->window, XDamageReportNonEmpty);
//
//       m_compositedWindows.insert(w, cw);
//     }
//   }
//
//   requestPaint(); // Queue repaint when window appears
//
//   if (m_windows.contains(w)) {
//     auto *window = m_windows.value(w);
//     if (!window->mapped) {
//       qInfo() << "[X11] Window mapped (MapNotify):" << w << window->title;
//       window->mapped = true;
//       emit windowChanged(window);
//     }
//   }
// }

void X11WindowManager::handleUnmapNotify(XUnmapEvent *event) {
  Window w = event->window;

  // DISABLED: Compositing disabled for now
  // // Remove from compositing
  // if (m_compositedWindows.contains(w)) {
  //   auto *cw = m_compositedWindows.take(w);
  //   XRenderFreePicture(m_display, cw->picture);
  //   XDamageDestroy(m_display, cw->damage);
  //   delete cw;
  //   requestPaint(); // Queue repaint when window disappears
  // }

  if (!m_windows.contains(w)) {
    // This might be a frame window or something else we don't track directly as
    // a client
    return;
  }

  qInfo() << "[X11] Window unmapped (UnmapNotify):" << w;

  auto *window = m_windows.value(w);
  if (window->mapped) {
    window->mapped = false;
    emit windowChanged(window);
  }
}

void X11WindowManager::handleDestroyNotify(XDestroyWindowEvent *event) {
  Window w = event->window;

  if (!m_windows.contains(w)) {
    return;
  }

  qInfo() << "[X11] Window destroyed (DestroyNotify):" << w;

  auto *window = m_windows.take(w);

  // Destroy associated frame if it exists
  if (window->frame) {
    qInfo() << "[X11] Destroying associated frame for window" << w;
    destroyFrame(window->frame);
    window->frame = nullptr;
  }

  emit windowRemoved(w);
  window->deleteLater();
}

void X11WindowManager::handleConfigureRequest(XConfigureRequestEvent *event) {
  // Window wants to change its configuration (size/position)
  XWindowChanges changes;
  changes.x = event->x;
  changes.y = event->y;
  changes.width = event->width;
  changes.height = event->height;
  changes.border_width = event->border_width;
  changes.sibling = event->above;
  changes.stack_mode = event->detail;

  XConfigureWindow(m_display, event->window, event->value_mask, &changes);
}

void X11WindowManager::updateWindowProperties(X11Window *win) {
  // Get window title
  XTextProperty text_prop;
  if (XGetWMName(m_display, win->window, &text_prop)) {
    if (text_prop.value) {
      win->title = QString::fromUtf8((char *)text_prop.value);
      XFree(text_prop.value);
    }
  }

  // Get window class (app ID)
  XClassHint class_hint;
  if (XGetClassHint(m_display, win->window, &class_hint)) {
    if (class_hint.res_class) {
      win->appId = QString::fromUtf8(class_hint.res_class);
      XFree(class_hint.res_class);
    }
    if (class_hint.res_name) {
      XFree(class_hint.res_name);
    }
  }

  // Update titlebar text if window has a frame
  if (win->frame) {
    drawTitleBarText(win->frame, win->title);
  }

  emit windowChanged(win);
}

void X11WindowManager::updateThemeColors() {
    auto theme = ThemeManager::instance();
    if (!theme) return;

    unsigned long frameBg = theme->uiSecondaryColor().rgb() & 0xFFFFFF;
    unsigned long textColor = theme->uiTextColor().rgb() & 0xFFFFFF;

    QSet<X11Frame*> processedFrames;

    for (auto it = m_frames.begin(); it != m_frames.end(); ++it) {
        X11Frame* frame = it.value();
        if (processedFrames.contains(frame)) continue;
        processedFrames.insert(frame);

        // Update Frame Background
        XSetWindowBackground(m_display, frame->frame, frameBg);
        XClearWindow(m_display, frame->frame);

        // Update Text Color in GC
        XSetForeground(m_display, frame->gc, textColor);

        // Redraw TitleBar (Gradient + Text + Buttons)
        drawTitleBar(frame);
    }
    
    XFlush(m_display);
}

// ========== Frame Management Functions ==========

X11Frame *X11WindowManager::createFrame(Window client, int x, int y, int width,
                                        int height) {
  qInfo() << "[X11] Creating frame for window" << client;

  auto *frame = new X11Frame();
  frame->client = client;
  frame->x = x;
  frame->y = y;
  frame->width = width;
  frame->height = height + TITLE_HEIGHT;

  // Create the frame window (outer container)
  unsigned long frameBg = 0x2b2b2b;
  unsigned long titleBg = 0x3c3c3c;
  unsigned long textColor = 0xffffff;
  
  if (auto theme = ThemeManager::instance()) {
      frameBg = theme->uiSecondaryColor().rgb() & 0xFFFFFF;
      titleBg = theme->uiTitleBarLeftColor().rgb() & 0xFFFFFF; // Use Left for solid color
      textColor = theme->uiTextColor().rgb() & 0xFFFFFF;
  }

  frame->frame = XCreateSimpleWindow(m_display, m_root, x, y, width,
                                     height + TITLE_HEIGHT, BORDER_WIDTH,
                                     0x444444, // border color (dark gray)
                                     frameBg
  );

  // DISABLED: Compositing disabled, no need for override_redirect now
  // // Set override_redirect on frame so it's not managed/composited
  // XSetWindowAttributes attrs;
  // attrs.override_redirect = True;
  // XChangeWindowAttributes(m_display, frame->frame, CWOverrideRedirect, &attrs);

  // Create title bar window
  frame->titleBar =
      XCreateSimpleWindow(m_display, frame->frame, 0, 0, width, TITLE_HEIGHT, 0,
                          0x000000, // border
                          titleBg
      );

  // DISABLED: Compositing disabled, no need for override_redirect now
  // // Set override_redirect on titlebar too
  // XChangeWindowAttributes(m_display, frame->titleBar, CWOverrideRedirect, &attrs);

  // Create graphics context for drawing text
  frame->gc = XCreateGC(m_display, frame->titleBar, 0, nullptr);
  XSetForeground(m_display, frame->gc, textColor); // text color

  // Initialize Xft for Unicode text rendering
  int screen = DefaultScreen(m_display);
  Visual *visual = DefaultVisual(m_display, screen);
  Colormap colormap = DefaultColormap(m_display, screen);

  // Create Xft font (using Noto Sans Symbols for best Unicode support)
  frame->xftFont = XftFontOpen(m_display, screen,
                               XFT_FAMILY, XftTypeString, "Noto Sans Symbols",
                               XFT_SIZE, XftTypeDouble, 12.0,
                               nullptr);
  if (!frame->xftFont) {
    qWarning() << "[X11] Failed to load Noto Sans Symbols, trying DejaVu Sans";
    frame->xftFont = XftFontOpen(m_display, screen,
                                 XFT_FAMILY, XftTypeString, "DejaVu Sans",
                                 XFT_SIZE, XftTypeDouble, 10.0,
                                 nullptr);
  }
  if (!frame->xftFont) {
    qWarning() << "[X11] Failed to load DejaVu Sans, using system default";
    frame->xftFont = XftFontOpenName(m_display, screen, "sans-10");
  }

  // Create Xft draw object for titlebar
  frame->xftDraw = XftDrawCreate(m_display, frame->titleBar, visual, colormap);

  // Create Xft color for text
  XRenderColor renderColor;
  renderColor.red = ((textColor >> 16) & 0xFF) * 257;
  renderColor.green = ((textColor >> 8) & 0xFF) * 257;
  renderColor.blue = (textColor & 0xFF) * 257;
  renderColor.alpha = 0xFFFF;
  XftColorAllocValue(m_display, visual, colormap, &renderColor, &frame->xftTextColor);

  // Select events we care about
  XSelectInput(m_display, frame->frame,
               SubstructureRedirectMask | SubstructureNotifyMask |
                   ButtonPressMask | ButtonReleaseMask | ExposureMask |
                   PointerMotionMask);  // Added motion for resize cursor and dragging
  XSelectInput(m_display, frame->titleBar,
               ButtonPressMask | ButtonReleaseMask | ExposureMask |
                   PointerMotionMask);
  // Note: Don't select ButtonPressMask on client - apps may already have it selected
  // which causes BadAccess error. We'll catch clicks on the frame instead.
  XSelectInput(m_display, client, StructureNotifyMask | PropertyChangeMask);

  // Reparent the client window into the frame
  XReparentWindow(m_display, client, frame->frame, 0, TITLE_HEIGHT);

  // Map all windows
  XMapWindow(m_display, frame->titleBar);
  XMapWindow(m_display, frame->frame);
  XMapWindow(m_display, client);

  // Store frame in hash for lookups (by all component windows)
  m_frames.insert(frame->frame, frame);
  m_frames.insert(frame->titleBar, frame);
  m_frames.insert(client, frame);

  qInfo() << "[X11] Frame created: frame=" << frame->frame
          << "titleBar=" << frame->titleBar << "client=" << client;

  return frame;
}

void X11WindowManager::destroyFrame(X11Frame *frame) {
  if (!frame)
    return;

  qInfo() << "[X11] Destroying frame" << frame->frame;

  // Remove from hash
  m_frames.remove(frame->frame);
  m_frames.remove(frame->titleBar);
  m_frames.remove(frame->client);

  // Remove button windows from hash BEFORE destroying them
  for (const X11Button &btn : frame->buttons) {
    m_frames.remove(btn.window);
  }

  // Free graphics context
  if (frame->gc) {
    XFreeGC(m_display, frame->gc);
  }

  // Free Xft resources
  if (frame->xftDraw) {
    XftDrawDestroy(frame->xftDraw);
  }
  if (frame->xftFont) {
    XftFontClose(m_display, frame->xftFont);
  }
  int screen = DefaultScreen(m_display);
  Visual *visual = DefaultVisual(m_display, screen);
  Colormap colormap = DefaultColormap(m_display, screen);
  XftColorFree(m_display, visual, colormap, &frame->xftTextColor);

  // Free icon pixmap
  if (frame->iconPixmap != None) {
    XFreePixmap(m_display, frame->iconPixmap);
  }

  // Destroy button windows (and free their Xft resources)
  for (const X11Button &btn : frame->buttons) {
    if (btn.xftDraw) {
      XftDrawDestroy(btn.xftDraw);
    }
    XDestroyWindow(m_display, btn.window);
  }

  // Destroy windows (this will unparent the client)
  XDestroyWindow(m_display, frame->titleBar);
  XDestroyWindow(m_display, frame->frame);

  delete frame;
}

X11Frame *X11WindowManager::findFrame(Window window) {
  return m_frames.value(window, nullptr);
}

void X11WindowManager::drawTitleBar(X11Frame *frame) {
    if (!frame || !frame->gc) return;

    int width = frame->width;
    int height = TITLE_HEIGHT;

    // Get colors from ThemeManager
    QColor leftColor = QColor("#3c3c3c");
    QColor rightColor = QColor("#3c3c3c");
    QColor textColor = QColor("#ffffff");

    if (auto theme = ThemeManager::instance()) {
        leftColor = theme->uiTitleBarLeftColor();
        rightColor = theme->uiTitleBarRightColor();
        textColor = theme->uiTextColor();
    }

    // Gradient drawing
    // We draw 2-pixel wide strips to be slightly faster than 1-pixel
    int step = 2;
    for (int x = 0; x < width; x += step) {
        float t = (float)x / (float)width;
        int r = leftColor.red() + t * (rightColor.red() - leftColor.red());
        int g = leftColor.green() + t * (rightColor.green() - leftColor.green());
        int b = leftColor.blue() + t * (rightColor.blue() - leftColor.blue());
        
        unsigned long pixel = (r << 16) | (g << 8) | b;
        XSetForeground(m_display, frame->gc, pixel);
        XFillRectangle(m_display, frame->titleBar, frame->gc, x, 0, step, height);
    }

    // Draw icon, text and buttons
    drawTitleBarIcon(frame);

    QString title = "Window";
    if (X11Window* win = m_windows.value(frame->client)) {
        title = win->title;
    }

    drawTitleBarText(frame, title);

    // Redraw buttons
    for (const auto& btn : frame->buttons) {
        drawTitleBarButton(frame, btn);
    }
}

void X11WindowManager::drawTitleBarText(X11Frame *frame, const QString &title) {
  if (!frame || !frame->xftDraw || !frame->xftFont)
    return;

  // Note: We do NOT clear the window here because it would erase the gradient background.
  // The background is handled by drawTitleBar().

  // Update Xft text color if theme changed
  if (auto theme = ThemeManager::instance()) {
      unsigned long textColor = theme->uiTextColor().rgb() & 0xFFFFFF;
      int screen = DefaultScreen(m_display);
      Visual *visual = DefaultVisual(m_display, screen);
      Colormap colormap = DefaultColormap(m_display, screen);

      // Free old color and allocate new one
      XftColorFree(m_display, visual, colormap, &frame->xftTextColor);
      XRenderColor renderColor;
      renderColor.red = ((textColor >> 16) & 0xFF) * 257;
      renderColor.green = ((textColor >> 8) & 0xFF) * 257;
      renderColor.blue = (textColor & 0xFF) * 257;
      renderColor.alpha = 0xFFFF;
      XftColorAllocValue(m_display, visual, colormap, &renderColor, &frame->xftTextColor);
  }

  // Convert QString to UTF-8 for Xft
  QByteArray titleBytes = title.toUtf8();

  // Calculate text width using Xft
  XGlyphInfo extents;
  XftTextExtentsUtf8(m_display, frame->xftFont,
                     (const FcChar8 *)titleBytes.constData(),
                     titleBytes.length(), &extents);

  // Calculate Position
  // Leave space for icon if it exists
  int iconSpace = 0;
  if (frame->iconPixmap != None && frame->iconWidth > 0) {
    iconSpace = PADDING + frame->iconWidth + PADDING; // Icon + padding on both sides
  }

  int textX = 0;
  if (ThemeManager::instance() && ThemeManager::instance()->titleBarTextLeft()) {
      textX = iconSpace + PADDING; // Left aligned, after icon
  } else {
      textX = (frame->width - extents.width) / 2; // Centered
      // Make sure centered text doesn't overlap icon
      if (textX < iconSpace) {
        textX = iconSpace + PADDING;
      }
  }

  int textY = TITLE_HEIGHT - PADDING - 4; // Y position for text baseline

  // Draw title text using Xft (supports Unicode)
  XftDrawStringUtf8(frame->xftDraw, &frame->xftTextColor, frame->xftFont,
                    textX, textY,
                    (const FcChar8 *)titleBytes.constData(),
                    titleBytes.length());

  // Redraw buttons
  for (const X11Button &btn : frame->buttons) {
    drawTitleBarButton(frame, btn);
  }

  XFlush(m_display);
}

void X11WindowManager::createTitleBarButtons(X11Frame *frame) {
  if (!frame)
    return;

  int buttonY = (TITLE_HEIGHT - BUTTON_SIZE) / 2;
  int rightEdge = frame->width - PADDING;

  int screen = DefaultScreen(m_display);
  Visual *visual = DefaultVisual(m_display, screen);
  Colormap colormap = DefaultColormap(m_display, screen);

  // DISABLED: Compositing disabled, no need for override_redirect now
  // // Set override_redirect for button windows
  // XSetWindowAttributes attrs;
  // attrs.override_redirect = True;

  // Close button (rightmost) - Red background
  X11Button closeBtn;
  closeBtn.type = X11Button::Close;
  closeBtn.x = rightEdge - BUTTON_SIZE;
  closeBtn.y = buttonY;
  closeBtn.width = BUTTON_SIZE;
  closeBtn.height = BUTTON_SIZE;
  closeBtn.color = 0xff5555; // Red
  closeBtn.window = XCreateSimpleWindow(m_display, frame->titleBar, closeBtn.x,
                                        closeBtn.y, BUTTON_SIZE, BUTTON_SIZE, 0,
                                        0x000000, closeBtn.color);
  // XChangeWindowAttributes(m_display, closeBtn.window, CWOverrideRedirect, &attrs);  // DISABLED
  closeBtn.xftDraw = XftDrawCreate(m_display, closeBtn.window, visual, colormap);
  XSelectInput(m_display, closeBtn.window,
               ButtonPressMask | ButtonReleaseMask | ExposureMask);
  XMapWindow(m_display, closeBtn.window);
  m_frames.insert(closeBtn.window, frame);
  frame->buttons.append(closeBtn);

  // Maximize button - Green background
  X11Button maxBtn;
  maxBtn.type = X11Button::Maximize;
  maxBtn.x = rightEdge - (BUTTON_SIZE + PADDING) * 2;
  maxBtn.y = buttonY;
  maxBtn.width = BUTTON_SIZE;
  maxBtn.height = BUTTON_SIZE;
  maxBtn.color = 0x55ff55; // Green
  maxBtn.window =
      XCreateSimpleWindow(m_display, frame->titleBar, maxBtn.x, maxBtn.y,
                          BUTTON_SIZE, BUTTON_SIZE, 0, 0x000000, maxBtn.color);
  // XChangeWindowAttributes(m_display, maxBtn.window, CWOverrideRedirect, &attrs);  // DISABLED
  maxBtn.xftDraw = XftDrawCreate(m_display, maxBtn.window, visual, colormap);
  XSelectInput(m_display, maxBtn.window,
               ButtonPressMask | ButtonReleaseMask | ExposureMask);
  XMapWindow(m_display, maxBtn.window);
  m_frames.insert(maxBtn.window, frame);
  frame->buttons.append(maxBtn);

  // Minimize button - Yellow background
  X11Button minBtn;
  minBtn.type = X11Button::Minimize;
  minBtn.x = rightEdge - (BUTTON_SIZE + PADDING) * 3;
  minBtn.y = buttonY;
  minBtn.width = BUTTON_SIZE;
  minBtn.height = BUTTON_SIZE;
  minBtn.color = 0xffff55; // Yellow
  minBtn.window =
      XCreateSimpleWindow(m_display, frame->titleBar, minBtn.x, minBtn.y,
                          BUTTON_SIZE, BUTTON_SIZE, 0, 0x000000, minBtn.color);
  // XChangeWindowAttributes(m_display, minBtn.window, CWOverrideRedirect, &attrs);  // DISABLED
  minBtn.xftDraw = XftDrawCreate(m_display, minBtn.window, visual, colormap);
  XSelectInput(m_display, minBtn.window,
               ButtonPressMask | ButtonReleaseMask | ExposureMask);
  XMapWindow(m_display, minBtn.window);
  m_frames.insert(minBtn.window, frame);
  frame->buttons.append(minBtn);

  qInfo() << "[X11] Created 3 titlebar buttons for frame" << frame->frame;
}

void X11WindowManager::drawTitleBarButton(X11Frame *frame,
                                          const X11Button &button) {
  if (!frame)
    return;

  // Create a GC for drawing shapes
  GC buttonGC = XCreateGC(m_display, button.window, 0, nullptr);
  XSetForeground(m_display, buttonGC, 0x000000); // Black
  XSetLineAttributes(m_display, buttonGC, 2, LineSolid, CapRound, JoinRound);

  int centerX = BUTTON_SIZE / 2;
  int centerY = BUTTON_SIZE / 2;
  int margin = 4;

  switch (button.type) {
  case X11Button::Close: {
    // Draw X using two diagonal lines
    XDrawLine(m_display, button.window, buttonGC,
              margin, margin,
              BUTTON_SIZE - margin, BUTTON_SIZE - margin);
    XDrawLine(m_display, button.window, buttonGC,
              BUTTON_SIZE - margin, margin,
              margin, BUTTON_SIZE - margin);
    break;
  }
  case X11Button::Maximize: {
    // Draw a square outline
    XDrawRectangle(m_display, button.window, buttonGC,
                   margin, margin,
                   BUTTON_SIZE - margin * 2, BUTTON_SIZE - margin * 2);
    break;
  }
  case X11Button::Minimize: {
    // Draw a horizontal line at the bottom
    XDrawLine(m_display, button.window, buttonGC,
              margin, BUTTON_SIZE - margin - 2,
              BUTTON_SIZE - margin, BUTTON_SIZE - margin - 2);
    break;
  }
  }

  XFreeGC(m_display, buttonGC);
}

void X11WindowManager::loadWindowIcon(X11Frame *frame, Window client) {
  if (!frame || !m_display) return;

  // Clean up old icon if it exists
  if (frame->iconPixmap != None) {
    XFreePixmap(m_display, frame->iconPixmap);
    frame->iconPixmap = None;
    frame->iconWidth = 0;
    frame->iconHeight = 0;
  }

  // Get _NET_WM_ICON atom
  Atom netWmIcon = XInternAtom(m_display, "_NET_WM_ICON", False);
  Atom actualType;
  int actualFormat;
  unsigned long nItems, bytesAfter;
  unsigned char *data = nullptr;

  // Try to get the icon property
  int result = XGetWindowProperty(m_display, client, netWmIcon,
                                  0, LONG_MAX, False, XA_CARDINAL,
                                  &actualType, &actualFormat,
                                  &nItems, &bytesAfter, &data);

  if (result != Success || !data || nItems < 2) {
    if (data) XFree(data);
    return;
  }

  // _NET_WM_ICON format: width, height, ARGB pixel data
  unsigned long *iconData = (unsigned long *)data;
  unsigned long width = iconData[0];
  unsigned long height = iconData[1];

  // We want a small icon for the titlebar (16x16)
  const int TARGET_SIZE = 16;

  // Find the best matching icon size
  unsigned long bestIdx = 0;
  unsigned long bestSize = width;
  unsigned long idx = 0;

  while (idx < nItems) {
    if (idx + 2 >= nItems) break;

    unsigned long w = iconData[idx];
    unsigned long h = iconData[idx + 1];
    unsigned long pixels = w * h;

    if (idx + 2 + pixels > nItems) break;

    // Prefer icons close to TARGET_SIZE
    if (w >= TARGET_SIZE && w <= bestSize) {
      bestSize = w;
      bestIdx = idx;
    }

    idx += 2 + pixels;
  }

  // Use the best icon found
  width = iconData[bestIdx];
  height = iconData[bestIdx + 1];
  unsigned long *pixels = &iconData[bestIdx + 2];

  // Get titlebar left color for alpha blending background
  QColor bgColor = QColor("#3c3c3c"); // Default fallback
  if (auto theme = ThemeManager::instance()) {
    bgColor = theme->uiTitleBarLeftColor();
  }
  unsigned char bgR = bgColor.red();
  unsigned char bgG = bgColor.green();
  unsigned char bgB = bgColor.blue();

  // Create a pixmap for the icon
  int screen = DefaultScreen(m_display);
  int depth = DefaultDepth(m_display, screen);
  Window root = DefaultRootWindow(m_display);

  frame->iconPixmap = XCreatePixmap(m_display, root, TARGET_SIZE, TARGET_SIZE, depth);

  if (frame->iconPixmap == None) {
    XFree(data);
    return;
  }

  // Create an XImage to convert ARGB data
  XImage *image = XCreateImage(m_display, DefaultVisual(m_display, screen),
                               depth, ZPixmap, 0, nullptr,
                               TARGET_SIZE, TARGET_SIZE, 32, 0);

  if (!image) {
    XFreePixmap(m_display, frame->iconPixmap);
    frame->iconPixmap = None;
    XFree(data);
    return;
  }

  // Allocate image data
  image->data = (char *)malloc(TARGET_SIZE * TARGET_SIZE * 4);
  if (!image->data) {
    XDestroyImage(image);
    XFreePixmap(m_display, frame->iconPixmap);
    frame->iconPixmap = None;
    XFree(data);
    return;
  }

  // Scale and convert ARGB to RGB with titlebar background color
  for (int y = 0; y < TARGET_SIZE; y++) {
    for (int x = 0; x < TARGET_SIZE; x++) {
      // Simple nearest-neighbor scaling
      int srcX = (x * width) / TARGET_SIZE;
      int srcY = (y * height) / TARGET_SIZE;
      unsigned long pixel = pixels[srcY * width + srcX];

      // Extract ARGB components
      unsigned char a = (pixel >> 24) & 0xFF;
      unsigned char r = (pixel >> 16) & 0xFF;
      unsigned char g = (pixel >> 8) & 0xFF;
      unsigned char b = pixel & 0xFF;

      // Alpha blending with titlebar left color background
      if (a < 255) {
        r = (r * a + bgR * (255 - a)) / 255;
        g = (g * a + bgG * (255 - a)) / 255;
        b = (b * a + bgB * (255 - a)) / 255;
      }

      unsigned long rgbPixel = (r << 16) | (g << 8) | b;
      XPutPixel(image, x, y, rgbPixel);
    }
  }

  // Draw the image to the pixmap
  GC gc = XCreateGC(m_display, frame->iconPixmap, 0, nullptr);
  XPutImage(m_display, frame->iconPixmap, gc, image, 0, 0, 0, 0, TARGET_SIZE, TARGET_SIZE);
  XFreeGC(m_display, gc);

  frame->iconWidth = TARGET_SIZE;
  frame->iconHeight = TARGET_SIZE;

  // Clean up
  free(image->data);
  image->data = nullptr;
  XDestroyImage(image);
  XFree(data);
}

void X11WindowManager::drawTitleBarIcon(X11Frame *frame) {
  if (!frame || frame->iconPixmap == None || frame->iconWidth == 0)
    return;

  // Draw icon on the left side of the titlebar
  int iconX = PADDING;
  int iconY = (TITLE_HEIGHT - frame->iconHeight) / 2;

  XCopyArea(m_display, frame->iconPixmap, frame->titleBar, frame->gc,
            0, 0, frame->iconWidth, frame->iconHeight,
            iconX, iconY);
}

void X11WindowManager::handleButtonPress(XButtonEvent *event) {
  X11Frame *frame = findFrame(event->window);
  if (!frame)
    return;

  // Focus the window on any click (titlebar, client area, or buttons)
  if (m_activeWindow != frame->client) {
    setFocus(frame->client);
  }

  // Check if it's a button click
  for (const X11Button &btn : frame->buttons) {
    if (btn.window == event->window) {
      qInfo() << "[X11] Button clicked:" << btn.type;

      switch (btn.type) {
      case X11Button::Close: {
        // Send WM_DELETE_WINDOW protocol message
        Atom wmProtocols = XInternAtom(m_display, "WM_PROTOCOLS", False);
        Atom wmDeleteWindow = XInternAtom(m_display, "WM_DELETE_WINDOW", False);

        XEvent ev;
        memset(&ev, 0, sizeof(ev));
        ev.type = ClientMessage;
        ev.xclient.window = frame->client;
        ev.xclient.message_type = wmProtocols;
        ev.xclient.format = 32;
        ev.xclient.data.l[0] = wmDeleteWindow;
        ev.xclient.data.l[1] = CurrentTime;

        XSendEvent(m_display, frame->client, False, NoEventMask, &ev);
        XFlush(m_display);
        break;
      }
      case X11Button::Maximize: {
        if (frame->isFullscreen) {
          // Restore to original size

          // Restore position and size from saved values
          frame->x = frame->savedX;
          frame->y = frame->savedY;
          frame->width = frame->savedWidth;
          frame->height = frame->savedHeight;

          // Resize the frame back to original size
          XMoveResizeWindow(m_display, frame->frame,
                           frame->x, frame->y,
                           frame->width, frame->height);

          // Resize the titlebar
          XResizeWindow(m_display, frame->titleBar, frame->width, TITLE_HEIGHT);

          // Resize the client window (subtract titlebar height)
          XResizeWindow(m_display, frame->client, frame->width, frame->height - TITLE_HEIGHT);

          // Recreate buttons for restored width
          for (const X11Button &btn : frame->buttons) {
            XDestroyWindow(m_display, btn.window);
            m_frames.remove(btn.window);
          }
          frame->buttons.clear();
          createTitleBarButtons(frame);

          // Redraw titlebar
          drawTitleBar(frame);

          frame->isFullscreen = false;

          // Update window state
          if (m_windows.contains(frame->client)) {
            m_windows[frame->client]->state = X11Window::Normal;
            emit windowChanged(m_windows[frame->client]);
          }
        } else {
          // Save current size and position before going fullscreen

          frame->savedX = frame->x;
          frame->savedY = frame->y;
          frame->savedWidth = frame->width;
          frame->savedHeight = frame->height;

          // Get screen dimensions
          int screenWidth = DisplayWidth(m_display, DefaultScreen(m_display));
          int screenHeight = DisplayHeight(m_display, DefaultScreen(m_display));

          // Update current dimensions
          frame->x = 0;
          frame->y = 0;
          frame->width = screenWidth;
          frame->height = screenHeight;

          // Move and resize frame to fill screen
          XMoveResizeWindow(m_display, frame->frame,
                           0, 0,
                           screenWidth, screenHeight);

          // Resize the titlebar to match screen width
          XResizeWindow(m_display, frame->titleBar, screenWidth, TITLE_HEIGHT);

          // Resize the client window
          XResizeWindow(m_display, frame->client, screenWidth, screenHeight - TITLE_HEIGHT);

          // Recreate buttons for fullscreen width
          for (const X11Button &btn : frame->buttons) {
            XDestroyWindow(m_display, btn.window);
            m_frames.remove(btn.window);
          }
          frame->buttons.clear();
          createTitleBarButtons(frame);

          // Redraw titlebar
          drawTitleBar(frame);

          frame->isFullscreen = true;

          // Update window state
          if (m_windows.contains(frame->client)) {
            m_windows[frame->client]->state = X11Window::Maximized;
            emit windowChanged(m_windows[frame->client]);
          }
        }

        XFlush(m_display);
        break;
      }
      case X11Button::Minimize: {
        // Use XIconifyWindow to minimize (iconify) the window
        // This hides the window and typically shows it in a taskbar
        int screen = DefaultScreen(m_display);
        XIconifyWindow(m_display, frame->client, screen);

        // Also unmap our frame
        XUnmapWindow(m_display, frame->frame);

        // Update window state
        if (m_windows.contains(frame->client)) {
          m_windows[frame->client]->state = X11Window::Minimized;
          emit windowChanged(m_windows[frame->client]);
        }

        XFlush(m_display);
        break;
      }
      }
      return;
    }
  }

  // Check if clicking on frame edge for resizing
  if (event->window == frame->frame) {
    int edge = detectResizeEdge(frame, event->x, event->y);

    if (edge != 0) {
      // Start resizing
      m_resizing = true;
      m_resizeFrame = frame;
      m_resizeEdge = edge;
      m_resizeStartX = event->x_root;
      m_resizeStartY = event->y_root;
      m_resizeStartWidth = frame->width;
      m_resizeStartHeight = frame->height;
      m_resizeStartFrameX = frame->x;
      m_resizeStartFrameY = frame->y;
      return;
    }
  }

  // If it's the titlebar (not a button), start dragging
  if (event->window == frame->titleBar) {
    m_dragging = true;
    m_dragFrame = frame;
    m_dragStartX = event->x_root;
    m_dragStartY = event->y_root;
    m_dragFrameStartX = frame->x;
    m_dragFrameStartY = frame->y;
  }
}

void X11WindowManager::handleButtonRelease(XButtonEvent *event) {
  if (m_resizing) {
    m_resizing = false;
    m_resizeFrame = nullptr;
    m_resizeEdge = 0;
  }

  if (m_dragging) {
    m_dragging = false;
    m_dragFrame = nullptr;
  }
}

int X11WindowManager::detectResizeEdge(X11Frame *frame, int x, int y) {
  // Returns bitmask: 1=left, 2=right, 4=top, 8=bottom
  int edge = 0;

  if (x < RESIZE_BORDER)
    edge |= 1; // Left
  else if (x > frame->width - RESIZE_BORDER)
    edge |= 2; // Right

  if (y < RESIZE_BORDER)
    edge |= 4; // Top
  else if (y > frame->height - RESIZE_BORDER)
    edge |= 8; // Bottom

  return edge;
}

void X11WindowManager::handleMotionNotify(XMotionEvent *event) {
  // Update cursor when hovering over edges (not while dragging/resizing)
  if (!m_dragging && !m_resizing) {
    X11Frame *frame = findFrame(event->window);
    if (frame && event->window == frame->frame) {
      // Only detect resize on the actual frame edges, not on titlebar area
      // The titlebar occupies y=0 to TITLE_HEIGHT
      if (event->y < TITLE_HEIGHT) {
        // We're in the titlebar area, use normal cursor
        XDefineCursor(m_display, frame->frame, m_cursorNormal);
      } else {
        // We're below the titlebar, check for resize edges
        int edge = detectResizeEdge(frame, event->x, event->y);

        Cursor cursor = m_cursorNormal;
        if (edge == (1|4) || edge == (2|8)) { // Top-left or bottom-right corner
          cursor = m_cursorResizeNWSE;
        } else if (edge == (2|4) || edge == (1|8)) { // Top-right or bottom-left corner
          cursor = m_cursorResizeNESW;
        } else if (edge & (1|2)) { // Left or right edge
          cursor = m_cursorResizeH;
        } else if (edge & (4|8)) { // Top or bottom edge
          cursor = m_cursorResizeV;
        }

        XDefineCursor(m_display, frame->frame, cursor);
      }
    }
  }

  // Handle window resizing
  if (m_resizing && m_resizeFrame) {
    int deltaX = event->x_root - m_resizeStartX;
    int deltaY = event->y_root - m_resizeStartY;

    int newX = m_resizeStartFrameX;
    int newY = m_resizeStartFrameY;
    int newWidth = m_resizeStartWidth;
    int newHeight = m_resizeStartHeight;

    // Adjust based on which edge is being dragged
    if (m_resizeEdge & 1) { // Left edge
      newX = m_resizeStartFrameX + deltaX;
      newWidth = m_resizeStartWidth - deltaX;
    }
    if (m_resizeEdge & 2) { // Right edge
      newWidth = m_resizeStartWidth + deltaX;
    }
    if (m_resizeEdge & 4) { // Top edge
      newY = m_resizeStartFrameY + deltaY;
      newHeight = m_resizeStartHeight - deltaY;
    }
    if (m_resizeEdge & 8) { // Bottom edge
      newHeight = m_resizeStartHeight + deltaY;
    }

    // Enforce minimum size
    const int minWidth = 100;
    const int minHeight = TITLE_HEIGHT + 50;
    if (newWidth < minWidth) newWidth = minWidth;
    if (newHeight < minHeight) newHeight = minHeight;

    // Apply the resize
    XMoveResizeWindow(m_display, m_resizeFrame->frame, newX, newY, newWidth, newHeight);

    // Update frame dimensions
    m_resizeFrame->x = newX;
    m_resizeFrame->y = newY;
    m_resizeFrame->width = newWidth;
    m_resizeFrame->height = newHeight;

    // Resize titlebar
    XResizeWindow(m_display, m_resizeFrame->titleBar, newWidth, TITLE_HEIGHT);

    // Resize client window
    XResizeWindow(m_display, m_resizeFrame->client, newWidth, newHeight - TITLE_HEIGHT);

    // Recreate buttons for new width
    for (const X11Button &btn : m_resizeFrame->buttons) {
      XDestroyWindow(m_display, btn.window);
      m_frames.remove(btn.window);
    }
    m_resizeFrame->buttons.clear();
    createTitleBarButtons(m_resizeFrame);

    // Redraw titlebar
    drawTitleBar(m_resizeFrame);

    return;
  }

  // Handle window dragging
  if (m_dragging && m_dragFrame) {
    // Calculate new position
    int deltaX = event->x_root - m_dragStartX;
    int deltaY = event->y_root - m_dragStartY;

    int newX = m_dragFrameStartX + deltaX;
    int newY = m_dragFrameStartY + deltaY;

    // Move the frame window
    XMoveWindow(m_display, m_dragFrame->frame, newX, newY);

    // Update saved position
    m_dragFrame->x = newX;
    m_dragFrame->y = newY;

    // Don't XFlush here - let the paint timer handle it at 60 FPS
    // This eliminates flickering during window drag
  }
}

void X11WindowManager::activateWindow(Window window) {
  if (!m_windows.contains(window)) {
    qWarning() << "[X11] Cannot activate window" << window << "- not found";
    return;
  }

  X11Window *win = m_windows[window];
  X11Frame *frame = win->frame;

  if (!frame) {
    qWarning() << "[X11] Cannot activate window" << window << "- no frame";
    return;
  }

  // If window is minimized, restore it
  if (win->state == X11Window::Minimized) {

    // Map the frame and client windows
    XMapWindow(m_display, frame->frame);
    XMapWindow(m_display, frame->client);

    // Update window state
    win->state = frame->isFullscreen ? X11Window::Maximized : X11Window::Normal;
    win->mapped = true;

    emit windowChanged(win);
  }

  // Set focus to the window (raises and focuses)
  setFocus(window);
}

void X11WindowManager::minimizeWindow(Window window) {
  if (!m_windows.contains(window)) {
    qWarning() << "[X11] Cannot minimize window" << window << "- not found";
    return;
  }

  X11Window *win = m_windows[window];
  X11Frame *frame = win->frame;

  if (!frame) {
    qWarning() << "[X11] Cannot minimize window" << window << "- no frame";
    return;
  }

  // Use XIconifyWindow to minimize (iconify) the window
  int screen = DefaultScreen(m_display);
  XIconifyWindow(m_display, frame->client, screen);

  // Also unmap our frame
  XUnmapWindow(m_display, frame->frame);

  // Update window state
  win->state = X11Window::Minimized;
  emit windowChanged(win);

  XFlush(m_display);
}

void X11WindowManager::closeWindow(Window window) {
  if (!m_windows.contains(window)) {
    qWarning() << "[X11] Cannot close window" << window << "- not found";
    return;
  }

  X11Window *win = m_windows[window];
  X11Frame *frame = win->frame;

  if (!frame) {
    qWarning() << "[X11] Cannot close window" << window << "- no frame";
    return;
  }

  // Send WM_DELETE_WINDOW protocol message
  Atom wmProtocols = XInternAtom(m_display, "WM_PROTOCOLS", False);
  Atom wmDeleteWindow = XInternAtom(m_display, "WM_DELETE_WINDOW", False);

  XEvent ev;
  memset(&ev, 0, sizeof(ev));
  ev.type = ClientMessage;
  ev.xclient.window = frame->client;
  ev.xclient.message_type = wmProtocols;
  ev.xclient.format = 32;
  ev.xclient.data.l[0] = wmDeleteWindow;
  ev.xclient.data.l[1] = CurrentTime;

  XSendEvent(m_display, frame->client, False, NoEventMask, &ev);
  XFlush(m_display);
}

void X11WindowManager::setFocus(Window window) {
  if (!m_windows.contains(window)) {
    qWarning() << "[X11] Cannot focus window" << window << "- not found";
    return;
  }

  X11Window *win = m_windows[window];
  X11Frame *frame = win->frame;

  if (!frame) {
    qWarning() << "[X11] Cannot focus window" << window << "- no frame";
    return;
  }

  // Update active window tracking
  m_activeWindow = window;

  // Raise the window to the top
  XRaiseWindow(m_display, frame->frame);

  // Set input focus
  XSetInputFocus(m_display, frame->client, RevertToPointerRoot, CurrentTime);

  XFlush(m_display);

  // Notify QML that window state changed (for taskbar highlighting)
  emit windowChanged(win);
}

void X11WindowManager::updateMonitors() {
  if (!m_display) return;

  m_monitors.clear();

  // Check if XRandR is available
  int eventBase, errorBase;
  if (!XRRQueryExtension(m_display, &eventBase, &errorBase)) {
    qWarning() << "[X11] XRandR extension not available";
    // Fallback: use default screen dimensions
    Monitor mon;
    mon.name = "Default";
    mon.x = 0;
    mon.y = 0;
    mon.width = DisplayWidth(m_display, DefaultScreen(m_display));
    mon.height = DisplayHeight(m_display, DefaultScreen(m_display));
    mon.primary = true;
    m_monitors.append(mon);
    qInfo() << "[X11] Using default screen:" << mon.width << "x" << mon.height;
    emit monitorsChanged();
    return;
  }

  // Get screen resources
  XRRScreenResources *res = XRRGetScreenResources(m_display, m_root);
  if (!res) {
    qWarning() << "[X11] Failed to get screen resources";
    return;
  }

  // Get primary output
  RROutput primaryOutput = XRRGetOutputPrimary(m_display, m_root);

  qInfo() << "[X11] Detecting monitors...";
  qInfo() << "[X11] Found" << res->noutput << "outputs";

  // Iterate through outputs
  for (int i = 0; i < res->noutput; i++) {
    XRROutputInfo *outputInfo = XRRGetOutputInfo(m_display, res, res->outputs[i]);

    if (!outputInfo) continue;

    // Only process connected outputs
    if (outputInfo->connection == RR_Connected && outputInfo->crtc) {
      XRRCrtcInfo *crtcInfo = XRRGetCrtcInfo(m_display, res, outputInfo->crtc);

      if (crtcInfo) {
        Monitor mon;
        mon.name = QString::fromUtf8(outputInfo->name);
        mon.x = crtcInfo->x;
        mon.y = crtcInfo->y;
        mon.width = crtcInfo->width;
        mon.height = crtcInfo->height;
        mon.primary = (res->outputs[i] == primaryOutput);

        m_monitors.append(mon);

        qInfo() << "[X11] Monitor:" << mon.name
                << (mon.primary ? "(PRIMARY)" : "")
                << "- Position:" << mon.x << "," << mon.y
                << "Size:" << mon.width << "x" << mon.height;

        XRRFreeCrtcInfo(crtcInfo);
      }
    }

    XRRFreeOutputInfo(outputInfo);
  }

  XRRFreeScreenResources(res);

  if (m_monitors.isEmpty()) {
    qWarning() << "[X11] No monitors detected, using fallback";
    Monitor mon;
    mon.name = "Fallback";
    mon.x = 0;
    mon.y = 0;
    mon.width = DisplayWidth(m_display, DefaultScreen(m_display));
    mon.height = DisplayHeight(m_display, DefaultScreen(m_display));
    mon.primary = true;
    m_monitors.append(mon);
  }

  emit monitorsChanged();
}
