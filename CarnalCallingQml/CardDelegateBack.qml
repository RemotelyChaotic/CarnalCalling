import QtQuick 2.14
import QtQuick.Controls 2.14
import JOIP.core 1.5

Image {
    id: previewDelegateCardLoaderBack
    asynchronous: true
    smooth: Settings.playerImageSmooth
    antialiasing: Settings.playerAntialiasing
    mipmap: Settings.playerImageMipMap

    property var cardViewElems: typeof model !== "undefined"  ? model.cardViewElems : null
    property int currentlyLoadedProjectId: typeof model !== "undefined"  ? model.projId : -1
    readonly property string unknownImage:
        "image://DataBaseImageProivider/" + currentlyLoadedProjectId + "/" + StyleParams.unknownIcon;

    source: null != cardViewElems ? cardViewElems.back.image : ""

    onStatusChanged: {
        if (status === Image.Error && unknownImage !== source) {
            source = unknownImage;
        }
    }
}