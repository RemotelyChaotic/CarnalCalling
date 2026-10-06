import QtQuick 2.14
import JOIP.core 1.5
import JOIP.db 1.1
import CarnalCallingQml 1.0

Item {
    id: repository

    property Project currentlyLoadedProject: null
    property var cards: null
    property var packs: null
    property var imageData: null
    property var commonIconImages: null

    readonly property string tagCard: "card"
    readonly property string tagLayer: "layer"
    readonly property string tagBack: "type:back"
    readonly property string tagFront: "type:front"
    readonly property string tagRarity: "type:rarity"
    readonly property string tagStyle: "style"

    readonly property string tagStyleCommon: "Common"
    readonly property string tagStyleUncommon: "Uncommon"
    readonly property string tagStyleRare: "Rare"
    readonly property string tagStyleMythic: "Mythic"



    function getCard(id, setId)
    {
        if (cards[setId] != null) {
            const found = cards[setId].find((c) => c.id === id);
            //console.log(JSON.stringify(found));
            return found;
        }
        return null;
    }

    function getCardViewElements(idOrCard, setId)
    {
        let locCard = idOrCard;
        if (Number.isInteger(idOrCard))
        {
            locCard = getCard(idOrCard, setId);
        }

        if (null == locCard.tags) {
            return null;
        }
        let cardType = locCard.tags.find((t) => t.startsWith(tagCard + ":"));
        if (null == cardType) {
            return null;
        }

        let retVal = {};
        retVal["image"] = "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + locCard.image;

        if (null != locCard.style) {
            // background
            if (null != imageData[cardType] && null != imageData[cardType][tagBack] &&
                null != imageData[cardType][tagBack][tagStyle + ":" + locCard.style]) {
                retVal["back"] = imageData[cardType][tagBack][tagStyle + ":" + locCard.style][0];
            }
            // rarity
            if (null != locCard.rarity) {
                if (null != imageData[cardType] && null != imageData[cardType][tagRarity] &&
                    null != imageData[cardType][tagRarity][tagStyle + ":" + locCard.style]) {

                    for (let data of imageData[cardType][tagRarity][tagStyle + ":" + locCard.style]) {
                        if (null != data.resource) {
                            if (null != data.resource.tags().find((t) => t === locCard.rarity)) {
                                retVal["rarity"] = data;
                            }
                        }
                    }
                }
            }
            // layers:
            if (null != imageData[cardType] && null != imageData[cardType][tagFront] &&
                null != imageData[cardType][tagFront][tagStyle + ":" + locCard.style]) {
                retVal["layers"] = [];
                const layersStyle = imageData[cardType][tagFront][tagStyle + ":" + locCard.style];
                var layersKeys = Object.keys(layersStyle);
                for (let l of layersKeys) {
                    retVal["layers"].push(layersStyle[l][0]);
                }
            }
        }

        let cType = null != commonIconImages["cardType"][locCard.cardType] ? locCard.cardType : "None";
        let slotT = null != commonIconImages["cardType"][cType][locCard.slot] ? locCard.slot : "None";
        let genderingT = null != commonIconImages["gendering"][""+locCard.gendering] ? ""+locCard.gendering : "-1";
        retVal["icons"] = {
            "cardType" : commonIconImages["cardType"][cType][slotT],
            "gendering": commonIconImages["gendering"][genderingT]
        };

        //console.log(JSON.stringify(retVal));
        return retVal;
    }

    function getPack(setId)
    {
        const found = packs.find((p) => p.setId === setId);
        return found;
    }

    Component.onCompleted: {
        let localCards = root.evaluate("localStorage.load('cardData')");
        //console.log(JSON.stringify(localCards));
        let cardsObj = {};
        for (const card of localCards.Cards) {
            if (cardsObj[card.setId] == null) {
                cardsObj[card.setId] = [];
            }
            cardsObj[card.setId].push(card);
        }
        cards = cardsObj;
        packs = root.evaluate("localStorage.load('packData')").Packs;

        // get the tags we need
        let cardTypesTags = [];
        let typesTags = [
            tagBack,
            tagFront,
            tagRarity
        ];
        let styleTags = [];
        let layersTags = [];
        let vsTags = currentlyLoadedProject.tags();
        for (const sTag of vsTags) {
            if (sTag.startsWith(tagCard + ":")) {
                cardTypesTags.push(sTag);
            }
            if (sTag.startsWith(tagStyle + ":")) {
                // -1 is a special style that is a synonym for all styles
                if (sTag !== tagStyle + ":-1") {
                    styleTags.push(sTag);
                }
            }
            if (sTag.startsWith(tagLayer + ":")) {
                layersTags.push(sTag);
            }
        }

        // build the image data cache
        let locImageData = {}
        for (const sCType of cardTypesTags) {
            locImageData[sCType] = {};
            for (const sType of typesTags) {
                locImageData[sCType][sType] = {};
                for (const sStyle of styleTags) {
                    if (tagBack === sType || tagRarity === sType) {
                        locImageData[sCType][sType][sStyle] = [];
                    }
                    else {
                        locImageData[sCType][sType][sStyle] = {};
                        for (const sLayer of layersTags) {
                            locImageData[sCType][sType][sStyle][sLayer] = [];
                        }
                    }
                }
            }
        }

        let vsResources = currentlyLoadedProject.resources();
        for (const sRes of vsResources) {
            let resurce = currentlyLoadedProject.resource(sRes);
            let vsResTags = resurce.tags();

            let sCardType = "";
            let sType = "";
            let sStyle = "";
            let sLayer = "";
            for (const sTag of vsResTags) {
                if (cardTypesTags.find((t) => t === sTag) != null) {
                    sCardType = sTag;
                }
                if (typesTags.find((t) => t === sTag) != null) {
                    sType = sTag;
                }
                if (styleTags.find((t) => t === sTag) != null) {
                    sStyle = sTag;
                } else if (tagStyle + ":-1" === sTag) {
                    sStyle = sTag;
                }
                if (layersTags.find((t) => t === sTag) != null) {
                    sLayer = sTag;
                }
            }

            //console.log("Before", sCardType, sType, sStyle, sLayer, resurce.name);
            if ("" !== sCardType && "" !== sType  &&
                ("" !== sStyle || tagStyle + ":-1" === sStyle) &&
                ("" !== sLayer || tagBack === sType || tagRarity === sType)) {

                //console.log("After", sCardType, sType, sStyle, sLayer, resurce.name);
                let objToPush = {
                    "name": resurce.name,
                    "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + resurce.name,
                    "resource": resurce
                };

                if (tagBack === sType || tagRarity === sType) {
                    if (tagStyle + ":-1" !== sStyle) {
                        locImageData[sCardType][sType][sStyle].push(objToPush);
                    } else {
                        for (const sStyleA of styleTags) {
                            locImageData[sCardType][sType][sStyleA].push(objToPush);
                        }
                    }
                } else {
                    objToPush["layer"] = sLayer;
                    if (tagStyle + ":-1" !== sStyle) {
                        locImageData[sCardType][sType][sStyle][sLayer].push(objToPush);
                    } else {
                        for (const sStyleA of styleTags) {
                            locImageData[sCardType][sType][sStyleA][sLayer].push(objToPush);
                        }
                    }
                }
            }
        }

        imageData = locImageData;
        //console.log(JSON.stringify(imageData))

        commonIconImages = {
            "cardType" : {
                "Social": {
                    "None": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconSocal"
                },
                "Action": {
                    "None": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconAction",
                    "Ass": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionAss",
                    "Chest": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionChest",
                    "Face": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionFace",
                    "Genitals": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionGenitals",
                    "Hoof": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionHoof",
                    "Horn": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionHorn",
                    "Mouth": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionMouth",
                    "Nipple": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionNipple",
                    "Wing": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionWing"
                },
                "Clothes": {
                    "None": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconClothes",
                    "Ass": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconClothesAss",
                    "Chest": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconClothesChest",
                    "Face": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconClothesFace",
                    "Genitals": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconClothesGenitals",
                    "Hoof": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconClothesHoof",
                    "Horn": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconClothesHorn",
                    "Mouth": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconClothesMouth",
                    "Nipple": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconClothesNipple",
                    "Wing": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconClothesWing"
                },
                "Blocker": {
                    "None": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconBlocker"
                },
                "None": {
                    "None": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "UnknownSvg"
                },
            },
            "gendering": {
                "-1": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "GenderIconNone",
                "0": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "GenderIconMale",
                "1": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "GenderIconFemale",
                "2": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "GenderIconShemale"
            }
        }
    }
}
