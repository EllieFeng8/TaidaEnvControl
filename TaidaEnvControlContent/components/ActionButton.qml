import QtQuick
import QtQuick.Controls

Button {
    id: root
    readonly property Theme theme: Theme {}
    property color accentColor: theme.blue
    implicitWidth: 90
    implicitHeight: 36
    hoverEnabled: true
    padding: 4
    background: Rectangle {
        radius: 4
        color: root.down ? root.accentColor
                         : root.hovered ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.24)
                                        : "#222831"
        border.color: root.hovered || root.activeFocus || root.down ? root.accentColor
                                                                                : Qt.darker(root.accentColor, 1.7)
        border.width: root.hovered || root.activeFocus || root.down ? 2 : 1
    }
    contentItem: Text {
        text: root.text
        color: root.down ? "#10131b" : root.accentColor
        font.family: root.theme.fontFamily
        font.pixelSize: 14
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
