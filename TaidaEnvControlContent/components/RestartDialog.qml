import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    readonly property Theme theme: Theme {}
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(380, parent ? parent.width - 32 : 380)
    modal: true
    focus: true
    padding: 24
    closePolicy: Popup.CloseOnEscape
    Overlay.modal: Rectangle { color: "#aa080b12" }
    background: Rectangle {
        color: root.theme.panel
        radius: 8
        border.color: root.theme.yellow
        border.width: 2
    }
    contentItem: ColumnLayout {
        spacing: 22
        Text {
            text: qsTr("確認重啟")
            color: root.theme.yellow
            font.family: root.theme.fontFamily
            font.pixelSize: 22
            font.bold: true
        }
        Text {
            Layout.fillWidth: true
            text: qsTr("是否要重啟設備？")
            color: root.theme.text
            font.family: root.theme.fontFamily
            font.pixelSize: 18
            font.bold: true
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 12
            ActionButton {
                id: cancelButton
                text: qsTr("取消")
                accentColor: root.theme.muted
                onClicked: root.reject()
            }
            ActionButton {
                text: qsTr("確認重啟")
                accentColor: root.theme.yellow
                onClicked: root.accept()
            }
        }
    }
    onOpened: cancelButton.forceActiveFocus()
}
