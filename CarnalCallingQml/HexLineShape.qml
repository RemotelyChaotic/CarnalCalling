import QtQuick 2.14
import QtQuick.Shapes 1.14
import JOIP.core 1.5
import CarnalCallingQml 1.0

Shape {
    id: textBgShape
    layer.enabled: Settings.playerAntialiasing
    layer.samples: 4 // (anti-aliasing)

    property alias fillColor: path.fillColor
    property alias strokeColor: path.strokeColor
    property alias strokeWidth: path.strokeWidth
    property alias capStyle: path.capStyle
    property alias joinStyle: path.joinStyle

    property real dy: textBgShape.height / 2
    property real dx: StyleParams.hexWidth*0.25

    ShapePath {
        id: path
        fillColor: StyleParams.fillColorHexActive
        strokeColor: StyleParams.strokeColorHexActive
        strokeWidth: StyleParams.strokeColorHexActiveWidth
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin

        startX: 0
        startY: textBgShape.dy

        PathLine { x: textBgShape.dx; y: 0 }
        PathLine { x: textBgShape.width - textBgShape.dx; y: 0 }
        PathLine { x: textBgShape.width; y: textBgShape.height / 2 }
        PathLine { x: textBgShape.width - textBgShape.dx; y: textBgShape.height }
        PathLine { x: textBgShape.dx; y: textBgShape.height }
        PathLine { x: 0; y: textBgShape.dy }
    }
}
