import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../" // For Theme

Rectangle {
    id: root
    
    property var monitors: []
    property string selectedMonitor: ""
    
    signal monitorSelected(string name)
    signal monitorMoved(string name, int x, int y)
    
    color: Theme.uiTertiaryColor
    border.color: Theme.uiTitleBarLeftColor
    border.width: 1
    clip: true
    
    // Virtual desktop bounds
    property int minX: 0
    property int minY: 0
    property int maxX: 1920
    property int maxY: 1080
    property real scaleFactor: 0.1
    property int offsetX: 0
    property int offsetY: 0
    
    function updateBounds() {
        if (!monitors || monitors.length === 0) return
        
        var x1 = 0, y1 = 0, x2 = 1920, y2 = 1080
        var first = true
        
        for (var i = 0; i < monitors.length; i++) {
            var m = monitors[i]
            if (!m.enabled) continue
            
            if (first) {
                x1 = m.x
                y1 = m.y
                x2 = m.x + m.width
                y2 = m.y + m.height
                first = false
            } else {
                x1 = Math.min(x1, m.x)
                y1 = Math.min(y1, m.y)
                x2 = Math.max(x2, m.x + m.width)
                y2 = Math.max(y2, m.y + m.height)
            }
        }
        
        // Add padding
        var padding = 2000
        minX = x1 - padding
        minY = y1 - padding
        maxX = x2 + padding
        maxY = y2 + padding
        
        var vWidth = maxX - minX
        var vHeight = maxY - minY
        
        var sX = width / vWidth
        var sY = height / vHeight
        scaleFactor = Math.min(sX, sY)
        
        // Center content
        offsetX = (width - vWidth * scaleFactor) / 2
        offsetY = (height - vHeight * scaleFactor) / 2
    }
    
    onWidthChanged: updateBounds()
    onHeightChanged: updateBounds()
    onMonitorsChanged: updateBounds()
    
    // Grid lines
    Repeater {
        model: 20
        Rectangle {
            x: 0
            y: (index * 1000 - root.minY) * root.scaleFactor + root.offsetY
            width: root.width
            height: 1
            color: Theme.uiTitleBarLeftColor
            opacity: 0.3
        }
    }
    
    Repeater {
        model: 20
        Rectangle {
            x: (index * 1000 - root.minX) * root.scaleFactor + root.offsetX
            y: 0
            width: 1
            height: root.height
            color: Theme.uiTitleBarLeftColor
            opacity: 0.3
        }
    }
    
    // Monitors
    Repeater {
        model: root.monitors
        
        Rectangle {
            id: monitorRect
            
            // Calculate position and size
            x: (modelData.x - root.minX) * root.scaleFactor + root.offsetX
            y: (modelData.y - root.minY) * root.scaleFactor + root.offsetY
            width: modelData.width * root.scaleFactor
            height: modelData.height * root.scaleFactor
            
            color: modelData.enabled ? Theme.uiSecondaryColor : "#444444"
            border.color: root.selectedMonitor === modelData.name ? Theme.uiHighlightColor : Theme.uiTitleBarLeftColor
            border.width: root.selectedMonitor === modelData.name ? 3 : 1
            
            opacity: modelData.enabled ? 1.0 : 0.5
            
            // Monitor Label
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                
                Text {
                    text: modelData.name
                    color: Theme.uiTextColor
                    font.bold: true
                    font.pixelSize: Math.max(10, 140 * root.scaleFactor) // Scale font but keep min size
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Text {
                    text: modelData.width + "x" + modelData.height
                    color: Theme.uiTextColor
                    font.pixelSize: Math.max(8, 100 * root.scaleFactor)
                    Layout.alignment: Qt.AlignHCenter
                    visible: modelData.enabled
                }
                
                Rectangle {
                    visible: modelData.primary
                    Layout.alignment: Qt.AlignHCenter
                    width: primaryLabel.width + 8
                    height: primaryLabel.height + 4
                    color: Theme.uiHighlightColor
                    radius: 2
                    
                    Text {
                        id: primaryLabel
                        anchors.centerIn: parent
                        text: "PRIMARY"
                        color: Theme.uiTextColor
                        font.bold: true
                        font.pixelSize: Math.max(8, 80 * root.scaleFactor)
                    }
                }
            }
            
            MouseArea {
                anchors.fill: parent
                drag.target: monitorRect
                drag.axis: Drag.XAndY
                enabled: modelData.enabled // Only drag enabled monitors
                
                onPressed: {
                    root.monitorSelected(modelData.name)
                }
                
                onReleased: {
                    // Snap to 10px grid
                    var rawX = (monitorRect.x - root.offsetX) / root.scaleFactor + root.minX
                    var rawY = (monitorRect.y - root.offsetY) / root.scaleFactor + root.minY
                    
                    var snappedX = Math.round(rawX / 10) * 10
                    var snappedY = Math.round(rawY / 10) * 10
                    
                    root.monitorMoved(modelData.name, snappedX, snappedY)
                    
                    // Force update to snap visually
                    root.updateBounds()
                }
            }
        }
    }
    
    // Center indicator (0,0)
    Rectangle {
        x: (0 - root.minX) * root.scaleFactor + root.offsetX - 5
        y: (0 - root.minY) * root.scaleFactor + root.offsetY - 5
        width: 10
        height: 10
        radius: 5
        color: Theme.uiHighlightColor
        opacity: 0.5
        
        ToolTip.visible: maCenter.containsMouse
        ToolTip.text: "Origin (0,0)"
        
        MouseArea {
            id: maCenter
            anchors.fill: parent
            hoverEnabled: true
        }
    }
}
