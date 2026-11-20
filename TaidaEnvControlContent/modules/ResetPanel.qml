import QtQuick
import "../components"

Panel {
    id: root
    signal resetRequested()
    implicitHeight: 75
    border.color: "#8d6500"
    Row {
        x: 25
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        StatusLight {
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: 8
            lightColor: root.theme.yellow
        }
        Text {
            text: qsTr("重置")
            color: root.theme.yellow
            font.family: root.theme.fontFamily
            font.pixelSize: 18
            font.bold: true
        }
    }
    RestartDialog {
        id: restartDialog
        onAccepted: root.resetRequested()
        onClosed: button.focus = false
    }
    ActionButton {
        id: button
        anchors.right: parent.right
        anchors.rightMargin: 25
        anchors.verticalCenter: parent.verticalCenter
        width: 78
        height: 34
        text: "⟳ RESET"
        accentColor: root.theme.yellow
        Accessible.name: qsTr("重置")
        onClicked: restartDialog.open()
    }
}
