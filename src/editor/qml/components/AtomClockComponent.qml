import QtQuick
import QtQuick.Controls
import CanvasDesk

Rectangle {
    id: root
    
    // Configurable properties
    property color textColor: Theme.uiTextColor
    property int fontSize: 24
    property string format: "hh:mm:ss"
    property bool showDate: true
    
    // Editor support
    property bool editorOpen: false
    
    color: "transparent"
    width: timeText.width + 20
    height: timeText.height + (showDate ? dateText.height : 0) + 10
    
    Column {
        anchors.centerIn: parent
        spacing: 2
        
        Text {
            id: timeText
            text: Qt.formatTime(new Date(), root.format)
            color: root.textColor
            font.pixelSize: root.fontSize
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Text {
            id: dateText
            visible: root.showDate
            text: Qt.formatDate(new Date(), "ddd, MMM d")
            color: root.textColor
            font.pixelSize: root.fontSize * 0.5
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
    
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            timeText.text = Qt.formatTime(new Date(), root.format)
            dateText.text = Qt.formatDate(new Date(), "ddd, MMM d")
        }
    }
}
