import QtQuick

Row {
    id: root
    property real value: 0
    property string unit: ""
    readonly property Theme theme: Theme {}
    spacing: 5
    Text {
        id: digits
        text: root.value.toFixed(1)
        color: root.theme.blue
        font.family: root.theme.fontFamily
        font.pixelSize: 36
        font.bold: true
    }
    Text {
        anchors.baseline: digits.baseline
        text: root.unit
        color: root.theme.muted
        font.family: root.theme.fontFamily
        font.pixelSize: 23
        font.bold: true
    }
}
