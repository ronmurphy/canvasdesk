import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CanvasDesk

ApplicationWindow {
    visible: true
    width: 1280
    height: 720
    title: "CanvasDesk Editor"

    // LayoutManager instance
    LayoutManager {
        id: layoutManager
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
                exec: item.exec
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
        RowLayout {
            ToolButton {
                text: "Save"
                onClicked: saveLayout()
            }
            ToolButton {
                text: "Load"
                onClicked: loadLayout()
            }
            ToolButton {
                text: "Run"
                onClicked: layoutManager.runProject("layout.json")
            }
            Item { Layout.fillWidth: true }
            Label {
                text: "CanvasDesk Editor"
                font.bold: true
            }
            Item { Layout.fillWidth: true }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        
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
                                ListElement { type: "Taskbar"; name: "Taskbar"; icon: "view-list-icons" }
                                ListElement { type: "AppGrid"; name: "App Grid"; icon: "view-grid" }
                                ListElement { type: "FileManager"; name: "File Manager"; icon: "system-file-manager" }
                            }
                            delegate: ItemDelegate {
                                width: parent.width
                                text: name
                                icon.name: icon
                                
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
                                width: parent.width
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
                    }
                }

                // Center Panel: Canvas
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                                anchors.fill: parent
                                drag.target: draggableItem
                                
                                onPressAndHold: {
                                    draggableItem.Drag.active = true
                                    draggableItem.Drag.hotSpot.x = mouseX
                                    draggableItem.Drag.hotSpot.y = mouseY
                                    draggableItem.visible = true
                                }
                                onReleased: {
                                    draggableItem.Drag.active = false
                                    draggableItem.visible = false
                                    draggableItem.x = 0
                                    draggableItem.y = 0
                                }
                            }
                            
                            // The item that is actually dragged
                            Rectangle {
                                id: draggableItem
                                width: parent.width
                                height: parent.height
                                color: "#aaccee"
                                opacity: 0.8
                                visible: false
                                Drag.active: dragArea.drag.active
                                Drag.keys: ["component"]
                                Drag.mimeData: { "type": modelData }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                }
                                
                                states: State {
                                    when: dragArea.drag.active
                                    ParentChange { target: draggableItem; parent: overlay }
                                    AnchorChanges { target: draggableItem; anchors.horizontalCenter: undefined; anchors.verticalCenter: undefined }
                                }
                            }
                        }
                    }
                }
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
                color: "white"
                border.color: "#999"
                
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
                                exec: data.properties.exec
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
    }
    
    // Overlay for dragged items to be on top of everything
    Item {
        id: overlay
        anchors.fill: parent
        z: 100
    }
}
