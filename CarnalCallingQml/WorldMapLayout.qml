import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14
import JoipEngine 1.3
import JOIP.core 1.5
import JOIP.db 1.1
import CarnalCallingQml 1.0
import "MapTypes.js" as MapTypes

Rectangle {
    id: layout
    anchors.fill: parent
    color: "transparent"

    property int spacing: 5

    readonly property bool isMobile: Settings.platform === "Android"
    readonly property int dominantHand: Settings.dominantHand
    readonly property int iconWidth: isMobile ? 32 : 48
    readonly property int iconHeight: isMobile ? 32 : 48
    property bool isLandscape: { return width > height; }

    property Project currentlyLoadedProject: root.currentlyLoadedProject

    PlayerMap {
        id: map
        anchors.fill: parent

        onTravelFinished: {
            eventReceiver.sendEventResponse("mapEvent", nextScene);
        }
    }

    PlayerMediaPlayer {
        id: mediaPlayer

        anchors.fill: parent
        userName: "mediaPlayer"
        mainMediaPlayer: true

        PlayerMetronome {
            id: metronome
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: Math.max(parent.height * Settings.metronomeSizeRel, Settings.metronomeSizeMin)
            userName: "metronome"
        }
    }

    Rectangle {
        id: iconRect
        anchors.top: parent.top
        x: DominantHand.Left === dominantHand ? 0 : parent.width - width

        width: (parent.width - parent.spacing * 2) / 4
        height: parent.height - textBox.height;
        color: "transparent"

        PlayerIcons {
            id: icon
            width: parent.width
            height: parent.height
            iconWidth: layout.iconWidth
            iconHeight: layout.iconHeight

            anchors.right: parent.right
            anchors.bottom: parent.bottom
            userName: "icon"
        }
    }

    Rectangle {
        id: timerRect
        anchors.top: parent.top
        x: DominantHand.Left === dominantHand ? parent.width - width : 0

        width: (parent.width - parent.spacing * 2) / 4
        height: parent.height - textBox.height;
        color: "transparent"

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            width: !isMobile ? parent.width : parent.width
            height: !isMobile ? parent.height / 2 : width
            color: "transparent"

            PlayerTimer {
                id: timer
                anchors.centerIn: parent
                width: Math.min(138, parent.width)
                height: Math.min(138, parent.width)
                userName: "timer"
            }
        }
    }

    CCPlayerNotification {
        id: notificationRect

        y: 48
        x: DominantHand.Left === dominantHand ? parent.spacing * 2 + 48 : parent.width - width - parent.spacing * 2

        width: 48 * 1.75
        height: sceneControl.y - y + 48

        hexWidth: 48
        hexHeight: 48

        userName: "notification"

        onTransitionRequested: {
            //scene
        }
    }

    CCPlayerTextBox {
        id: textBox;

        x: parent.spacing * 2
        y: parent.height - height
        width: parent.width - parent.spacing * 4
        height: parent.height / 3 - parent.spacing / 2
        iconWidth: layout.iconWidth
        iconHeight: layout.iconHeight
        hexWidth: 48
        hexHeight: 48

        userName: "textBox"
        mainTextBox: true
        hideLogAfterInactivity: true

        Behavior on y {
            NumberAnimation { duration: 500; easing.type: Easing.OutBack}
        }

        states: [
            State {
                name: "VISIBLE"
                PropertyChanges { target: textBox; y: parent.height - height; }
            },
            State {
                name: "HIDDEN"
                PropertyChanges { target: textBox; y: parent.height - sceneControl.height + layout.spacing + 2; }
            }
        ]
    }

    CCPlayerControls {
        id: sceneControl

        x: textBox.x
        y: textBox.y - height / 2
        width: textBox.width
        height: 48*1.5

        buttonHeight: 48
        buttonWidth: 48
        spacing: 0

        onSetUiVisible: {
            iconRect.opacity = visible ? 1.0 : 0.0;
            timerRect.opacity = visible ? 1.0 : 0.0;
            notificationRect.opacity = visible ? 1.0 : 0.0;
            textBox.opacity = visible ? 1.0 : 0.0;
        }

        HexButton {
            id: travel
            Layout.preferredHeight: sceneControl.buttonHeight
            Layout.preferredWidth: sceneControl.buttonWidth
            Layout.alignment: Qt.AlignBottom

            enabled: textBox.opacity > 0
            text: Settings.keyBinding("Tools")

            shortcut: Settings.keyBinding("Tools")
            toolTipText: qsTr("Head to location")
            imageSource:
                "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "UnknownSvg";

            onTriggeredButton: {
                map.headToSelected();
            }
        }
    }

    PlayerEventCommunicator {
        id: eventReceiver;
    }

    function handleOpenMap(sData)
    {
        let mapData = JSON.parse(sData);
        map.showWith(mapData.resource, new MapTypes.Map(mapData.data), mapData.current);
        textBox.state = "HIDDEN";
    }

    Component.onCompleted: {
        eventReceiver.registerEventHandler("openMap", handleOpenMap);
    }
}
