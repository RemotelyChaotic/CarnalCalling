import QtQuick 2.14
import QtQuick.Controls 2.14
import JOIP.core 1.5
import JoipEngine 1.3
import CarnalCallingQml 1.0
import SortFilterProxyModel 0.2

ListView {
    id: keywordList
    width: StyleParams.toolTipWidth

    property DataRepository repository: null
    property real toolTipHeight: StyleParams.toolTipHeight
    property real itemMargin: 5

    readonly property string tagKeyword: "keyword"

    function showWith(tags) {
        if (null != repository) {
            for (let tag of tags) {
                if (tag.startsWith(tagKeyword + ":")) {
                    let tagId = tag.replace(tagKeyword + ":", "");
                    let tagObj = repository.keywordData[tagId];
                    cardModel.append({
                                        "name": tagObj.name,
                                        "image": tagObj.image,
                                        "text": tagObj.text
                                     });
                }
            }

            if (cardModel.count > 0) {
                visible = true;
            }
        }
    }

    function hide() {
        cardModel.clear();
        visible = false;
    }

    ListModel {
        id: cardModel
        dynamicRoles: false
    }

    clip: true
    model: SortFilterProxyModel {
        id: cardProxyModel

        sourceModel: cardModel

        sorters: StringSorter {
            id: sorter
            roleName: "name"
        }
    }

    delegate: Rectangle {
        width: keywordList.width
        height: keywordList.toolTipHeight
        color: "transparent"

        HexLineShape {
            id: titleBar
            y: 0
            x: 0
            width: parent.width
            height: StyleParams.toolTiptitleHeight

            fillColor: StyleParams.fillColorHexInactive
            strokeColor: StyleParams.strokeColorHexInactive
            strokeWidth: StyleParams.strokeColorHexInactiveWidth

            Text {
                id: titleText
                y: thisKeyword.border.width
                x: 0
                width: parent.width - parent.dy
                height: parent.height

                text: "&nbsp;<img src=\""+ model.image +"\" width=\""+ StyleParams.menuTextPonintSize +"\" height=\""+ StyleParams.menuTextPonintSize +"\" /> " +  model.name

                font.family: null != root.currentlyLoadedProject ?
                                 root.currentlyLoadedProject.font : "Arial"
                font.pixelSize: StyleParams.toolTipTitleSize
                font.hintingPreference: Font.PreferNoHinting
                font.bold: true

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
                wrapMode: Text.WordWrap
                color: StyleParams.textColorMenu
                textFormat: Text.RichText
            }
        }

        Rectangle {
            id: thisKeyword
            x: titleBar.dx
            y: titleBar.height
            width: parent.width - keywordList.itemMargin - titleBar.dx
            height: parent.height - keywordList.itemMargin - titleBar.height

            color: StyleParams.fillColorHexActive
            border.width: StyleParams.strokeColorHexActiveWidth
            border.color: StyleParams.strokeColorHexActive
            opacity: 0.7

            Rectangle {
                x: 0
                y: 0
                width: parent.width - parent.border.width
                height: 2
                color: StyleParams.textColorMenu
            }

            Text {
                id: titleDescription
                anchors.centerIn: parent
                width: parent.width - thisKeyword.border.width - scrollV.width * 2
                height: parent.height - thisKeyword.border.width

                text: "&nbsp;" + model.text

                font.family: null != root.currentlyLoadedProject ?
                                 root.currentlyLoadedProject.font : "Arial"
                font.pixelSize: StyleParams.toolTipPonintSize
                font.hintingPreference: Font.PreferNoHinting

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
                wrapMode: Text.WordWrap
                color: StyleParams.textColorMenu
                textFormat: Text.RichText
            }
        }
    }

    ScrollBar.vertical: ScrollBar {
        id: scrollV
        orientation: Qt.Vertical
        policy: Qt.ScrollBarAsNeeded
        x: StyleParams.dominantHand === DominantHand.Left ?
            keywordList.x + keywordList.width + (StyleParams.hexWidth - width)/2 :
            keywordList.x - (StyleParams.hexWidth + width)/2
        width: StyleParams.hexWidth/3

        contentItem: Rectangle {
            implicitWidth: parent.width - StyleParams.strokeColorHexInactiveWidth*2
            implicitHeight: 100
            radius: width / 2
            color: StyleParams.fillColorHexActive
        }
        background: Rectangle {
            implicitWidth: parent.width
            radius: width / 2
            color: StyleParams.fillColorHexInactive
            border.color: StyleParams.strokeColorHexInactive
        }
    }
}
