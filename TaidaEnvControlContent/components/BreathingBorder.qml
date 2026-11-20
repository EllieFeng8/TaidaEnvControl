import QtQuick

Item {
    id: root
    property bool active: false
    property color borderColor: "#ffb0ad"
    property real cornerRadius: 8
    property real borderWidth: 3
    property real intensity: 1
    visible: active
    onActiveChanged: {
        if (!active)
            intensity = 1
    }

    // Animate only the border and its halo, keeping the panel content steady.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: root.cornerRadius + 4
        color: "transparent"
        border.color: root.borderColor
        border.width: 4
        opacity: root.intensity * 0.18
    }
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: "transparent"
        border.color: root.borderColor
        border.width: root.borderWidth
        opacity: root.intensity
    }
    SequentialAnimation {
        running: root.active
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "intensity"; from: 0.35; to: 1; duration: 1000; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "intensity"; from: 1; to: 0.35; duration: 1000; easing.type: Easing.InOutSine }
    }
}
