import QtQuick
import QtQuick.Controls

// Wrapper for desktop components that adds editing capabilities
Item {
    id: root
    
    property bool editorOpen: false
    property bool selected: false
    property var componentData: null
    property string componentType: ""
    property string parentId: ""  // ID of parent panel if docked
    property bool isDocked: parentId !== ""
    property bool canDock: false  // Visual feedback during drag
    
    // Signal for docking
    signal dockRequested(var component, var panel)
    
    // Selection border
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: {
            if (canDock) return "#2ecc71"  // Green when over a panel
            return selected ? "#4a90e2" : "transparent"
        }
        border.width: canDock ? 3 : 2
        z: -1
    }
    
    // Docked indicator
    Rectangle {
        visible: isDocked && editorOpen
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 4
        width: 20
        height: 20
        radius: 10
        color: "#9b59b6"
        border.color: "#8e44ad"
        border.width: 1
        z: 999
        
        Text {
            anchors.centerIn: parent
            text: "📌"
            font.pixelSize: 10
        }
    }
    
    // Component loader
    Loader {
        id: componentLoader
        anchors.fill: parent
        source: componentType ? "components/" + componentType + "Component.qml" : ""
        
        onLoaded: {
            // Pass editorOpen state to component
            if (item) {
                item.editorOpen = Qt.binding(function() { return root.editorOpen })
                
                // Set component properties from data
                if (componentData && componentData.props) {
                    for (var prop in componentData.props) {
                        if (item.hasOwnProperty(prop)) {
                            item[prop] = componentData.props[prop]
                        }
                    }
                }
            }
        }
    }
    
    // Delete button (top-center when selected)
    Rectangle {
        visible: selected && editorOpen
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: -10
        width: 24
        height: 24
        radius: 12
        color: "#e74c3c"
        border.color: "#c0392b"
        border.width: 1
        z: 1000
        
        Text {
            anchors.centerIn: parent
            text: "×"
            color: "white"
            font.pixelSize: 16
            font.bold: true
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.destroy()
                // TODO: Remove from layout data
            }
        }
    }
    
    // Resize handles (corners when selected)
    Repeater {
        model: selected && editorOpen ? 4 : 0
        
        Rectangle {
            property int corner: index
            width: 12
            height: 12
            radius: 6
            color: "#4a90e2"
            border.color: "#2980b9"
            border.width: 1
            z: 1000
            
            x: {
                if (corner === 0 || corner === 3) return -6  // Left
                else return root.width - 6  // Right
            }
            
            y: {
                if (corner === 0 || corner === 1) return -6  // Top
                else return root.height - 6  // Bottom
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: {
                    if (corner === 0 || corner === 2) return Qt.SizeFDiagCursor
                    else return Qt.SizeBDiagCursor
                }
                
                property point startPos
                property size startSize
                
                onPressed: {
                    startPos = Qt.point(mouseX, mouseY)
                    startSize = Qt.size(root.width, root.height)
                }
                
                onPositionChanged: {
                    if (!pressed) return
                    
                    var dx = mouseX - startPos.x
                    var dy = mouseY - startPos.y
                    
                    // Bottom-right corner
                    if (corner === 2) {
                        root.width = Math.max(50, startSize.width + dx)
                        root.height = Math.max(30, startSize.height + dy)
                    }
                    // Top-right corner
                    else if (corner === 1) {
                        var newHeight = Math.max(30, startSize.height - dy)
                        root.y = root.y + (startSize.height - newHeight)
                        root.height = newHeight
                        root.width = Math.max(50, startSize.width + dx)
                    }
                    // Top-left corner
                    else if (corner === 0) {
                        var newWidth = Math.max(50, startSize.width - dx)
                        var newHeight = Math.max(30, startSize.height - dy)
                        root.x = root.x + (startSize.width - newWidth)
                        root.y = root.y + (startSize.height - newHeight)
                        root.width = newWidth
                        root.height = newHeight
                    }
                    // Bottom-left corner
                    else if (corner === 3) {
                        var newWidth = Math.max(50, startSize.width - dx)
                        root.x = root.x + (startSize.width - newWidth)
                        root.width = newWidth
                        root.height = Math.max(30, startSize.height + dy)
                    }
                }
            }
        }
    }
    
    // Drag handle (entire component when editor open)
    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: editorOpen
        drag.target: editorOpen ? parent : null
        cursorShape: editorOpen ? Qt.OpenHandCursor : Qt.ArrowCursor
        
        property point dragStartPos
        
        onClicked: {
            if (editorOpen) {
                root.selected = !root.selected
            }
        }
        
        onPressed: {
            if (editorOpen) {
                cursorShape = Qt.ClosedHandCursor
                dragStartPos = Qt.point(root.x, root.y)
            }
        }
        
        onPositionChanged: {
            if (pressed && editorOpen) {
                // Check if dragging over a panel
                checkDockTarget()
            }
        }
        
        onReleased: {
            if (editorOpen) {
                cursorShape = Qt.OpenHandCursor
                
                // Try to dock if over a panel
                if (canDock) {
                    attemptDock()
                }
                canDock = false
            }
        }
    }
    
    // Check if component is over a panel
    function checkDockTarget() {
        canDock = false
        if (!parent || !parent.children) return
        
        var centerX = root.x + root.width / 2
        var centerY = root.y + root.height / 2
        
        for (var i = 0; i < parent.children.length; i++) {
            var child = parent.children[i]
            if (child === root) continue
            if (child.componentType !== "Panel") continue
            
            // Check if center is inside panel bounds
            if (centerX >= child.x && centerX <= child.x + child.width &&
                centerY >= child.y && centerY <= child.y + child.height) {
                canDock = true
                return
            }
        }
    }
    
    // Attempt to dock into a panel
    function attemptDock() {
        if (!parent || !parent.children) return
        
        var centerX = root.x + root.width / 2
        var centerY = root.y + root.height / 2
        
        for (var i = 0; i < parent.children.length; i++) {
            var child = parent.children[i]
            if (child === root) continue
            if (child.componentType !== "Panel") continue
            
            // Check if center is inside panel bounds
            if (centerX >= child.x && centerX <= child.x + child.width &&
                centerY >= child.y && centerY <= child.y + child.height) {
                // Found a panel to dock into
                dockRequested(root, child)
                return
            }
        }
    }
}
