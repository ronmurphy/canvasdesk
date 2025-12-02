import QtQuick

/**
 * PopupPositionHelper - Smart positioning for popups, modals, and overlays
 *
 * Intelligently positions popups considering:
 * - Docked status (if source is in a panel)
 * - Panel position (top, bottom, left, right)
 * - Screen boundaries
 * - Available space in all directions
 *
 * Usage:
 *   PopupPositionHelper {
 *       id: posHelper
 *       sourceItem: myButton
 *       popupWidth: 400
 *       popupHeight: 500
 *   }
 *
 *   Rectangle {
 *       x: posHelper.x
 *       y: posHelper.y
 *   }
 */
QtObject {
    id: helper

    // Input properties
    property Item sourceItem: null           // The button/component triggering the popup
    property real popupWidth: 400           // Popup width
    property real popupHeight: 500          // Popup height
    property real margin: 8                 // Margin from edges/source

    // Output properties (calculated)
    property real x: 0
    property real y: 0
    property string preferredDirection: "below"  // "above", "below", "left", "right"

    // Internal calculations
    property point sourceGlobalPos: Qt.point(0, 0)
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Detect if source is docked in a panel
    property bool isDocked: sourceItem && sourceItem.parent && sourceItem.parent.parent && sourceItem.parent.parent.isDocked
    property var dockedPanel: isDocked && sourceItem.parent.parent.dockedPanel ? sourceItem.parent.parent.dockedPanel : null
    property string panelEdge: "bottom"  // Default if not docked

    // Detect other panels on screen to avoid overlap
    property var bottomPanelBounds: null  // {y, height}
    property var topPanelBounds: null
    property var leftPanelBounds: null
    property var rightPanelBounds: null

    // Space available in each direction (accounting for panels)
    property real spaceAbove: 0
    property real spaceBelow: 0
    property real spaceLeft: 0
    property real spaceRight: 0

    onSourceItemChanged: calculatePosition()
    onPopupWidthChanged: calculatePosition()
    onPopupHeightChanged: calculatePosition()

    function calculatePosition() {
        if (!sourceItem) {
            return
        }

        // Get desktop root (try to find the top-level container)
        var desktop = sourceItem
        while (desktop.parent && desktop.parent.parent) {
            desktop = desktop.parent
        }

        // Map source position to desktop coordinates
        sourceGlobalPos = sourceItem.mapToItem(desktop, 0, 0)
        screenWidth = desktop.width || 1920
        screenHeight = desktop.height || 1080

        // Check if docked and get panel edge
        if (isDocked && dockedPanel && dockedPanel.loadedItem) {
            panelEdge = dockedPanel.loadedItem.edge || "bottom"
        }

        // Detect all panels on desktop to avoid overlap
        detectPanels(desktop)

        // Calculate available space in each direction (accounting for panels)
        calculateAvailableSpace()

        // Determine best position based on panel edge (if docked) or available space
        if (isDocked) {
            positionRelativeToPanelEdge()
        } else {
            positionRelativeToSource()
        }

        // Ensure popup stays within screen bounds
        clampToScreen()
    }

    function detectPanels(desktop) {
        // Reset panel bounds
        bottomPanelBounds = null
        topPanelBounds = null
        leftPanelBounds = null
        rightPanelBounds = null

        if (!desktop || !desktop.children) return

        // Scan desktop children for panels
        for (var i = 0; i < desktop.children.length; i++) {
            var child = desktop.children[i]
            if (child.componentType === "Panel" && child.loadedItem) {
                var panel = child.loadedItem
                var edge = panel.edge || "bottom"

                var panelBounds = {
                    x: child.x,
                    y: child.y,
                    width: child.width,
                    height: child.height
                }

                // Store bounds by edge
                if (edge === "bottom") {
                    bottomPanelBounds = panelBounds
                } else if (edge === "top") {
                    topPanelBounds = panelBounds
                } else if (edge === "left") {
                    leftPanelBounds = panelBounds
                } else if (edge === "right") {
                    rightPanelBounds = panelBounds
                }
            }
        }
    }

    function calculateAvailableSpace() {
        // Calculate raw space
        var rawSpaceAbove = sourceGlobalPos.y
        var rawSpaceBelow = screenHeight - (sourceGlobalPos.y + sourceItem.height)
        var rawSpaceLeft = sourceGlobalPos.x
        var rawSpaceRight = screenWidth - (sourceGlobalPos.x + sourceItem.width)

        // Adjust for panels
        if (topPanelBounds) {
            var topPanelBottom = topPanelBounds.y + topPanelBounds.height
            if (topPanelBottom > 0) {
                rawSpaceAbove = Math.max(0, sourceGlobalPos.y - topPanelBottom)
            }
        }

        if (bottomPanelBounds) {
            var bottomPanelTop = bottomPanelBounds.y
            var sourceBottom = sourceGlobalPos.y + sourceItem.height
            if (bottomPanelTop < screenHeight) {
                rawSpaceBelow = Math.max(0, bottomPanelTop - sourceBottom - margin)
            }
        }

        if (leftPanelBounds) {
            var leftPanelRight = leftPanelBounds.x + leftPanelBounds.width
            if (leftPanelRight > 0) {
                rawSpaceLeft = Math.max(0, sourceGlobalPos.x - leftPanelRight)
            }
        }

        if (rightPanelBounds) {
            var rightPanelLeft = rightPanelBounds.x
            var sourceRight = sourceGlobalPos.x + sourceItem.width
            if (rightPanelLeft < screenWidth) {
                rawSpaceRight = Math.max(0, rightPanelLeft - sourceRight - margin)
            }
        }

        spaceAbove = rawSpaceAbove
        spaceBelow = rawSpaceBelow
        spaceLeft = rawSpaceLeft
        spaceRight = rawSpaceRight
    }

    function positionRelativeToPanelEdge() {
        // For docked items, position away from the panel edge
        var centerX = sourceGlobalPos.x + sourceItem.width / 2
        var centerY = sourceGlobalPos.y + sourceItem.height / 2

        if (panelEdge === "bottom") {
            // Panel at bottom - show popup ABOVE
            preferredDirection = "above"
            x = Math.max(margin, Math.min(screenWidth - popupWidth - margin, centerX - popupWidth / 2))
            y = sourceGlobalPos.y - popupHeight - margin

        } else if (panelEdge === "top") {
            // Panel at top - show popup BELOW
            preferredDirection = "below"
            x = Math.max(margin, Math.min(screenWidth - popupWidth - margin, centerX - popupWidth / 2))
            y = sourceGlobalPos.y + sourceItem.height + margin

        } else if (panelEdge === "left") {
            // Panel at left - show popup RIGHT
            preferredDirection = "right"
            x = sourceGlobalPos.x + sourceItem.width + margin
            y = Math.max(margin, Math.min(screenHeight - popupHeight - margin, centerY - popupHeight / 2))

        } else if (panelEdge === "right") {
            // Panel at right - show popup LEFT
            preferredDirection = "left"
            x = sourceGlobalPos.x - popupWidth - margin
            y = Math.max(margin, Math.min(screenHeight - popupHeight - margin, centerY - popupHeight / 2))
        }
    }

    function positionRelativeToSource() {
        // For non-docked items, choose best direction based on available space
        var centerX = sourceGlobalPos.x + sourceItem.width / 2
        var centerY = sourceGlobalPos.y + sourceItem.height / 2

        // Prefer below if enough space, otherwise above
        if (spaceBelow >= popupHeight + margin) {
            preferredDirection = "below"
            x = Math.max(margin, Math.min(screenWidth - popupWidth - margin, centerX - popupWidth / 2))
            y = sourceGlobalPos.y + sourceItem.height + margin

        } else if (spaceAbove >= popupHeight + margin) {
            preferredDirection = "above"
            x = Math.max(margin, Math.min(screenWidth - popupWidth - margin, centerX - popupWidth / 2))
            y = sourceGlobalPos.y - popupHeight - margin

        } else if (spaceRight >= popupWidth + margin) {
            preferredDirection = "right"
            x = sourceGlobalPos.x + sourceItem.width + margin
            y = Math.max(margin, Math.min(screenHeight - popupHeight - margin, centerY - popupHeight / 2))

        } else {
            preferredDirection = "left"
            x = sourceGlobalPos.x - popupWidth - margin
            y = Math.max(margin, Math.min(screenHeight - popupHeight - margin, centerY - popupHeight / 2))
        }
    }

    function clampToScreen() {
        // Ensure popup doesn't go off screen edges
        x = Math.max(margin, Math.min(screenWidth - popupWidth - margin, x))

        // Clamp Y considering top panel
        var minY = margin
        if (topPanelBounds) {
            minY = Math.max(minY, topPanelBounds.y + topPanelBounds.height + margin)
        }

        // Clamp Y considering bottom panel
        var maxY = screenHeight - popupHeight - margin
        if (bottomPanelBounds) {
            maxY = Math.min(maxY, bottomPanelBounds.y - popupHeight - margin)
        }

        y = Math.max(minY, Math.min(maxY, y))
    }

    // Helper function to get desktop parent (call from QML)
    function getDesktopParent(item) {
        var current = item
        var iterations = 0
        while (current.parent && iterations < 20) {
            // Look for desktop container or root
            if (current.objectName === "desktopContainer" || !current.parent.parent) {
                return current
            }
            current = current.parent
            iterations++
        }
        return current
    }
}
