import QtQuick
import QtQuick.Controls

Row {
    id: root
    property real value: 0
    // 接上 proxy 時只送出操作，由外部綁定回填已套用值。
    property bool proxyValue: false
    signal submitted(real value)
    readonly property Theme theme: Theme {}
    spacing: 4
    opacity: enabled ? 1 : 0.4
    onEnabledChanged: {
        if (!enabled) {
            field.text = root.value.toFixed(1)
            field.deselect()
            field.focus = false
            applyButton.focus = false
        }
    }
    onValueChanged: field.text = root.value.toFixed(1)
    function reset() {
        if (!root.proxyValue)
            root.value = 0
        clearDraft()
    }
    function clearDraft() {
        // Clear an unsubmitted edit even when the stored value is already zero.
        field.text = root.value.toFixed(1)
        field.deselect()
        field.focus = false
        applyButton.focus = false
    }
    function submit() {
        if (!root.enabled)
            return
        const number = Number(field.text)
        if (field.acceptableInput && isFinite(number)) {
            if (!root.proxyValue)
                root.value = number
            root.submitted(number)
        }
        field.text = root.value.toFixed(1)
        field.deselect()
        field.focus = false
        applyButton.focus = false
    }
    TextField {
        id: field
        property bool selectOnRelease: false
        width: 112
        height: 36
        text: root.value.toFixed(1)
        color: root.theme.text
        font.family: root.theme.fontFamily
        font.pixelSize: 22
        font.bold: true
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        rightPadding: 8
        selectByMouse: true
        readOnly: !root.enabled
        validator: DoubleValidator { bottom: 0; top: 100; decimals: 1; locale: "C"; notation: DoubleValidator.StandardNotation }
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        Accessible.name: qsTr("閥門設定值，範圍 0 到 100")
        onAccepted: root.submit()
        onActiveFocusChanged: {
            if (activeFocus) {
                selectOnRelease = true
                Qt.callLater(function() {
                    if (field.activeFocus)
                        field.selectAll()
                })
            } else {
                selectOnRelease = false
                deselect()
            }
        }
        onReleased: {
            if (selectOnRelease) {
                selectAll()
                selectOnRelease = false
            }
        }
        background: Rectangle {
            radius: 2
            color: "#30353f"
            border.width: field.activeFocus ? 1 : 0
            border.color: root.theme.blue
        }
    }
    ActionButton {
        id: applyButton
        width: 36
        height: 36
        text: "SET"
        Accessible.name: qsTr("套用設定值")
        onClicked: root.submit()
    }
}
