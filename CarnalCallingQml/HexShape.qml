import QtQuick 2.14
import QtQuick.Shapes 1.14
import JOIP.core 1.5
import CarnalCallingQml 1.0

Shape {
    layer.enabled: Settings.playerAntialiasing
    layer.samples: 4 // (anti-aliasing)

    property alias fillColor: path.fillColor
    property alias strokeColor: path.strokeColor
    property alias strokeWidth: path.strokeWidth
    property alias capStyle: path.capStyle
    property alias joinStyle: path.joinStyle

    ShapePath {
        id: path
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
