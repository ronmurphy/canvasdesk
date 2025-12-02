# CanvasDesk Unified Binary Plan

## Goal
Single executable that serves as both editor and runtime, with clean mode switching.

## Architecture

### Command Line Interface
```bash
canvasdesk              # Launch editor (default)
canvasdesk --runtime    # Launch as runtime only (no editor UI)
canvasdesk --preview    # Launch in preview mode with layout
canvasdesk --help       # Show help
```

### Project Structure
```
src/
├── main.cpp              # Single entry point for both modes
├── core/                 # Shared backend (AppManager, WindowManager, etc.)
├── qml/                  # Runtime QML components
├── editor/              # Editor-specific code
│   └── qml/             # Editor UI (includes preview mode)
└── CMakeLists.txt       # Single unified build
```

### Implementation Steps

#### Phase 1: Merge Executables ✅ (Ready to implement)
1. Create single main.cpp that:
   - Parses command line arguments
   - Loads EditorMain.qml by default
   - Loads RuntimeMain.qml if --runtime flag
2. Update CMakeLists to build single executable
3. Link all modules (Core, QML, Editor) into one binary

#### Phase 2: Runtime Mode in Editor
1. Add `--runtime` mode to editor
2. When in runtime mode:
   - Hide editor panels
   - Show only the preview container
   - Load layout.json automatically
   - No Save/Load/Preview buttons

#### Phase 3: Improve Preview Mode (Already Done!)
- ✅ Preview button in editor
- ✅ Live component rendering
- ✅ Switch between edit/preview seamlessly

## Benefits

### For Users
- ✅ Single app to install
- ✅ Smaller download size
- ✅ No confusion about which binary to run
- ✅ Instant preview without subprocess issues

### For Development
- ✅ Shared code between editor and runtime
- ✅ Easier to maintain
- ✅ Single build process
- ✅ Better testing (all code in one binary)

## Migration Path

### Step 1: Keep Both Binaries (Current State)
- `canvasdesk-editor` with preview mode ✅ DONE
- `canvasdesk-runtime` standalone ✅ EXISTS

### Step 2: Create Unified Binary
- Merge into single `canvasdesk` executable
- Support `--runtime` flag for runtime-only mode
- Keep old binaries as symlinks for compatibility

### Step 3: Distribution
- Primary: `canvasdesk` (unified binary)
- Optional: `canvasdesk-runtime` (symlink or minimal wrapper)

## Technical Details

### main.cpp Structure
```cpp
int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);

    // Parse arguments
    QCommandLineParser parser;
    parser.addOption({"runtime", "Run as desktop runtime only"});
    parser.addOption({"preview", "Run in preview mode"});
    parser.process(app);

    QQmlApplicationEngine engine;
    engine.addImportPath("qrc:/");

    // Load appropriate QML based on mode
    if (parser.isSet("runtime")) {
        engine.load(QUrl("qrc:/CanvasDeskRuntime/Main.qml"));
    } else {
        engine.load(QUrl("qrc:/CanvasDeskEditor/qml/EditorMain.qml"));
        // If preview flag, set previewMode = true
    }

    return app.exec();
}
```

### CMakeLists Changes
```cmake
# Single executable
qt_add_executable(canvasdesk
    src/main.cpp
)

# Include both editor and runtime QML
qt_add_qml_module(canvasdesk
    URI "CanvasDesk"
    QML_FILES
        src/qml/Main.qml
        src/editor/qml/EditorMain.qml
)

# Link all libraries
target_link_libraries(canvasdesk PRIVATE
    CanvasDeskCore
    CanvasDeskQml
)
```

## Next Actions

1. ✅ Preview mode in editor - DONE
2. ⏭️ Implement unified main.cpp
3. ⏭️ Update CMakeLists for single binary
4. ⏭️ Test both modes work from single executable
5. ⏭️ Update documentation
