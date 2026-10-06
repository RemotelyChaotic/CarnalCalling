import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14
import JoipEngine 1.3
import JOIP.core 1.5
import JOIP.db 1.1
import CarnalCallingQml 1.0

Rectangle {
    id: cardRoot
    width: StyleParams.cardCollectionWidthMin
    height: StyleParams.cardCollectionHeightMin
    color: "transparent"

    property var cardData: typeof model !== "undefined"  ? model.cardData : null
    property var cardViewElems: typeof model !== "undefined"  ? model.cardViewElems : null
    property int currentlyLoadedProjectId: typeof model !== "undefined"  ? model.projId : -1

    property real zoomFactorX: width / StyleParams.cardWidthOrig
    property real zoomFactorY: height / StyleParams.cardHeightOrig

    readonly property string tagLayer: "layer"
    readonly property string unknownImage:
        "image://DataBaseImageProivider/" + currentlyLoadedProjectId + "/" + StyleParams.unknownIcon;

    Image {
        id: background
        anchors.fill: parent

        asynchronous: true
        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap
        source: {
            if (null == cardViewElems) {
                return "";
            }

            const layer = cardViewElems.layers.find((l) => l.layer === tagLayer + ":" + 0);
            if (null != layer) {
                return layer.image;
            }
            return cardRoot.unknownImage;
        }

        onStatusChanged: {
            if (status === Image.Error && cardRoot.unknownImage !== source) {
                source = cardRoot.unknownImage;
            }
        }
    }

    Image {
        id: artImage
        x: 60 * zoomFactorX
        y: 60 * zoomFactorY
        width: parent.width - 2 * x
        height: 980 * zoomFactorY

        asynchronous: true
        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap

        source: null != cardData ? cardData.image : ""

        onStatusChanged: {
            if (status === Image.Error && cardRoot.unknownImage !== source) {
                source = cardRoot.unknownImage;
            }
        }
    }

    Image {
        id: middleLayer
        anchors.fill: parent

        asynchronous: true
        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap
        source: {
            if (null == cardViewElems) {
                return "";
            }

            const layer = cardViewElems.layers.find((l) => l.layer === tagLayer + ":" + 1);
            if (null != layer) {
                return layer.image;
            }
            return cardRoot.unknownImage;
        }

        onStatusChanged: {
            if (status === Image.Error && cardRoot.unknownImage !== source) {
                source = cardRoot.unknownImage;
            }
        }
    }

    Image {
        id: topLayer
        anchors.fill: parent

        asynchronous: true
        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap
        source: {
            if (null == cardViewElems) {
                return "";
            }

            const layer = cardViewElems.layers.find((l) => l.layer === tagLayer + ":" + 2);
            if (null != layer) {
                return layer.image;
            }
            return cardRoot.unknownImage;
        }

        onStatusChanged: {
            if (status === Image.Error && cardRoot.unknownImage !== source) {
                source = cardRoot.unknownImage;
            }
        }
    }

    // Text
    TextItemFormated {
        id: iconText
        anchors.horizontalCenter: parent.horizontalCenter
        y: 110 * zoomFactorX
        height: 152 * zoomFactorX
        text: null != cardData ? cardData.title : ""
        pointSize: StyleParams.cardTitleTextPonintSize * zoomFactorX
        maximumWidth: parent.width - 275*2 * zoomFactorX
        textColor: StyleParams.textColorMenu
    }
    Text {
        id: description
        anchors.horizontalCenter: parent.horizontalCenter
        y: 1040 * zoomFactorY
        height: 650 * zoomFactorY
        width: parent.width - 2 * 100 * zoomFactorX
        text: null != cardData ? cardData.description
            .replace(/\{id\}/g, ""+cardRoot.currentlyLoadedProjectId)
            .replace(/\{w\}/g, ""+(StyleParams.cardDescTextPonintSize*zoomFactorX))
            .replace(/\{h\}/g, ""+(StyleParams.cardDescTextPonintSize*zoomFactorX)) :
            "";

        font.family: null != root.currentlyLoadedProject ?
                         root.currentlyLoadedProject.font : "Arial"
        font.pixelSize: StyleParams.cardDescTextPonintSize * zoomFactorX
        font.hintingPreference: Font.PreferNoHinting

        horizontalAlignment: Text.AlignLeft
        elide: Text.ElideNone
        wrapMode: Text.WordWrap
        color: StyleParams.textColorMenu
        textFormat: Text.RichText
    }

    // icons and stats
    Image {
        id: cardTypeLayer
        x: 20 * zoomFactorX
        y: 20 * zoomFactorY
        width: 300 * zoomFactorX
        height: 300 * zoomFactorY

        asynchronous: true
        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap
        source: null != cardViewElems ? cardViewElems.icons.cardType : ""

        onStatusChanged: {
            if (status === Image.Error && cardRoot.unknownImage !== source) {
                source = cardRoot.unknownImage;
            }
        }
    }
    Image {
        id: timingInfoLayer
        x: parent.width - 80 * zoomFactorX - width
        y: 80 * zoomFactorY
        width: 165 * zoomFactorX
        height: 165 * zoomFactorY

        asynchronous: true
        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap
        source:
            null != cardViewElems ?
            "image://DataBaseImageProivider/" + currentlyLoadedProjectId + "/" + "TimeIcon" :
                ""


        onStatusChanged: {
            if (status === Image.Error && cardRoot.unknownImage !== source) {
                source = cardRoot.unknownImage;
            }
        }
    }
    Image {
        id: genderLayer
        x: 50 * zoomFactorX
        y: parent.height - 50 * zoomFactorY - height
        width: 240 * zoomFactorX
        height: 240 * zoomFactorY

        asynchronous: true
        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap
        source: null != cardViewElems ? cardViewElems.icons.gendering : ""

        onStatusChanged: {
            if (status === Image.Error && cardRoot.unknownImage !== source) {
                source = cardRoot.unknownImage;
            }
        }
    }
    Image {
        id: statsLayerSocial
        x: parent.width - 170 * zoomFactorX - width
        y: parent.height - 50 * zoomFactorY - height
        width: 120 * zoomFactorX
        height: 240 * zoomFactorY

        asynchronous: true
        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap
        source: {
            if (null == cardData) {
                return "";
            }
            if ("Social" === cardData.cardType)
            {
                return cardData.draw > 0 ?
                    "image://DataBaseImageProivider/" + currentlyLoadedProjectId + "/" + "DrawIcon" :
                    "image://DataBaseImageProivider/" + currentlyLoadedProjectId + "/" + "DiscardIcon";
            }
            return "";
        }
        visible: null != cardData && "Social" === cardData.cardType

        onStatusChanged: {
            if (status === Image.Error && cardRoot.unknownImage !== source &&
                "Social" === cardData.cardType) {
                source = cardRoot.unknownImage;
            }
        }
    }
    Image {
        id: statsLayerActionDamage
        x: parent.width - 170 * zoomFactorX - width
        y: parent.height - 170 * zoomFactorY - height
        width: 120 * zoomFactorX
        height: 120 * zoomFactorY

        asynchronous: true
        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap
        source: {
            if (null == cardData) {
                return "";
            }
            if ("Action" === cardData.cardType && cardData.damage > 0)
            {
                return "image://DataBaseImageProivider/" + currentlyLoadedProjectId + "/" + "HorniIcon" ;
            }
            return "";
        }
        visible: null != cardData && "Action" === cardData.cardType && cardData.damage > 0

        onStatusChanged: {
            if (status === Image.Error && cardRoot.unknownImage !== source &&
                "Action" === cardData.cardType) {
                source = cardRoot.unknownImage;
            }
        }
    }
    Image {
        id: statsLayerActionCombo
        x: parent.width - 170 * zoomFactorX - width
        y: parent.height - 50 * zoomFactorY - height
        width: 120 * zoomFactorX
        height: 120 * zoomFactorY

        asynchronous: true
        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap
        source: {
            if (null == cardData) {
                return "";
            }
            if ("Action" === cardData.cardType && cardData.combo > 0)
            {
                return "image://DataBaseImageProivider/" + currentlyLoadedProjectId + "/" + "ComboIcon" ;
            }
            return "";
        }
        visible: null != cardData && "Action" === cardData.cardType && cardData.combo > 0

        onStatusChanged: {
            if (status === Image.Error && cardRoot.unknownImage !== source &&
                "Action" === cardData.cardType) {
                source = cardRoot.unknownImage;
            }
        }
    }
    Image {
        id: rarityLayer
        y: parent.height - height - 95 * zoomFactorY
        height: sourceSize.height * zoomFactorY
        width: sourceSize.width * zoomFactorX
        anchors.horizontalCenter: parent.horizontalCenter

        asynchronous: true
        smooth: Settings.playerImageSmooth
        antialiasing: Settings.playerAntialiasing
        mipmap: Settings.playerImageMipMap
        source: null != cardViewElems ? cardViewElems.rarity.image : ""

        onStatusChanged: {
            if (status === Image.Error && cardRoot.unknownImage !== source) {
                source = cardRoot.unknownImage;
            }
        }
    }
}
