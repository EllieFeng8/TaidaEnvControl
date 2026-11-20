import QtQuick
import "../components"

Panel {
    id: root
    property string title: ""
    property real processValue: 0
    property alias setpoint: input.value
    property bool setpointEnabled: true
    property alias proxyValue: input.proxyValue
    signal setpointRequested(real value)
    implicitHeight: 193
    function clearDraft() {
        input.clearDraft()
    }
    function resetSetpoint() {
        input.reset()
    }
    Text {
        x: 24
        y: 24
        text: root.title
        color: root.theme.text
        font.family: root.theme.fontFamily
        font.pixelSize: 18
        font.bold: true
    }
    Rectangle { x: 24; y: 51; width: parent.width - 48; height: 2; color: root.theme.line }
    Text {
        x: 24
        y: 80
        text: qsTr("現在開度 (PV)")
        color: root.theme.muted
        font.family: root.theme.fontFamily
        font.pixelSize: 16
        font.bold: true
    }
    ValueReadout {
        anchors.right: parent.right
        anchors.rightMargin: 24
        y: 68
        value: root.processValue
    }
    Text {
        x: 24
        y: 140
        text: qsTr("設定值 (SV)")
        color: root.theme.muted
        font.family: root.theme.fontFamily
        font.pixelSize: 16
        font.bold: true
    }
    SetpointInput {
        id: input
        enabled: root.setpointEnabled
        anchors.right: parent.right
        anchors.rightMargin: 24
        y: 133
        onSubmitted: value => root.setpointRequested(value)
    }
}
