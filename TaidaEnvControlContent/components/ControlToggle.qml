import QtQuick
import QtQuick.Controls

AbstractButton {
    id: root
    readonly property Theme theme: Theme {}
    implicitWidth: 56
    implicitHeight: 28
    checkable: true
    Accessible.name: qsTr("緊急開關")
    background: Rectangle {
        radius: height / 2
        color: root.checked ? "#48252d" : root.down ? "#323b48" : "#252a34"
        border.color: root.checked ? root.theme.red : root.activeFocus ? root.theme.blue : "#414954"
        border.width: root.checked ? 3 : 1
    }
    contentItem: Item {
        StatusLight {
            x: root.checked ? root.width - width - 5 : 5
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            lightColor: root.checked ? root.theme.red : root.theme.blue
            Behavior on x { NumberAnimation { duration: 140 } }
        }
    }
}
