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
    property var iconImages: null

    readonly property string tagCard: "card"
    readonly property string tagLayer: "layer"
    readonly property string tagBack: "type:back"
    readonly property string tagFront: "type:front"
    readonly property string tagIcon: "type:icon"
    readonly property string tagIconType: "icontype"
    readonly property string tagStyle: "style"

    readonly property var commonIconSets : {
        "icontype:Social": {
            "None": {
                "name": "CardIconSocal",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconSocal",
                "resource": null
            }
        },
        "icontype:Secondary": {
            "None": {
                "name": "CardIconAction",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionSecondary",
                "resource": null
            },
            "Ass": {
                "name": "CardIconActionAss",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionAssSecondary",
                "resource": null
            },
            "Chest": {
                "name": "CardIconActionChest",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionChestSecondary",
                "resource": null
            },
            "Face": {
                "name": "CardIconActionFace",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionFaceSecondary",
                "resource": null
            },
            "Genitals": {
                "name": "CardIconActionGenitals",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionGenitalsSecondary",
                "resource": null
            },
            "Hoof": {
                "name": "CardIconActionHoof",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionHoofSecondary",
                "resource": null
            },
            "Horn": {
                "name": "CardIconActionHorn",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionHornSecondary",
                "resource": null
            },
            "Mouth": {
                "name": "CardIconActionMouth",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionMouthSecondary",
                "resource": null
            },
            "Nipple": {
                "name": "CardIconActionNipple",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionNippleSecondary",
                "resource": null
            },
            "Wing": {
                "name": "CardIconActionWing",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionWingSecondary",
                "resource": null
            }
        },
        "icontype:Clothes": {
            "None": {
                "name": "CardIconAction",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconAction",
                "resource": null
            },
            "Ass": {
                "name": "CardIconActionAss",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionAss",
                "resource": null
            },
            "Chest": {
                "name": "CardIconActionChest",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionChest",
                "resource": null
            },
            "Face": {
                "name": "CardIconActionFace",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionFace",
                "resource": null
            },
            "Genitals": {
                "name": "CardIconActionGenitals",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionGenitals",
                "resource": null
            },
            "Hoof": {
                "name": "CardIconActionHoof",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionHoof",
                "resource": null
            },
            "Horn": {
                "name": "CardIconActionHorn",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionHorn",
                "resource": null
            },
            "Mouth": {
                "name": "CardIconActionMouth",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionMouth",
                "resource": null
            },
            "Nipple": {
                "name": "CardIconActionNipple",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionNipple",
                "resource": null
            },
            "Wing": {
                "name": "CardIconActionWing",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconActionWing",
                "resource": null
            }
        },
        "icontype:Blocker": {
            "None": {
                "name": "CardIconBlocker",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "CardIconBlocker",
                "resource": null
            }
        },
        "icontype:gender": {
            "-1": {
                "name": "GenderIconNone",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "GenderIconNone",
                "resource": null
            },
            "0": {
                "name": "GenderIconMale",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "GenderIconMale",
                "resource": null
            },
            "1": {
                "name": "GenderIconFemale",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "GenderIconFemale",
                "resource": null
            },
            "2": {
                "name": "GenderIconShemale",
                "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + "GenderIconShemale",
                "resource": null
            }
        }
    }

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

        retVal["icons"] = iconImages[cardType];

        //console.log(JSON.stringify(retVal));
        return retVal;
    }

    function allPacks()
    {
        let retVal = [];
        for (const p of packs) {
            retVal.push(p.setId);
        }
        retVal.sort();
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
            tagFront
        ];
        let styleTags = [];
        let layersTags = [];
        let iconTypeTags = [];
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
            if (sTag.startsWith(tagIconType + ":")) {
                iconTypeTags.push(sTag);
            }
        }

        // build the image data cache
        let locImageData = {}
        for (const sCType of cardTypesTags) {
            locImageData[sCType] = {};
            for (const sType of typesTags) {
                locImageData[sCType][sType] = {};
                for (const sStyle of styleTags) {
                    if (tagBack === sType) {
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

        // do this after building the card table
        typesTags.push(tagIcon);

        // build the icon data cace
        let locIconData = {};
        for (const sCType of cardTypesTags) {
            locIconData[sCType] = {};
            // procedural data gotten from tags
            for (const sIType of iconTypeTags) {
                locIconData[sCType][sIType] = {};
            }
            for (const sKey of Object.keys(commonIconSets)) {
                locIconData[sCType][sKey] = commonIconSets[sKey];
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
            let sIconType = "";
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
                if (iconTypeTags.find((t) => t === sTag) != null) {
                    sIconType = sTag;
                }
            }

            //console.log("Before", sCardType, sType, sStyle, sLayer, resurce.name);
            // Add card template images
            if ("" !== sCardType && "" !== sType  &&
                ("" !== sStyle || tagStyle + ":-1" === sStyle) &&
                ("" !== sLayer || tagBack === sType)) {

                //console.log("After", sCardType, sType, sStyle, sLayer, resurce.name);
                let objToPush = {
                    "name": resurce.name,
                    "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + resurce.name,
                    "resource": resurce
                };

                if (tagBack === sType) {
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

            // add icon sets
            if ("" !== sCardType && tagIcon === sType &&
                "" != sIconType) {
                let iconTypeTagName = sIconType.split(":")[1];

                let iconCategory = "";
                for (const sTag of vsResTags) {
                    if (sTag.startsWith(iconTypeTagName)) {
                        iconCategory = sTag.split(":")[1];
                        break;
                    }
                }

                if ("" !== iconCategory) {
                    let objToPush = {
                        "name": resurce.name,
                        "image": "image://DataBaseImageProivider/" + currentlyLoadedProject.id + "/" + resurce.name,
                        "resource": resurce
                    };

                    locIconData[sCardType][sIconType][iconCategory] = objToPush;
                }
            }
        }

        imageData = locImageData;
        //console.log(JSON.stringify(imageData))

        iconImages = locIconData;
        //console.log(JSON.stringify(iconImages))
    }
}
