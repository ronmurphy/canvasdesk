import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import CanvasDesk
import "components"

ApplicationWindow {
    id: desktopWindow
    visible: true

    // Try to span all monitors by using desktop available dimensions
    width: Screen.desktopAvailableWidth
    height: Screen.desktopAvailableHeight
    x: 0
    y: 0

    visibility: Window.FullScreen
    flags: {
        // Base flags for frameless fullscreen window
        var baseFlags = Qt.FramelessWindowHint

        // When running as a login session (not in dev environment like Plasma),
        // add flags to make this behave like a desktop/background window
        if (typeof isSessionMode !== 'undefined' && isSessionMode) {
            return baseFlags | Qt.WindowStaysOnBottomHint | Qt.Tool
        }

        return baseFlags
    }
    title: "CanvasDesk"
    color: Theme.wallpaperPath ? "black" : Theme.uiSecondaryColor

    // Wallpaper
    Image {
        id: wallpaperImage
        anchors.fill: parent
        z: -200
        source: Theme.wallpaperPath ? (Theme.wallpaperPath.startsWith("/") ? "file://" + Theme.wallpaperPath : Theme.wallpaperPath) : ""
        fillMode: Theme.wallpaperFillMode
        visible: Theme.wallpaperPath !== ""
    }

    // LayoutManager instance
    LayoutManager {
        id: layoutManager
    }

    // Selected component for property editing
    property var selectedComponent: null
    property bool isManuallyEditing: false
    
    // Editor Settings
    property bool showGrid: false
    property bool snapToGrid: false
    property int gridSize: 20
    property color backgroundColor: Theme.uiSecondaryColor
    
    // Update property fields when selection changes
    onSelectedComponentChanged: {
        if (selectedComponent) {
            if (fieldX) fieldX.text = Math.round(selectedComponent.x).toString()
            if (fieldY) fieldY.text = Math.round(selectedComponent.y).toString()
            if (fieldWidth) fieldWidth.text = Math.round(selectedComponent.width).toString()
            if (fieldHeight) fieldHeight.text = Math.round(selectedComponent.height).toString()
        }
    }

    // Update selected component when any component is clicked
    function selectComponent(component) {
        // Deselect all other components
        for (var i = 0; i < desktopContainer.children.length; i++) {
            var child = desktopContainer.children[i]
            if (child && child.componentType && child !== component) {
                child.selected = false
            }
        }

        // Set the selected component
        selectedComponent = component.selected ? component : null
    }
    
    // Floating editor panel visibility
    property bool showFloatingEditor: false

    // Floating Control Center visibility
    property bool showControlCenter: false

    // Desktop content area (where layout components are rendered)
    Item {
        id: desktopContainer
        anchors.fill: parent

        // Grid Visualization
        Canvas {
            id: gridCanvas
            anchors.fill: parent
            z: -100 // Behind everything
            visible: showGrid
            
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = "rgba(255, 255, 255, 0.1)"
                ctx.lineWidth = 1
                
                ctx.beginPath()
                
                // Vertical lines
                for (var x = 0; x < width; x += gridSize) {
                    ctx.moveTo(x, 0)
                    ctx.lineTo(x, height)
                }
                
                // Horizontal lines
                for (var y = 0; y < height; y += gridSize) {
                    ctx.moveTo(0, y)
                    ctx.lineTo(width, y)
                }
                
                ctx.stroke()
            }
            
            // Repaint when grid size changes
            Connections {
                target: desktopWindow
                function onGridSizeChanged() { gridCanvas.requestPaint() }
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        // Expose selectComponent so child components can find it
        function selectComponent(component) {
            // Use direct ID reference to the window
            desktopWindow.selectComponent(component)
        }
    }
    
    // Load layout after window is ready
    Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: loadDesktopLayout()
    }

    // Small floating toggle button (32x32)
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        z: 200
        width: 32
        height: 32
        color: showFloatingEditor ? Theme.uiHighlightColor : Theme.uiSecondaryColor
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

    // Floating editor panel
    Rectangle {
        id: floatingEditorPanel
        visible: showFloatingEditor
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
            color: Theme.uiTitleBarLeftColor
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
                TabButton { text: "Settings" }
            }
            
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: floatingTabBar.currentIndex
                
                // Components Tab
                ScrollView {
                    ListView {
                        model: ListModel {
                            ListElement { type: "Panel"; name: "Panel"; icon: "view-list-tree" }
                            ListElement { type: "AppLauncher"; name: "App Launcher"; icon: "application-menu" }
                            ListElement { type: "AppGrid"; name: "App Grid"; icon: "view-grid" }
                            ListElement { type: "Taskbar"; name: "Taskbar"; icon: "view-list-icons" }
                            ListElement { type: "Clock"; name: "Clock"; icon: "clock" }
                            ListElement { type: "WorkspaceSwitcher"; name: "Workspace Switcher"; icon: "view-multiple" }
                            ListElement { type: "FileManager"; name: "File Manager"; icon: "folder" }
                            ListElement { type: "SessionManager"; name: "Session Manager"; icon: "system-shutdown" }
                            ListElement { type: "Button"; name: "Button"; icon: "button" }
                            ListElement { type: "AtomClock"; name: "Atom Clock"; icon: "clock" }
                            ListElement { type: "AtomSysInfo"; name: "Atom SysInfo"; icon: "utilities-system-monitor" }
                        }
                        
                        delegate: ItemDelegate {
                            width: parent.width
                            
                            contentItem: RowLayout {
                                spacing: 8
                                
                                Image {
                                    source: "image://theme/" + model.icon
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                }
                                
                                Text {
                                    text: name
                                    color: Theme.uiTextColor
                                    Layout.fillWidth: true
                                }
                                
                                Button {
                                    text: "+"
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    onClicked: {
                                        // Add component to desktop
                                        var comp = {
                                            type: type,
                                            text: name,
                                            icon: model.icon,
                                            exec: ""
                                        }

                                        // Special positioning for Panel
                                        if (type === "Panel") {
                                            comp.x = desktopContainer.width / 2 - 400  // Center the 800px panel
                                            comp.y = desktopContainer.height - 80  // Near bottom with some margin
                                            comp.width = 800
                                            comp.height = 64
                                            comp.props = {
                                                edge: "bottom",
                                                autoHide: false
                                            }
                                        } else {
                                            // Default positioning for other components
                                            comp.x = desktopContainer.width / 2 - 50
                                            comp.y = desktopContainer.height / 2 - 25
                                        }

                                        console.log("Adding component:", type, "at", comp.x, comp.y)
                                        createDesktopComponent(comp)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Properties Tab
                ScrollView {
                    clip: true

                    ColumnLayout {
                        width: parent ? parent.width : 300
                        spacing: 12

                        // Header
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            color: Theme.uiSecondaryColor
                            radius: 4

                            Label {
                                anchors.centerIn: parent
                                text: selectedComponent ? selectedComponent.componentType + " Properties" : "Select a Component"
                                color: Theme.uiTextColor
                                font.bold: true
                                font.pixelSize: 14
                            }
                        }

                        // No selection message
                        Label {
                            visible: !selectedComponent
                            text: "Click a component on the desktop to edit its properties"
                            color: "#888"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            Layout.margins: 8
                        }

                        // Property sections (only visible when component selected)
                        ColumnLayout {
                            visible: selectedComponent !== null
                            Layout.fillWidth: true
                            spacing: 16

                            // Position & Size section
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: "Position & Size"
                                    color: Theme.uiHighlightColor
                                    font.bold: true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Theme.uiTitleBarLeftColor
                                }

                                // X position
                                RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: "X:"
                                        color: Theme.uiTextColor
                                        Layout.preferredWidth: 60
                                    }
                                    TextField {
                                        id: fieldX
                                        Layout.fillWidth: true
                                        validator: IntValidator { bottom: 0; top: 9999 }
                                        onAccepted: {
                                            if (selectedComponent) {
                                                selectedComponent.x = parseInt(text) || 0
                                            }
                                        }
                                    }
                                }

                                // Y position
                                RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: "Y:"
                                        color: Theme.uiTextColor
                                        Layout.preferredWidth: 60
                                    }
                                    TextField {
                                        id: fieldY
                                        Layout.fillWidth: true
                                        validator: IntValidator { bottom: 0; top: 9999 }
                                        onAccepted: {
                                            if (selectedComponent) {
                                                selectedComponent.y = parseInt(text) || 0
                                            }
                                        }
                                    }
                                }

                                // Width
                                RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: "Width:"
                                        color: Theme.uiTextColor
                                        Layout.preferredWidth: 60
                                    }
                                    TextField {
                                        id: fieldWidth
                                        Layout.fillWidth: true
                                        validator: IntValidator { bottom: 10; top: 9999 }
                                        onAccepted: {
                                            if (selectedComponent) {
                                                selectedComponent.width = parseInt(text) || 100
                                            }
                                        }
                                    }
                                }

                                // Height
                                RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: "Height:"
                                        color: Theme.uiTextColor
                                        Layout.preferredWidth: 60
                                    }
                                    TextField {
                                        id: fieldHeight
                                        Layout.fillWidth: true
                                        validator: IntValidator { bottom: 10; top: 9999 }
                                        onAccepted: {
                                            if (selectedComponent) {
                                                selectedComponent.height = parseInt(text) || 50
                                            }
                                        }
                                    }
                                }
                            }

                            // Component-specific properties  
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 400
                                visible: selectedComponent !== null
                                
                                // Panel properties
                                ColumnLayout {
                                    anchors.fill: parent
                                    visible: selectedComponent && selectedComponent.componentType === "Panel"
                                    spacing: 8

                                    Label {
                                        text: "Panel Settings"
                                        color: Theme.uiHighlightColor
                                        font.bold: true
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: Theme.uiTitleBarLeftColor
                                    }

                                    // Edge
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Label {
                                            text: "Edge:"
                                            color: Theme.uiTextColor
                                            Layout.preferredWidth: 100
                                        }
                                        ComboBox {
                                            Layout.fillWidth: true
                                            model: ["top", "bottom", "left", "right"]
                                            currentIndex: {
                                                if (!selectedComponent || !selectedComponent.loadedItem) return 1
                                                var edge = selectedComponent.loadedItem.edge || "bottom"
                                                return model.indexOf(edge)
                                            }
                                            onActivated: {
                                                if (selectedComponent && selectedComponent.loadedItem) {
                                                    selectedComponent.loadedItem.edge = model[index]
                                                }
                                            }
                                        }
                                    }

                                    // Auto Hide
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Label {
                                            text: "Auto Hide:"
                                            color: Theme.uiTextColor
                                            Layout.preferredWidth: 100
                                        }
                                        CheckBox {
                                            checked: selectedComponent && selectedComponent.loadedItem ? selectedComponent.loadedItem.autoHide : false
                                            onToggled: {
                                                if (selectedComponent && selectedComponent.loadedItem) {
                                                    selectedComponent.loadedItem.autoHide = checked
                                                }
                                            }
                                        }
                                    }

                                    Item { Layout.fillHeight: true }
                                }

                                // Clock properties
                                ColumnLayout {
                                    anchors.fill: parent
                                    visible: selectedComponent && selectedComponent.componentType === "Clock"
                                    spacing: 8

                                    Label {
                                        text: "Clock Settings"
                                        color: Theme.uiHighlightColor
                                        font.bold: true
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: Theme.uiTitleBarLeftColor
                                    }

                                    Item { Layout.fillHeight: true }
                                }

                                // AppLauncher properties
                                ColumnLayout {
                                    anchors.fill: parent
                                    visible: selectedComponent && selectedComponent.componentType === "AppLauncher"
                                    spacing: 8

                                    Label {
                                        text: "App Launcher Settings"
                                        color: Theme.uiHighlightColor
                                        font.bold: true
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: Theme.uiTitleBarLeftColor
                                    }

                                    // Button Text
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Label {
                                            text: "Button Text:"
                                            color: Theme.uiTextColor
                                            Layout.preferredWidth: 100
                                        }
                                        TextField {
                                            Layout.fillWidth: true
                                            text: selectedComponent && selectedComponent.loadedItem ? selectedComponent.loadedItem.buttonText : "Apps"
                                            onEditingFinished: {
                                                if (selectedComponent && selectedComponent.loadedItem) {
                                                    selectedComponent.loadedItem.buttonText = text
                                                }
                                            }
                                        }
                                    }

                                    Item { Layout.fillHeight: true }
                                }
                            }
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
                        onClicked: {
                            saveDesktopLayout()
                        }
                    }
                    
                    Button {
                        text: "Load Layout"
                        Layout.fillWidth: true
                        onClicked: {
                            loadDesktopLayout()
                        }
                    }
                    
                    Button {
                        text: "Apply Changes"
                        Layout.fillWidth: true
                        highlighted: true
                        onClicked: {
                            saveDesktopLayout()
                            // Clear and reload
                            for (var i = desktopContainer.children.length - 1; i >= 0; --i) {
                                desktopContainer.children[i].destroy()
                            }
                            loadDesktopLayout()
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                }

                // Settings Tab
                ScrollView {
                    clip: true
                    
                    ColumnLayout {
                        width: parent ? parent.width : 300
                        spacing: 16
                        anchors.margins: 8

                        // Grid Settings
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: "Grid Settings"
                                color: Theme.uiHighlightColor
                                font.bold: true
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.uiTitleBarLeftColor
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: "Show Grid"
                                    color: Theme.uiTextColor
                                    Layout.fillWidth: true
                                }
                                Switch {
                                    checked: showGrid
                                    onToggled: showGrid = checked
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: "Snap to Grid"
                                    color: Theme.uiTextColor
                                    Layout.fillWidth: true
                                }
                                Switch {
                                    checked: snapToGrid
                                    onToggled: snapToGrid = checked
                                }
                            }
                            
                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: "Grid Size: " + gridSize + "px"
                                    color: Theme.uiTextColor
                                    Layout.fillWidth: true
                                }
                                Slider {
                                    from: 10
                                    to: 100
                                    stepSize: 5
                                    value: gridSize
                                    onMoved: gridSize = value
                                    Layout.preferredWidth: 120
                                }
                            }
                        }

                        // Control Center
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: "Control Center"
                                color: Theme.uiHighlightColor
                                font.bold: true
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.uiTitleBarLeftColor
                            }

                            Button {
                                Layout.fillWidth: true
                                text: showControlCenter ? "Close Control Center" : "Open Control Center"

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
                                    showControlCenter = !showControlCenter
                                }
                            }

                            Label {
                                text: "• Monitor Configuration\n• Appearance Settings\n• System Settings"
                                color: Theme.uiTextColor
                                font.pixelSize: 11
                                opacity: 0.7
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        // Appearance Settings
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: "Appearance"
                                color: Theme.uiHighlightColor
                                font.bold: true
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.uiTitleBarLeftColor
                            }

                            // Wallpaper
                            Label {
                                text: "Wallpaper"
                                color: Theme.uiTextColor
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                TextField {
                                    id: wallpaperPathField
                                    Layout.fillWidth: true
                                    text: Theme.wallpaperPath
                                    placeholderText: "Path to image..."
                                    onEditingFinished: Theme.wallpaperPath = text
                                }
                                Button {
                                    text: "..."
                                    onClicked: wallpaperDialog.open()
                                }
                            }

                            FileDialog {
                                id: wallpaperDialog
                                title: "Select Wallpaper"
                                nameFilters: ["Image files (*.jpg *.png *.jpeg *.bmp)"]
                                onAccepted: {
                                    Theme.wallpaperPath = selectedFile
                                }
                            }

                            // Fill Mode
                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: "Fill Mode"
                                    color: Theme.uiTextColor
                                    Layout.preferredWidth: 80
                                }
                                ComboBox {
                                    Layout.fillWidth: true
                                    model: ["Stretch", "Preserve Aspect Fit", "Preserve Aspect Crop", "Tile", "Center"]
                                    currentIndex: {
                                        var mode = Theme.wallpaperFillMode
                                        if (mode === Image.Stretch) return 0
                                        if (mode === Image.PreserveAspectFit) return 1
                                        if (mode === Image.PreserveAspectCrop) return 2
                                        if (mode === Image.Tile) return 3
                                        if (mode === Image.Pad) return 4
                                        return 2 // Default to Crop
                                    }
                                    onActivated: {
                                        var modes = [Image.Stretch, Image.PreserveAspectFit, Image.PreserveAspectCrop, Image.Tile, Image.Pad]
                                        Theme.wallpaperFillMode = modes[index]
                                    }
                                }
                            }

                            // Extracted Colors Preview
                            Label {
                                text: "Theme Colors (Click to Assign)"
                                color: Theme.uiTextColor
                                topPadding: 8
                            }

                            RowLayout {
                                spacing: 4
                                
                                // Helper component for color box
                                component ColorBox: Rectangle {
                                    property string label
                                    property color colorValue
                                    width: 30
                                    height: 30
                                    color: colorValue
                                    border.color: Theme.uiTitleBarLeftColor
                                    
                                    ToolTip.visible: ma.containsMouse
                                    ToolTip.text: label
                                    
                                    MouseArea {
                                        id: ma
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            assignMenu.targetColor = parent.colorValue
                                            assignMenu.popup()
                                        }
                                    }
                                }

                                ColorBox { label: "Primary"; colorValue: Theme.primaryColor }
                                ColorBox { label: "Secondary"; colorValue: Theme.secondaryColor }
                                ColorBox { label: "Tertiary"; colorValue: Theme.tertiaryColor }
                                ColorBox { label: "Accent"; colorValue: Theme.accentColor }
                                ColorBox { label: "Neutral"; colorValue: Theme.neutralColor }
                                ColorBox { label: "Brightest"; colorValue: Theme.brightestColor }
                                
                                // Universal Colors
                                Rectangle { width: 1; height: 30; color: Theme.uiTitleBarLeftColor }
                                ColorBox { label: "White"; colorValue: Theme.whiteColor }
                                ColorBox { label: "Grey"; colorValue: Theme.greyColor }
                                ColorBox { label: "Black"; colorValue: Theme.blackColor }
                            }

                            Menu {
                                id: assignMenu
                                property color targetColor
                                
                                MenuItem { text: "Set as Primary UI Color"; onTriggered: Theme.assignColorToRole(assignMenu.targetColor, "Primary") }
                                MenuItem { text: "Set as Secondary UI Color"; onTriggered: Theme.assignColorToRole(assignMenu.targetColor, "Secondary") }
                                MenuItem { text: "Set as Tertiary UI Color"; onTriggered: Theme.assignColorToRole(assignMenu.targetColor, "Tertiary") }
                                MenuItem { text: "Set as Highlight Color"; onTriggered: Theme.assignColorToRole(assignMenu.targetColor, "Highlight") }
                                MenuItem { text: "Set as Text Color"; onTriggered: Theme.assignColorToRole(assignMenu.targetColor, "Text") }
                                MenuItem { text: "Set as TitleBar Left"; onTriggered: Theme.assignColorToRole(assignMenu.targetColor, "TitleBarLeft") }
                                MenuItem { text: "Set as TitleBar Right"; onTriggered: Theme.assignColorToRole(assignMenu.targetColor, "TitleBarRight") }
                            }

                            // Current Assignments Display
                            Label {
                                text: "Current UI Assignments"
                                color: Theme.uiTextColor
                                topPadding: 8
                            }
                            
                            GridLayout {
                                columns: 2
                                rowSpacing: 4
                                columnSpacing: 8
                                
                                Rectangle { width: 16; height: 16; color: Theme.uiPrimaryColor; border.color: Theme.uiTitleBarLeftColor } Label { text: "Primary UI"; color: Theme.uiTextColor }
                                Rectangle { width: 16; height: 16; color: Theme.uiSecondaryColor; border.color: Theme.uiTitleBarLeftColor } Label { text: "Secondary UI"; color: Theme.uiTextColor }
                                Rectangle { width: 16; height: 16; color: Theme.uiTertiaryColor; border.color: Theme.uiTitleBarLeftColor } Label { text: "Tertiary UI"; color: Theme.uiTextColor }
                                Rectangle { width: 16; height: 16; color: Theme.uiHighlightColor; border.color: Theme.uiTitleBarLeftColor } Label { text: "Highlight"; color: Theme.uiTextColor }
                                Rectangle { width: 16; height: 16; color: Theme.uiTextColor; border.color: Theme.uiTitleBarLeftColor } Label { text: "Text"; color: Theme.uiTextColor }
                                Rectangle { width: 16; height: 16; color: Theme.uiTitleBarLeftColor; border.color: Theme.uiTitleBarLeftColor } Label { text: "TitleBar Left"; color: Theme.uiTextColor }
                                Rectangle { width: 16; height: 16; color: Theme.uiTitleBarRightColor; border.color: Theme.uiTitleBarLeftColor } Label { text: "TitleBar Right"; color: Theme.uiTextColor }
                            }

                            CheckBox {
                                text: "Titlebar Text on Left"
                                checked: Theme.titleBarTextLeft
                                onCheckedChanged: Theme.titleBarTextLeft = checked
                                contentItem: Text {
                                    text: parent.text
                                    color: Theme.uiTextColor
                                    font: parent.font
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: parent.indicator.width + parent.spacing
                                }
                            }

                            // Manual Background Color (Fallback)
                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: "Fallback Color"
                                    color: Theme.uiTextColor
                                    Layout.fillWidth: true
                                }
                                Rectangle {
                                    width: 24
                                    height: 24
                                    color: backgroundColor
                                    border.color: Theme.uiTitleBarLeftColor
                                    border.width: 1
                                }
                            }
                            
                            TextField {
                                Layout.fillWidth: true
                                text: backgroundColor
                                placeholderText: "#RRGGBB"
                                onEditingFinished: {
                                    backgroundColor = text
                                    // Only apply if no wallpaper
                                    if (Theme.wallpaperPath === "") {
                                        desktopWindow.color = text
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }

    // Floating Control Center panel
    Rectangle {
        id: floatingControlCenter
        visible: showControlCenter
        width: 900
        height: 650
        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2
        z: 260
        color: Theme.uiPrimaryColor // Was uiBackgroundColor which is invalid
        border.color: Theme.uiTitleBarLeftColor
        border.width: 1
        radius: 6
        opacity: 0.98

        // Draggable header
        Rectangle {
            id: controlCenterHeader
            width: parent.width
            height: 50
            color: Theme.uiSecondaryColor
            radius: 6

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8

                Text {
                    text: "CanvasDesk Control Center"
                    color: Theme.uiTextColor
                    font.bold: true
                    font.pixelSize: 16
                    Layout.fillWidth: true
                }

                Button {
                    text: "×"
                    Layout.preferredWidth: 35
                    Layout.preferredHeight: 35
                    onClicked: showControlCenter = false

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
                        font.pixelSize: 18
                    }
                }
            }

            MouseArea {
                id: controlCenterDragArea
                anchors.fill: parent
                drag.target: floatingControlCenter
                drag.minimumX: 0
                drag.maximumX: parent.parent.parent.width - floatingControlCenter.width
                drag.minimumY: 0
                drag.maximumY: parent.parent.parent.height - floatingControlCenter.height
            }
        }

        // Tab bar
        Rectangle {
            anchors.top: controlCenterHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 5
            height: 50
            color: Theme.uiSecondaryColor

            Row {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 5

                Repeater {
                    model: ["Monitors", "Appearance", "System"]

                    Button {
                        width: 120
                        height: 40
                        text: modelData

                        background: Rectangle {
                            color: controlCenterTabView.currentIndex === index ? Theme.uiPrimaryColor : Theme.uiTertiaryColor
                            border.color: Theme.uiHighlightColor
                            border.width: controlCenterTabView.currentIndex === index ? 2 : 0
                            radius: 4
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Theme.uiTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            font.bold: controlCenterTabView.currentIndex === index
                        }

                        onClicked: controlCenterTabView.currentIndex = index
                    }
                }
            }
        }

        // Content area
        StackLayout {
            id: controlCenterTabView
            anchors.top: parent.top
            anchors.topMargin: 110
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10

            currentIndex: 0

            // Monitors Tab
            Rectangle {
                color: Theme.uiPrimaryColor
                property string selectedMonitorName: ""
                property var currentMonitor: {
                    var mons = WindowManager.monitorManager ? WindowManager.monitorManager.monitors : []
                    for (var i = 0; i < mons.length; i++) {
                        if (mons[i].name === selectedMonitorName) return mons[i]
                    }
                    return null
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    anchors.margins: 10

                    Text {
                        text: "Monitor Configuration"
                        font.pixelSize: 20
                        font.bold: true
                        color: Theme.uiTextColor
                    }

                    // Main Content Area (Split View)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        // Left: Visual Arranger
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.preferredWidth: 2
                            color: Theme.uiSecondaryColor
                            border.color: Theme.uiHighlightColor
                            border.width: 1
                            radius: 4
                            clip: true

                            MonitorArranger {
                                anchors.fill: parent
                                anchors.margins: 1
                                monitors: WindowManager.monitorManager ? WindowManager.monitorManager.monitors : []
                                selectedMonitor: parent.parent.parent.parent.selectedMonitorName // Access property from Monitors Tab Rectangle
                                
                                onMonitorSelected: {
                                    parent.parent.parent.parent.selectedMonitorName = name
                                }
                                
                                onMonitorMoved: {
                                    if (WindowManager.monitorManager) {
                                        WindowManager.monitorManager.setMonitorPosition(name, x, y)
                                    }
                                }
                            }
                            
                            Text {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.margins: 10
                                text: "Drag monitors to rearrange"
                                color: Theme.uiTextColor
                                opacity: 0.5
                                font.pixelSize: 12
                            }
                        }

                        // Right: Settings Panel
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            color: Theme.uiTertiaryColor
                            border.color: Theme.uiTitleBarLeftColor
                            border.width: 1
                            radius: 4

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 15
                                
                                visible: !!parent.parent.parent.parent.currentMonitor
                                
                                Text {
                                    text: parent.parent.parent.parent.currentMonitor ? parent.parent.parent.parent.currentMonitor.name : ""
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: Theme.uiTextColor
                                    Layout.fillWidth: true
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Theme.uiTitleBarLeftColor
                                }

                                // Enable/Disable
                                RowLayout {
                                    Layout.fillWidth: true
                                    Label { 
                                        text: "Status"
                                        color: Theme.uiTextColor
                                        Layout.fillWidth: true
                                    }
                                    Button {
                                        text: (parent.parent.parent.parent.parent.currentMonitor && parent.parent.parent.parent.parent.currentMonitor.enabled) ? "Enabled" : "Disabled"
                                        
                                        background: Rectangle {
                                            color: parent.down ? Theme.uiHighlightColor : ((parent.parent.parent.parent.parent.currentMonitor && parent.parent.parent.parent.parent.currentMonitor.enabled) ? Theme.uiPrimaryColor : "#F44336")
                                            border.color: Theme.uiHighlightColor
                                            border.width: 1
                                            radius: 4
                                        }
                                        
                                        contentItem: Text {
                                            text: parent.text
                                            color: "white"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        
                                        onClicked: {
                                            var mon = parent.parent.parent.parent.parent.currentMonitor
                                            if (WindowManager.monitorManager && mon) {
                                                WindowManager.monitorManager.setMonitorEnabled(mon.name, !mon.enabled)
                                            }
                                        }
                                    }
                                }
                                
                                // Primary
                                RowLayout {
                                    Layout.fillWidth: true
                                    Label { 
                                        text: "Primary Display"
                                        color: Theme.uiTextColor
                                        Layout.fillWidth: true
                                    }
                                    CheckBox {
                                        checked: parent.parent.parent.parent.parent.currentMonitor ? parent.parent.parent.parent.parent.currentMonitor.primary : false
                                        enabled: parent.parent.parent.parent.parent.currentMonitor ? parent.parent.parent.parent.parent.currentMonitor.enabled : false
                                        onClicked: {
                                            var mon = parent.parent.parent.parent.parent.currentMonitor
                                            if (WindowManager.monitorManager && mon && !mon.primary) {
                                                WindowManager.monitorManager.setPrimaryMonitor(mon.name)
                                            }
                                        }
                                    }
                                }

                                // Resolution
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Label { 
                                        text: "Resolution"
                                        color: Theme.uiTextColor
                                    }
                                    ComboBox {
                                        Layout.fillWidth: true
                                        model: parent.parent.parent.parent.parent.currentMonitor ? (parent.parent.parent.parent.parent.currentMonitor.availableModes || []) : []
                                        currentIndex: {
                                            var mon = parent.parent.parent.parent.parent.currentMonitor
                                            if (!mon) return -1
                                            var current = mon.width + "x" + mon.height
                                            return model.indexOf(current)
                                        }
                                        enabled: parent.parent.parent.parent.parent.currentMonitor ? parent.parent.parent.parent.parent.currentMonitor.enabled : false
                                        onActivated: {
                                            var mon = parent.parent.parent.parent.parent.currentMonitor
                                            if (WindowManager.monitorManager && mon) {
                                                var parts = currentText.split("x")
                                                if (parts.length === 2) {
                                                    WindowManager.monitorManager.setMonitorResolution(
                                                        mon.name,
                                                        parseInt(parts[0]),
                                                        parseInt(parts[1])
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Rotation
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Label { 
                                        text: "Rotation"
                                        color: Theme.uiTextColor
                                    }
                                    ComboBox {
                                        Layout.fillWidth: true
                                        model: ["0°", "90°", "180°", "270°"]
                                        currentIndex: {
                                            var mon = parent.parent.parent.parent.parent.currentMonitor
                                            if (!mon) return 0
                                            var rotations = [0, 90, 180, 270]
                                            return rotations.indexOf(mon.rotation)
                                        }
                                        enabled: parent.parent.parent.parent.parent.currentMonitor ? parent.parent.parent.parent.parent.currentMonitor.enabled : false
                                        onActivated: {
                                            var mon = parent.parent.parent.parent.parent.currentMonitor
                                            if (WindowManager.monitorManager && mon) {
                                                var rotations = [0, 90, 180, 270]
                                                WindowManager.monitorManager.setMonitorRotation(
                                                    mon.name,
                                                    rotations[currentIndex]
                                                )
                                            }
                                        }
                                    }
                                }
                                
                                // Position Manual Override
                                Label { 
                                    text: "Manual Position"
                                    color: Theme.uiTextColor
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Label { text: "X:"; color: Theme.uiTextColor }
                                    SpinBox {
                                        from: -8000; to: 8000; stepSize: 10
                                        value: parent.parent.parent.parent.parent.currentMonitor ? parent.parent.parent.parent.parent.currentMonitor.x : 0
                                        enabled: parent.parent.parent.parent.parent.currentMonitor ? parent.parent.parent.parent.parent.currentMonitor.enabled : false
                                        onValueModified: {
                                            var mon = parent.parent.parent.parent.parent.currentMonitor
                                            if (WindowManager.monitorManager && mon) {
                                                WindowManager.monitorManager.setMonitorPosition(mon.name, value, mon.y)
                                            }
                                        }
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Label { text: "Y:"; color: Theme.uiTextColor }
                                    SpinBox {
                                        from: -8000; to: 8000; stepSize: 10
                                        value: parent.parent.parent.parent.parent.currentMonitor ? parent.parent.parent.parent.parent.currentMonitor.y : 0
                                        enabled: parent.parent.parent.parent.parent.currentMonitor ? parent.parent.parent.parent.parent.currentMonitor.enabled : false
                                        onValueModified: {
                                            var mon = parent.parent.parent.parent.parent.currentMonitor
                                            if (WindowManager.monitorManager && mon) {
                                                WindowManager.monitorManager.setMonitorPosition(mon.name, mon.x, value)
                                            }
                                        }
                                    }
                                }
                                
                                Item { Layout.fillHeight: true }
                            }
                            
                            // Placeholder when no monitor selected
                            Text {
                                anchors.centerIn: parent
                                visible: !parent.parent.parent.parent.currentMonitor
                                text: "Select a monitor\nto configure"
                                color: Theme.uiTextColor
                                opacity: 0.5
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    // Bottom buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "⚠ Changes require clicking 'Apply Configuration'"
                            color: Theme.uiTextColor
                            font.pixelSize: 11
                            opacity: 0.8
                        }

                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: "Identify Displays"
                            onClicked: {
                                identifyTimer.start()
                            }
                            
                            background: Rectangle {
                                color: parent.down ? Theme.uiHighlightColor : Theme.uiSecondaryColor
                                border.color: Theme.uiHighlightColor
                                border.width: 1
                                radius: 4
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: Theme.uiTextColor
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Button {
                            text: "Refresh"
                            onClicked: {
                                if (WindowManager.monitorManager) {
                                    WindowManager.monitorManager.updateMonitors()
                                }
                            }

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
                            }
                        }

                        Button {
                            text: "Apply Configuration"
                            highlighted: true

                            background: Rectangle {
                                color: parent.down ? "#2a7d2e" : "#4CAF50"
                                border.color: "#2a7d2e"
                                border.width: 2
                                radius: 4
                            }

                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.bold: true
                            }

                            onClicked: {
                                if (WindowManager.monitorManager) {
                                    var success = WindowManager.monitorManager.applyConfiguration()
                                    if (success) {
                                        console.log("Monitor configuration applied successfully")
                                    } else {
                                        console.log("Failed to apply monitor configuration")
                                    }
                                }
                            }
                        }

                        Button {
                            text: "Close"
                            onClicked: showControlCenter = false

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
                            }
                        }
                    }
                }
            }

            // Appearance Tab (placeholder)
            Rectangle {
                color: Theme.uiPrimaryColor

                Text {
                    anchors.centerIn: parent
                    text: "Appearance settings will be moved here\nfrom the Editor Settings tab"
                    color: Theme.uiTextColor
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // System Tab (placeholder)
            Rectangle {
                color: Theme.uiPrimaryColor

                Text {
                    anchors.centerIn: parent
                    text: "System settings\n(Keyboard, Mouse, Icons, Cursors, etc.)\nComing soon..."
                    color: Theme.uiTextColor
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    // Identify Overlay
    Timer {
        id: identifyTimer
        interval: 3000
        repeat: false
    }
    
    Instantiator {
        model: identifyTimer.running && WindowManager.monitorManager ? WindowManager.monitorManager.monitors : []
        
        delegate: Window {
            x: modelData.x
            y: modelData.y
            width: modelData.width
            height: modelData.height
            flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
            color: "transparent"
            visible: true
            
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: 0.7
                border.color: Theme.uiHighlightColor
                border.width: 10
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 20
                    
                    Text {
                        text: modelData.name
                        color: "white"
                        font.pixelSize: 100
                        font.bold: true
                        style: Text.Outline
                        styleColor: "black"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Text {
                        text: modelData.width + "x" + modelData.height
                        color: "white"
                        font.pixelSize: 60
                        style: Text.Outline
                        styleColor: "black"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Text {
                        text: modelData.primary ? "PRIMARY" : ""
                        color: Theme.uiHighlightColor
                        font.pixelSize: 60
                        font.bold: true
                        style: Text.Outline
                        styleColor: "black"
                        visible: modelData.primary
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    // Note: Docking is now handled automatically by EditableComponent and PanelComponent
    // No need for a separate handleDocking function

    function saveDesktopLayout() {
        var components = []

        // Iterate through all desktop components (non-docked ones)
        for (var i = 0; i < desktopContainer.children.length; i++) {
            var child = desktopContainer.children[i]

            // Check if it's an EditableComponent and not docked
            if (child && child.componentType && !child.isDocked) {
                var comp = {
                    type: child.componentType,
                    x: child.x,
                    y: child.y,
                    width: child.width,
                    height: child.height
                }

                // Include any custom properties from componentData
                if (child.componentData && child.componentData.props) {
                    comp.props = child.componentData.props
                }

                // If this is a Panel, save its docked components
                if (child.componentType === "Panel") {
                    console.log("Saving Panel with docked components...")
                    if (child.loadedItem && child.loadedItem.getDockedComponents) {
                        var dockedComps = child.loadedItem.getDockedComponents()
                        console.log("Panel has", dockedComps.length, "docked components")
                        if (dockedComps.length > 0) {
                            comp.dockedComponents = []
                            for (var j = 0; j < dockedComps.length; j++) {
                                var dockedChild = dockedComps[j]
                                console.log("  - Saving docked:", dockedChild.componentType)
                                comp.dockedComponents.push({
                                    type: dockedChild.componentType,
                                    width: dockedChild.width,
                                    height: dockedChild.height,
                                    props: dockedChild.componentData ? dockedChild.componentData.props : {}
                                })
                            }
                        }
                    }
                }

                components.push(comp)
            }
        }

        var layoutData = {
            components: components
        }

        var json = JSON.stringify(layoutData, null, 2)
        if (layoutManager.saveLayout("layout.json", json)) {
            console.log("Layout saved successfully")
        } else {
            console.log("Failed to save layout")
        }
    }

    function loadDesktopLayout() {
        // Clear existing components
        for (var i = desktopContainer.children.length - 1; i >= 0; --i) {
            desktopContainer.children[i].destroy()
        }

        var json = layoutManager.loadLayout("layout.json")
        if (json) {
            console.log("Loading desktop layout")
            try {
                var data = JSON.parse(json)
                if (data.components) {
                    // First pass: create all components on desktop
                    var panels = []
                    for (var i = 0; i < data.components.length; ++i) {
                        var component = createDesktopComponent(data.components[i])

                        // Track panels for second pass
                        if (component && data.components[i].type === "Panel" && data.components[i].dockedComponents) {
                            panels.push({
                                panel: component,
                                dockedData: data.components[i].dockedComponents
                            })
                        }
                    }

                    // Second pass: dock components into panels
                    // Wait a frame for panels to be fully initialized
                    Qt.callLater(function() {
                        for (var i = 0; i < panels.length; i++) {
                            restoreDockedComponents(panels[i].panel, panels[i].dockedData)
                        }
                    })
                }
            } catch (e) {
                console.log("Error loading layout: " + e)
            }
        } else {
            console.log("No layout found, creating default desktop layout")
            createDefaultLayout()
        }
    }

    function createDefaultLayout() {
        console.log("Creating default desktop with panel and basic components")

        // Create a bottom panel
        var panelData = {
            type: "Panel",
            x: desktopContainer.width / 2 - 800,  // Center a 1600px panel
            y: desktopContainer.height - 80,      // Near bottom with margin
            width: 1600,
            height: 64,
            props: {
                edge: "bottom",
                autoHide: false
            },
            dockedComponents: [
                // App Launcher on the left
                {
                    type: "AppLauncher",
                    width: 80,
                    height: 40,
                    props: {}
                },
                // Taskbar in the middle
                {
                    type: "Taskbar",
                    width: 400,
                    height: 40,
                    props: {}
                },
                // Clock on the right
                {
                    type: "Clock",
                    width: 120,
                    height: 40,
                    props: {}
                },
                // Session Manager on the far right
                {
                    type: "SessionManager",
                    width: 100,
                    height: 40,
                    props: {}
                }
            ]
        }

        // Create the panel component
        var panel = createDesktopComponent(panelData)

        // Dock the components to the panel after a short delay
        // to ensure panel is fully initialized
        Qt.callLater(function() {
            if (panel && panelData.dockedComponents) {
                restoreDockedComponents(panel, panelData.dockedComponents)
            }
        })

        console.log("Default layout created")
    }

    function restoreDockedComponents(panelComponent, dockedData) {
        if (!panelComponent || !dockedData) {
            console.log("restoreDockedComponents: missing panel or data")
            return
        }

        console.log("Restoring", dockedData.length, "docked components to panel")

        if (!panelComponent.loadedItem || !panelComponent.loadedItem.dockComponent) {
            console.log("Panel loadedItem not ready")
            return
        }

        var panel = panelComponent.loadedItem

        for (var i = 0; i < dockedData.length; i++) {
            var compData = dockedData[i]
            console.log("  Restoring docked component:", compData.type)

            // Create the component
            var componentQml = 'import QtQuick 2.15; import "."; EditableComponent { ' +
                'width: ' + (compData.width || 40) + '; ' +
                'height: ' + (compData.height || 40) + '; ' +
                'componentType: "' + compData.type + '"; ' +
                'editorOpen: showFloatingEditor; ' +
                'componentData: (' + JSON.stringify(compData) + '); ' +
                'desktopParent: desktopContainer' +
            '}'

            try {
                var newComponent = Qt.createQmlObject(componentQml, desktopContainer, "docked_" + compData.type + "_" + i)

                // Dock it immediately
                if (newComponent) {
                    var success = panel.dockComponent(newComponent)
                    console.log("  Docking result:", success)
                }
            } catch (e) {
                console.log("Error creating docked component " + compData.type + ": " + e)
            }
        }
    }

    function createDesktopComponent(data) {
        // Default sizes for different component types
        var defaults = {
            "Panel": { width: 800, height: 64 },
            "AppLauncher": { width: 80, height: 40 },
            "AppGrid": { width: 300, height: 400 },
            "Taskbar": { width: 400, height: 40 },
            "Clock": { width: 120, height: 40 },
            "WorkspaceSwitcher": { width: 180, height: 40 },
            "FileManager": { width: 300, height: 400 },
            "SessionManager": { width: 150, height: 200 },
            "Button": { width: 100, height: 40 },
            "AtomClock": { width: 150, height: 60 },
            "AtomSysInfo": { width: 150, height: 80 }
        }

        var defaultSize = defaults[data.type] || { width: 100, height: 50 }
        var width = data.width || defaultSize.width
        var height = data.height || defaultSize.height

        // Create component wrapper with loader
        var comp_id = "comp_" + data.type + "_" + Date.now()
        var componentQml = 'import QtQuick 2.15; import "."; EditableComponent { ' +
            'x: ' + data.x + '; ' +
            'y: ' + data.y + '; ' +
            'width: ' + width + '; ' +
            'height: ' + height + '; ' +
            'componentType: "' + data.type + '"; ' +
            'editorOpen: showFloatingEditor; ' +
            'componentData: (' + JSON.stringify(data) + '); ' +
            'desktopParent: desktopContainer' +
        '}'

        try {
            var newComponent = Qt.createQmlObject(componentQml, desktopContainer, "component_" + data.type + "_" + Date.now())
            return newComponent
        } catch (e) {
            console.log("Error creating component " + data.type + ": " + e)
            return null
        }
    }
}
