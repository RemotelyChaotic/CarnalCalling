import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14
import JoipEngine 1.3
import JOIP.core 1.5
import JOIP.db 1.1
import CarnalCallingQml 1.0

Rectangle {
    id: layout
    color: "transparent"

    property Project currentlyLoadedProject: root.currentlyLoadedProject

    property real offsetX: hexBg.x
    property real offsetY: hexBg.y
    readonly property alias numRows: hexBg.numRows
    readonly property alias numCols: hexBg.numCols

    /*
    Rectangle {
        id: debugRenderer
        x: hexBg.x
        y: hexBg.y
        width: parent.width - hexBg.x *2
        height: parent.height - hexBg.y *2
        color: "transparent"
        border.color: "blue"
    }
    */

    HexGridRenderer {
        id: hexBg
        anchors.centerIn: parent
        width: gridWidth - hexWidth / 2
        height: gridHeight
        widthHint: parent.width
        heightHint: parent.height

        color: "transparent"

        hexWidth: StyleParams.hexWidth
        hexHeight: StyleParams.hexHeight
        lineWeight: StyleParams.strokeColorHexInactiveWidth/2

        hexFillString: StyleParams.fillColorHexInactive
        lineFillString: StyleParams.strokeColorHexInactive

        animateMouseOver: true
        gradientRendering: false
    }
}
