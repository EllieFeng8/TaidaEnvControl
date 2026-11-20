import QtQuick

Window {
    id: appWindow

    width: 1100
    height: 770
    minimumWidth: 660
    minimumHeight: 462

    visible: true
    visibility: Window.FullScreen
    title: qsTr("台達西側治具")

    Shortcut {
        sequence: "F11"
        onActivated: {
            if (appWindow.visibility === Window.FullScreen)
                appWindow.showNormal()
            else
                appWindow.showFullScreen()
        }
    }

    Screen01 {
        id: mainScreen

        anchors.fill: parent
    }

}

