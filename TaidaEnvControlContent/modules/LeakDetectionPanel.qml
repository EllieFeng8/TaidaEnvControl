import QtQuick
import QtQuick.Layouts
import "../components"

Panel {
    id: root
    property bool roomAlarm: false
    property bool pipeAlarm: false
    property bool cabinetAlarm: false
    implicitHeight: 132
    StatusLight { x: 24; y: 31; square: true; glowing: false; lightColor: root.theme.red }
    Text {
        x: 42
        y: 24
        text: qsTr("漏水檢知信號燈 (LEAK DETECTION)")
        color: root.theme.text
        font.family: root.theme.fontFamily
        font.pixelSize: 18
        font.bold: true
        font.letterSpacing: 0.3
    }
    Rectangle { x: 24; y: 52; width: parent.width - 48; height: 2; color: root.theme.line }
    RowLayout {
        x: 24
        y: 69
        width: parent.width - 48
        spacing: 8
        LeakIndicator { Layout.fillWidth: true; Layout.preferredWidth: 1; label: qsTr("漏水檢知 1 (機房)"); alarm: root.roomAlarm }
        LeakIndicator { Layout.fillWidth: true; Layout.preferredWidth: 1; label: qsTr("漏水檢知 2 (管路)"); alarm: root.pipeAlarm }
        LeakIndicator { Layout.fillWidth: true; Layout.preferredWidth: 1; label: qsTr("漏水檢知 3 (閥箱)"); alarm: root.cabinetAlarm }
    }
}
