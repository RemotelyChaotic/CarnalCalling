import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import JOIP.core 1.5

Rectangle {
    id: sceneControl
    color: "transparent"

    property real buttonWidth: StyleParams.hexWidth
    property real buttonHeight: StyleParams.hexHeight

    default property alias content: customContent.children

    property alias exitButton: exitButtonLoader
    property alias pauseButton: pauseButtonLoader
    property alias hideButton: hideButtonLoader

    signal setUiVisible(bool visible)

    property var quit: function()
    {
        root.quit();
    }

    property var pausePlayScene: function()
    {
        pauseButtonLoader.paused = !pauseButtonLoader.paused;
        if (pauseButtonLoader.paused)
        {
            ScriptRunner.pauseExecution();
        }
        else
        {
            ScriptRunner.resumeExecution();
        }
    }

    function setUiVisibleImpl()
    {
        hideButtonLoader.visibleUi = !hideButtonLoader.visibleUi;
        setUiVisible(hideButtonLoader.visibleUi);
    }

    Component {
        id: buttonTemplate
        HexButton {
            id: buttonTemplateButton
        }
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: -parent.buttonWidth / 4
        layoutDirection: DominantHand.Left === dominantHand ? Qt.LeftToRight :
                                                              Qt.RightToLeft

        property int dominantHand: StyleParams.dominantHand

        function indexOfItem(targetItem) {
            for (var i = 0; i < children.length; i++) {
                if (children[i] === targetItem) {
                    return i;
                }
            }
            return -1;
        }

        Loader {
            id: exitButtonLoader
            sourceComponent: buttonTemplate

            property string buttonText: Settings.keyBinding("Exit")
            property string shortcut: Settings.keyBinding("Exit")
            property string toolTipText: qsTr("Exit tease")
            property string imageSource:
                item.hovered ? StyleParams.exitHoverButton : StyleParams.exitButton

            Layout.preferredHeight: sceneControl.buttonHeight
            Layout.preferredWidth: sceneControl.buttonWidth
            Layout.alignment: rowLayout.indexOfItem(exitButtonLoader) % 2 ? Qt.AlignTop : Qt.AlignBottom
            visible: true

            onImageSourceChanged: {
                item.imageSource = imageSource;
            }

            onLoaded: {
                item.text = buttonText;
                item.shortcut = shortcut;
                item.toolTipText = toolTipText;
                item.imageSource = imageSource;
                item.triggeredButton.connect(sceneControl.quit);
            }
        }

        Loader {
            id: pauseButtonLoader
            sourceComponent: buttonTemplate

            property bool paused: false

            property string buttonText: Settings.keyBinding("Pause")
            property string shortcut: Settings.keyBinding("Pause")
            property string toolTipText: qsTr("Pause or resume execution")
            property string imageSource:
                paused ? (item.hovered ? StyleParams.playHoverButton : StyleParams.playButton) :
                         (item.hovered ? StyleParams.pauseHoverButton : StyleParams.pauseButton)

            Layout.preferredHeight: sceneControl.buttonHeight
            Layout.preferredWidth: sceneControl.buttonWidth
            Layout.alignment: rowLayout.indexOfItem(pauseButtonLoader) % 2 ? Qt.AlignTop : Qt.AlignBottom

            onImageSourceChanged: {
                item.imageSource = imageSource;
            }

            onLoaded: {
                item.text = buttonText;
                item.shortcut = shortcut;
                item.toolTipText = toolTipText;
                item.imageSource = imageSource;
                item.triggeredButton.connect(sceneControl.pausePlayScene)
            }
        }

        Loader {
            id: hideButtonLoader
            sourceComponent: buttonTemplate

            property bool visibleUi: true

            property string buttonText: Settings.keyBinding("ToggleUI")
            property string shortcut: Settings.keyBinding("ToggleUI")
            property string toolTipText: qsTr("Show or hide UI")
            property string imageSource:
                visibleUi ? (item.hovered ? StyleParams.visibleHoverButton : StyleParams.visibleButton) :
                            (item.hovered ? StyleParams.inVisibleHoverButton : StyleParams.inVisibleButton)

            Layout.preferredHeight: sceneControl.buttonHeight
            Layout.preferredWidth: sceneControl.buttonWidth
            Layout.alignment: rowLayout.indexOfItem(hideButtonLoader) % 2 ? Qt.AlignTop : Qt.AlignBottom

            onImageSourceChanged: {
                item.imageSource = imageSource;
            }

            onLoaded: {
                item.text = buttonText;
                item.shortcut = shortcut;
                item.toolTipText = toolTipText;
                item.imageSource = imageSource;
                item.triggeredButton.connect(sceneControl.setUiVisibleImpl)
            }
        }

        RowLayout {
            id: customContent
            Layout.preferredHeight: parent.height
            spacing: -sceneControl.buttonWidth / 4
            layoutDirection: DominantHand.Left === Settings.dominantHand ? Qt.LeftToRight :
                                                                           Qt.RightToLeft
        }

        Rectangle {
            id: spacerHoriz
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: parent.height
            Layout.alignment: Qt.AlignVCenter
            color: "transparent"
        }
    }

    Connections {
        target: ScriptRunner
        onRunningChanged: {
            pauseButtonLoader.paused = !bRunning;
        }
    }
}
