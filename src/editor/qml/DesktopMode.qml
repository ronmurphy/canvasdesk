import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CanvasDesk

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
    color: "#1a1a1a"

    // LayoutManager instance
    LayoutManager {
        id: layoutManager
    }

    // Selected component for property editing
    property var selectedComponent: null
    property bool isManuallyEditing: false
    
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

    // Desktop content area (where layout components are rendered)
    Item {
        id: desktopContainer
        anchors.fill: parent

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
        color: showFloatingEditor ? "#4a90e2" : "#2a2a2a"
        border.color: "#555"
        border.width: 1
        radius: 4
        opacity: 0.8
        
        Text {
            anchors.centerIn: parent
            text: "✎"
            color: "white"
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
        color: "#2a2a2a"
        border.color: "#555"
        border.width: 1
        radius: 6
        opacity: 0.95
        
        // Draggable header
        Rectangle {
            id: panelHeader
            width: parent.width
            height: 40
            color: "#1a1a1a"
            border.color: "#555"
            radius: 6
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                
                Text {
                    text: "CanvasDesk Editor"
                    color: "white"
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
                            ListElement { type: "Panel"; name: "Panel"; icon: "view-list-tree" }
                            ListElement { type: "AppLauncher"; name: "App Launcher"; icon: "application-menu" }
                            ListElement { type: "AppGrid"; name: "App Grid"; icon: "view-grid" }
                            ListElement { type: "Taskbar"; name: "Taskbar"; icon: "view-list-icons" }
                            ListElement { type: "Clock"; name: "Clock"; icon: "clock" }
                            ListElement { type: "WorkspaceSwitcher"; name: "Workspace Switcher"; icon: "view-multiple" }
                            ListElement { type: "FileManager"; name: "File Manager"; icon: "folder" }
                            ListElement { type: "SessionManager"; name: "Session Manager"; icon: "system-shutdown" }
                            ListElement { type: "Button"; name: "Button"; icon: "button" }
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
                                    color: "white"
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
                            color: "#2a2a2a"
                            radius: 4

                            Label {
                                anchors.centerIn: parent
                                text: selectedComponent ? selectedComponent.componentType + " Properties" : "Select a Component"
                                color: "white"
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
                                    color: "#4a90e2"
                                    font.bold: true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: "#333"
                                }

                                // X position
                                RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: "X:"
                                        color: "#ccc"
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
                                        color: "#ccc"
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
                                        color: "#ccc"
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
                                        color: "#ccc"
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
                                        color: "#4a90e2"
                                        font.bold: true
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: "#333"
                                    }

                                    // Edge
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Label {
                                            text: "Edge:"
                                            color: "#ccc"
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
                                            color: "#ccc"
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
                                        color: "#4a90e2"
                                        font.bold: true
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: "#333"
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
                                        color: "#4a90e2"
                                        font.bold: true
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: "#333"
                                    }

                                    // Button Text
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Label {
                                            text: "Button Text:"
                                            color: "#ccc"
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
            "Button": { width: 100, height: 40 }
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
