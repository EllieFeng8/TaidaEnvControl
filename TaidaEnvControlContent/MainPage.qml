import QtQuick
import QtQuick.Controls
import "components"
import "modules"

Item {
    id: root
    property alias currentIndex: navigation.currentIndex
    readonly property Theme theme: Theme {}

    Item {
        width: 1100
        height: 770
        scale: Math.min(root.width / width, root.height / height)
        anchors.centerIn: parent

        // 保留首頁實例，切換分頁時不會遺失尚未套用的輸入。
        Dashboard {
            anchors.fill: parent
            embedded: true
            visible: navigation.currentIndex === 0
        }
        AlarmList {
            anchors.fill: parent
            visible: navigation.currentIndex === 1
        }
        DashboardHeader {
            id: pageHeader
            objectName: "pageHeader"
            x: 62
            y: 46
            width: 976
        }
        TabBar {
            id: navigation
            objectName: "pageNavigation"
            x: 62
            y: 94
            width: 340
            height: 40
            spacing: 12
            background: Item {}
            Repeater {
                model: 2
                TabButton {
                    required property int index
                    text: index === 0 ? qsTr("首頁") : qsTr("異常列表") + " (" + TC.activeAlarmCount + ")"
                    height: 40
                    background: Rectangle {
                        radius: 6
                        color: parent.checked ? "#233b4c" : parent.hovered ? "#242c37" : root.theme.panel
                        border.color: parent.checked || parent.activeFocus ? root.theme.blue : root.theme.line
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.checked ? root.theme.blue : root.theme.muted
                        font.family: root.theme.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        Rectangle {
            id: alarmMarquee
            objectName: "alarmMarquee"
            x: navigation.x + navigation.width + 24
            y: navigation.y
            width: pageHeader.x + pageHeader.width - x
            height: navigation.height
            radius: 6
            color: root.theme.panel
            border.color: root.theme.red
            visible: TC.alarmMarqueeEnabled && TC.activeAlarmCount > 0
            // 內容直接沿用 proxy 的目前異常，已解除紀錄不參與輪播。
            readonly property string text: TC.activeAlarms.map(alarm => alarm.message).join("　｜　")
            Accessible.role: Accessible.StaticText
            Accessible.name: text

            Item {
                id: marqueeViewport
                anchors.fill: parent
                anchors.margins: 10
                clip: true
                Text {
                    id: marqueeText
                    objectName: "alarmMarqueeText"
                    anchors.verticalCenter: parent.verticalCenter
                    text: alarmMarquee.text
                    color: root.theme.red
                    font.family: root.theme.fontFamily
                    font.pixelSize: 16
                    font.bold: true
                    onTextChanged: {
                        if (marqueeAnimation.running)
                            marqueeAnimation.restart()
                    }
                    NumberAnimation on x {
                        id: marqueeAnimation
                        from: marqueeViewport.width
                        to: -marqueeText.implicitWidth
                        duration: Math.max(1000, (marqueeViewport.width + marqueeText.implicitWidth) / 65 * 1000)
                        loops: Animation.Infinite
                        running: alarmMarquee.visible && marqueeText.text.length > 0
                    }
                }
            }
        }
    }
}
