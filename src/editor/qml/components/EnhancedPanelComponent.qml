import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts
// import CanvasDesk // Removing potential conflict

Rectangle {
    id: root

    // Panel configuration
    property string edge: "bottom"  // top, bottom, left, right
    property bool autoHide: false
    property color panelColor: "#1a1a1a"
    property color panelBorderColor: "#444"
    property int panelRadius: 8
    property real panelOpacity: 0.95

    // Enhanced configuration
    property int sectionCount: 3
    property var sectionRatios: [1, 1, 1] // Relative sizing
    property bool centerComponents: false // Center content in sections
    property bool sizeToFit: false // Auto-size panel to content (forces single section, ignores ratios and centering)
    
    // When sizeToFit is enabled, force single section
    readonly property int effectiveSectionCount: sizeToFit ? 1 : sectionCount

    // Editor support
    property bool editorOpen: false

    // Internal state for auto-hide
    property bool revealed: !autoHide || editorOpen
    property bool mouseInside: false

    // Computed orientation for layout
    readonly property bool isHorizontal: edge === "top" || edge === "bottom"

    // Expose the container for reparenting
    property alias dockedContainer: contentContainer

    // --- Strut Integration ---
    function updateStrut() {
        if (typeof WindowManager === "undefined") return;

        if (!visible || (Qt.application.state !== Qt.ApplicationActive && false)) {
             // ...
        }
        
        if (autoHide && !revealed && !mouseInside) {
             WindowManager.setStrut(0,0,0,0)
             return
        }

        var dpr = Screen.devicePixelRatio || 1
        var physH = Math.ceil(height * dpr)
        var physW = Math.ceil(width * dpr)

        if (edge === "top") WindowManager.setStrut(physH, 0, 0, 0)
        else if (edge === "bottom") WindowManager.setStrut(0, physH, 0, 0)
        else if (edge === "left") WindowManager.setStrut(0, 0, physW, 0)
        else if (edge === "right") WindowManager.setStrut(0, 0, 0, physW)
    }

    onYChanged: updateStrut()
    onHeightChanged: updateStrut()
    onWidthChanged: updateStrut()
    onVisibleChanged: updateStrut()
    onEdgeChanged: updateStrut()
    onRevealedChanged: updateStrut()
    Component.onCompleted: updateStrut()
    Component.onDestruction: {
        if (typeof WindowManager !== "undefined") WindowManager.setStrut(0,0,0,0)
    }

    color: panelColor
    opacity: autoHide && !revealed && !editorOpen ? 0.3 : panelOpacity
    border.color: panelBorderColor
    border.width: 2
    radius: panelRadius
    clip: false  // Allow child popups to render outside panel bounds
    
    // Auto-resize panel when sizeToFit is enabled
    width: {
        if (sizeToFit) {
            var layout = isHorizontal ? horizontalLayout : verticalLayout
            return layout.implicitWidth + contentContainer.anchors.margins * 2 + border.width * 2
        }
        return width // Keep existing width binding if any
    }
    
    height: {
        if (sizeToFit) {
            var layout = isHorizontal ? horizontalLayout : verticalLayout
            return layout.implicitHeight + contentContainer.anchors.margins * 2 + border.width * 2
        }
        return height // Keep existing height binding if any
    }

    // Smooth opacity animation for auto-hide
    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    // Always show in editor mode
    onEditorOpenChanged: {
        if (editorOpen) {
            revealed = true
        }
    }

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
            spacing: 4
            
            Repeater {
                id: horizontalRepeater
                model: isHorizontal ? root.effectiveSectionCount : 0
                delegate: sectionDelegate
            }
        }

        // Vertical layout for left/right panels
        ColumnLayout {
            id: verticalLayout
            visible: !isHorizontal
            anchors.fill: parent
            spacing: 4
            
            Repeater {
                id: verticalRepeater
                model: !isHorizontal ? root.effectiveSectionCount : 0
                delegate: sectionDelegate
            }
        }
        
        Component {
            id: sectionDelegate
            Rectangle {
                id: sectionRect
                
                // Layout properties for the SECTION
                Layout.fillWidth: root.sizeToFit ? false : true
                Layout.fillHeight: root.sizeToFit ? false : true
                Layout.preferredWidth: root.sizeToFit ? -1 : (root.isHorizontal ? (root.sectionRatios[index] || 1) : -1)
                Layout.preferredHeight: root.sizeToFit ? -1 : (!root.isHorizontal ? (root.sectionRatios[index] || 1) : -1)
                
                color: "transparent"
                border.color: root.editorOpen ? "#444" : "transparent"
                border.width: 1
                radius: 4
                clip: true
                
                // Inner Layouts for items
                RowLayout {
                    id: sectionRowLayout
                    visible: root.isHorizontal
                    // In sizeToFit mode, fill parent with margins. In centerComponents mode, center. Otherwise fill completely.
                    anchors.fill: root.sizeToFit ? parent : (root.centerComponents ? undefined : parent)
                    anchors.centerIn: (!root.sizeToFit && root.centerComponents) ? parent : undefined
                    anchors.margins: root.sizeToFit ? 4 : 0
                    spacing: 4
                }
                
                ColumnLayout {
                    id: sectionColumnLayout
                    visible: !root.isHorizontal
                    // In sizeToFit mode, fill parent with margins. In centerComponents mode, center. Otherwise fill completely.
                    anchors.fill: root.sizeToFit ? parent : (root.centerComponents ? undefined : parent)
                    anchors.centerIn: (!root.sizeToFit && root.centerComponents) ? parent : undefined
                    anchors.margins: root.sizeToFit ? 4 : 0
                    spacing: 4
                }
                
                property var layout: root.isHorizontal ? sectionRowLayout : sectionColumnLayout
            }
        }
    }

    // Panel hover area for auto-hide
    MouseArea {
        id: panelHoverArea
        anchors.fill: parent
        enabled: autoHide && !editorOpen
        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.NoButton  // Don't capture clicks, just hover

        onEntered: {
            mouseInside = true
            revealed = true
        }

        onExited: {
            mouseInside = false
            hideTimer.restart()
        }
    }

    // Timer to hide panel when mouse leaves
    Timer {
        id: hideTimer
        interval: 500
        onTriggered: {
            if (!mouseInside && autoHide && !editorOpen) {
                revealed = false
            }
        }
    }

    // Trigger area at screen edge (for revealing hidden panel)
    // This is positioned at the parent level to catch edge hovers
    MouseArea {
        id: edgeTrigger
        enabled: autoHide && !revealed && !editorOpen
        hoverEnabled: true
        z: -1  // Below panel

        // Position depends on edge
        x: {
            if (edge === "left") return -5
            if (edge === "right") return root.width
            return 0
        }
        y: {
            if (edge === "top") return -5
            if (edge === "bottom") return root.height
            return 0
        }
        width: isHorizontal ? root.width : 5
        height: isHorizontal ? 5 : root.height

        onEntered: {
            if (autoHide && !editorOpen) {
                revealed = true
            }
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
    function dockComponent(component, targetSectionIndex) {
        if (!component) {
            console.log("Panel: Cannot dock null component")
            return false
        }

        console.log("Panel: Docking component type:", component.componentType)
        
        // Mark component as docked
        component.isDocked = true
        component.dockedPanel = root

        var mainRepeater = isHorizontal ? horizontalRepeater : verticalRepeater
        var targetSection = null

        // If explicit section index provided (e.g. from load), use it
        if (targetSectionIndex !== undefined && targetSectionIndex >= 0 && targetSectionIndex < mainRepeater.count) {
             targetSection = mainRepeater.itemAt(targetSectionIndex)
             console.log("Panel: Using explicit target section index:", targetSectionIndex)
        } else {
            // Find target section based on position
            var panelPos = root.mapFromItem(component.parent, component.x, component.y)
            var componentCenter = Qt.point(panelPos.x + component.width/2, panelPos.y + component.height/2)
            
            console.log("Panel: Component center in panel coords:", componentCenter.x, componentCenter.y)
            
            for (var i = 0; i < mainRepeater.count; i++) {
                var section = mainRepeater.itemAt(i)
                if (!section || !section.width || !section.height) continue
                
                // Map section position to panel coordinates
                var sectionInPanel = contentContainer.mapToItem(root, section.x, section.y)
                var sectionRect = Qt.rect(sectionInPanel.x, sectionInPanel.y, section.width, section.height)
                
                console.log("Panel: Section", i, "rect:", sectionRect.x, sectionRect.y, sectionRect.width, sectionRect.height)
                
                if (componentCenter.x >= sectionRect.x && componentCenter.x <= sectionRect.x + sectionRect.width &&
                    componentCenter.y >= sectionRect.y && componentCenter.y <= sectionRect.y + sectionRect.height) {
                    console.log("Panel: Found target section", i)
                    targetSection = section
                    break
                }
            }
        }
        
        // Default to first section if nothing found
        if (!targetSection) {
            if (mainRepeater.count > 0) {
                targetSection = mainRepeater.itemAt(0)
            }
        }
        
        if (!targetSection || !targetSection.layout) {
            console.log("EnhancedPanel: No valid section found")
            return false
        }

        // Reparent to the section's inner layout
        var layout = targetSection.layout
        console.log("Panel: Reparenting to section layout")

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
            // In horizontal layout, maintain width
            component.Layout.preferredWidth = component.width
            
            // Only bind height to section if NOT in sizeToFit mode
            if (root.sizeToFit) {
                // In sizeToFit mode, keep component's natural height
                component.Layout.fillHeight = false
                component.Layout.preferredHeight = component.height
            } else {
                // In normal mode, fill the section height
                component.Layout.fillHeight = true
                component.height = Qt.binding(function() { return targetSection.height - 8 })
            }
            console.log("Panel: Set horizontal layout properties, width =", component.width, "height =", component.height)
        } else {
            // In vertical layout, maintain height
            component.Layout.preferredHeight = component.height
            
            // Only bind width to section if NOT in sizeToFit mode
            if (root.sizeToFit) {
                // In sizeToFit mode, keep component's natural width
                component.Layout.fillWidth = false
                component.Layout.preferredWidth = component.width
            } else {
                // In normal mode, fill the section width
                component.Layout.fillWidth = true
                component.width = Qt.binding(function() { return targetSection.width - 8 })
            }
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
        var mainRepeater = isHorizontal ? horizontalRepeater : verticalRepeater

        for (var i = 0; i < mainRepeater.count; i++) {
            var section = mainRepeater.itemAt(i)
            // Check if it has the 'layout' property we defined
            if (section && section.layout) {
                var innerLayout = section.layout
                for (var j = 0; j < innerLayout.children.length; j++) {
                    var child = innerLayout.children[j]
                    if (child && child.componentType) {
                        // Return object with item and section index
                        components.push({ item: child, sectionIndex: i })
                    }
                }
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
