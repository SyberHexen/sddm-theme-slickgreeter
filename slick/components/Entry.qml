// A text entry drawn like a GTK 3 Adwaita entry, as Slick Greeter shows
// them, with the placeholder in grey and an arrow (or a spinner while
// logging in) on the right
import QtQuick

Rectangle {
    id: entry

    property real s: 1
    property string fontFamily: "Ubuntu"
    property alias text: input.text
    property alias echoMode: input.echoMode
    property string placeholder: ""
    property bool busy: false

    signal accepted()

    function clear() { input.text = "" }
    function focusInput() { input.forceActiveFocus() }

    implicitHeight: 36 * s
    radius: 5 * s
    color: input.enabled ? "#ffffff" : "#fafafa"
    border.width: Math.max(1, s)
    border.color: input.activeFocus ? "#3584e4" : "#cdc7c2"

    // Adwaita's focus ring
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1 * entry.s
        radius: entry.radius + entry.s
        color: "transparent"
        border.width: entry.s
        border.color: Qt.rgba(0.21, 0.52, 0.89, 0.5)
        visible: input.activeFocus
    }

    TextInput {
        id: input
        anchors.left: parent.left
        anchors.right: indicator.left
        anchors.leftMargin: 8 * entry.s
        anchors.rightMargin: 4 * entry.s
        anchors.verticalCenter: parent.verticalCenter
        color: "#2e3436"
        selectionColor: "#3584e4"
        selectedTextColor: "white"
        font.family: entry.fontFamily
        font.pixelSize: 14 * 96 / 72 * entry.s
        passwordCharacter: "●"
        clip: true
        enabled: !entry.busy
        onAccepted: entry.accepted()
    }

    Text {
        anchors.left: input.left
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text.length === 0
        text: entry.placeholder
        color: "#888888"
        font.family: entry.fontFamily
        font.pixelSize: 13 * 96 / 72 * entry.s
    }

    Item {
        id: indicator
        anchors.right: parent.right
        anchors.rightMargin: 6 * entry.s
        anchors.verticalCenter: parent.verticalCenter
        width: 20 * entry.s
        height: 20 * entry.s

        Image {
            anchors.centerIn: parent
            visible: !entry.busy && input.text.length > 0
            source: Qt.resolvedUrl("../assets/arrow_right.svg")
            sourceSize.width: 14 * entry.s
            sourceSize.height: 20 * entry.s
            MouseArea {
                anchors.fill: parent
                onClicked: entry.accepted()
            }
        }

        // Spinner while logging in
        Item {
            anchors.fill: parent
            visible: entry.busy
            Repeater {
                model: 8
                Rectangle {
                    x: parent.width / 2 - width / 2 + Math.cos(index * Math.PI / 4) * parent.width * 0.35
                    y: parent.height / 2 - height / 2 + Math.sin(index * Math.PI / 4) * parent.height * 0.35
                    width: 3 * entry.s
                    height: 3 * entry.s
                    radius: width / 2
                    color: "#2e3436"
                    opacity: ((index - spin.step + 8) % 8) / 8 + 0.15
                }
            }
            Timer {
                id: spin
                property int step: 0
                interval: 90
                repeat: true
                running: entry.busy
                onTriggered: step = (step + 1) % 8
            }
        }
    }
}
