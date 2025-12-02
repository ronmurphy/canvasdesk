import QtQuick
import QtQuick.Controls
import CanvasDesk

Rectangle {
    id: root
    
    // Configurable properties
    property color buttonColor: "#3a3a3a"
    property color popupColor: "#1a1a1a"
    property string buttonText: "Apps"
    
    // Editor support
    property bool editorOpen: false
    
    // Internal state
    property bool showPopup: false
    
    color: "transparent"
    
    // Launcher button
    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 8
        height: parent.height - 8
        color: buttonColor
        border.color: "#555"
        radius: 4
        
        Text {
            anchors.centerIn: parent
            text: root.buttonText
            color: "white"
            font.pixelSize: 14
        }
        
        MouseArea {
            anchors.fill: parent
            enabled: !root.editorOpen
            onClicked: root.showPopup = !root.showPopup
        }
    }
    
    // App grid popup
    Rectangle {
        id: popup
        visible: showPopup
        width: 400
        height: 500
        color: popupColor
        border.color: "#555"
        border.width: 2
        radius: 6
        z: 1000
        
        // Smart positioning based on screen edges
        property point buttonGlobalPos: root.mapToItem(null, 0, 0)
        property real screenWidth: root.parent ? root.parent.width : 1920
        property real screenHeight: root.parent ? root.parent.height : 1080
        
        // Calculate available space in each direction
        property real spaceAbove: buttonGlobalPos.y
        property real spaceBelow: screenHeight - (buttonGlobalPos.y + root.height)
        property real spaceLeft: buttonGlobalPos.x
        property real spaceRight: screenWidth - (buttonGlobalPos.x + root.width)
        
        // Determine vertical position (above or below)
        property bool showAbove: spaceAbove > spaceBelow && spaceAbove >= height + 8
        
        // Determine horizontal alignment
        property real centerOffset: (width / 2) - (root.width / 2)
        property real leftEdge: buttonGlobalPos.x - centerOffset
        property real rightEdge: leftEdge + width
        
        x: {
            var desiredX = root.x - centerOffset
            
            // Check if popup would go off left edge
            if (leftEdge < 8) {
                desiredX = root.x - (buttonGlobalPos.x - 8)
            }
            // Check if popup would go off right edge
            else if (rightEdge > screenWidth - 8) {
                desiredX = root.x - (rightEdge - screenWidth + 8) - centerOffset
            }
            
            return desiredX
        }
        
        y: {
            if (showAbove) {
                // Position above button
                return root.y - height - 8
            } else {
                // Position below button
                return root.y + root.height + 8
            }
        }
        
        GridView {
            anchors.fill: parent
            anchors.margins: 12
            cellWidth: 80
            cellHeight: 80
            clip: true
            model: AppManager.apps
            
            delegate: Item {
                width: 80
                height: 80
                
                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    
                    Rectangle {
                        width: 48
                        height: 48
                        color: "transparent"
                        
                        Image {
                            anchors.fill: parent
                            source: "image://theme/" + (modelData.icon || "application-x-executable")
                            sourceSize.width: 48
                            sourceSize.height: 48
                            fillMode: Image.PreserveAspectFit
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                AppManager.launch(modelData.exec)
                                root.showPopup = false
                            }
                        }
                    }
                    
                    Text {
                        text: modelData.name
                        width: 70
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 9
                        color: "white"
                    }
                }
            }
        }
        
        // Close button
        Button {
            text: "×"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 4
            width: 30
            height: 30
            onClicked: root.showPopup = false
        }
    }
    
    // Click outside to close
    MouseArea {
        visible: showPopup
        anchors.fill: parent.parent
        z: 999
        onClicked: root.showPopup = false
    }
}
