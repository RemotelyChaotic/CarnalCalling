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

    property bool canToggleOnlyOwned: true
    readonly property var genderStrings: [ "None", "Male", "Female", "Herm"]

    visible: false

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
                                 "cardData": null,
                                 "cardViewElems": cardView,
                                 "cardLayout": "CardDelegateBack.qml",
                                 "cardCount": 0,
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
                                 "cardData": card,
                                 "cardViewElems": repository.getCardViewElements(card),
                                 "cardLayout": card.layout,
                                 "cardCount": cardData.count,
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
        anchors.centerIn: parent
        width: parent.width - StyleParams.hexWidth*3
        height: parent.height - StyleParams.hexHeight*3
        cellWidth: StyleParams.cardCollectionWidthMin+10
        cellHeight: StyleParams.cardCollectionHeightMin+10

        flow: GridView.FlowLeftToRight
        layoutDirection: Qt.LeftToRight
        verticalLayoutDirection: GridView.TopToBottom

        innerMouseAreaEnabled: !previewDelegate.visible

        sourceModel: cardModel
        filters: AllOf {
            filters: [
                RegExpFilter {
                    roleName: "cardFilter"
                    pattern: filterTextArea.text === "" ? ".*" : filterTextArea.text
                    caseSensitivity: Qt.CaseInsensitive
                },
                RegExpFilter {
                    roleName: "cardLayout"
                    pattern: showOnlyOwnedButtonCheckable.checked ? "^(?!CardDelegateBack[.]qml$).*" : ".*"
                    caseSensitivity: Qt.CaseInsensitive
                }
            ]
        }

        onItemClicked: {
            previewDelegate.x = x;
            previewDelegate.y = y;
            previewDelegate.width = StyleParams.cardCollectionWidthMin;
            previewDelegate.height = StyleParams.cardCollectionHeightMin;

            let card = repository.getCard(id, setId);
            if (null != card) {
                previewDelegate.cardData = card;
                previewDelegate.cardViewElems = repository.getCardViewElements(card);
                previewDelegate.source = card.layout;
            }

            previewDelegate.show();
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

    CardPreviewRender {
        id: previewDelegate
        x: 0
        y: 0
        width: 0
        height: 0
        currentlyLoadedProject: layout.currentlyLoadedProject.id
    }
}
