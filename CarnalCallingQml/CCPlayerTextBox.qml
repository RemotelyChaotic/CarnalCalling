import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Shapes 1.14
import QtGraphicalEffects 1.14
import JoipEngine 1.3
import JOIP.core 1.5
import JOIP.db 1.1
import JOIP.script 1.1

Rectangle {
    id: textBoxWrapper
    color: "transparent"

    property real hexWidth: StyleParams.hexWidth
    property real hexHeight: StyleParams.hexHeight

    property alias userName: textBoxWrapped.userName
    property alias mainTextBox: textBoxWrapped.mainTextBox
    property alias iconWidth: textBoxWrapped.iconWidth
    property alias iconHeight: textBoxWrapped.iconHeight
    property alias logShown: textBoxWrapped.logShown
    property alias hideLogAfterInactivity: textBoxWrapped.hideLogAfterInactivity

    function clearTextBox()
    {
        textBoxWrapped.clearTextBox();
    }

    function showButtonPrompts(vsLabels, sStoreIntoVar, sRequestId, bStoreIntoStorageInstead)
    {
        textBoxWrapped.showButtonPrompts(vsLabels, sStoreIntoVar, sRequestId, bStoreIntoStorageInstead);
    }

    function showSceneSelectionPrompts(vsLabels)
    {
        textBoxWrapped.showSceneSelectionPrompts(vsLabels);
    }

    function showInput(sDefault, sStoreIntoVar, sRequestId, bStoreIntoStorageInstead)
    {
        textBoxWrapped.showInput(sDefault, sStoreIntoVar, sRequestId, bStoreIntoStorageInstead);
    }

    function showText(sText, onlyInList)
    {
        textBoxWrapped.showText(sText, onlyInList);
    }

    property int dominantHand: StyleParams.dominantHand
    property int noDebugOffset: !root.debug ?
                                    (DominantHand.Left === dominantHand ? -hexWidth*1/4 : hexWidth*3/4) :
                                    (DominantHand.Left === dominantHand ? -hexWidth*4/4 : 0)
    property int rootTl: DominantHand.Left === dominantHand ? 0 : width
    property int factorHexHand: DominantHand.Left === dominantHand ? 1 : -1

    // instanced Hex drawing for performance
    Repeater {
        model: [
            // tr hexes
            { x: rootTl+factorHexHand*hexWidth+factorHexHand*noDebugOffset, y: 0, width: hexWidth, height: hexHeight, opacity: 0.5 },
            { x: rootTl+factorHexHand*hexWidth+factorHexHand*noDebugOffset, y: hexHeight*4/4, width: hexWidth, height: hexHeight, opacity: 0.2 },
            { x: rootTl+factorHexHand*hexWidth+factorHexHand*noDebugOffset, y: hexHeight*8/4, width: hexWidth, height: hexHeight, opacity: 0.1 },
            { x: rootTl+factorHexHand*hexWidth*7/4+factorHexHand*noDebugOffset, y: hexHeight*2/4, width: hexWidth, height: hexHeight, opacity: 0.3 },
            { x: rootTl+factorHexHand*hexWidth*10/4+factorHexHand*noDebugOffset, y: 0, width: hexWidth, height: hexHeight, opacity: 0.5 },
            { x: rootTl+factorHexHand*hexWidth*13/4+factorHexHand*noDebugOffset, y: -hexHeight*2/4, width: hexWidth, height: hexHeight, opacity: 0.3 },
            { x: rootTl+factorHexHand*hexWidth*16/4+factorHexHand*noDebugOffset, y: 0, width: hexWidth, height: hexHeight, opacity: 0.3 },
            { x: rootTl+factorHexHand*hexWidth*19/4+factorHexHand*noDebugOffset, y: -hexHeight*2/4, width: hexWidth, height: hexHeight, opacity: 0.1 }
            // bl hexes
        ]
        delegate: Shape {
                x: modelData.x
                y: modelData.y
                width: modelData.width
                height: modelData.height

                opacity: modelData.opacity

                layer.enabled: Settings.playerAntialiasing
                layer.samples: 4 // (anti-aliasing)

                ShapePath {
                    fillColor: StyleParams.fillColorHexInactive
                    strokeColor: StyleParams.strokeColorHexInactive
                    strokeWidth: StyleParams.strokeColorHexInactiveWidth
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
    }

    Behavior on opacity {
        NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
    }

    PlayerTextBox {
        id: textBoxWrapped
        anchors.fill: parent

        displayMode: PlayerTextBox.TextBoxMode.Log
        hideTimerIntervalMS: Settings.hideSettingsTimeout
    }
}
