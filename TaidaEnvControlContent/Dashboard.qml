import QtQuick
import QtQuick.Layouts
import "modules"

Item {
    id: root
    property bool embedded: false
    // 所有設備狀態由 TC proxy 提供；此處保留唯讀名稱供畫面使用。
    readonly property real outletValue: TC.outPv
    readonly property real inletValue: TC.inPv
    readonly property real temperature1: TC.temp1
    readonly property real temperature2: TC.temp2
    readonly property real outletSetpoint: TC.outSv
    readonly property real inletSetpoint: TC.inSv
    readonly property bool emergencyEngaged: TC.emergency
    readonly property bool roomLeak: TC.leak1
    readonly property bool pipeLeak: TC.leak2
    readonly property bool cabinetLeak: TC.leak3
    signal emergencyRequested(bool engaged)
    signal resetRequested()
    signal outletSetpointRequested(real value)
    signal inletSetpointRequested(real value)

    // 重置通知同時清除尚未套用的輸入，即使 SV 原本已是零。
    Connections {
        target: TC
        function onResetRequested() {
            outlet.clearDraft()
            inlet.clearDraft()
            root.resetRequested()
        }
    }

    Item {
        width: 1100
        height: 770
        scale: Math.min(root.width / width, root.height / height)
        anchors.centerIn: parent
        ColumnLayout {
            x: 62
            y: root.embedded ? 158 : 78
            width: 976
            spacing: 24
            DashboardHeader { visible: !root.embedded; Layout.fillWidth: true; Layout.bottomMargin: 5 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 24
                EmergencyPanel {
                    id: emergency
                    Layout.fillWidth: true
                    engaged: TC.emergency
                    onEmergencyRequested: engaged => {
                        TC.emergency = engaged
                        root.emergencyRequested(engaged)
                    }
                }
                ResetPanel {
                    Layout.preferredWidth: 204
                    onResetRequested: TC.setReset()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 24
                ValvePanel {
                    id: outlet
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    title: qsTr("出水閥")
                    setpointEnabled: !root.emergencyEngaged
                    processValue: root.outletValue
                    proxyValue: true
                    setpoint: TC.outSv
                    onSetpointRequested: value => {
                        TC.outSv = value
                        root.outletSetpointRequested(value)
                    }
                }
                ValvePanel {
                    id: inlet
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    title: qsTr("入水閥")
                    setpointEnabled: !root.emergencyEngaged
                    processValue: root.inletValue
                    proxyValue: true
                    setpoint: TC.inSv
                    onSetpointRequested: value => {
                        TC.inSv = value
                        root.inletSetpointRequested(value)
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 24
                TemperaturePanel {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    title: qsTr("溫度監控 1")
                    temperature: root.temperature1
                }
                TemperaturePanel {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    title: qsTr("溫度監控 2")
                    temperature: root.temperature2
                }
            }
            LeakDetectionPanel {
                Layout.fillWidth: true
                roomAlarm: TC.leak1
                pipeAlarm: TC.leak2
                cabinetAlarm: TC.leak3
            }
        }
    }
}
