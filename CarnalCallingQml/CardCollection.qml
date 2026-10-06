import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14
import JoipEngine 1.3
import JOIP.core 1.5
import JOIP.db 1.1
import CarnalCallingQml 1.0
import SortFilterProxyModel 0.2

Rectangle {
    id: layout
    color: "transparent"

    property Project currentlyLoadedProject: root.currentlyLoadedProject
    property DataRepository repository: null

    property real offsetX: hexBg.x
    property real offsetY: hexBg.y
    readonly property alias numRows: hexBg.numRows
    readonly property alias numCols: hexBg.numCols
    readonly property var genderStrings: [ "None", "Male", "Female", "Herm"]

    visible: false

    function showWith(ownedCards)
    {
        cardModel.clear();

        if (null != ownedCards) {
            for (const card of ownedCards) {
                pushCard(card);
            }
        }

        layout.visible = true;
    }

    function pushCard(cardData)
    {
        if (null != repository && null != cardData && null != cardData.id &&
            null != cardData.setId && -1 < cardData.id && "" !== cardData.setId)
        {
            let card = repository.getCard(cardData.id, cardData.setId);
            let cardFilter = card.setId + ";" + card.id + ";" + card.title + ";" +
                             card.description + ";" + card.faction + ";" + card.cardType + ";" +
                             card.slot + ";" + card.rarity + ";" +
                             genderStrings[card.gendering+1] + ";" +
                             card.tags.join(";");
            cardModel.append({
                                 "cardData": card,
                                 "cardViewElems": repository.getCardViewElements(card),
                                 "cardLayout": card.layout,
                                 "projId": currentlyLoadedProject.id,
                                 "cardFilter": cardFilter,
                                 "orderId": cardData.setId + ";" + cardData.id
                            });
        }
    }

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

    ListModel {
        id: cardModel
        dynamicRoles: true
    }

    GridView {
        id: cardList
        anchors.centerIn: parent
        width: parent.width
        height: parent.height

        signal itemClicked(int index, real x, real y, string setId, int id)

        onItemClicked: {
            previewDelegate.x = x;
            previewDelegate.y = y;
            previewDelegate.width = StyleParams.cardCollectionWidthMin;
            previewDelegate.height = StyleParams.cardCollectionHeightMin;

            let card = repository.getCard(id, setId);
            if (null != card) {
                previewDelegate.cardData = card;
                previewDelegate.cardViewElems = repository.getCardViewElements(card);
                previewDelegateCardLoaderFront.source = card.layout;
            }

            appearAnimation.start();
        }

        model: SortFilterProxyModel {
            id: cardProxyModel

            sourceModel: cardModel
            filters: RegExpFilter {
                id: sortFilter
                roleName: "cardFilter"
                pattern: ".*"
                caseSensitivity: Qt.CaseInsensitive
            }

            sorters: StringSorter {
                id: sorter
                roleName: "orderId"
            }
        }

        delegate: Component {
            Loader {
                width: StyleParams.cardCollectionWidthMin
                height: StyleParams.cardCollectionHeightMin
                asynchronous: true
                visible: status == Loader.Ready

                sourceComponent: Component {
                    Rectangle {
                        width: StyleParams.cardCollectionWidthMin
                        height: StyleParams.cardCollectionHeightMin
                        color: "transparent"

                        Loader {
                            id: cardLoader
                            anchors.fill: parent
                            source: ""
                            asynchronous: true
                            visible: status == Loader.Ready
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !previewDelegate.visible

                            onClicked: {
                                let pointInLayout = mapToItem(layout, 0.0, 0.0);
                                cardList.itemClicked(
                                            index,
                                            pointInLayout.x,
                                            pointInLayout.y,
                                            model.cardData.setId,
                                            model.cardData.id);
                            }
                        }

                        Component.onCompleted: {
                            cardLoader.source = model.cardLayout
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: overlayRect
        anchors.fill: parent
        color: "#88000000"
        opacity: previewDelegate.visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
        }

        MouseArea {
            anchors.fill: parent
            enabled: previewDelegate.visible
            onClicked: {
                previewDelegate.visible = false;
            }
        }
    }

    Rectangle {
        id: previewDelegate
        x: 0
        y: 0
        width: 0
        height: 0
        color: "transparent"

        property real intendedWidth: origW * scale
        property real intendedHeight: origH * scale

        readonly property real origW: StyleParams.cardWidthOrig
        readonly property real origH: StyleParams.cardHeightOrig
        readonly property real availW: parent.width
        readonly property real availH: parent.height
        readonly property real scaleW: availW / origW
        readonly property real scaleH: availH / origH
        readonly property real scale: Math.min(1.0, scaleW, scaleH)
        visible: false

        property var cardData: null
        property var cardViewElems: null

        property var animationFinished: false

        property real cardRotationX: 0
        property real cardRotationY: 0
        property real cardRotationZ: 0

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
            source: ""
            anchors.fill: parent
            asynchronous: true
            // Hide the original item visually after animation is over.
            // It is still rendered into ShaderEffectSource below.
            visible: status == Loader.Ready && !previewDelegate.animationFinished

            onLoaded: {
                item.currentlyLoadedProjectId = layout.currentlyLoadedProject.id;
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
                    //
                    // qt_Vertex is in item coordinates.
                    // ----------------------------------------------------

                    highp float x =
                        qt_Vertex.x - cardWidth * 0.5;

                    highp float y =
                        qt_Vertex.y - cardHeight * 0.5;

                    highp float z = 0.0;

                    // ----------------------------------------------------
                    // Angles
                    // ----------------------------------------------------

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
                    // ----------------------------------------------------

                    highp float x1 = x;

                    highp float y1 =
                        y * cx - z * sx;

                    highp float z1 =
                        y * sx + z * cx;

                    // ----------------------------------------------------
                    // Rotate around Y
                    // ----------------------------------------------------

                    highp float x2 =
                        x1 * cy + z1 * sy;

                    highp float y2 =
                        y1;

                    highp float z2 =
                        -x1 * sy + z1 * cy;

                    // ----------------------------------------------------
                    // Rotate around Z
                    // ----------------------------------------------------

                    highp float x3 =
                        x2 * cz - y2 * sz;

                    highp float y3 =
                        x2 * sz + y2 * cz;

                    highp float z3 =
                        z2;

                    // ----------------------------------------------------
                    // Perspective projection.
                    // ----------------------------------------------------

                    highp float depth =
                        cameraDistance - z3;

                    highp float projection =
                        cameraDistance / depth;

                    x3 *= projection;
                    y3 *= projection;

                    // ----------------------------------------------------
                    // Back to item coordinates
                    // ----------------------------------------------------

                    highp float finalX =
                        x3 + cardWidth * 0.5;

                    highp float finalY =
                        y3 + cardHeight * 0.5;

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

                    qt_Facing =
                        cx * cy;
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
                    highp vec2 uv =
                        qt_TexCoord0;

                    if (qt_Facing >= 0.0)
                    {
                        gl_FragColor =
                            texture2D(sourceFront, uv);
                    }
                    else
                    {
                        // The back is viewed from the opposite side.
                        uv.x = 1.0 - uv.x;

                        gl_FragColor =
                            texture2D(sourceBack, uv);
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
}
