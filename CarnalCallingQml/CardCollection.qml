import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Shapes 1.14
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

    property int numRows: 0
    property int numCols: 0

    property alias innerMouseAreaEnabled: cardList.innerMouseAreaEnabled

    property bool canToggleOnlyOwned: true
    readonly property var genderStrings: [ "None", "Male", "Female", "Herm"]

    visible: false

    signal showCardPreview(real x, real y, real width, real height, var cardData, var cardViewElems, string source)

    function cardKey(setId, id)
    {
        return setId + ";" + String(id).padStart(4, '0');
    }

    function initWith(ownedCards, onlyShowOwned = false)
    {
        cardModel.clear();
        showOnlyOwnedButtonCheckable.checked = onlyShowOwned;

        if (null != repository) {
            const ownedByKey = new Map();
            if (ownedCards) {
                for (const card of ownedCards) {
                    ownedByKey.set(cardKey(card.setId, card.id), card);
                }
            }

            let allPacks = repository.allPacks();

            let vAllCardsSorted = [];

            for (const packId of allPacks) {

                const pack = repository.getPack(packId);
                const rarityTypes = Object.keys(pack.cards);
                for (const rarity of rarityTypes) {
                    if (!rarity.startsWith('_')) {
                        for (const cardC of pack.cards[rarity]) {
                            vAllCardsSorted.push(cardC);
                        }
                    }
                }
            }

            vAllCardsSorted.sort((a, b) => {
                // Primary: setId (string comparison)
                const setIdCompare = a.setId.localeCompare(b.setId);
                if (setIdCompare !== 0) {
                  return setIdCompare;
                }

                // Secondary: id (numeric)
                return a.id - b.id;
            });

            if (null != ownedCards) {
                for (const c of vAllCardsSorted) {
                    const found = ownedByKey.get(cardKey(c.setId, c.id));
                    if (null != found) {
                        pushCard(found);
                    } else {
                        pushBackground(c);
                    }
                }
            }
        }
    }

    function showWith(ownedCards, onlyShowOwned = false)
    {
        initWith(ownedCards, onlyShowOwned);

        addTimer.start();

        layout.visible = true;
    }

    function showWithAlreadyLoaded()
    {
        addTimer.start();

        layout.visible = true;
    }

    function pushBackground(cardData)
    {
        if (null != cardData && null != cardData.id &&
            null != cardData.setId && -1 < cardData.id && "" !== cardData.setId)
        {
            let cardView = repository.getCardViewElements(cardData.id, cardData.setId);
            let cardFilter = cardData.setId + ";" + cardData.id;
            addTimer.itemsToAdd.push({
                                 "enabled": true,
                                 "cardData": null,
                                 "cardViewElems": cardView,
                                 "cardLayout": "CardDelegateBack.qml",
                                 "cardCount": 0,
                                 "cardCountColor": StyleParams.textColorMenu,
                                 "projId": currentlyLoadedProject.id,
                                 "cardFilter": cardFilter,
                                 "orderId": cardKey(cardData.setId, cardData.id)
                            });
        }
    }

    function pushCard(cardData)
    {
        if (null != cardData && null != cardData.id &&
            null != cardData.setId && -1 < cardData.id && "" !== cardData.setId)
        {
            let card = repository.getCard(cardData.id, cardData.setId);
            let cardFilter = card.setId + ";" + card.id + ";" + card.title + ";" +
                             card.description + ";" + card.faction + ";" + card.cardType + ";" +
                             card.slot + ";" + card.rarity + ";" +
                             genderStrings[card.gendering+1] + ";" +
                             card.tags.join(";");
            addTimer.itemsToAdd.push({
                                 "enabled": true,
                                 "cardData": card,
                                 "cardViewElems": repository.getCardViewElements(card),
                                 "cardLayout": card.layout,
                                 "cardCount": cardData.count,
                                 "cardCountColor": StyleParams.textColorMenu,
                                 "projId": currentlyLoadedProject.id,
                                 "cardFilter": cardFilter,
                                 "orderId": cardKey(cardData.setId, cardData.id)
                            });
        }
    }

    Timer {
        id: addTimer
        interval: 100
        repeat: true
        running: false

        property var itemsToAdd: []
        property int nextItem: 0

        onTriggered: {
            if (0 < itemsToAdd.length) {
                cardModel.append(itemsToAdd.splice(0,1)[0]);

                nextItem++
            } else {
                stop();
            }
        }
    }

    ListModel {
        id: cardModel
        dynamicRoles: false
    }

    CardGrid {
        id: cardList

        y: StyleParams.hexHeight
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - StyleParams.hexWidth*2
        height: parent.height - StyleParams.hexHeight*2

        cellHintWidth: StyleParams.cardCollectionWidthMin
        cellHintHeight: StyleParams.cardCollectionHeightMin
        cellMargin: 10

        flow: GridView.FlowLeftToRight
        layoutDirection: Qt.LeftToRight
        verticalLayoutDirection: GridView.TopToBottom

        innerMouseAreaEnabled: true

        sourceModel: cardModel
        filterPattern: filterTextArea.text === "" ? ".*" : filterTextArea.text
        onlyShowNonZeroCount: showOnlyOwnedButtonCheckable.checked

        onItemClicked: {
            let card = repository.getCard(id, setId);
            if (null != card) {
                let mapped = layout.mapToGlobal(x,y);
                layout.showCardPreview(mapped.x,
                                       mapped.y,
                                       StyleParams.cardCollectionWidthMin,
                                       StyleParams.cardCollectionHeightMin,
                                       card,
                                       repository.getCardViewElements(card),
                                       card.layout);
            }
        }
    }

    HexButtonWithToolTip {
        id: searchButton
        x: 0
        y: 0
        width: StyleParams.hexWidth
        height: StyleParams.hexHeight
        hexWidth: StyleParams.hexWidth
        hexHeight: StyleParams.hexHeight
        orientation: HexButtonWithToolTip.Top
        textBoxOffset: 6

        text: qsTr("Filter")
        imageSource: hovered ? StyleParams.searchHoverButton : StyleParams.searchButton
        glowHexColor: StyleParams.glowHexColor
    }

    TextArea {
        id: filterTextArea
        x: searchButton.x + searchButton.width
        y: 0
        width: {
            if (StyleParams.hexWidth * 7 > parent.width) {
                let hexStride = StyleParams.hexWidth*0.75;
                let numCols = Math.floor(parent.width / hexStride) - 1;

                // Last column with the same parity as column 1
                let lastCol = numCols % 2 === 0
                        ? numCols - 1
                        : numCols;

                return Math.max(0, (lastCol - 1) * hexStride - StyleParams.hexWidth);
            }
            return StyleParams.hexWidth * 5;
        }
        height: StyleParams.hexHeight

        leftPadding: StyleParams.hexWidth * 0.25
        rightPadding: StyleParams.hexWidth * 0.25
        topPadding: 0
        bottomPadding: 0
        verticalAlignment: TextEdit.AlignVCenter

        color: StyleParams.textColorMenu

        text: ""
        placeholderText: qsTr("Enter a filter expression")
        placeholderTextColor: StyleParams.placeholderTextColorMenu
        font.pointSize: StyleParams.menuTextPonintSize
        font.family: null != root.currentlyLoadedProject ?
                         root.currentlyLoadedProject.font : "Arial"
        font.hintingPreference: Font.PreferNoHinting

        cursorDelegate: Rectangle {
            width: StyleParams.cursorWidth
            color: StyleParams.cursorColor
        }

        background: HexLineShape {
            id: textBgShape
            width: parent.width
            height: parent.height
        }
    }

    HexButtonWithToolTip {
        id: showOnlyOwnedButtonCheckable
        x: filterTextArea.width + searchButton.width
        y: 0
        width: StyleParams.hexWidth
        height: StyleParams.hexHeight
        hexWidth: StyleParams.hexWidth
        hexHeight: StyleParams.hexHeight
        orientation: HexButtonWithToolTip.Top
        textBoxOffset: 6

        text: qsTr("Only Show Owned")
        imageSource: hovered ? StyleParams.onlyShowOwnedHoverButton : StyleParams.onlyShowOwnedButton
        glowHexColor: StyleParams.glowHexColor

        checkable: true
        visible: layout.canToggleOnlyOwned
    }
}
