import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import JOIP.core 1.5

Rectangle {
    id: sceneControl
    color: "transparent"

    property int buttonHeight: 48
    property int buttonWidth: 48
    property int spacing: 10

    default property alias content: customContent.children

    signal setUiVisible(bool visible)

    function quit()
    {
        root.quit();
    }

    function pausePlayScene()
    {
        pauseButtonLoader.paused = !pauseButtonLoader.paused;
        if (pauseButtonLoader.paused)
        {
            ScriptRunner.resumeExecution();
        }
        else
        {
            ScriptRunner.pauseExecution();
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

        property int dominantHand: Settings.dominantHand

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
                Settings.styleFolderQml() + (item.hovered ? "/ButtonExitHover.svg" : "/ButtonExit.svg")

            Layout.preferredHeight: sceneControl.buttonHeight
            Layout.preferredWidth: sceneControl.buttonWidth
            Layout.alignment: rowLayout.indexOfItem(exitButtonLoader) % 2 ? Qt.AlignTop : Qt.AlignBottom
            visible: !root.debug

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
                Settings.styleFolderQml() +
                    (paused ? (item.hovered ? "/ButtonPlayHover.svg" : "/ButtonPlay.svg") :
                              (item.hovered ? "/ButtonPauseHover.svg" : "/ButtonPause.svg"))

            Layout.preferredHeight: sceneControl.buttonHeight
            Layout.preferredWidth: sceneControl.buttonWidth
            Layout.alignment: rowLayout.indexOfItem(pauseButtonLoader) % 2 ? Qt.AlignTop : Qt.AlignBottom

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
                Settings.styleFolderQml() +
                        (visibleUi ? (item.hovered ? "/ButtonVisibleHover.svg" : "/ButtonVisible.svg") :
                                     (item.hovered ? "/ButtonInvisibleHover.svg" : "/ButtonInvisible.svg"))

            Layout.preferredHeight: sceneControl.buttonHeight
            Layout.preferredWidth: sceneControl.buttonWidth
            Layout.alignment: rowLayout.indexOfItem(hideButtonLoader) % 2 ? Qt.AlignTop : Qt.AlignBottom

            onLoaded: {
                item.text = buttonText;
                item.shortcut = shortcut;
                item.toolTipText = toolTipText;
                item.imageSource = imageSource;
                item.triggeredButton.connect(sceneControl.setUiVisibleImpl)
            }
        }

        Loader {
            id: devicesButtonLoader
            sourceComponent: buttonTemplate

            property bool visibleUi: true

            property string buttonText: Settings.keyBinding("Devices")
            property string shortcut: Settings.keyBinding("Devices")
            property string toolTipText: qsTr("Show device list")
            property string imageSource:
                Settings.styleFolderQml() + (item.hovered ? "/ButtonPlugHover.png" : "/ButtonPlug.png")

            Layout.preferredHeight: sceneControl.buttonHeight
            Layout.preferredWidth: sceneControl.buttonWidth
            Layout.alignment: rowLayout.indexOfItem(devicesButtonLoader) % 2 ? Qt.AlignTop : Qt.AlignBottom

            function openMenu()
            {
                var globalCoordinares = item.mapToItem(root, 0, item.height);
                TeaseDeviceController.openSelectionScreen(globalCoordinares.x, globalCoordinares.y);
            }

            onLoaded: {
                item.text = buttonText;
                item.shortcut = shortcut;
                item.toolTipText = toolTipText;
                item.imageSource = imageSource;
                item.triggeredButton.connect(openMenu)
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
