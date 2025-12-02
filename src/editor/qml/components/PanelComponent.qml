import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
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
    
    // Docked components
    property var dockedComponents: []
    
    // Panel background
    Rectangle {
        id: panelBackground
        anchors.fill: parent
        color: panelColor
        border.color: panelBorderColor
        border.width: 1
        radius: 2
    }
    
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
    
    // Invisible trigger area at screen edge (like macOS Dock)
    MouseArea {
        id: triggerArea
        enabled: autoHide && !editorOpen && !revealed
        hoverEnabled: true
        z: 100
        
        // Position at screen edge
        states: [
            State {
                name: "top"
                when: edge === "top"
                PropertyChanges { target: triggerArea; x: 0; y: 0; width: parent.width; height: 2 }
            },
            State {
                name: "bottom"
                when: edge === "bottom"
                PropertyChanges { target: triggerArea; x: 0; y: parent.height - 2; width: parent.width; height: 2 }
            },
            State {
                name: "left"
                when: edge === "left"
                PropertyChanges { target: triggerArea; x: 0; y: 0; width: 2; height: parent.height }
            },
            State {
                name: "right"
                when: edge === "right"
                PropertyChanges { target: triggerArea; x: parent.width - 2; y: 0; width: 2; height: parent.height }
            }
        ]
        
        onEntered: {
            revealed = true
        }
    }
    
    // Panel mouse area to keep it revealed while mouse is over it
    MouseArea {
        id: panelArea
        anchors.fill: parent
        enabled: autoHide && !editorOpen
        hoverEnabled: true
        propagateComposedEvents: true
        
        onEntered: {
            mouseInside = true
        }
        
        onExited: {
            mouseInside = false
            // Hide after a short delay
            hideTimer.start()
        }
        
        onPressed: mouse.accepted = false
        onReleased: mouse.accepted = false
        onClicked: mouse.accepted = false
    }
    
    // Timer to hide panel when mouse leaves
    Timer {
        id: hideTimer
        interval: 300
        onTriggered: {
            if (!mouseInside && autoHide && !editorOpen) {
                revealed = false
            }
        }
    }
    
    // Container for docked components
    Row {
        id: horizontalContainer
        visible: edge === "top" || edge === "bottom"
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        
        Repeater {
            model: dockedComponents
            delegate: Item {
                width: modelData.width || 40
                height: parent.height
                
                Loader {
                    anchors.centerIn: parent
                    source: "qrc:/qt/qml/CanvasDeskEditor/" + modelData.type + "Component.qml"
                    
                    onLoaded: {
                        // Pass through properties
                        if (modelData.properties) {
                            for (var prop in modelData.properties) {
                                item[prop] = modelData.properties[prop]
                            }
                        }
                    }
                }
            }
        }
    }
    
    Column {
        id: verticalContainer
        visible: edge === "left" || edge === "right"
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        
        Repeater {
            model: dockedComponents
            delegate: Item {
                width: parent.width
                height: modelData.height || 40
                
                Loader {
                    anchors.centerIn: parent
                    source: "qrc:/qt/qml/CanvasDeskEditor/" + modelData.type + "Component.qml"
                    
                    onLoaded: {
                        // Pass through properties
                        if (modelData.properties) {
                            for (var prop in modelData.properties) {
                                item[prop] = modelData.properties[prop]
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Function to dock a component
    function dockComponent(componentType, properties) {
        var newComponent = {
            type: componentType,
            properties: properties || {}
        }
        dockedComponents.push(newComponent)
        dockedComponentsChanged()
    }
    
    // Function to undock a component
    function undockComponent(index) {
        if (index >= 0 && index < dockedComponents.length) {
            dockedComponents.splice(index, 1)
            dockedComponentsChanged()
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
