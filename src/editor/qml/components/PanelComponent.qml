import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    
    // Panel configuration
    property string edge: "bottom"  // top, bottom, left, right
    property bool autoHide: true
    property int thickness: 48
    property color panelColor: "#1a1a1a"
    property color panelBorderColor: "#444"
    
    // Editor support
    property bool editorOpen: false
    
    // Internal state
    property bool revealed: !autoHide
    property bool mouseInside: false
    
    color: panelColor
    border.color: panelBorderColor
    border.width: 1
    
    // Position based on edge
    states: [
        State {
            name: "top"
            when: edge === "top"
            PropertyChanges { target: root; x: 0; y: revealed ? 0 : -thickness; width: parent.width; height: thickness }
        },
        State {
            name: "bottom"
            when: edge === "bottom"
            PropertyChanges { target: root; x: 0; y: revealed ? parent.height - thickness : parent.height; width: parent.width; height: thickness }
        },
        State {
            name: "left"
            when: edge === "left"
            PropertyChanges { target: root; x: revealed ? 0 : -thickness; y: 0; width: thickness; height: parent.height }
        },
        State {
            name: "right"
            when: edge === "right"
            PropertyChanges { target: root; x: revealed ? parent.width - thickness : parent.width; y: 0; width: thickness; height: parent.height }
        }
    ]
    
    transitions: Transition {
        NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutQuad }
    }
    
    // Mouse area for reveal on hover
    MouseArea {
        id: revealArea
        enabled: autoHide && !editorOpen
        hoverEnabled: true
        
        // Extend slightly beyond panel for easier triggering
        anchors.fill: parent
        anchors.margins: -5
        
        onEntered: {
            mouseInside = true
            revealed = true
        }
        
        onExited: {
            mouseInside = false
            revealed = false
        }
    }
    
    // Container for child components
    Loader {
        id: childContainer
        anchors.fill: parent
        anchors.margins: 4
        
        sourceComponent: (edge === "top" || edge === "bottom") ? horizontalLayout : verticalLayout
    }
    
    // Horizontal layout for top/bottom panels
    Component {
        id: horizontalLayout
        Row {
            spacing: 4
            // Children will be added here dynamically
        }
    }
    
    // Vertical layout for left/right panels
    Component {
        id: verticalLayout
        Column {
            spacing: 4
            // Children will be added here dynamically
        }
    }
    
    // Always show panel in editor mode
    onEditorOpenChanged: {
        if (editorOpen) {
            revealed = true
        } else {
            revealed = autoHide ? mouseInside : true
        }
    }
}
