import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Shapes 1.14
import QtGraphicalEffects 1.14
import JOIP.core 1.5
import CarnalCallingQml 1.0

Button {
    id: buttonTemplateButton

    focusPolicy: Qt.NoFocus

    signal triggeredButton()

    property string shortcut: ""
    property string toolTipText: ""
    property string imageSource: ""
    property string glowColor: StyleParams.glowHexColor

    property Item soundEffects: root.soundEffects

    background: HexShape {
        anchors.fill: parent
    }

    contentItem: Text {
        anchors.fill: parent
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignBottom
        rightPadding: 5
        bottomPadding: 5

        text: parent.text
        font.family: Settings.font
        font.pixelSize: 8
        color: StyleParams.textColorMenu
    }

    ToolTip.delay: 1000
    ToolTip.timeout: 5000
    ToolTip.visible: hovered && toolTipText !== ""
    ToolTip.text: toolTipText

    Rectangle {
        id: glowRectColorSource
        anchors.fill: parent
        color: buttonTemplateButton.glowColor
        visible: false
    }

    Image {
        id: iconImage
        anchors.centerIn: parent
        width: (parent.width < parent.height ? parent.width : parent.height) - 10
        height: (parent.width < parent.height ? parent.width : parent.height) - 10
        fillMode: Image.PreserveAspectFit

        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap

        source: buttonTemplateButton.imageSource
        visible: !buttonTemplateButton.down && !buttonTemplateButton.checked
    }

    OpacityMask {
        anchors.centerIn: parent
        width: buttonTemplateButton.checkable ? iconImage.width : parent.width
        height: buttonTemplateButton.checkable ? iconImage.height : parent.height
        source: glowRectColorSource
        maskSource: iconImage
        visible: buttonTemplateButton.down || buttonTemplateButton.checked
    }

    onHoveredChanged: {
        if (hovered)
        {
            soundEffects.hoverSound.play();
        }
    }
    onClicked: {
        soundEffects.clickSound.play();
        triggeredButton();
    }

    Shortcut {
        sequence: buttonTemplateButton.shortcut
        context: Qt.ApplicationShortcut
        onActivated: {
            buttonTemplateButton.triggeredButton();
        }
    }
}
