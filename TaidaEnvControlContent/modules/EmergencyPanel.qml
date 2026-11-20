import QtQuick
import "../components"

Panel {
    id: root
    property alias engaged: toggle.checked
    signal emergencyRequested(bool engaged)
    implicitHeight: 75
    border.color: root.engaged ? "transparent" : "#414954"
    border.width: root.engaged ? 3 : 1
    BreathingBorder {
        anchors.fill: parent
        active: root.engaged
        borderColor: root.theme.red
        cornerRadius: root.radius
    }
    StatusLight {
        x: 25
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        square: true
        lightColor: root.theme.red
    }
    Row {
        x: 57
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Text {
            text: qsTr("緊急開關")
            color: root.theme.red
            font.family: root.theme.fontFamily
            font.pixelSize: 18
            font.bold: true
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "(EMERGENCY SWITCH)"
            color: root.theme.red
            font.family: root.theme.fontFamily
            font.pixelSize: 14
            font.bold: true
            font.letterSpacing: 0.6
        }
    }
    Rectangle {
        anchors.right: toggle.left
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        width: 88
        height: 34
        radius: 3
        color: root.engaged ? "#48252d" : "#2b3643"
        border.color: root.engaged ? root.theme.red : "#40586b"
        border.width: root.engaged ? 3 : 1
        Row {
            anchors.centerIn: parent
            spacing: 4
            StatusLight {
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                lightColor: root.engaged ? root.theme.red : root.theme.blue
            }
            Text {
                text: root.engaged ? qsTr("啟動中") : qsTr("關閉中")
                color: root.engaged ? root.theme.red : root.theme.blue
                font.family: root.theme.fontFamily
                font.pixelSize: root.engaged ? 16 : 14
                font.weight: root.engaged ? Font.Black : Font.Bold
            }
        }
    }
    ControlToggle {
        id: toggle
        anchors.right: parent.right
        anchors.rightMargin: 25
        anchors.verticalCenter: parent.verticalCenter
        onClicked: root.emergencyRequested(checked)
    }
}
