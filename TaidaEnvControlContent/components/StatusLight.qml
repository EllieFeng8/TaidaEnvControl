pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    property color lightColor: "#78d0ff"
    property bool glowing: true
    property bool square: false
    implicitWidth: 10
    implicitHeight: 10
    Repeater {
        model: root.glowing ? 5 : 0
        Rectangle {
            required property int index
            anchors.centerIn: parent
            width: root.width + (index + 1) * 4
            height: root.height + (index + 1) * 4
            radius: root.square ? 3 : width / 2
            color: root.lightColor
            opacity: 0.025
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: root.square ? 0 : width / 2
        color: root.lightColor
    }
}
