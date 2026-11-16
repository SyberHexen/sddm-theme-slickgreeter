// The top bar: host name on the left; keyboard layout, clock and the power
// button on the right
import QtQuick

BlurredPanel {
    id: bar

    property real s: 1
    property string fontFamily: "Ubuntu"
    property string clockFormat: "HH:mm"
    property bool showHostname: true
    property bool showClock: true
    property bool showPower: true

    signal powerClicked()

    readonly property color textColor: "#eeeeec"
    readonly property real fontPx: 11 * 96 / 72 * s

    Text {
        visible: bar.showHostname
        anchors.left: parent.left
        anchors.leftMargin: 12 * bar.s
        anchors.verticalCenter: parent.verticalCenter
        text: sddm.hostName
        color: bar.textColor
        font.family: bar.fontFamily
        font.pixelSize: bar.fontPx
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 6 * bar.s
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4 * bar.s
        layoutDirection: Qt.RightToLeft

        // Power
        Rectangle {
            visible: bar.showPower
            width: 32 * bar.s
            height: 24 * bar.s
            radius: 3 * bar.s
            color: powerArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
            Image {
                anchors.centerIn: parent
                source: Qt.resolvedUrl("../assets/shutdown.svg")
                sourceSize.width: 16 * bar.s
                sourceSize.height: 16 * bar.s
            }
            MouseArea {
                id: powerArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: bar.powerClicked()
            }
        }

        // Clock
        Item {
            visible: bar.showClock
            width: clock.implicitWidth + 16 * bar.s
            height: 24 * bar.s
            Text {
                id: clock
                anchors.centerIn: parent
                color: bar.textColor
                font.family: bar.fontFamily
                font.pixelSize: bar.fontPx
                function update() { text = Qt.formatTime(new Date(), bar.clockFormat) }
                Component.onCompleted: update()
            }
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.update()
            }
        }

        // Keyboard layout, when there is more than one; a click cycles them
        Rectangle {
            visible: keyboard.layouts.length > 1
            width: layoutRow.implicitWidth + 12 * bar.s
            height: 24 * bar.s
            radius: 3 * bar.s
            color: layoutArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
            Row {
                id: layoutRow
                anchors.centerIn: parent
                spacing: 6 * bar.s
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    source: Qt.resolvedUrl("../assets/keyboard.svg")
                    sourceSize.height: 16 * bar.s
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: bar.textColor
                    font.family: bar.fontFamily
                    font.pixelSize: bar.fontPx
                    text: keyboard.layouts.length > keyboard.currentLayout
                          ? keyboard.layouts[keyboard.currentLayout].shortName : ""
                }
            }
            MouseArea {
                id: layoutArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: keyboard.currentLayout =
                    (keyboard.currentLayout + 1) % keyboard.layouts.length
            }
        }
    }
}
