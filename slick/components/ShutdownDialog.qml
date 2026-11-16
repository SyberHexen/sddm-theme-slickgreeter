// "Goodbye. Would you like to..." with Suspend, Hibernate, Restart and
// Shut Down, over the dimmed screen
import QtQuick

Item {
    id: dialog

    property Item source
    property real s: 1
    property string fontFamily: "Ubuntu"

    visible: false
    focus: visible

    function open() { visible = true; forceActiveFocus() }
    function close() { visible = false; closed() }
    signal closed()

    Keys.onEscapePressed: close()

    // Darkened background; a click outside the dialog closes it
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.25)
        MouseArea {
            anchors.fill: parent
            onClicked: dialog.close()
        }
    }

    BlurredPanel {
        id: box
        source: dialog.source
        anchors.centerIn: parent
        width: content.implicitWidth + 2 * 30 * dialog.s
        height: content.implicitHeight + 2 * 20 * dialog.s
        radius: 4 * dialog.s
        tint: Qt.rgba(0.18, 0.20, 0.21, 0.72)

        MouseArea { anchors.fill: parent }  // Clicks on the dialog stay there

        Column {
            id: content
            anchors.centerIn: parent
            spacing: 20 * dialog.s

            Text {
                text: qsTr("Goodbye. Would you like to...")
                color: "white"
                font.family: dialog.fontFamily
                font.weight: Font.Light
                font.pixelSize: 13 * 96 / 72 * dialog.s
            }

            Row {
                spacing: 20 * dialog.s

                Repeater {
                    model: [
                        { label: qsTr("Suspend"), icon: "suspend", show: sddm.canSuspend,
                          run: function () { sddm.suspend() } },
                        { label: qsTr("Hibernate"), icon: "hibernate", show: sddm.canHibernate,
                          run: function () { sddm.hibernate() } },
                        { label: qsTr("Restart"), icon: "restart", show: sddm.canReboot,
                          run: function () { sddm.reboot() } },
                        { label: qsTr("Shut Down"), icon: "shutdown_dialog", show: sddm.canPowerOff,
                          highlight: "shutdown_highlight",
                          run: function () { sddm.powerOff() } }
                    ]

                    Column {
                        visible: modelData.show
                        spacing: 9 * dialog.s

                        Image {
                            id: icon
                            anchors.horizontalCenter: parent.horizontalCenter
                            sourceSize.width: 168 * dialog.s
                            sourceSize.height: 168 * dialog.s
                            source: Qt.resolvedUrl("../assets/" +
                                    (area.containsMouse || icon.activeFocus
                                     ? (modelData.highlight || modelData.icon + "_highlight")
                                     : modelData.icon) + ".svg")
                            activeFocusOnTab: true
                            Keys.onReturnPressed: { dialog.close(); modelData.run() }
                            Keys.onSpacePressed: { dialog.close(); modelData.run() }
                            MouseArea {
                                id: area
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: { dialog.close(); modelData.run() }
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            color: "white"
                            font.family: dialog.fontFamily
                            font.weight: Font.Light
                            font.pixelSize: 11 * 96 / 72 * dialog.s
                        }
                    }
                }
            }
        }

        Image {
            x: -7 * dialog.s
            y: -7 * dialog.s
            source: Qt.resolvedUrl(closeArea.containsMouse ? "../assets/dialog_close_highlight.svg"
                                                            : "../assets/dialog_close.svg")
            sourceSize.width: 20 * dialog.s
            sourceSize.height: 20 * dialog.s
            MouseArea {
                id: closeArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: dialog.close()
            }
        }
    }
}
