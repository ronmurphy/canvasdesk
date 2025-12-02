import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CanvasDesk

ApplicationWindow {
    visible: true
    width: Screen.width
    height: Screen.height
    visibility: Window.FullScreen
    flags: Qt.FramelessWindowHint
    title: "CanvasDesk"
    color: "#1a1a1a"

    // LayoutManager instance
    LayoutManager {
        id: layoutManager
    }

    // Selected component for property editing
    property var selectedComponent: null
    
    // Floating editor panel visibility
    property bool showFloatingEditor: false

    // Desktop content area (where layout components are rendered)
    Item {
        id: desktopContainer
        anchors.fill: parent
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
                                        // Add component to desktop at center
                                        var comp = {
                                            type: type,
                                            x: desktopContainer.width / 2 - 150,
                                            y: desktopContainer.height / 2 - 100,
                                            text: name,
                                            icon: model.icon,
                                            exec: ""
                                        }
                                        console.log("Adding component:", type)
                                        createDesktopComponent(comp)
                                    }
                                }
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
                            color: "white"
                            font.bold: true
                        }
                        
                        Label {
                            visible: selectedComponent
                            text: selectedComponent ? "Type: " + selectedComponent.type : ""
                            color: "#aaa"
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

    function saveDesktopLayout() {
        var components = []
        
        // Iterate through all desktop components
        for (var i = 0; i < desktopContainer.children.length; i++) {
            var child = desktopContainer.children[i]
            
            // Check if it's an EditableComponent
            if (child && child.componentType) {
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
                    for (var i = 0; i < data.components.length; ++i) {
                        createDesktopComponent(data.components[i])
                    }
                }
            } catch (e) {
                console.log("Error loading layout: " + e)
            }
        } else {
            console.log("No layout found, starting with empty desktop")
        }
    }

    function createDesktopComponent(data) {
        // Default sizes for different component types
        var defaults = {
            "Panel": { width: 800, height: 48 },
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
        var componentQml = 'import QtQuick 2.15; import "."; EditableComponent { ' +
            'x: ' + data.x + '; ' +
            'y: ' + data.y + '; ' +
            'width: ' + width + '; ' +
            'height: ' + height + '; ' +
            'componentType: "' + data.type + '"; ' +
            'editorOpen: showFloatingEditor; ' +
            'componentData: (' + JSON.stringify(data) + ') ' +
        '}'

        try {
            Qt.createQmlObject(componentQml, desktopContainer, "component_" + data.type)
        } catch (e) {
            console.log("Error creating component " + data.type + ": " + e)
        }
    }
}
