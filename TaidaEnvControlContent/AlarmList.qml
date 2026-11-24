import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "modules"

Item {
    id: root
    readonly property Theme theme: Theme {}
    readonly property int alarmCount: TC.activeAlarmCount

    ColumnLayout {
        x: 62
        y: 158
        width: 976
        height: 568
        spacing: 24
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: qsTr("異常列表")
                color: root.theme.text
                font.family: root.theme.fontFamily
                font.pixelSize: 26
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.alarmCount > 0 ? qsTr("目前 %1 項異常").arg(root.alarmCount) : qsTr("設備狀態正常")
                color: root.alarmCount > 0 ? root.theme.red : root.theme.blue
                font.family: root.theme.fontFamily
                font.pixelSize: 16
            }
        }
        Panel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 0
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    spacing: 16
                    Repeater {
                        model: [qsTr("發生時間"), qsTr("解除時間"), qsTr("異常來源"), qsTr("異常說明"), qsTr("目前狀態")]
                        Text {
                            required property int index
                            required property string modelData
                            Layout.preferredWidth: index < 2 ? 168 : index === 2 ? 90 : index === 4 ? 80 : 0
                            Layout.fillWidth: index === 3
                            text: modelData
                            color: root.theme.subtle
                            font.family: root.theme.fontFamily
                            font.pixelSize: 14
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: root.theme.line }
                ListView {
                    id: alarmView
                    objectName: "alarmHistoryList"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: TC.alarmHistory
                    ScrollBar.vertical: ScrollBar {}
                    delegate: Item {
                        required property var modelData
                        width: alarmView.width
                        height: 80
                        RowLayout {
                            anchors.fill: parent
                            spacing: 16
                            Text {
                                Layout.preferredWidth: 168
                                text: Qt.formatDateTime(modelData.occurredAt, "yyyy/MM/dd HH:mm:ss")
                                color: root.theme.muted
                                font.family: root.theme.fontFamily
                                font.pixelSize: 14
                            }
                            Text {
                                Layout.preferredWidth: 168
                                text: modelData.active ? "—" : Qt.formatDateTime(modelData.clearedAt, "yyyy/MM/dd HH:mm:ss")
                                color: root.theme.muted
                                font.family: root.theme.fontFamily
                                font.pixelSize: 14
                            }
                            Text {
                                Layout.preferredWidth: 90
                                text: modelData.source
                                color: root.theme.text
                                font.family: root.theme.fontFamily
                                font.pixelSize: 16
                                font.bold: true
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.message
                                color: root.theme.text
                                font.family: root.theme.fontFamily
                                font.pixelSize: 16
                                wrapMode: Text.Wrap
                            }
                            Text {
                                Layout.preferredWidth: 80
                                text: modelData.active ? qsTr("異常中") : qsTr("已解除")
                                color: modelData.active ? root.theme.red : root.theme.blue
                                font.family: root.theme.fontFamily
                                font.pixelSize: 15
                                font.bold: true
                            }
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.theme.line }
                    }
                    Column {
                        anchors.centerIn: parent
                        spacing: 14
                        visible: alarmView.count === 0
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("尚無異常紀錄")
                            color: root.theme.blue
                            font.family: root.theme.fontFamily
                            font.pixelSize: 24
                            font.bold: true
                        }
                        Text {
                            text: qsTr("異常發生時將自動記錄，解除後仍保留於列表。")
                            color: root.theme.subtle
                            font.family: root.theme.fontFamily
                            font.pixelSize: 15
                        }
                    }
                }
            }
        }
        Text {
            text: qsTr("保留本次執行期間的異常紀錄，依發生時間由新至舊排列；重新啟動程式後清空。")
            color: root.theme.subtle
            font.family: root.theme.fontFamily
            font.pixelSize: 14
        }
    }
}
