import QtQuick
import "../components"

Item {
    id: root
    readonly property Theme theme: Theme {}
    implicitHeight: 33
    StatusLight { y: 4; square: true; lightColor: root.theme.blue }
    Text {
        x: 18
        y: -9
        text: qsTr("台達西側治具")
        color: root.theme.blue
        font.family: root.theme.fontFamily
        font.pixelSize: 28
        font.bold: true
    }
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 2
        color: root.theme.line
    }
}
