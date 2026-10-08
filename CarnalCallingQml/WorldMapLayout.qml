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
        x: DominantHand.Left === StyleParams.dominantHand ? 0 : parent.width - width

        width: (parent.width - parent.spacing * 2) / 4
        height: parent.height - textBox.height;
        color: "transparent"

        PlayerIcons {
            id: icon
            width: parent.width
            height: parent.height
            iconWidth: StyleParams.iconWidth
            iconHeight: StyleParams.iconHeight

            anchors.right: parent.right
            anchors.bottom: parent.bottom
            userName: "icon"
        }
    }

    Rectangle {
        id: timerRect
        anchors.top: parent.top
        x: DominantHand.Left === StyleParams.dominantHand ? parent.width - width : 0

        width: (parent.width - parent.spacing * 2) / 4
        height: parent.height - textBox.height;
        color: "transparent"

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            width: !StyleParams.isMobile ? parent.width : parent.width
            height: !StyleParams.isMobile ? parent.height / 2 : width
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

        y: StyleParams.hexHeight
        x: DominantHand.Left === StyleParams.dominantHand ?
               parent.spacing * 2 :
               parent.width - width - parent.spacing * 2

        width: StyleParams.hexWidth * 1.75
        height: sceneControl.y + sceneControl.height - y

        hexWidth: StyleParams.hexWidth
        hexHeight: StyleParams.hexHeight

        userName: "notification"

        onTransitionRequested: {
            switch(scene) {
            case "options":
                // todo: show options
                break;
            case "cards":
                eventReceiver.sendEventResponse("mapEvent", "Cards");
                break;
            case "decks":
                eventReceiver.sendEventResponse("mapEvent", "Decks");
                break;
            }
        }
    }

    CCPlayerTextBox {
        id: textBox;

        x: parent.spacing * 2
        y: parent.height - height
        width: parent.width - parent.spacing * 4
        height: parent.height / 3 - parent.spacing / 2
        iconWidth: StyleParams.iconWidth
        iconHeight: StyleParams.iconHeight
        hexWidth: StyleParams.hexWidth
        hexHeight: StyleParams.hexHeight
        minHeightHidden: sceneControl.height

        userName: "textBox"
        mainTextBox: true
        hideLogAfterInactivity: true
    }

    CCPlayerControls {
        id: sceneControl

        x: textBox.x
        y: textBox.y - height / 3
        width: textBox.width
        height: StyleParams.hexHeight * 1.5

        buttonWidth: StyleParams.hexWidth
        buttonHeight: StyleParams.hexHeight

        onSetUiVisible: {
            iconRect.opacity = visible ? 1.0 : 0.0;
            timerRect.opacity = visible ? 1.0 : 0.0;
            notificationRect.opacity = visible ? 1.0 : 0.0;
            textBox.opacity = visible ? 1.0 : 0.0;
        }


        HexButtonWithToolTip {
            id: travel
            Layout.preferredHeight: sceneControl.buttonHeight
            Layout.preferredWidth: sceneControl.buttonWidth
            Layout.alignment: Qt.AlignTop

            orientation: HexButtonWithToolTip.Top
            textBoxOffset: 6

            enabled: textBox.opacity > 0
            text: qsTr("Travel")

            shortcut: Settings.keyBinding("Tools")
            toolTipText: qsTr("Head to location")
            imageSource: hovered ? StyleParams.travelButton : StyleParams.travelHoverButton

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
        StyleParams.currentProjectId = currentlyLoadedProject.id;
        eventReceiver.registerEventHandler("openMap", handleOpenMap);
    }
}
