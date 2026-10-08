import QtQuick 2.14
import QtQuick.Controls 2.14
import QtGraphicalEffects 1.14
import JOIP.core 1.5
import JoipEngine 1.3

Rectangle {
    id: previewDelegate
    x: 0
    y: 0
    width: 0
    height: 0
    color: "transparent"
    visible: false

    property int currentlyLoadedProject : -1

    property real intendedWidth: origW * scale
    property real intendedHeight: origH * scale

    readonly property real origW: StyleParams.cardWidthOrig
    readonly property real origH: StyleParams.cardHeightOrig
    readonly property real availW: parent.width
    readonly property real availH: parent.height
    readonly property real scaleW: availW / origW
    readonly property real scaleH: availH / origH
    readonly property real scale: Math.min(1.0, scaleW, scaleH)

    property var cardData: null
    property var cardViewElems: null

    property bool animationFinished: false

    property real cardRotationX: 0
    property real cardRotationY: 0
    property real cardRotationZ: 0

    property string source : ""

    function show()
    {
        if (null != previewDelegateCardLoaderFront.item) {
            previewDelegateCardLoaderFront.item.currentlyLoadedProjectId = currentlyLoadedProject;
            previewDelegateCardLoaderFront.item.cardData = previewDelegate.cardData;
            previewDelegateCardLoaderFront.item.cardViewElems = previewDelegate.cardViewElems;
        }
        appearAnimation.start();
    }

    SequentialAnimation {
        id: appearAnimation
        loops: 1
        running: false
        ScriptAction {
            script: {
                previewDelegate.cardRotationX = 0;
                previewDelegate.cardRotationY = 0;
                previewDelegate.cardRotationZ = 0;
                previewDelegate.visible = true;
                previewDelegate.animationFinished = false;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: previewDelegate; property: "x"; to: layout.width/2-previewDelegate.intendedWidth/2; duration: 300 }
            NumberAnimation { target: previewDelegate; property: "y"; to: layout.height/2-previewDelegate.intendedHeight/2; duration: 300 }
            NumberAnimation { target: previewDelegate; property: "width"; to: previewDelegate.intendedWidth; duration: 300 }
            NumberAnimation { target: previewDelegate; property: "height"; to: previewDelegate.intendedHeight; duration: 300 }
        }
        ScriptAction {
            script: {
                cardTextureFront.width = previewDelegate.width;
                cardTextureFront.height = previewDelegate.height;
                cardTextureBack.width = previewDelegate.width;
                cardTextureBack.height = previewDelegate.height;
                previewDelegate.animationFinished = true;
            }
        }
    }

    Image {
        id: previewDelegateCardLoaderBack
        anchors.fill: parent
        asynchronous: true
        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap
        source: null != previewDelegate.cardViewElems ? previewDelegate.cardViewElems.back.image : ""
        // Hide the original item visually. It is still rendered into
        // ShaderEffectSource below.
        visible: false
    }

    Loader {
        id: previewDelegateCardLoaderFront
        source: previewDelegate.source
        anchors.fill: parent
        asynchronous: true
        // Hide the original item visually after animation is over.
        // It is still rendered into ShaderEffectSource below.
        visible: status == Loader.Ready && !previewDelegate.animationFinished

        onLoaded: {
            item.currentlyLoadedProjectId = currentlyLoadedProject;
            item.cardData = previewDelegate.cardData;
            item.cardViewElems = previewDelegate.cardViewElems;
        }
    }

    ShaderEffectSource {
        id: cardTextureFront

        sourceItem: previewDelegateCardLoaderFront.item

        width: previewDelegate.width
        height: previewDelegate.height

        live: true
        hideSource: false
        smooth: true

        visible: false
    }
    ShaderEffectSource {
        id: cardTextureBack

        sourceItem: previewDelegateCardLoaderBack

        width: previewDelegate.width
        height: previewDelegate.height

        live: true
        hideSource: true
        smooth: true

        visible: false
    }

    ShaderEffect {
        id: card3d

        anchors.fill: parent

        visible: previewDelegateCardLoaderFront.status === Loader.Ready &&
                 previewDelegate.animationFinished

        property variant sourceFront: cardTextureFront
        property variant sourceBack: cardTextureBack

        property real rotationX: previewDelegate.cardRotationX
        property real rotationY: previewDelegate.cardRotationY
        property real rotationZ: previewDelegate.cardRotationZ

        property real cardWidth: width
        property real cardHeight: height

        // Distance of virtual camera from card.
        // Increase this for weaker perspective.
        property real cameraDistance: 1500.0

        mesh: GridMesh {
            resolution: Qt.size(40, 40)
        }

        cullMode: ShaderEffect.NoCulling

        // ------------------------------------------------------------
        // Vertex shader
        // ------------------------------------------------------------

        vertexShader: "
            precision highp float;

            uniform highp mat4 qt_Matrix;

            uniform highp float rotationX;
            uniform highp float rotationY;
            uniform highp float rotationZ;

            uniform highp float cardWidth;
            uniform highp float cardHeight;

            uniform highp float cameraDistance;

            attribute highp vec4 qt_Vertex;
            attribute highp vec2 qt_MultiTexCoord0;

            varying highp vec2 qt_TexCoord0;
            varying highp float qt_Facing;

            void main()
            {
                // ----------------------------------------------------
                // Convert QML vertex to coordinates relative to center.
                // qt_Vertex is in item coordinates.

                highp float x = qt_Vertex.x - cardWidth * 0.5;
                highp float y = qt_Vertex.y - cardHeight * 0.5;
                highp float z = 0.0;

                // ----------------------------------------------------
                // Angles

                highp float rx = radians(rotationX);
                highp float ry = radians(rotationY);
                highp float rz = radians(rotationZ);

                highp float sx = sin(rx);
                highp float cx = cos(rx);

                highp float sy = sin(ry);
                highp float cy = cos(ry);

                highp float sz = sin(rz);
                highp float cz = cos(rz);

                // ----------------------------------------------------
                // Rotate around X
                highp float x1 = x;
                highp float y1 = y * cx - z * sx;
                highp float z1 = y * sx + z * cx;

                // Rotate around Y
                highp float x2 = x1 * cy + z1 * sy;
                highp float y2 = y1;
                highp float z2 = -x1 * sy + z1 * cy;

                // Rotate around Z
                highp float x3 = x2 * cz - y2 * sz;
                highp float y3 = x2 * sz + y2 * cz;
                highp float z3 = z2;

                // ----------------------------------------------------
                // Perspective projection.

                highp float depth = cameraDistance - z3;
                highp float projection = cameraDistance / depth;

                x3 *= projection;
                y3 *= projection;

                // ----------------------------------------------------
                // Back to item coordinates

                highp float finalX = x3 + cardWidth * 0.5;
                highp float finalY = y3 + cardHeight * 0.5;

                // ----------------------------------------------------
                // Qt scene graph transformation
                // ----------------------------------------------------

                gl_Position =
                    qt_Matrix *
                    vec4(finalX, finalY, 0.0, 1.0);

                qt_TexCoord0 =
                    qt_MultiTexCoord0;

                // Z component of the rotated normal.
                //
                // Positive = front
                // Negative = back
                // ----------------------------------------------------

                qt_Facing = cx * cy;
            }
        "

        // ------------------------------------------------------------
        // Fragment shader
        // ------------------------------------------------------------

        fragmentShader: "
            precision highp float;

            uniform sampler2D sourceFront;
            uniform sampler2D sourceBack;

            varying highp vec2 qt_TexCoord0;
            varying highp float qt_Facing;

            void main()
            {
                highp vec2 uv = qt_TexCoord0;

                if (qt_Facing >= 0.0)
                {
                    gl_FragColor = texture2D(sourceFront, uv);
                }
                else
                {
                    // The back is viewed from the opposite side.
                    uv.x = 1.0 - uv.x;

                    gl_FragColor = texture2D(sourceBack, uv);
                }
            }
        "
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: {
           previewDelegate.cardRotationY =  (mouse.x - width / 2) / (width/2) * 20
           previewDelegate.cardRotationX =  -(mouse.y - height / 2) / (width/2) * 20;
        }
        onExited: {
            previewDelegate.cardRotationX = 0;
            previewDelegate.cardRotationY = 0;
            previewDelegate.cardRotationZ = 0;
        }
    }
}
