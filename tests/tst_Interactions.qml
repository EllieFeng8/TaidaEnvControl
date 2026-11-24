import QtQuick
import QtQuick.Controls
import QtTest
import "../TaidaEnvControlContent"
import "../TaidaEnvControlContent/components"
import "../TaidaEnvControlContent/modules"

Item {
    width: 1100
    height: 770
    SetpointInput { id: input; x: 30; y: 30; value: 70.0 }
    ResetPanel { id: reset; x: 30; y: 100; width: 204 }
    EmergencyPanel { id: emergency; x: 30; y: 220; width: 748 }
    SignalSpy { id: resetSpy; target: reset; signalName: "resetRequested" }
    SignalSpy { id: submitSpy; target: input; signalName: "submitted" }
    SignalSpy { id: emergencySpy; target: emergency; signalName: "emergencyRequested" }
    SignalSpy { id: svSpy; target: TC; signalName: "outSvChanged" }
    SignalSpy { id: proxyResetSpy; target: TC; signalName: "resetRequested" }
    Component { id: dashboardComponent; Dashboard { width: 1100; height: 770; z: 10 } }
    Component { id: mainPageComponent; MainPage { width: 1100; height: 770; z: 10 } }
    SignalSpy { id: alarmsSpy; target: TC; signalName: "activeAlarmsChanged" }
    SignalSpy { id: marqueeSpy; target: TC; signalName: "alarmMarqueeEnabledChanged" }

    TestCase {
        name: "DashboardInteractions"
        when: windowShown
        property int historyBaseline: 0

        function init() {
            TC.outPv = 0
            TC.inPv = 0
            TC.temp1 = 0
            TC.temp2 = 0
            TC.emergency = false
            TC.leak1 = false
            TC.leak2 = false
            TC.leak3 = false
            TC.alarmMarqueeEnabled = true
            TC.setReset()
            svSpy.clear()
            proxyResetSpy.clear()
            alarmsSpy.clear()
            marqueeSpy.clear()
            historyBaseline = TC.alarmHistory.length
        }

        function test_activeAlarmLifecycle() {
            compare(TC.activeAlarmCount, 0)
            compare(TC.activeAlarms.length, 0)
            TC.leak1 = true
            compare(alarmsSpy.count, 1)
            compare(TC.alarmHistory.length, historyBaseline + 1)
            verify(TC.alarmHistory[0].active)
            verify(isNaN(TC.alarmHistory[0].clearedAt.getTime()))
            compare(TC.activeAlarmCount, 1)
            compare(TC.activeAlarms[0].code, "LEAK_1")
            const firstTime = TC.activeAlarms[0].occurredAt.getTime()
            verify(!isNaN(firstTime))
            TC.leak1 = true
            compare(alarmsSpy.count, 1)
            compare(TC.alarmHistory.length, historyBaseline + 1)
            compare(TC.activeAlarms[0].occurredAt.getTime(), firstTime)
            wait(10)
            TC.emergency = true
            TC.leak2 = true
            TC.leak3 = true
            compare(TC.activeAlarmCount, 4)
            verify(TC.activeAlarms[0].occurredAt.getTime() >= firstTime)
            compare(TC.activeAlarms[3].code, "LEAK_1")
            TC.setReset()
            compare(TC.activeAlarmCount, 4)
            TC.leak1 = false
            compare(TC.activeAlarmCount, 3)
            compare(TC.alarmHistory.length, historyBaseline + 4)
            verify(!TC.alarmHistory[3].active)
            compare(TC.alarmHistory[3].occurredAt.getTime(), firstTime)
            verify(TC.alarmHistory[3].clearedAt.getTime() >= firstTime)
            const clearedTime = TC.alarmHistory[3].clearedAt.getTime()
            TC.leak1 = false
            compare(TC.alarmHistory[3].clearedAt.getTime(), clearedTime)
            for (let i = 0; i < TC.activeAlarms.length; ++i)
                verify(TC.activeAlarms[i].code !== "LEAK_1")
            wait(10)
            TC.leak1 = true
            compare(TC.activeAlarms[0].code, "LEAK_1")
            verify(TC.activeAlarms[0].occurredAt.getTime() > firstTime)
            compare(TC.alarmHistory.length, historyBaseline + 5)
            verify(TC.alarmHistory[0].active)
            verify(!TC.alarmHistory[4].active)
            compare(TC.alarmHistory[4].clearedAt.getTime(), clearedTime)
        }

        function test_alarmPageNavigationAndLiveUpdates() {
            const page = createTemporaryObject(mainPageComponent, parent)
            verify(page !== null)
            compare(page.currentIndex, 0)
            const outletInput = findObject(page, item => typeof item.submit === "function")
            const field = findObject(outletInput, item => typeof item.selectAll === "function")
            field.text = "27.5"
            const tabs = findObject(page, item => item.objectName === "pageNavigation")
            verify(waitForRendering(page))
            const header = findObject(page, item => item.objectName === "pageHeader")
            verify(tabs.y >= header.y + header.height)
            compare(tabs.x, header.x)
            mouseClick(tabs.itemAt(1))
            compare(page.currentIndex, 1)
            const list = findObject(page, item => item.objectName === "alarmHistoryList")
            tryCompare(list, "count", historyBaseline)
            TC.leak2 = true
            tryCompare(list, "count", historyBaseline + 1)
            compare(tabs.itemAt(1).text, "異常列表 (1)")
            tryVerify(function() { return list.itemAtIndex(0) !== null })
            verify(findObject(list.itemAtIndex(0), item => item.text === "偵測到管路漏水") !== null)
            TC.leak2 = false
            tryCompare(list, "count", historyBaseline + 1)
            compare(tabs.itemAt(1).text, "異常列表 (0)")
            verify(findObject(list.itemAtIndex(0), item => item.text === "已解除") !== null)
            mouseClick(tabs.itemAt(0))
            compare(page.currentIndex, 0)
            compare(field.text, "27.5")
            TC.leak3 = true
            compare(tabs.itemAt(1).text, "異常列表 (1)")
            mouseClick(tabs.itemAt(1))
            tryCompare(list, "count", historyBaseline + 2)
        }

        function test_alarmMarqueeControlAndContent() {
            const page = createTemporaryObject(mainPageComponent, parent)
            const marquee = findObject(page, item => item.objectName === "alarmMarquee")
            const text = findObject(page, item => item.objectName === "alarmMarqueeText")
            const tabs = findObject(page, item => item.objectName === "pageNavigation")
            verify(!marquee.visible)
            verify(marquee.x > tabs.x + tabs.width)
            TC.leak1 = true
            verify(marquee.visible)
            compare(marquee.text, "偵測到機房漏水")
            verify(waitForRendering(page))
            const startX = text.x
            tryVerify(function() { return text.x < startX - 5 }, 1500)
            TC.leak2 = true
            verify(marquee.text.includes("偵測到機房漏水"))
            verify(marquee.text.includes("偵測到管路漏水"))
            TC.alarmMarqueeEnabled = false
            verify(!marquee.visible)
            compare(marqueeSpy.count, 1)
            TC.alarmMarqueeEnabled = false
            compare(marqueeSpy.count, 1)
            const historyCount = TC.alarmHistory.length
            compare(TC.activeAlarmCount, 2)
            TC.leak1 = false
            compare(marquee.text, "偵測到管路漏水")
            TC.alarmMarqueeEnabled = true
            verify(marquee.visible)
            page.currentIndex = 1
            verify(marquee.visible)
            compare(TC.alarmHistory.length, historyCount)
            TC.leak2 = false
            verify(!marquee.visible)
            compare(marquee.text, "")
            compare(TC.alarmHistory.length, historyCount)
        }

        function test_proxyValidationAndNotifications() {
            TC.outSv = 37.5
            compare(svSpy.count, 1)
            TC.outSv = 37.5
            compare(svSpy.count, 1)
            TC.outSv = -1
            TC.outSv = 101
            TC.outSv = NaN
            TC.outSv = Infinity
            compare(TC.outSv, 37.5)
            compare(svSpy.count, 1)
            TC.inSv = 100
            TC.inSv = -1
            compare(TC.inSv, 100)
            TC.inSv = 12.34
            compare(TC.inSv, 12.3)
            TC.temp1 = -12.5
            TC.temp1 = NaN
            compare(TC.temp1, -12.5)
        }

        function test_proxyBindingsRemainAfterInteraction() {
            const dashboard = createTemporaryObject(dashboardComponent, parent)
            const outletInput = findObject(dashboard, item => typeof item.submit === "function")
            const field = findObject(outletInput, item => typeof item.selectAll === "function")
            field.text = "27.5"
            outletInput.submit()
            compare(TC.outSv, 27.5)
            TC.outSv = 64.2
            compare(outletInput.value, 64.2)
            compare(field.text, "64.2")
            const toggle = findObject(dashboard, item => item.checkable === true)
            mouseClick(toggle)
            verify(TC.emergency)
            TC.emergency = false
            verify(!toggle.checked)
            mouseClick(toggle)
            verify(TC.emergency)
            TC.outPv = 41.2
            TC.inPv = 52.3
            TC.temp1 = 23.4
            TC.temp2 = 34.5
            TC.leak1 = true
            TC.leak2 = true
            TC.leak3 = true
            compare(dashboard.outletValue, 41.2)
            compare(dashboard.inletValue, 52.3)
            compare(dashboard.temperature1, 23.4)
            compare(dashboard.temperature2, 34.5)
            verify(dashboard.roomLeak && dashboard.pipeLeak && dashboard.cabinetLeak)
            TC.setReset()
            TC.setReset()
            compare(proxyResetSpy.count, 2)
            compare(TC.outSv, 0)
            compare(field.text, "0.0")
            verify(TC.leak1 && TC.leak2 && TC.leak3)
            verify(TC.emergency)
            compare(TC.outPv, 41.2)
        }

        function findObject(parent, predicate) {
            const objects = parent.data || parent.children || []
            for (let i = 0; i < objects.length; ++i) {
                if (predicate(objects[i]))
                    return objects[i]
                const match = findObject(objects[i], predicate)
                if (match)
                    return match
            }
            return null
        }

        function test_dashboardDefaultsAndReset() {
            const dashboard = createTemporaryObject(dashboardComponent, parent)
            verify(dashboard !== null)
            compare(dashboard.outletValue, 0)
            compare(dashboard.inletValue, 0)
            compare(dashboard.temperature1, 0)
            compare(dashboard.temperature2, 0)
            compare(dashboard.outletSetpoint, 0)
            compare(dashboard.inletSetpoint, 0)
            const outletInput = findObject(dashboard, item => typeof item.submit === "function")
            const inletInput = findObject(dashboard, item => item !== outletInput && typeof item.submit === "function")
            const outletField = findObject(outletInput, item => typeof item.selectAll === "function")
            const inletField = findObject(inletInput, item => typeof item.selectAll === "function")
            const button = findObject(dashboard, item => item.text === "⟳ RESET" && typeof item.clicked === "function")
            const dialog = findObject(dashboard, item => typeof item.open === "function" && typeof item.accept === "function")
            outletField.text = "37.5"
            outletInput.submit()
            inletField.text = "62.1"
            inletInput.submit()
            mouseClick(button)
            tryCompare(dialog, "opened", true)
            dialog.reject()
            tryCompare(dialog, "visible", false)
            compare(dashboard.outletSetpoint, 37.5)
            compare(dashboard.inletSetpoint, 62.1)
            mouseClick(button)
            tryCompare(dialog, "opened", true)
            const confirm = findObject(dialog.contentItem, item => item.text === "確認重啟" && typeof item.clicked === "function")
            mouseClick(confirm)
            tryCompare(dialog, "visible", false)
            compare(dashboard.outletSetpoint, 0)
            compare(dashboard.inletSetpoint, 0)
            compare(outletField.text, "0.0")
            compare(inletField.text, "0.0")
            // A second reset must also clear drafts when the saved values remain zero.
            outletField.text = "99.9"
            inletField.text = "88.8"
            mouseClick(button)
            tryCompare(dialog, "opened", true)
            mouseClick(confirm)
            tryCompare(dialog, "visible", false)
            compare(outletField.text, "0.0")
            compare(inletField.text, "0.0")
        }

        function test_dashboardEmergencyLock() {
            const dashboard = createTemporaryObject(dashboardComponent, parent)
            verify(dashboard !== null)
            const outletInput = findObject(dashboard, item => typeof item.submit === "function")
            const inletInput = findObject(dashboard, item => item !== outletInput && typeof item.submit === "function")
            const outletField = findObject(outletInput, item => typeof item.selectAll === "function")
            const inletField = findObject(inletInput, item => typeof item.selectAll === "function")
            const outletButton = findObject(outletInput, item => item.text === "SET" && typeof item.clicked === "function")
            const inletButton = findObject(inletInput, item => item.text === "SET" && typeof item.clicked === "function")
            const breathingBorder = findObject(dashboard, item => item.intensity !== undefined && item.borderColor !== undefined)
            verify(breathingBorder !== null)
            verify(!breathingBorder.active)
            TC.outSv = 24.5
            TC.inSv = 36.7
            outletField.forceActiveFocus()
            outletField.text = "99.9"
            TC.emergency = true
            verify(breathingBorder.active)
            verify(breathingBorder.visible)
            verify(!outletInput.enabled)
            verify(!inletInput.enabled)
            verify(!outletField.enabled)
            verify(!inletField.enabled)
            verify(!outletButton.enabled)
            verify(!inletButton.enabled)
            verify(!outletField.activeFocus)
            compare(outletField.text, "24.5")
            mouseClick(outletField, 25, 18)
            keyClick(Qt.Key_9)
            compare(outletField.text, "24.5")
            mouseClick(outletButton)
            mouseClick(inletButton)
            outletInput.submit()
            inletInput.submit()
            compare(dashboard.outletSetpoint, 24.5)
            compare(dashboard.inletSetpoint, 36.7)
            const intensity = breathingBorder.intensity
            tryVerify(function() { return Math.abs(breathingBorder.intensity - intensity) > 0.1 }, 1500)
            TC.emergency = false
            verify(!breathingBorder.visible)
            compare(breathingBorder.intensity, 1)
            verify(outletField.enabled)
            verify(inletField.enabled)
            verify(outletButton.enabled)
            verify(inletButton.enabled)
            mouseClick(inletField, 25, 18)
            tryCompare(inletField, "selectedText", "36.7")
            keyClick(Qt.Key_4)
            keyClick(Qt.Key_2)
            mouseClick(inletButton)
            compare(dashboard.inletSetpoint, 42)
            TC.emergency = true
            verify(breathingBorder.active)
            const restartedIntensity = breathingBorder.intensity
            tryVerify(function() { return Math.abs(breathingBorder.intensity - restartedIntensity) > 0.1 }, 1500)
        }

        function test_setpointFocusAndSubmit() {
            const field = findObject(input, item => typeof item.selectAll === "function")
            const button = findObject(input, item => item.text === "SET" && typeof item.clicked === "function")
            verify(field !== null)
            verify(button !== null)
            field.focus = false
            mouseClick(field, 25, 18)
            tryCompare(field, "selectedText", "70.0")
            keyClick(Qt.Key_5)
            keyClick(Qt.Key_2)
            keyClick(Qt.Key_Period)
            keyClick(Qt.Key_3)
            compare(field.text, "52.3")
            mouseMove(button, 16, 18)
            tryCompare(button, "hovered", true)
            mousePress(button, 16, 18)
            compare(button.down, true)
            mouseRelease(button, 16, 18)
            compare(input.value, 52.3)
            compare(submitSpy.count, 1)
            verify(!field.activeFocus)
            verify(!button.activeFocus)
            compare(field.selectedText, "")
            field.forceActiveFocus(Qt.TabFocusReason)
            tryCompare(field, "selectedText", "52.3")
            keyClick(Qt.Key_Enter)
            verify(!field.activeFocus)
            verify(!button.activeFocus)
        }

        function test_resetConfirmation() {
            const button = findObject(reset, item => item.text === "⟳ RESET" && typeof item.clicked === "function")
            const dialog = findObject(reset, item => typeof item.open === "function" && typeof item.accept === "function")
            verify(button !== null)
            verify(dialog !== null)
            mouseMove(button, 30, 17)
            tryCompare(button, "hovered", true)
            mouseClick(button, 30, 17)
            tryCompare(dialog, "opened", true)
            compare(resetSpy.count, 0)
            const cancel = findObject(dialog.contentItem, item => item.text === "取消" && typeof item.clicked === "function")
            const confirm = findObject(dialog.contentItem, item => item.text === "確認重啟" && typeof item.clicked === "function")
            verify(cancel !== null)
            verify(confirm !== null)
            mouseClick(cancel)
            tryCompare(dialog, "visible", false)
            compare(resetSpy.count, 0)
            mouseClick(button)
            tryCompare(dialog, "opened", true)
            keyClick(Qt.Key_Escape)
            tryCompare(dialog, "visible", false)
            compare(resetSpy.count, 0)
            mouseClick(button)
            tryCompare(dialog, "opened", true)
            mouseClick(confirm)
            tryCompare(dialog, "visible", false)
            compare(resetSpy.count, 1)
        }

        function test_emergencyAppearance() {
            const toggle = findObject(emergency, item => item.checkable === true)
            verify(toggle !== null)
            mouseClick(toggle)
            verify(emergency.engaged)
            compare(emergencySpy.count, 1)
            compare(toggle.background.border.color, toggle.theme.red)
            compare(toggle.background.border.width, 3)
            const status = findObject(emergency, item => item.text === "啟動中")
            verify(status !== null)
            compare(status.font.weight, Font.Black)
            compare(status.parent.parent.border.color, emergency.theme.red)
            compare(status.parent.parent.border.width, 3)
        }
    }
}
