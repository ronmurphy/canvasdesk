#include "X11WindowManager.h"
#include <QDebug>
#include <X11/Xatom.h>
#include <X11/Xutil.h>

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

  // Restore default error handler
  XSetErrorHandler(nullptr);

  qInfo() << "[X11] Successfully registered as window manager";

  // Initialize Extensions
  if (!XCompositeQueryExtension(m_display, &m_compositeEventBase,
                                &m_compositeErrorBase)) {
    qCritical() << "[X11] XComposite extension not found!";
    return false;
  }
  if (!XRenderQueryExtension(m_display, &m_renderEventBase,
                             &m_renderErrorBase)) {
    qCritical() << "[X11] XRender extension not found!";
    return false;
  }
  if (!XDamageQueryExtension(m_display, &m_damageEventBase,
                             &m_damageErrorBase)) {
    qCritical() << "[X11] XDamage extension not found!";
    return false;
  }

  // Redirect all subwindows of root (Manual Compositing)
  XCompositeRedirectSubwindows(m_display, m_root, CompositeRedirectManual);
  qInfo() << "[X11] Enabled Manual Compositing";

  // Initialize existing windows
  Window root_return, parent_return;
  Window *children;
  unsigned int nchildren;
  if (XQueryTree(m_display, m_root, &root_return, &parent_return, &children,
                 &nchildren)) {
    for (unsigned int i = 0; i < nchildren; i++) {
      XWindowAttributes attrs;
      if (XGetWindowAttributes(m_display, children[i], &attrs) &&
          attrs.map_state == IsViewable) {
        // Create composited window wrapper
        auto *cw = new CompositedWindow;
        cw->window = children[i];
        cw->attrs = attrs;

        XRenderPictFormat *format =
            XRenderFindVisualFormat(m_display, attrs.visual);
        cw->picture =
            XRenderCreatePicture(m_display, cw->window, format, 0, nullptr);
        cw->damage =
            XDamageCreate(m_display, cw->window, XDamageReportNonEmpty);

        m_compositedWindows.insert(cw->window, cw);
      }
    }
    if (children)
      XFree(children);
  }

  // Set up Qt integration for X event processing
  int x11_fd = ConnectionNumber(m_display);
  m_notifier = new QSocketNotifier(x11_fd, QSocketNotifier::Read, this);
  connect(m_notifier, &QSocketNotifier::activated, this,
          &X11WindowManager::processXEvents);

  qInfo() << "[X11] ✓ X11 window manager initialized successfully";

  // Initial paint
  paint();

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
    case MapNotify:
      handleMapNotify(&event.xmap);
      break;
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
    case CreateNotify:
      // Track new windows for compositing
      // (We might want to wait for MapNotify, but tracking here is safe)
      break;
    case ConfigureNotify: {
      // Update window attributes for compositing
      Window w = event.xconfigure.window;
      if (m_compositedWindows.contains(w)) {
        m_compositedWindows[w]->attrs.x = event.xconfigure.x;
        m_compositedWindows[w]->attrs.y = event.xconfigure.y;
        m_compositedWindows[w]->attrs.width = event.xconfigure.width;
        m_compositedWindows[w]->attrs.height = event.xconfigure.height;
        paint(); // Repaint on move/resize
      }
      break;
    }
    default:
      // Check for Damage events
      if (event.type == m_damageEventBase + XDamageNotify) {
        XDamageNotifyEvent *de = (XDamageNotifyEvent *)&event;
        XDamageSubtract(m_display, de->damage, None, None);
        paint();
      }
      break;
    }
  }
}

void X11WindowManager::paint() {
  // Create root picture if needed (or just create every time for simplicity)
  XRenderPictFormat *format = XRenderFindVisualFormat(
      m_display, DefaultVisual(m_display, DefaultScreen(m_display)));
  Picture rootPicture =
      XRenderCreatePicture(m_display, m_root, format, 0, nullptr);

  // Fill background (Dark Gray)
  XRenderColor color = {0x2b2b, 0x2b2b, 0x2b2b, 0xffff};
  XRenderFillRectangle(m_display, PictOpSrc, rootPicture, &color, 0, 0,
                       DisplayWidth(m_display, 0), DisplayHeight(m_display, 0));

  // Get windows in stacking order
  Window root_return, parent_return;
  Window *children;
  unsigned int nchildren;
  if (XQueryTree(m_display, m_root, &root_return, &parent_return, &children,
                 &nchildren)) {
    for (unsigned int i = 0; i < nchildren; i++) {
      Window w = children[i];
      if (m_compositedWindows.contains(w)) {
        CompositedWindow *cw = m_compositedWindows[w];
        // Composite window onto root
        XRenderComposite(m_display, PictOpOver, cw->picture, None, rootPicture,
                         0, 0, 0, 0, cw->attrs.x, cw->attrs.y, cw->attrs.width,
                         cw->attrs.height);
      }
    }
    if (children)
      XFree(children);
  }

  XRenderFreePicture(m_display, rootPicture);
  XFlush(m_display);
}

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

  // Create titlebar buttons
  createTitleBarButtons(frame);

  // Draw initial title
  drawTitleBarText(frame, window->title);

  emit windowAdded(window);

  qInfo() << "[X11] Window added:" << window->title << "(" << window->appId
          << ")";
}

