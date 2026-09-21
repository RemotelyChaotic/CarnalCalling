import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14

Item {
    id: grid
    width: 800
    height: 600
    property string color: "transparent"

    property real hexWidth: StyleParams.hexWidth
    property real hexHeight: StyleParams.hexHeight
    property real lineWeight: StyleParams.strokeColorHexInactiveWidth

    property color hexFillString: StyleParams.fillColorHexInactive
    property color lineFillString: StyleParams.strokeColorHexInactive

    // Re-use matching metrics for QML container sizing
    readonly property real colStep: hexWidth * 0.75
    readonly property real rowStep: hexHeight

    readonly property int numCols: Math.max(1, Math.floor(width / colStep))
    readonly property int numRows: Math.max(1, Math.floor(height / rowStep))

    readonly property real gridWidth:  numCols * colStep
    readonly property real gridHeight: numRows * rowStep

    /*
    Rectangle {
        id: dDEBUG
        anchors.fill: parent
        color: "green"
    }
    */

    Rectangle{
        anchors.centerIn: parent
        color: grid.color

        width: grid.gridWidth
        height: grid.gridHeight

        ShaderEffect {
            id: hexShader
            anchors.fill: parent

            blending: true

            // Uniforms passed directly to the GLSL fragment shader
            property vector2d resolution: Qt.vector2d(width, height)
            property vector2d hexDimension: Qt.vector2d(grid.hexWidth, grid.hexHeight)
            property real lineWeight: grid.lineWeight
            property real numCols: grid.numCols
            property real numRows: grid.numRows
            property vector4d hexColor:
                Qt.vector4d(grid.hexFillString.r,
                            grid.hexFillString.g,
                            grid.hexFillString.b,
                            grid.hexFillString.a)
            property vector4d lineColor:
                Qt.vector4d(grid.lineFillString.r,
                            grid.lineFillString.g,
                            grid.lineFillString.b,
                            grid.lineFillString.a)

            // Default to a coordinate far off-screen (-1000) when not hovering.
            property vector2d hoverPos: Qt.vector2d(-1000.0, -1000.0)

            fragmentShader: "
                precision mediump float;

                varying highp vec2 qt_TexCoord0;
                uniform highp float qt_Opacity;

                uniform highp vec2 resolution;
                uniform highp vec2 hexDimension;
                uniform highp float lineWeight;
                uniform highp float numRows;
                uniform highp float numCols;
                uniform lowp vec4 hexColor;
                uniform lowp vec4 lineColor;
                uniform highp vec2 hoverPos;

                void main()
                {
                    // ========================================================
                    // BASIC DIMENSIONS
                    // ========================================================

                    highp float W = hexDimension.x;
                    highp float H = hexDimension.y;

                    highp float halfW = W * 0.5;
                    highp float halfH = H * 0.5;

                    // Distance between centers of neighboring columns.
                    highp float colStep = W * 0.75;

                    // Distance between centers vertically.
                    highp float rowStep = H;


                    // ========================================================
                    // PIXEL POSITION
                    // ========================================================

                    highp vec2 p =
                        qt_TexCoord0 * resolution;


                    // ========================================================
                    // FIND COLUMN
                    //
                    // Flat-top hex columns:
                    //
                    //       ______
                    //      /      \      ______
                    //     /        \    /      \
                    //     \        /   /        \
                    //      \______/    \        /
                    //           <---->
                    //           0.75 W
                    //
                    // Odd columns are shifted down by H/2.
                    // ========================================================

                    highp float col =
                        floor(p.x / colStep + 0.5);


                    highp float colOffset =
                        mod(col, 2.0) * halfH;


                    // ========================================================
                    // FIND ROW
                    // ========================================================

                    highp float row =
                        floor(
                            (p.y - colOffset) / rowStep
                            + 0.5
                        );


                    // ========================================================
                    // CURRENT HEX CENTER
                    // ========================================================

                    highp vec2 cellCenter =
                        vec2(
                            col * colStep,
                            row * rowStep + colOffset
                        );


                    highp vec2 centerOffset =
                        p - cellCenter;


                    // ========================================================
                    // CHECK ADJACENT COLUMNS
                    //
                    // The simple rounding above is sufficient for most of
                    // the cell, but near the slanted boundaries the nearest
                    // hex can belong to a neighboring column.
                    //
                    // Check both neighbors.
                    // ========================================================

                    highp float bestDistance =
                        dot(centerOffset, centerOffset);


                    // ----- Previous column ---------------------------------

                    highp float prevCol =
                        col - 1.0;

                    highp float prevOffset =
                        mod(prevCol, 2.0) * halfH;

                    highp float prevRow =
                        floor(
                            (p.y - prevOffset) / rowStep
                            + 0.5
                        );

                    highp vec2 prevCenter =
                        vec2(
                            prevCol * colStep,
                            prevRow * rowStep + prevOffset
                        );

                    highp vec2 prevDelta =
                        p - prevCenter;

                    highp float prevDistance =
                        dot(prevDelta, prevDelta);


                    if (prevDistance < bestDistance)
                    {
                        col = prevCol;
                        row = prevRow;

                        cellCenter = prevCenter;
                        centerOffset = prevDelta;

                        bestDistance = prevDistance;
                    }


                    // ----- Next column -------------------------------------

                    highp float nextCol =
                        col + 1.0;

                    highp float nextOffset =
                        mod(nextCol, 2.0) * halfH;

                    highp float nextRow =
                        floor(
                            (p.y - nextOffset) / rowStep
                            + 0.5
                        );

                    highp vec2 nextCenter =
                        vec2(
                            nextCol * colStep,
                            nextRow * rowStep + nextOffset
                        );

                    highp vec2 nextDelta =
                        p - nextCenter;

                    highp float nextDistance =
                        dot(nextDelta, nextDelta);


                    if (nextDistance < bestDistance)
                    {
                        col = nextCol;
                        row = nextRow;

                        cellCenter = nextCenter;
                        centerOffset = nextDelta;

                        bestDistance = nextDistance;
                    }


                    // ========================================================
                    // MOUSE / HOVER HEX
                    // ========================================================

                    highp float mouseCol =
                        floor(
                            hoverPos.x / colStep + 0.5
                        );

                    highp float mouseColOffset =
                        mod(mouseCol, 2.0) * halfH;

                    highp float mouseRow =
                        floor(
                            (hoverPos.y - mouseColOffset)
                            / rowStep
                            + 0.5
                        );

                    highp vec2 mouseCellCenter =
                        vec2(
                            mouseCol * colStep,
                            mouseRow * rowStep
                                + mouseColOffset
                        );


                    // ========================================================
                    // HOVER
                    // ========================================================

                    bool isHovered =
                        distance(
                            cellCenter,
                            mouseCellCenter
                        ) < 1.0;


                    // ========================================================
                    // HEXAGON BORDER DISTANCE
                    //
                    // For a regular flat-top hex:
                    //
                    //             ______
                    //           /        \
                    //          /          \
                    //          \          /
                    //           \________/
                    //
                    // H = W * sqrt(3)/2
                    //
                    // The apothem is H/2.
                    //
                    // The boundary can be represented by:
                    //
                    // max(
                    //     abs(y),
                    //     sqrt(3)/2 * abs(x)
                    //       + 0.5 * abs(y)
                    // )
                    //
                    // This evaluates to H/2 at every edge.
                    // ========================================================

                    highp vec2 q =
                        abs(centerOffset);

                    highp float dist =
                        max(
                            q.y,
                            q.x * 0.86602540378
                                + q.y * 0.5
                        );


                    // IMPORTANT:
                    //
                    // The boundary value is H/2, NOT W/2.
                    //
                    highp float radiusBound =
                        halfH;


                    // ========================================================
                    // BORDER
                    // ========================================================

                    highp float antialiasRange =
                        1.0;

                    highp float targetLineWeight =
                        isHovered
                            ? 0.0
                            : lineWeight;

                    highp float edge =
                        smoothstep(
                            radiusBound
                                - targetLineWeight
                                - antialiasRange,

                            radiusBound
                                - targetLineWeight,

                            dist
                        );


                    lowp vec4 mixedColor =
                        mix(
                            hexColor,
                            lineColor,
                            edge
                        );


                    // ========================================================
                    // GRID CLIPPING
                    //
                    // Use the actual integer cell coordinates rather than
                    // testing the hex bounding boxes against gridW/gridH.
                    // ========================================================

                    bool validCell =
                        col >= 0.0 &&
                        col < numCols &&
                        row >= 0.0 &&
                        row < numRows;


                    // Also discard pixels outside the ShaderEffect itself.
                    bool insideRect =
                        p.x >= 0.0 &&
                        p.y >= 0.0 &&
                        p.x <= resolution.x &&
                        p.y <= resolution.y &&
                        cellCenter.x > 0.0 &&
                        cellCenter.y > 0.0;


                    if (!validCell || !insideRect)
                    {
                        mixedColor = vec4(0.0);
                    }


                    gl_FragColor =
                        mixedColor * qt_Opacity;
                }
            "
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            // Feed real-time coordinates into the shader uniform vector
            onPositionChanged: {
                hexShader.hoverPos = Qt.vector2d(mouse.x, mouse.y);
            }

            // Reset the tracker when the mouse exits the window area
            onExited: {
                hexShader.hoverPos = Qt.vector2d(-1000.0, -1000.0);
            }
        }
    }
}
