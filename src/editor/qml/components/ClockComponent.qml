import QtQuick
import QtQuick.Controls
import CanvasDesk

Rectangle {
    id: root
    
    // Configurable properties
    property color backgroundColor: "#2a2a2a"
    property color textColor: Theme.uiTextColor
    property int fontSize: 16
    property string fontFamily: "monospace"
    
    // Editor support
    property bool editorOpen: false
    
    color: backgroundColor
    border.color: "#555"
    radius: 4
    
    Text {
        id: clockText
        anchors.centerIn: parent
        color: root.textColor
        font.pixelSize: root.fontSize
        font.family: root.fontFamily
        text: Qt.formatTime(new Date(), "hh:mm:ss")
    }
    
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm:ss")
    }
}
