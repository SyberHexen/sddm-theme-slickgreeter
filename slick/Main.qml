// An SDDM theme laid out like Linux Mint's Slick Greeter: the background,
// a blurred top bar, and the users in a column on a 40 px grid, the chosen
// one in a blurred box with the password entry and its session badge.
import QtQuick
import QtQuick.Window
import "components"

Rectangle {
    id: root

    width: 1920
    height: 1080
    color: config.backgroundColor ? config.backgroundColor : "black"

    function cfgBool(v, def) {
        if (v === undefined || v === null || String(v) === "")
            return def;
        return v === true || String(v).toLowerCase() === "true";
    }

    // The monitor this window is on.  Qt can name the wrong one for a login
    // window on Wayland (the first monitor, once it is shown), but SDDM sizes
    // each window to its monitor: the monitor of this size, and if several
    // have it, the one Qt names.
    readonly property var myScreen: {
        var screens = Qt.application.screens;
        var match = null, count = 0;
        for (var i = 0; i < screens.length; i++) {
            if (Math.abs(screens[i].width - width) < 1 &&
                Math.abs(screens[i].height - height) < 1) {
                count++;
                if (match === null || screens[i].name === Screen.name)
                    match = screens[i];
            }
        }
        return match;
    }
    readonly property string myScreenName: myScreen ? myScreen.name : Screen.name
    readonly property real myScreenX: myScreen ? myScreen.virtualX : Screen.virtualX
    readonly property real myScreenY: myScreen ? myScreen.virtualY : Screen.virtualY

    // The login box is on the monitor chosen in the settings (its connector
    // name, as DP-1) if it is connected, else on SDDM's primary screen; the
    // others show the background only
    readonly property string chosenMonitor: {
        var name = String(config.monitor ? config.monitor : "auto");
        if (name === "auto")
            return "";
        var screens = Qt.application.screens;
        for (var i = 0; i < screens.length; i++) {
            if (screens[i].name === name)
                return name;
        }
        return "";
    }
    readonly property bool isPrimary: chosenMonitor !== ""
        ? myScreenName === chosenMonitor
        : (typeof primaryScreen === "undefined" ? true : primaryScreen)

    readonly property real s: {
        var v = String(config.scale ? config.scale : "auto");
        if (v === "auto")
            return height >= 1800 ? 2 : 1;
        var n = parseFloat(v);
        return n > 0 ? n : 1;
    }
    readonly property string fontFamily: config.font ? config.font : "Ubuntu"
    readonly property string contentAlign:
        config.contentAlign ? String(config.contentAlign) : "left"

    // Slick Greeter's grid
    readonly property real grid: 40 * s
    readonly property real border: 4 * s
    readonly property real menubarHeight: 32 * s
    readonly property real boxWidth: 9 * grid - 2 * border
    function gridOffset(size) { return Math.floor((size % grid) / 2) }

    // ---- Background ----------------------------------------------------

    Item {
        id: background
        anchors.fill: parent

        // Around a picture that does not fill the screen (and blurred with it)
        Rectangle {
            anchors.fill: parent
            color: root.color
        }

        Image {
            id: backgroundImage

            readonly property bool stretch:
                root.cfgBool(config.stretchBackgroundAcrossMonitors, true)
            readonly property rect area: {
                var screens = Qt.application.screens;
                if (!stretch || screens.length < 2)
                    return Qt.rect(0, 0, root.width, root.height);
                var x1 = Infinity, y1 = Infinity, x2 = -Infinity, y2 = -Infinity;
                for (var i = 0; i < screens.length; i++) {
                    var sc = screens[i];
                    x1 = Math.min(x1, sc.virtualX);
                    y1 = Math.min(y1, sc.virtualY);
                    x2 = Math.max(x2, sc.virtualX + sc.width);
                    y2 = Math.max(y2, sc.virtualY + sc.height);
                }
                return Qt.rect(x1 - root.myScreenX, y1 - root.myScreenY,
                               x2 - x1, y2 - y1);
            }

            x: area.x
            y: area.y
            width: area.width
            height: area.height
            source: config.background ? config.background : ""
            // As Cinnamon's background settings name them
            fillMode: {
                switch (String(config.backgroundFill ? config.backgroundFill : "zoom")) {
                case "scaled": return Image.PreserveAspectFit;
                case "stretched": return Image.Stretch;
                case "centered": return Image.Pad;
                default: return Image.PreserveAspectCrop;  // zoom
                }
            }
            asynchronous: false
            smooth: true
        }
    }

    // ---- Users ---------------------------------------------------------

    // userModel copied into a list, without hidden users, and with an entry
    // for typing a user name
    property var users: []
    property int current: 0

    Repeater {
        id: userSource
        model: userModel
        delegate: Item {
            visible: false
            property string userName: model.name
            property string realName: model.realName
            property string icon: model.icon ? String(model.icon) : ""
        }
        onItemAdded: rebuildTimer.restart()
        onItemRemoved: rebuildTimer.restart()
    }

    Timer {
        id: rebuildTimer
        interval: 0
        onTriggered: root.rebuildUsers()
    }

    function rebuildUsers() {
        var hidden = String(config.hiddenUsers ? config.hiddenUsers : "")
                         .split(",").map(function (u) { return u.trim() });
        var list = [];
        var listUsers = cfgBool(config.showUserList, true);
        for (var i = 0; listUsers && i < userSource.count; i++) {
            var u = userSource.itemAt(i);
            if (!u || hidden.indexOf(u.userName) >= 0)
                continue;
            var icon = u.icon.replace(/^file:\/\//, "");
            // SDDM's stock face is not shown, as Slick Greeter shows none
            if (icon.indexOf("/sddm/faces/") >= 0)
                icon = "";
            list.push({ name: u.userName,
                        label: u.realName ? u.realName : u.userName,
                        icon: icon, manual: false });
        }
        if (cfgBool(config.showManualLogin, true) || list.length === 0)
            list.push({ name: "", label: qsTr("Login"), icon: "", manual: true });

        var selected = 0;
        for (var j = 0; j < list.length; j++) {
            if (!list[j].manual && list[j].name === userModel.lastUser)
                selected = j;
        }
        users = list;
        select(selected);
    }

    property bool showingSessions: false
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property bool busy: false
    property string message: ""
    // Manual login: the user name was entered, the password is asked
    property string manualName: ""

    function select(i) {
        if (i < 0 || i >= users.length || busy)
            return;
        current = i;
        showingSessions = false;
        message = "";
        manualName = "";
        loginBox.resetEntries();
    }

    function currentUser() { return users.length > current ? users[current] : null }

    function login(password) {
        var u = currentUser();
        if (!u)
            return;
        var name = u.manual ? manualName : u.name;
        if (name === "")
            return;
        busy = true;
        message = "";
        sddm.login(name, password, sessionIndex);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.message = qsTr("Invalid password, please try again");
            loginBox.resetEntries();
        }
        function onLoginSucceeded() {
            root.busy = false;
        }
        function onInformationMessage(text) {
            root.message = text;
        }
    }

    // Sessions, for the badge and the session list
    Repeater {
        id: sessionSource
        model: sessionModel
        delegate: Item {
            visible: false
            property string sessionName: model.name
            property string file: model.file ? String(model.file) : ""
        }
    }

    function sessionBadge(i) {
        var it = sessionSource.count > i ? sessionSource.itemAt(i) : null;
        return it ? it.file.replace(/^.*\//, "").replace(/\.desktop$/, "") : "";
    }

    // ---- Layout --------------------------------------------------------

    Item {
        id: content
        visible: root.isPrimary
        // A window without the login box takes no typing
        enabled: root.isPrimary
        x: 0
        y: root.menubarHeight + root.gridOffset(root.height)
        width: root.width
        height: root.height - root.menubarHeight - 2 * root.gridOffset(root.height)

        // Where the list starts: Slick Greeter has a grid-wide column for its
        // back button before it
        readonly property real listX: {
            var listWidth = 9 * root.grid;
            if (root.contentAlign === "right")
                return root.width - root.gridOffset(root.width) - root.grid - listWidth;
            if (root.contentAlign === "center")
                return (root.width - listWidth - 2 * root.grid) / 2 + 2 * root.grid
                       - root.grid / 2;
            return root.gridOffset(root.width) + root.grid + root.grid;
        }

        // The row the box is in, as Slick Greeter computes it
        readonly property real boxY: {
            var row = Math.floor((root.menubarHeight + height) / root.grid);
            row = Math.floor((row - 3) / 2);
            return row * root.grid - root.menubarHeight;
        }
        readonly property real boxHeight: loginBox.height + 2 * root.border
        readonly property int nAbove: Math.floor(boxY / root.grid)
        readonly property int nBelow:
            Math.floor((height - boxY - boxHeight) / root.grid)

        function rowY(position) {
            if (position < 0)
                return boxY + position * root.grid;
            if (position === 0)
                return boxY;
            return boxY + boxHeight + (position - 1) * root.grid;
        }

        // The other users, above and below the box
        Repeater {
            model: root.users.length

            Item {
                readonly property int position: index - root.current
                visible: position !== 0 && !root.showingSessions && opacity > 0
                x: content.listX + root.border
                y: content.rowY(position)
                width: root.boxWidth
                height: root.grid
                opacity: position < 0 ? 1 + position / (content.nAbove + 1)
                                      : 1 - position / (content.nBelow + 1)

                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Row {
                    x: 12 * root.s + 2 * root.s
                    y: root.border
                    height: root.grid
                    spacing: 6 * root.s
                    Image {
                        visible: source != ""
                        anchors.verticalCenter: parent.verticalCenter
                        source: root.users[index] && root.users[index].icon
                                ? "file://" + root.users[index].icon : ""
                        sourceSize.width: 24 * root.s
                        sourceSize.height: 24 * root.s
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.users[index] ? root.users[index].label : ""
                        color: "white"
                        font.family: root.fontFamily
                        font.pixelSize: 13 * 96 / 72 * root.s
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.select(index)
                }
            }
        }

        // Back from the session list
        Rectangle {
            visible: root.showingSessions
            x: content.listX - root.grid + root.border
            y: (content.height - root.menubarHeight) / 2 - height / 2
            width: root.grid - 2 * root.border
            height: width
            radius: 3 * root.s
            color: backArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
            Image {
                anchors.centerIn: parent
                source: Qt.resolvedUrl("assets/arrow_left.svg")
                sourceSize.width: 14 * root.s
                sourceSize.height: 20 * root.s
            }
            MouseArea {
                id: backArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: { root.showingSessions = false; loginBox.resetEntries() }
            }
        }

        // The box of the chosen user
        BlurredPanel {
            id: loginBox

            source: background
            x: content.listX + root.border
            y: content.boxY + root.border
            width: root.boxWidth
            // Whole grid rows, as Slick Greeter sizes it
            height: Math.ceil((boxContent.implicitHeight + 2 * root.border) / root.grid)
                    * root.grid - 2 * root.border
            radius: 0.3 * root.grid
            tint: Qt.rgba(0.1, 0.1, 0.1, 0.55)
            borderColor: Qt.rgba(0.4, 0.4, 0.4, 0.4)
            borderWidth: Math.max(1, root.s)

            Behavior on height { NumberAnimation { duration: 150 } }

            readonly property var user: root.currentUser()
            readonly property bool askName:
                user !== null && user.manual && root.manualName === ""

            function resetEntries() {
                nameEntry.clear();
                passwordEntry.clear();
                if (askName)
                    nameEntry.focusInput();
                else
                    passwordEntry.focusInput();
            }

            Column {
                id: boxContent
                visible: !root.showingSessions
                x: 12 * root.s
                y: root.border
                width: parent.width - 24 * root.s
                spacing: 3 * root.s

                // Name and session badge
                Item {
                    width: parent.width
                    height: root.grid

                    Row {
                        x: 2 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6 * root.s
                        Image {
                            visible: source != ""
                            anchors.verticalCenter: parent.verticalCenter
                            source: loginBox.user && loginBox.user.icon
                                    ? "file://" + loginBox.user.icon : ""
                            sourceSize.width: 24 * root.s
                            sourceSize.height: 24 * root.s
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: !loginBox.user ? ""
                                  : loginBox.user.manual && root.manualName !== ""
                                    ? root.manualName : loginBox.user.label
                            color: "white"
                            font.family: root.fontFamily
                            font.pixelSize: 13 * 96 / 72 * root.s
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22 * root.s + 12 * root.s
                        height: 22 * root.s + 8 * root.s
                        radius: 3 * root.s
                        color: badgeArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                        Badge {
                            anchors.centerIn: parent
                            session: root.sessionBadge(root.sessionIndex)
                            s: root.s
                        }
                        MouseArea {
                            id: badgeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.showingSessions = true
                        }
                    }
                }

                Entry {
                    id: nameEntry
                    visible: loginBox.askName
                    width: parent.width
                    s: root.s
                    fontFamily: root.fontFamily
                    placeholder: qsTr("Username")
                    onAccepted: {
                        if (text !== "") {
                            root.manualName = text;
                            passwordEntry.focusInput();
                        }
                    }
                }

                Entry {
                    id: passwordEntry
                    visible: !loginBox.askName
                    width: parent.width
                    s: root.s
                    fontFamily: root.fontFamily
                    echoMode: TextInput.Password
                    placeholder: qsTr("Password")
                    busy: root.busy
                    onAccepted: root.login(text)
                }

                Text {
                    visible: root.message !== ""
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: root.message
                    color: "#ffd64d"
                    font.family: root.fontFamily
                    font.bold: true
                    font.pixelSize: 10 * 96 / 72 * root.s
                }
            }

            // Session list, in the box
            Column {
                id: sessionList
                visible: root.showingSessions
                x: 0
                y: root.border
                width: parent.width

                Repeater {
                    model: sessionModel

                    Rectangle {
                        width: sessionList.width
                        height: root.grid
                        color: sessionArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                        Image {
                            visible: index === root.sessionIndex
                            x: 4 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            source: Qt.resolvedUrl("assets/active.png")
                            sourceSize.width: 5 * root.s
                            sourceSize.height: 7 * root.s
                        }
                        Text {
                            x: 14 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.name
                            color: "white"
                            font.family: root.fontFamily
                            font.pixelSize: 13 * 96 / 72 * root.s
                        }
                        Badge {
                            anchors.right: parent.right
                            anchors.rightMargin: 18 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            session: root.sessionBadge(index)
                            s: root.s
                        }
                        MouseArea {
                            id: sessionArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.sessionIndex = index;
                                root.showingSessions = false;
                                loginBox.resetEntries();
                            }
                        }
                    }
                }
            }

            // Session list height instead of the prompt's while it is shown
            states: State {
                when: root.showingSessions
                PropertyChanges {
                    target: loginBox
                    height: Math.max(1, sessionSource.count) * root.grid - 2 * root.border
                }
            }
        }

    }

    // Up and Down choose another user, Escape clears; keys the entries do
    // not use come here
    Keys.enabled: isPrimary
    Keys.onUpPressed: select(current - 1)
    Keys.onDownPressed: select(current + 1)
    Keys.onEscapePressed: {
        if (showingSessions) {
            showingSessions = false;
            loginBox.resetEntries();
        } else {
            select(current);
        }
    }

    Component.onCompleted: {
        rebuildUsers();
        logScreen("loaded");
    }
    onIsPrimaryChanged: logScreen("changed")
    onMyScreenNameChanged: logScreen("moved")

    // Which monitor this window is on and whether it shows the login box,
    // in the greeter's log (journalctl -t sddm-greeter-qt6)
    function logScreen(why) {
        var names = [];
        for (var i = 0; i < Qt.application.screens.length; i++)
            names.push(Qt.application.screens[i].name);
        console.warn("slick: " + why + ": " + width + "x" + height
                     + " monitor of that size=" + myScreenName
                     + " Screen.name=" + Screen.name
                     + " screens=" + names.join(",")
                     + " monitor=" + config.monitor + " chosen=" + chosenMonitor
                     + " primaryScreen=" + (typeof primaryScreen === "undefined" ? "?" : primaryScreen)
                     + " isPrimary=" + isPrimary + " users=" + users.length);
    }

    // ---- Top bar and shutdown dialog -----------------------------------

    TopBar {
        visible: root.isPrimary
        source: background
        x: 0
        y: 0
        width: root.width
        height: root.menubarHeight
        s: root.s
        fontFamily: root.fontFamily
        clockFormat: config.clockFormat ? config.clockFormat : "HH:mm"
        showHostname: root.cfgBool(config.showHostname, true)
        showClock: root.cfgBool(config.showClock, true)
        showPower: root.cfgBool(config.showPower, true)
        onPowerClicked: shutdownDialog.open()
    }

    ShutdownDialog {
        id: shutdownDialog
        anchors.fill: parent
        source: background
        s: root.s
        fontFamily: root.fontFamily
        onClosed: loginBox.resetEntries()
    }
}
