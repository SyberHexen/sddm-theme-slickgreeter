// A session's badge from Slick Greeter's set: <session>.svg or .png, else
// the unknown one
import QtQuick
import "badges.js" as Badges

Image {
    property string session: ""
    property real s: 1

    function badgeFile(name) {
        if (name !== "") {
            if (Badges.files.indexOf(name + ".svg") >= 0)
                return name + ".svg";
            if (Badges.files.indexOf(name + ".png") >= 0)
                return name + ".png";
        }
        return "unknown.png";
    }

    source: Qt.resolvedUrl("../assets/badges/" + badgeFile(session))
    sourceSize.width: 22 * s
    sourceSize.height: 22 * s
}
