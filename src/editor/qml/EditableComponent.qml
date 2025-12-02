import QtQuick
import QtQuick.Controls

// Wrapper for desktop components that adds editing capabilities
Item {
    id: root

    property bool editorOpen: false
    property bool selected: false
    property var componentData: null
    property string componentType: ""
    property bool isDocked: false
    property var dockedPanel: null  // Reference to the panel this is docked to
    property bool canDock: false  // Visual feedback during drag

    // Store original parent for undocking
    property var desktopParent: null

    // Expose the loaded component for docking access
    property alias loadedItem: componentLoader.item

    // Notify parent when selection changes
    onSelectedChanged: {
        // Find the DesktopMode parent and notify it
        var current = parent
        while (current && !current.selectComponent) {
            current = current.parent
        }
        
        if (current && current.selectComponent) {
            current.selectComponent(root)
        }
    }

    Component.onCompleted: {
        if (!isDocked) {
            desktopParent = parent
        }
    }

    // Selection border
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: {
            if (canDock) return "#2ecc71"  // Green when over a panel
            return selected ? "#4a90e2" : "transparent"
        }
        border.width: canDock ? 3 : (selected ? 2 : 0)
        z: -1
    }

    // Docked indicator (clickable to undock)
    Rectangle {
        visible: isDocked && editorOpen
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 4
        width: 24
        height: 24
        radius: 12
        color: "#9b59b6"
        border.color: "#8e44ad"
        border.width: 1
        z: 999

        Text {
            anchors.centerIn: parent
            text: "📌"
            font.pixelSize: 12
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: parent.color = "#8e44ad"
            onExited: parent.color = "#9b59b6"

            onClicked: {
                console.log("Undocking", root.componentType, "from panel")
                if (dockedPanel && desktopParent) {
                    dockedPanel.undockComponent(root, desktopParent)

                    // Position at center of desktop after undocking
                    root.x = desktopParent.width / 2 - root.width / 2
                    root.y = desktopParent.height / 2 - root.height / 2
                }
            }
        }

        // Tooltip
        ToolTip {
            visible: parent.children[1].containsMouse
            text: "Click to undock from panel"
            delay: 500
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
                // If docked, undock first
                if (isDocked && dockedPanel) {
                    dockedPanel.undockComponent(root, desktopParent)
                }
                root.destroy()
            }
        }
    }

    // Resize handles (corners when selected and not docked)
    Repeater {
        model: selected && editorOpen && !isDocked ? 4 : 0

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
        enabled: editorOpen && !isDocked
        drag.target: (editorOpen && !isDocked) ? parent : null
        cursorShape: (editorOpen && !isDocked) ? Qt.OpenHandCursor : Qt.ArrowCursor
        z: 100  // Above content to capture events in editor mode
        acceptedButtons: Qt.LeftButton
        
        // Make transparent to mouse when not in editor mode
        visible: editorOpen

        property point dragStartPos
        property var dragStartParent

        onClicked: {
            root.selected = !root.selected
        }

        onPressed: {
            if (editorOpen) {
                cursorShape = Qt.ClosedHandCursor
                dragStartPos = Qt.point(root.x, root.y)
                dragStartParent = root.parent

                // If docked, undock when starting drag
                if (isDocked && dockedPanel) {
                    console.log("Undocking component for drag")
                    dockedPanel.undockComponent(root, desktopParent)

                    // Position at mouse cursor
                    var globalPos = mapToItem(desktopParent, mouseX, mouseY)
                    root.x = globalPos.x - root.width / 2
                    root.y = globalPos.y - root.height / 2
                }
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

        // Don't try to dock to ourselves or if we don't have a desktop parent
        if (!desktopParent || !desktopParent.children) return

        var centerX = root.x + root.width / 2
        var centerY = root.y + root.height / 2

        for (var i = 0; i < desktopParent.children.length; i++) {
            var child = desktopParent.children[i]
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
        if (!desktopParent || !desktopParent.children) return

        var centerX = root.x + root.width / 2
        var centerY = root.y + root.height / 2

        for (var i = 0; i < desktopParent.children.length; i++) {
            var child = desktopParent.children[i]
            if (child === root) continue
            if (child.componentType !== "Panel") continue

            // Check if center is inside panel bounds
            if (centerX >= child.x && centerX <= child.x + child.width &&
                centerY >= child.y && centerY <= child.y + child.height) {

                // Found a panel to dock into
                console.log("Attempting to dock", root.componentType, "into Panel")

                // Access the panel component via loadedItem property
                if (child.loadedItem && child.loadedItem.dockComponent) {
                    var success = child.loadedItem.dockComponent(root)
                    if (success) {
                        console.log("Successfully docked!")
                    } else {
                        console.log("Docking failed")
                    }
                } else {
                    console.log("Panel doesn't have dockComponent function")
                }
                return
            }
        }
    }
}
