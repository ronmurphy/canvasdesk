# CanvasDesk Session Testing Notes

## Latest Update (Dec 2, 2025):
**Fixed:** Wayland socket detection
- Script now auto-detects which socket wayfire creates (wayland-0, wayland-1, etc.)
- Previous issue: hardcoded wayland-0 but wayfire created wayland-1
- This caused "Failed to create wl_display" crash

## What Changed:
1. **Session wrapper now uses wayfire** instead of labwc
2. **Debug logging enabled** - all output goes to `/tmp/canvasdesk-session-*.log`
3. **WlrWindowManager has detailed logging** with `[WLR]` prefix
4. **Taskbar component fixed** - should show "(no windows)" instead of crashing
5. **Auto-detect Wayland socket** - no longer assumes wayland-0

## Testing Steps:

### 1. Log Out and Log Into CanvasDesk Session
- Log out of KDE Plasma
- At login screen (SDDM/GDM), select **"CanvasDesk"** session
- Log in
- You should see the CanvasDesk desktop with panels

### 2. Test Window Management
- Open some applications (dolphin, konsole, kate, etc.)
- Check if they appear in the **Taskbar component** at the bottom panel
- Try clicking on taskbar items to switch windows

### 3. After Testing - Find the Log File
- When you log back into KDE, the log will be in `/tmp/`
- Find it with: `ls -lt /tmp/canvasdesk-session-*.log | head -1`
- Or just: `cat /tmp/canvasdesk-session-*.log`

### 4. Share the Log
- Copy the log file contents and share it with Claude
- Or run: `cat /tmp/canvasdesk-session-*.log | grep -E "(WLR|WindowManager|Taskbar|wayfire)"`

## What to Look For in the Log:

### ✅ Success Indicators:
```
[WLR] Attempting to initialize wlr window management...
[WLR] Connected to Wayland display
[WLR] Got Wayland registry
[WLR] ✓ Bound to wlr_foreign_toplevel_manager_v1
[WLR] ✓ wlr_foreign_toplevel_management_v1 initialized successfully
[WLR] 🪟 New toplevel window detected! ID: 1
```

### ❌ Problem Indicators:
```
[WLR] wlr_foreign_toplevel_management_v1 protocol not advertised by compositor
```
or
```
ERROR: wayfire compositor not found!
```

## Alternative: Run Nested (Advanced)
If you want to test without logging out:
```bash
# Run wayfire in a window (nested)
wayfire --socket wayfire-1 &
sleep 2
WAYLAND_DISPLAY=wayfire-1 ./build/canvasdesk --runtime
```
This runs CanvasDesk inside a wayfire window within KDE.

## Return Instructions:
1. Test the session
2. Log back into KDE
3. Find the log file: `ls -lt /tmp/canvasdesk-session-*.log | head -1`
4. Share the log with Claude, especially lines containing:
   - `[WLR]`
   - `WindowManager`
   - `Taskbar`
   - Any errors or warnings

---
**Note:** If wayfire doesn't start, you may need to install it:
```bash
sudo pacman -S wayfire
```
