import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    // Panel configuration
    property string edge: "bottom"  // top, bottom, left, right
    property bool autoHide: false
    property color panelColor: "#1a1a1a"
    property color panelBorderColor: "#444"
    property int panelRadius: 8
    property real panelOpacity: 0.95

    // Editor support
    property bool editorOpen: false

    // Computed orientation for layout
    readonly property bool isHorizontal: edge === "top" || edge === "bottom"

    // Expose the container for reparenting
    property alias dockedContainer: contentContainer

    color: panelColor
    opacity: panelOpacity
    border.color: panelBorderColor
    border.width: 2
    radius: panelRadius
    clip: false  // Allow child popups to render outside panel bounds

    // Container for docked components
    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: 12

        // Horizontal layout for top/bottom panels
        RowLayout {
            id: horizontalLayout
            visible: isHorizontal
            anchors.fill: parent
            spacing: 8
        }

        // Vertical layout for left/right panels
        ColumnLayout {
            id: verticalLayout
            visible: !isHorizontal
            anchors.fill: parent
            spacing: 8
        }
    }

    // Drop area visual feedback
    DropArea {
        id: dropArea
        anchors.fill: parent
        enabled: editorOpen

        onEntered: (drag) => {
            root.border.color = "#2ecc71"  // Green
            root.border.width = 3
        }

        onExited: {
            root.border.color = panelBorderColor
            root.border.width = 2
        }

        onDropped: (drop) => {
            root.border.color = panelBorderColor
            root.border.width = 2
        }
    }

    // Docking functions - called by EditableComponent
    function dockComponent(component) {
        if (!component) {
            console.log("Panel: Cannot dock null component")
            return false
        }

        console.log("Panel: Docking component type:", component.componentType)
        console.log("Panel: Component current parent:", component.parent)
        console.log("Panel: Component position before dock:", component.x, component.y)

        // Mark component as docked
        component.isDocked = true
        component.dockedPanel = root

        // Reparent to the appropriate layout
        var layout = isHorizontal ? horizontalLayout : verticalLayout
        console.log("Panel: Reparenting to layout (horizontal=" + isHorizontal + ")")

        var oldParent = component.parent
        component.parent = layout

        console.log("Panel: Parent changed from", oldParent, "to", component.parent)
        console.log("Panel: Layout children count:", layout.children.length)

        // Clear any anchors (incompatible with Layouts)
        component.anchors.fill = undefined
        component.anchors.centerIn = undefined

        // Reset position (layout handles it)
        component.x = 0
        component.y = 0

        // Adjust size for panel and set Layout properties
        if (isHorizontal) {
            // In horizontal layout, maintain width but fill height
            component.Layout.preferredWidth = component.width
            component.Layout.fillHeight = true
            component.height = Qt.binding(function() { return root.height - 24 })
            console.log("Panel: Set horizontal layout properties, width =", component.width, "height =", component.height)
        } else {
            // In vertical layout, maintain height but fill width
            component.Layout.preferredHeight = component.height
            component.Layout.fillWidth = true
            component.width = Qt.binding(function() { return root.width - 24 })
            console.log("Panel: Set vertical layout properties, width =", component.width, "height =", component.height)
        }

        console.log("Panel: Docking complete, children count =", getDockedComponents().length)
        return true
    }

    function undockComponent(component, newParent) {
        if (!component) {
            console.log("Panel: Cannot undock null component")
            return false
        }

        console.log("Panel: Undocking component type:", component.componentType)
        console.log("Panel: Returning component to parent:", newParent)

        // Store current size before undocking
        var currentWidth = component.width
        var currentHeight = component.height

        // Mark as not docked
        component.isDocked = false
        component.dockedPanel = null

        // Reparent back to desktop
        component.parent = newParent

        // Reset layout properties
        component.Layout.fillHeight = false
        component.Layout.fillWidth = false
        component.Layout.preferredWidth = -1
        component.Layout.preferredHeight = -1

        // Restore reasonable size (layouts may have changed it)
        component.width = currentWidth
        component.height = currentHeight

        console.log("Panel: Component undocked, new parent:", component.parent)
        console.log("Panel: Remaining children count:", getDockedComponents().length)

        return true
    }

    function getDockedComponents() {
        var components = []
        var layout = isHorizontal ? horizontalLayout : verticalLayout

        for (var i = 0; i < layout.children.length; i++) {
            var child = layout.children[i]
            if (child && child.componentType) {
                components.push(child)
            }
        }

        return components
    }

    // Empty state indicator
    Text {
        anchors.centerIn: parent
        visible: getDockedComponents().length === 0
        text: "Panel (drop components here)"
        color: "#888"
        font.pixelSize: 14
    }

    // Docked items count indicator
    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        visible: getDockedComponents().length > 0
        text: getDockedComponents().length + " items"
        color: "#aaa"
        font.pixelSize: 11
    }
}
