import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    
    // Configurable properties
    property color backgroundColor: "#2a2a2a"
    property color buttonColor: "#3a3a3a"
    property bool showLabels: true
    
    // Editor support
    property bool editorOpen: false
    
    color: backgroundColor
    border.color: "#555"
    border.width: 1
    radius: 4
    
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 8
        
        Button {
            text: showLabels ? "🔒 Lock Screen" : "🔒"
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            enabled: !root.editorOpen
            onClicked: {
                // Lock screen command
                Qt.quit()  // For now, just exit
            }
        }
        
        Button {
            text: showLabels ? "🚪 Logout" : "🚪"
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            enabled: !root.editorOpen
            onClicked: {
                // Logout
                Qt.quit()
            }
        }
        
        Button {
            text: showLabels ? "🔄 Reboot" : "🔄"
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            enabled: !root.editorOpen
            onClicked: {
                // Reboot system
                // Would need system integration
                console.log("Reboot requested")
            }
        }
        
        Button {
            text: showLabels ? "⏻ Shutdown" : "⏻"
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            enabled: !root.editorOpen
            onClicked: {
                // Shutdown system
                // Would need system integration
                console.log("Shutdown requested")
            }
        }
    }
}
