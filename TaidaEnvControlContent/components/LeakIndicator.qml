import QtQuick

Rectangle {
    id: root
    property string label: ""
    property bool alarm: false
    readonly property Theme theme: Theme {}
    implicitHeight: 38
    radius: 4
    color: alarm ? "#282a32" : "#1c212a"
    border.color: alarm ? "#bc8583" : "#282e38"
    Accessible.role: Accessible.StaticText
    Accessible.name: label + (alarm ? qsTr("，可能漏水") : qsTr("，正常"))
    StatusLight {
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        lightColor: root.alarm ? root.theme.red : "#343c46"
        glowing: root.alarm
    }
    Text {
        anchors.left: parent.left
        anchors.leftMargin: 34
        anchors.right: badge.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.alarm ? root.theme.red : root.theme.text
        font.family: root.theme.fontFamily
        font.pixelSize: 14
        font.bold: true
        elide: Text.ElideRight
    }
    Rectangle {
        id: badge
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: root.alarm ? 76 : 45
        height: 24
        radius: 2
        color: root.alarm ? "#a60016" : "#282e38"
        Text {
            anchors.centerIn: parent
            text: root.alarm ? qsTr("可能漏水") : qsTr("正常")
            color: root.alarm ? root.theme.red : root.theme.muted
            font.family: root.theme.fontFamily
            font.pixelSize: 14
            font.bold: true
        }
    }
}
