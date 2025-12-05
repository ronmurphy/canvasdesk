import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import CanvasDesk

ApplicationWindow {
    visible: true
    width: isRuntimeMode ? Screen.width : 1280
    height: isRuntimeMode ? Screen.height : 720
    title: isRuntimeMode ? "CanvasDesk" : "CanvasDesk Editor"
    visibility: isRuntimeMode ? Window.FullScreen : Window.Windowed
    flags: isRuntimeMode ? Qt.FramelessWindowHint : Qt.Window
    
    // Runtime mode flag from C++ (set via context property)
    // Using different name to avoid self-reference
    property bool isRuntimeMode: false
    property bool isPreviewMode: false
    
    // Floating editor panel visibility (for runtime mode)
    property bool showFloatingEditor: false
    
    // Debug output
    onIsRuntimeModeChanged: console.log("Runtime Mode:", isRuntimeMode)
    
    // Selected component for property editing
    property var selectedComponent: null

    // LayoutManager instance
    LayoutManager {
        id: layoutManager
    }

    // Preview mode state (always true in runtime, or when preview is toggled in editor)
    property bool previewMode: isRuntimeMode || isPreviewMode
    onPreviewModeChanged: {
        if (previewMode) {
            loadPreview()
        } else {
            clearPreview()
        }
    }

    function saveLayout() {
        var items = []
        for (var i = 0; i < canvasModel.count; ++i) {
            var item = canvasModel.get(i)
            items.push({ 
                type: item.type, 
                x: item.x, 
                y: item.y,
                text: item.text,
                icon: item.icon,
                exec: item.exec,
                // Enhanced properties
                sectionRatios: item.sectionRatios,
                centerComponents: item.centerComponents
            })
        }
        var json = JSON.stringify({ components: items }, null, 2)
        if (layoutManager.saveLayout("layout.json", json)) {
            console.log("Layout saved to layout.json")
        }
    }

    function loadLayout() {
        var json = layoutManager.loadLayout("layout.json")
        if (json) {
            try {
                var data = JSON.parse(json)
                canvasModel.clear()
                if (data.components) {
                    for (var i = 0; i < data.components.length; ++i) {
                        canvasModel.append(data.components[i])
                    }
                }
                console.log("Layout loaded")
            } catch (e) {
                console.log("Error parsing layout JSON: " + e)
            }
        }
    }

    // Model to store components on the canvas
    ListModel {
        id: canvasModel
    }

    header: ToolBar {
        visible: !isRuntimeMode
        height: !isRuntimeMode ? implicitHeight : 0
        
        RowLayout {
            ToolButton {
                text: "Save"
                onClicked: saveLayout()
                enabled: !previewMode
            }
            ToolButton {
                text: "Load"
                onClicked: loadLayout()
                enabled: !previewMode
            }
            ToolButton {
                text: previewMode ? "Edit" : "Preview"
                highlighted: previewMode
                onClicked: {
                    if (!previewMode) {
                        // Save before previewing
                        saveLayout()
                    }
                    previewMode = !previewMode
                }
            }
            ToolButton {
                text: "Run"
                onClicked: layoutManager.runProject("layout.json")
                enabled: !previewMode
            }
            Item { Layout.fillWidth: true }
            Label {
                text: previewMode ? "CanvasDesk Preview" : "CanvasDesk Editor"
                font.bold: true
            }
            Item { Layout.fillWidth: true }
        }
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: previewMode ? 1 : 0

        // EDIT MODE (Index 0) - Only shown in editor (not runtime)
        RowLayout {
            spacing: 0
            visible: !isRuntimeMode

            // Component List (Left Panel)
        Rectangle {
            Layout.preferredWidth: 250
            Layout.fillHeight: true
            color: "#f0f0f0"
            border.color: "#ccc"
            z: 2
            
            SplitView {
                anchors.fill: parent
                orientation: Qt.Horizontal

                // Left Panel: Components & Apps
                ColumnLayout {
                    SplitView.preferredWidth: 250
                    SplitView.minimumWidth: 200
                    spacing: 0

                    TabBar {
                        id: leftTabBar
                        Layout.fillWidth: true
                        TabButton { text: "Components" }
                        TabButton { text: "Apps" }
                        TabButton { text: "Settings" }
                    }

                    StackLayout {
                        currentIndex: leftTabBar.currentIndex
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Components List
                        ListView {
                            model: ListModel {
                                ListElement { type: "Rectangle"; name: "Rectangle"; icon: "rectangle" }
                                ListElement { type: "Button"; name: "Button"; icon: "button" }
                                ListElement { type: "Text"; name: "Text Label"; icon: "text" }
                                ListElement { type: "Image"; name: "Image"; icon: "image" }
                                ListElement { type: "Clock"; name: "Clock"; icon: "clock" }
                                ListElement { type: "Taskbar"; name: "Taskbar"; icon: "view-list-icons" }
                                ListElement { type: "AppGrid"; name: "App Grid"; icon: "view-grid" }
                                ListElement { type: "FileManager"; name: "File Manager"; icon: "system-file-manager" }
                                ListElement { type: "WorkspaceSwitcher"; name: "Workspace Switcher"; icon: "view-multiple" }
                                ListElement { type: "EnhancedPanel"; name: "Enhanced Panel"; icon: "view-dashboard" }
                                ListElement { type: "AppLauncher"; name: "App Launcher"; icon: "system-search" }
                                ListElement { type: "AtomClock"; name: "Atom Clock"; icon: "clock" }
                                ListElement { type: "AtomCpu"; name: "Atom CPU"; icon: "cpu" }
                                ListElement { type: "AtomRam"; name: "Atom RAM"; icon: "memory" }
                                ListElement { type: "AtomDisk"; name: "Atom Disk"; icon: "drive-harddisk" }
                            }
                            delegate: ItemDelegate {
                                width: parent.width
                                text: name
                                icon.name: model.icon

                                Drag.active: dragHandler.active
                                Drag.dragType: Drag.Automatic
                                Drag.mimeData: { "text/plain": type }

                                DragHandler {
                                    id: dragHandler
                                    onActiveChanged: if (active) parent.grabToImage(function(result) { parent.Drag.imageSource = result.url })
                                }
                            }
                        }

                        // Apps List
                        ListView {
                            model: AppManager.apps
                            clip: true
                            delegate: ItemDelegate {
                                width: parent ? parent.width : 200
                                text: modelData.name
                                icon.name: modelData.icon || "application-x-executable"
                                
                                Drag.active: appDragHandler.active
                                Drag.dragType: Drag.Automatic
                                // Pass app data as JSON in mime data
                                Drag.mimeData: { 
                                    "application/x-canvasdesk-app": JSON.stringify({
                                        type: "Button",
                                        properties: {
                                            text: modelData.name,
                                            icon: modelData.icon,
                                            exec: modelData.exec
                                        }
                                    })
                                }

                                DragHandler {
                                    id: appDragHandler
                                    onActiveChanged: if (active) parent.grabToImage(function(result) { parent.Drag.imageSource = result.url })
                                }
                            }
                        }

                        // Settings Tab
                        ColumnLayout {
                            spacing: 10

                            Text {
                                text: "Settings"
                                font.pixelSize: 16
                                font.bold: true
                                Layout.margins: 10
                            }

                            Button {
                                Layout.fillWidth: true
                                Layout.margins: 10
                                text: "Open Control Center"

                                background: Rectangle {
                                    color: parent.down ? Theme.uiHighlightColor : Theme.uiPrimaryColor
                                    border.color: Theme.uiHighlightColor
                                    border.width: 1
                                    radius: 4
                                }

                                contentItem: Text {
                                    text: parent.text
                                    color: Theme.uiTextColor
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 14
                                }

                                onClicked: {
                                    var component = Qt.createComponent("ControlCenter.qml")
                                    if (component.status === Component.Ready) {
                                        var window = component.createObject(null)
                                        window.show()
                                    } else {
                                        console.log("Error loading ControlCenter:", component.errorString())
                                    }
                                }
                            }

                            Text {
                                Layout.margins: 10
                                Layout.fillWidth: true
                                text: "The Control Center provides:\n• Monitor Configuration\n• Appearance Settings\n• System Settings"
                                font.pixelSize: 12
                                color: Theme.uiTextColor
                                opacity: 0.7
                                wrapMode: Text.WordWrap
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }
                // Placeholder for additional panels if needed
            }
        }
        
        // Canvas (Center Panel)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#e0e0e0"
            clip: true
            z: 1
            
            // The actual canvas area
            Rectangle {
                id: canvasArea
                width: 800
                height: 600
                anchors.centerIn: parent
                color: Theme.uiSecondaryColor
                border.color: Theme.uiTitleBarLeftColor
                
                DropArea {
                    anchors.fill: parent
                    onDropped: (drop) => {
                        if (drop.hasText && !drop.formats.includes("application/x-canvasdesk-app")) {
                            var type = drop.text
                            var comp = { type: type, x: drop.x, y: drop.y }
                            canvasModel.append(comp)
                            drop.accept()
                        } else if (drop.formats.includes("application/x-canvasdesk-app")) {
                            var data = JSON.parse(drop.getDataAsString("application/x-canvasdesk-app"))
                            var comp = { 
                                type: data.type, 
                                x: drop.x, 
                                y: drop.y,
                                // We need to store properties in the model. 
                                // For prototype simplicity, we'll just store specific ones or a generic map if ListModel supports it (it doesn't well).
                                // So we'll flatten important ones.
                                text: data.properties.text,
                                icon: data.properties.icon,
                                exec: data.properties.exec,
                                sectionRatios: data.properties.sectionRatios,
                                centerComponents: data.properties.centerComponents
                            }
                            canvasModel.append(comp)
                            drop.accept()
                        }
                    }
                }
                
                // Render dropped components
                Repeater {
                    model: canvasModel
                    delegate: Rectangle {
                        id: componentRect
                        x: model.x
                        y: model.y
                        width: 100
                        height: 50
                        color: "#ddeeff"
                        border.color: "blue"

                        Text {
                            anchors.centerIn: parent
                            text: model.type
                        }

                        MouseArea {
                            anchors.fill: parent
                            drag.target: parent
                            onClicked: {
                                console.log("Selected: " + model.type)
                                propertyInspector.selectedComponent = model
                            }
                            onReleased: {
                                // Update model position when drag ends
                                canvasModel.setProperty(index, "x", componentRect.x)
                                canvasModel.setProperty(index, "y", componentRect.y)
                            }
                        }
                    }
                }
            }
        }
        
        // Property Inspector (Right Panel)
        Rectangle {
            id: propertyInspector
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            color: "#f0f0f0"
            border.color: "#ccc"
            z: 2
            
            property var selectedComponent: null
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                
                Text {
                    text: "Properties"
                    font.bold: true
                    font.pixelSize: 16
                }
                
                Text {
                    text: propertyInspector.selectedComponent ? propertyInspector.selectedComponent.type : "No selection"
                    font.pixelSize: 14
                }
                
                Item { Layout.fillHeight: true }
            }
        }
        } // End Edit Mode RowLayout

        // PREVIEW MODE (Index 1)
        Rectangle {
            color: "#2b2b2b"

            Item {
                id: previewContainer
                anchors.fill: parent
            }
        } // End Preview Mode

    } // End StackLayout

    // Small floating toggle button for runtime mode (32x32)
    Rectangle {
        visible: isRuntimeMode
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        z: 200
        width: 32
        height: 32
        color: showFloatingEditor ? "#4a90e2" : "#2a2a2a"
        border.color: Theme.uiTitleBarLeftColor
        border.width: 1
        radius: 4
        opacity: 0.8
        
        Text {
            anchors.centerIn: parent
            text: "✎"
            color: Theme.uiTextColor
            font.pixelSize: 18
        }
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.opacity = 1.0
            onExited: parent.opacity = 0.8
            onClicked: showFloatingEditor = !showFloatingEditor
        }
    }

    // Floating editor panel for runtime mode
    Rectangle {
        id: floatingEditorPanel
        visible: isRuntimeMode && showFloatingEditor
        width: 350
        height: 500
        x: parent.width - width - 50
        y: 50
        z: 250
        color: Theme.uiSecondaryColor
        border.color: Theme.uiTitleBarLeftColor
        border.width: 1
        radius: 6
        opacity: 0.95
        
        // Draggable header
        Rectangle {
            id: panelHeader
            width: parent.width
            height: 40
            color: Theme.uiPrimaryColor
            border.color: Theme.uiTitleBarLeftColor
            radius: 6
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                
                Text {
                    text: "CanvasDesk Editor"
                    color: Theme.uiTextColor
                    font.bold: true
                    Layout.fillWidth: true
                }
                
                Button {
                    text: "×"
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    onClicked: showFloatingEditor = false
                }
            }
            
            MouseArea {
                id: dragArea
                anchors.fill: parent
                drag.target: floatingEditorPanel
                drag.minimumX: 0
                drag.maximumX: parent.parent.parent.width - floatingEditorPanel.width
                drag.minimumY: 0
                drag.maximumY: parent.parent.parent.height - floatingEditorPanel.height
            }
        }
        
        // Content area with tabs
        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 40
            anchors.margins: 8
            spacing: 0
            
            TabBar {
                id: floatingTabBar
                Layout.fillWidth: true
                
                TabButton { text: "Components" }
                TabButton { text: "Properties" }
                TabButton { text: "Layout" }
            }
            
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: floatingTabBar.currentIndex
                
                // Components Tab
                ScrollView {
                    ListView {
                        model: ListModel {
                            ListElement { type: "Button"; name: "Button"; icon: "button" }
                            ListElement { type: "Clock"; name: "Clock"; icon: "clock" }
                            ListElement { type: "Taskbar"; name: "Taskbar"; icon: "view-list-icons" }
                            ListElement { type: "AppGrid"; name: "App Grid"; icon: "view-grid" }
                            ListElement { type: "WorkspaceSwitcher"; name: "Workspace Switcher"; icon: "view-multiple" }
                        }
                        
                        delegate: ItemDelegate {
                            width: parent.width
                            text: name
                            icon.name: model.icon
                            
                            onClicked: {
                                // Add component to desktop at center
                                var comp = {
                                    type: type,
                                    x: parent.parent.parent.parent.parent.parent.width / 2 - 50,
                                    y: parent.parent.parent.parent.parent.parent.height / 2 - 25,
                                    text: name,
                                    icon: model.icon,
                                    exec: ""
                                }
                                canvasModel.append(comp)
                            }
                        }
                    }
                }
                
                // Properties Tab
                ScrollView {
                    ColumnLayout {
                        width: parent.width
                        spacing: 8
                        
                        Label {
                            text: selectedComponent ? "Component Properties" : "Select a component"
                            color: Theme.uiTextColor
                            font.bold: true
                        }
                        
                        Label {
                            visible: selectedComponent
                            text: selectedComponent ? "Type: " + selectedComponent.type : ""
                            color: "#aaa"
                        }
                        
                        // Property Editors
                        
                        // Section Ratios (for EnhancedPanel)
                        ColumnLayout {
                            visible: selectedComponent && selectedComponent.type === "EnhancedPanel"
                            Layout.fillWidth: true
                            
                            Text { 
                                text: "Section Ratios (comma separated)" 
                                font.pixelSize: 12
                                color: "#555"
                            }
                            
                            TextField {
                                Layout.fillWidth: true
                                text: selectedComponent && selectedComponent.sectionRatios ? selectedComponent.sectionRatios : "1,1,1"
                                onEditingFinished: {
                                    if (selectedComponent) {
                                        // Update the model
                                        selectedComponent.sectionRatios = text
                                        // Force model update (hacky but works for ListModel)
                                        var idx = -1
                                        for(var i=0; i<canvasModel.count; i++) {
                                            if(canvasModel.get(i) === selectedComponent) {
                                                idx = i; break;
                                            }
                                        }
                                        if(idx !== -1) canvasModel.setProperty(idx, "sectionRatios", text)
                                    }
                                }
                            }
                        }
                        
                        // Center Components (for EnhancedPanel)
                        RowLayout {
                            visible: selectedComponent && selectedComponent.type === "EnhancedPanel"
                            Layout.fillWidth: true
                            
                            CheckBox {
                                text: "Center Components"
                                checked: selectedComponent && selectedComponent.centerComponents ? selectedComponent.centerComponents : false
                                onCheckedChanged: {
                                    if (selectedComponent) {
                                        selectedComponent.centerComponents = checked
                                        // Force model update
                                        var idx = -1
                                        for(var i=0; i<canvasModel.count; i++) {
                                            if(canvasModel.get(i) === selectedComponent) {
                                                idx = i; break;
                                            }
                                        }
                                        if(idx !== -1) canvasModel.setProperty(idx, "centerComponents", checked)
                                    }
                                }
                            }
                        }
                        
                        Label {
                            visible: !selectedComponent
                            text: "Click a component on the desktop to edit its properties"
                            color: "#888"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
                
                // Layout Tab (Save/Load)
                ColumnLayout {
                    spacing: 8
                    anchors.margins: 8
                    
                    Button {
                        text: "Save Layout"
                        Layout.fillWidth: true
                        onClicked: saveLayout()
                    }
                    
                    Button {
                        text: "Load Layout"
                        Layout.fillWidth: true
                        onClicked: {
                            loadLayout()
                            clearPreview()
                            loadPreview()
                        }
                    }
                    
                    Button {
                        text: "Apply Changes"
                        Layout.fillWidth: true
                        highlighted: true
                        onClicked: {
                            saveLayout()
                            clearPreview()
                            loadPreview()
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }

    // Overlay for dragged items to be on top of everything
    Item {
        id: overlay
        anchors.fill: parent
        z: 100
        visible: !previewMode
    }

    // Preview loading functions
    function loadPreview() {
        clearPreview()
        var json = layoutManager.loadLayout("layout.json")
        if (json) {
            console.log("Loading preview")
            try {
                var data = JSON.parse(json)
                if (data.components) {
                    for (var i = 0; i < data.components.length; ++i) {
                        createPreviewObject(data.components[i])
                    }
                }
            } catch (e) {
                console.log("Error loading preview: " + e)
            }
        }
    }

    function clearPreview() {
        // Remove all preview children
        for (var i = previewContainer.children.length - 1; i >= 0; --i) {
            previewContainer.children[i].destroy()
        }
    }

    function createPreviewObject(data) {
        var qml = ""
        if (data.type === "Button") {
            qml = 'import QtQuick; import QtQuick.Controls; import CanvasDesk; Rectangle { width: 100; height: 40; color: "lightgray"; border.color: "gray"; radius: 4; x: ' + data.x + '; y: ' + data.y + '; Text { anchors.centerIn: parent; text: "' + (data.text || "Button") + '" } MouseArea { anchors.fill: parent; onClicked: AppManager.launch("' + (data.exec || "") + '") } }'
        } else if (data.type === "Clock") {
            qml = 'import QtQuick; import QtQuick.Controls; Rectangle { width: 120; height: 40; color: Theme.uiSecondaryColor; border.color: Theme.uiTitleBarLeftColor; radius: 4; x: ' + data.x + '; y: ' + data.y + '; Text { id: clockText; anchors.centerIn: parent; color: Theme.uiTextColor; font.pixelSize: 16; font.family: "monospace"; text: Qt.formatTime(new Date(), "hh:mm:ss"); } Timer { interval: 1000; running: true; repeat: true; onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm:ss") } }'
        } else if (data.type === "Taskbar") {
            qml = 'import QtQuick; import QtQuick.Controls; import QtQuick.Layouts; import CanvasDesk; Rectangle { width: 400; height: 40; x: ' + data.x + '; y: ' + data.y + '; color: Theme.uiPrimaryColor; border.color: "#444"; border.width: 1; radius: 4; ListView { anchors.fill: parent; anchors.margins: 2; orientation: ListView.Horizontal; spacing: 4; model: WindowManager.windows; delegate: Rectangle { width: 100; height: 30; color: modelData.active ? "#3a3a3a" : "#2a2a2a"; border.color: Theme.uiTitleBarLeftColor; radius: 2; Text { anchors.centerIn: parent; text: modelData.title; color: Theme.uiTextColor; elide: Text.ElideRight; width: parent.width - 10; horizontalAlignment: Text.AlignHCenter } MouseArea { anchors.fill: parent; onClicked: WindowManager.activate(modelData.id) } } Text { visible: parent.count === 0; anchors.centerIn: parent; text: "Taskbar (no windows)"; color: "#888"; font.pixelSize: 12 } } }'
        } else if (data.type === "AppGrid") {
            qml = 'import QtQuick; import QtQuick.Controls; import CanvasDesk; Rectangle { width: 300; height: 400; x: ' + data.x + '; y: ' + data.y + '; color: Theme.uiPrimaryColor; border.color: "#444"; border.width: 1; radius: 4; GridView { anchors.fill: parent; anchors.margins: 8; cellWidth: 80; cellHeight: 80; clip: true; model: AppManager.apps; delegate: Item { width: 80; height: 80; Column { anchors.centerIn: parent; spacing: 5; Rectangle { width: 48; height: 48; color: "transparent"; Image { anchors.fill: parent; source: "image://theme/" + (modelData.icon || "application-x-executable"); sourceSize.width: 48; sourceSize.height: 48; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: AppManager.launch(modelData.exec) } } Text { text: modelData.name; width: 70; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 10; color: Theme.uiTextColor } } } } }'
        } else if (data.type === "WorkspaceSwitcher") {
            qml = 'import QtQuick; import QtQuick.Controls; import QtQuick.Layouts; import CanvasDesk; Rectangle { width: 180; height: 40; x: ' + data.x + '; y: ' + data.y + '; color: Theme.uiPrimaryColor; border.color: "#444"; border.width: 1; radius: 4; Row { anchors.centerIn: parent; spacing: 5; Repeater { model: WindowManager.workspaceCount; delegate: Rectangle { width: 40; height: 30; color: WindowManager.currentWorkspace === index ? "#3a3a3a" : "#2a2a2a"; border.color: Theme.uiTitleBarLeftColor; radius: 2; Text { anchors.centerIn: parent; text: (index + 1).toString(); color: Theme.uiTextColor } MouseArea { anchors.fill: parent; onClicked: WindowManager.switchToWorkspace(index) } } } } }'
        } else if (data.type === "FileManager") {
            qml = 'import QtQuick; import QtQuick.Controls; import Qt.labs.folderlistmodel; import CanvasDesk; Rectangle { width: 250; height: 300; x: ' + data.x + '; y: ' + data.y + '; color: Theme.uiPrimaryColor; border.color: "#444"; border.width: 1; radius: 4; ListView { anchors.fill: parent; anchors.margins: 4; clip: true; model: FolderListModel { folder: "file://" + AppManager.homeDir(); showDirsFirst: true; nameFilters: ["*"] } delegate: Rectangle { width: parent.width; height: 30; color: "transparent"; Row { anchors.fill: parent; spacing: 5; leftPadding: 5; Image { source: "image://theme/" + (fileIsDir ? "folder" : "text-x-generic"); width: 20; height: 20; anchors.verticalCenter: parent.verticalCenter } Text { text: fileName; color: Theme.uiTextColor; anchors.verticalCenter: parent.verticalCenter } } } } }'
        } else if (data.type === "EnhancedPanel") {
             var ratios = data.sectionRatios || "1,1,1"
             var center = data.centerComponents === true ? "true" : "false"
             var ratioArray = "[" + ratios + "]"
             qml = 'import QtQuick; import QtQuick.Controls; import QtQuick.Layouts; import CanvasDesk; import "components"; EnhancedPanelComponent { width: 800; height: 100; x: ' + data.x + '; y: ' + data.y + '; sectionRatios: ' + ratioArray + '; sectionCount: ' + ratioArray + '.length; centerComponents: ' + center + ' }'
        } else if (data.type === "AppLauncher") {
             qml = 'import QtQuick; import QtQuick.Controls; import CanvasDesk; import "components"; AppLauncherComponent { width: 400; height: 500; x: ' + data.x + '; y: ' + data.y + ' }'
        } else if (data.type === "AtomClock") {
             qml = 'import QtQuick; import QtQuick.Controls; import CanvasDesk; import "components"; AtomClockComponent { x: ' + data.x + '; y: ' + data.y + ' }'
        } else if (data.type === "AtomCpu") {
             qml = 'import QtQuick; import QtQuick.Controls; import CanvasDesk; import "components"; AtomCpuComponent { x: ' + data.x + '; y: ' + data.y + ' }'
        } else if (data.type === "AtomRam") {
             qml = 'import QtQuick; import QtQuick.Controls; import CanvasDesk; import "components"; AtomRamComponent { x: ' + data.x + '; y: ' + data.y + ' }'
        } else if (data.type === "AtomDisk") {
             qml = 'import QtQuick; import QtQuick.Controls; import CanvasDesk; import "components"; AtomDiskComponent { x: ' + data.x + '; y: ' + data.y + ' }'
        } else {
            qml = 'import QtQuick; Rectangle { color: "#ddeeff"; border.color: "blue"; width: 100; height: 50; x: ' + data.x + '; y: ' + data.y + '; Text { anchors.centerIn: parent; text: "' + data.type + '"; color: "black" } }'
        }

        try {
            Qt.createQmlObject(qml, previewContainer, "previewComponent")
        } catch (e) {
            console.log("Error creating preview object: " + e)
        }
    }
}