void X11WindowManager::handleMapNotify(XMapEvent *event) {
  Window w = event->window;

  // Create composited window if not exists
  if (!m_compositedWindows.contains(w)) {
    XWindowAttributes attrs;
    if (XGetWindowAttributes(m_display, w, &attrs)) {
      auto *cw = new CompositedWindow;
      cw->window = w;
      cw->attrs = attrs;

      XRenderPictFormat *format =
          XRenderFindVisualFormat(m_display, attrs.visual);
      cw->picture =
          XRenderCreatePicture(m_display, cw->window, format, 0, nullptr);
      cw->damage = XDamageCreate(m_display, cw->window, XDamageReportNonEmpty);

      m_compositedWindows.insert(w, cw);
    }
  }

  paint(); // Repaint when window appears

  if (m_windows.contains(w)) {
    auto *window = m_windows.value(w);
    if (!window->mapped) {
      qInfo() << "[X11] Window mapped (MapNotify):" << w << window->title;
      window->mapped = true;
      emit windowChanged(window);
    }
  }
}

void X11WindowManager::handleUnmapNotify(XUnmapEvent *event) {
  Window w = event->window;

  // Remove from compositing
  if (m_compositedWindows.contains(w)) {
    auto *cw = m_compositedWindows.take(w);
    XRenderFreePicture(m_display, cw->picture);
    XDamageDestroy(m_display, cw->damage);
    delete cw;
    paint(); // Repaint when window disappears
  }

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
  frame->frame = XCreateSimpleWindow(m_display, m_root, x, y, width,
                                     height + TITLE_HEIGHT, BORDER_WIDTH,
                                     0x444444, // border color (dark gray)
                                     0x2b2b2b  // background color (darker gray)
  );

  // Create title bar window
  frame->titleBar =
      XCreateSimpleWindow(m_display, frame->frame, 0, 0, width, TITLE_HEIGHT, 0,
                          0x000000, // border
                          0x3c3c3c  // title bar background (lighter gray)
      );

  // Create graphics context for drawing text
  frame->gc = XCreateGC(m_display, frame->titleBar, 0, nullptr);
  XSetForeground(m_display, frame->gc, 0xffffff); // white text

  // Select events we care about
  XSelectInput(m_display, frame->frame,
               SubstructureRedirectMask | SubstructureNotifyMask |
                   ButtonPressMask | ExposureMask);
  XSelectInput(m_display, frame->titleBar,
               ButtonPressMask | ButtonReleaseMask | ExposureMask |
                   PointerMotionMask);
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

  // Free graphics context
  if (frame->gc) {
    XFreeGC(m_display, frame->gc);
  }

  // Destroy button windows
  for (const X11Button &btn : frame->buttons) {
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

void X11WindowManager::drawTitleBarText(X11Frame *frame, const QString &title) {
  if (!frame || !frame->gc)
    return;

  // Clear the titlebar
  XClearWindow(m_display, frame->titleBar);

  // Draw title text (simple X11 text for now, no Xft yet)
  QByteArray titleBytes = title.toUtf8();
  XDrawString(m_display, frame->titleBar, frame->gc, PADDING,
              TITLE_HEIGHT - PADDING - 4, // y position for text baseline
              titleBytes.constData(), titleBytes.length());

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
  XSelectInput(m_display, minBtn.window,
               ButtonPressMask | ButtonReleaseMask | ExposureMask);
  XMapWindow(m_display, minBtn.window);
  m_frames.insert(minBtn.window, frame);
  frame->buttons.append(minBtn);

  qInfo() << "[X11] Created 3 titlebar buttons for frame" << frame->frame;
}

void X11WindowManager::drawTitleBarButton(X11Frame *frame,
                                          const X11Button &button) {
  if (!frame || !frame->gc)
    return;

  // Create a GC for the button
  GC buttonGC = XCreateGC(m_display, button.window, 0, nullptr);
  XSetForeground(m_display, buttonGC, 0x000000); // Black text

  const char *symbol = "";
  switch (button.type) {
  case X11Button::Close:
    symbol = "X";
    break;
  case X11Button::Maximize:
    symbol = "O";
    break;
  case X11Button::Minimize:
    symbol = "_";
    break;
  }

  // Draw symbol centered in button
  XDrawString(m_display, button.window, buttonGC, BUTTON_SIZE / 2 - 4,
              BUTTON_SIZE / 2 + 4, symbol, 1);

  XFreeGC(m_display, buttonGC);
}

void X11WindowManager::handleButtonPress(XButtonEvent *event) {
  X11Frame *frame = findFrame(event->window);
  if (!frame)
    return;

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
      case X11Button::Maximize:
        qInfo() << "[X11] Maximize not yet implemented";
        // TODO: Implement maximize
        break;
      case X11Button::Minimize:
        qInfo() << "[X11] Minimize not yet implemented";
        // TODO: Implement minimize (iconify)
        break;
      }
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

    qInfo() << "[X11] Started dragging window at" << m_dragStartX << ","
            << m_dragStartY;
  }
}

void X11WindowManager::handleButtonRelease(XButtonEvent *event) {
  if (m_dragging) {
    m_dragging = false;
    m_dragFrame = nullptr;
    qInfo() << "[X11] Stopped dragging";
  }
}

void X11WindowManager::handleMotionNotify(XMotionEvent *event) {
  if (!m_dragging || !m_dragFrame)
    return;

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

  XFlush(m_display);
}
