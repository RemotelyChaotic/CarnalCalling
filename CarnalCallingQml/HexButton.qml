import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Shapes 1.14
import JOIP.core 1.5

Button {
    id: buttonTemplateButton

    focusPolicy: Qt.NoFocus

    signal triggeredButton()

    property string shortcut: ""
    property string toolTipText: ""
    property string imageSource: ""
    property Item soundEffects: root.soundEffects

    background: Shape {
        anchors.fill: parent
        layer.enabled: Settings.playerAntialiasing
        layer.samples: 4 // (anti-aliasing)

        ShapePath {
            fillColor: StyleParams.fillColorHexActive
            strokeColor: StyleParams.strokeColorHexActive
            strokeWidth: StyleParams.strokeColorHexActiveWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: width * 0.25
            startY: 0

            PathLine { x: width * 0.75; y: 0 }
            PathLine { x: width;        y: height * 0.5 }
            PathLine { x: width * 0.75; y: height }
            PathLine { x: width * 0.25; y: height }
            PathLine { x: 0;            y: height * 0.5 }
            PathLine { x: width * 0.25; y: 0 }
        }
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
    ToolTip.visible: hovered
    ToolTip.text: toolTipText

    Image {
        anchors.centerIn: parent
        width: (parent.width < parent.height ? parent.width : parent.height) - 10
        height: (parent.width < parent.height ? parent.width : parent.height) - 10
        fillMode: Image.PreserveAspectFit

        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap

        source: buttonTemplateButton.imageSource
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