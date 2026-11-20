import QtQuick
import "../components"

Panel {
    id: root
    property string title: ""
    property real temperature: 0
    implicitHeight: 80
    Text {
        x: 24
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: root.theme.text
        font.family: root.theme.fontFamily
        font.pixelSize: 18
        font.bold: true
    }
    ValueReadout {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        value: root.temperature
        unit: "°C"
    }
}
