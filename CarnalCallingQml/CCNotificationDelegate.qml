import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Shapes 1.14
import QtGraphicalEffects 1.14
import JOIP.core 1.5
import JoipEngine 1.3

Rectangle {
    id: delegate
    width: hexWidth
    height: hexHeight
    color: "transparent"

    property string text: ""
    property real hexWidth: StyleParams.hexWidth
    property real hexHeight: StyleParams.hexHeight
    property int orientation: StyleParams.dominantHand
    property int textBoxOffset: 6

    property string glowHexColor: StyleParams.glowHexColor
    property int glowHexRadius: StyleParams.glowHexRadius
    property int glowHexSpread: StyleParams.glowHexSpread

    signal triggeredButton()

    property alias shortcut: hexButton.shortcut
    property alias toolTipText: hexButton.toolTipText
    property alias imageSource: hexButton.imageSource
    property alias hovered: hexButton.hovered

    Glow {
        id: textBGGlow

        anchors.fill: textBG
        source: textBG

        radius: StyleParams.glowHexRadius
        samples: 15
        color: StyleParams.glowHexColor
        spread: StyleParams.glowHexSpread

        opacity: hexButton.hovered ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: textBG
        x: orientation === DominantHand.Left ?
               (hexButton.hovered ? delegate.textBoxOffset : hexButton.x) :
               (hexButton.hovered ? -width - delegate.textBoxOffset : hexButton.x)
        y: hexButton.y - 5
        width: textButton.width + 30
        height: textButton.height + 10
        color: StyleParams.colorPlaceBg
        radius: height / 2

        opacity: hexButton.hovered ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad}
        }
        Behavior on x {
            NumberAnimation { duration: 500; easing.type: Easing.OutBack}
        }

        TextItemFormated {
            id: textButton
            x: 15
            y: 5
            height: hexButton.height
            maximumWidth: 200

            text: delegate.text
            textColor: StyleParams.textColorMenu
            pointSize: StyleParams.menuTextPonintSize
        }
    }

    HexButton {
        id: hexButton
        x: 0
        y: 0
        width: parent.hexWidth
        height: parent.hexHeight

        display: AbstractButton.IconOnly
        glowColor: delegate.glowHexColor

        onTriggeredButton: {
            delegate.triggeredButton();
        }
    }
}
