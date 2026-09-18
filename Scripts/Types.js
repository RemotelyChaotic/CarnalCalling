import * as MapTypes from "MapTypes.js"

// Qt 5.14 doesn't fully support Symbol e.g. (.description) is missing, so we use
// a custom thing
function EnumValue(name) {
    return Object.freeze({
        name,
        toString() { return name; }
    });
}

const RarityType = Object.freeze({
    Common:     EnumValue("Common"),
    Uncommon:   EnumValue("Uncommon"),
    Rare:       EnumValue("Rare"),
    Mythic:     EnumValue("Mythic")
});

const FactionType = Object.freeze({
    Earth:      EnumValue("Earth"),
    Unicorn:    EnumValue("Unicorn"),
    Pegasus:    EnumValue("Pegasus"),
    Alicorn:    EnumValue("Alicorn"),
    Changeling: EnumValue("Changeling"),
    Thestral:   EnumValue("Thestral"),
    Kirin:      EnumValue("Kirin")
});

const CardType = Object.freeze({
    Social:     EnumValue("Social"),
    Action:     EnumValue("Action"),
    Clothes:    EnumValue("Clothes"),
    Blocker:    EnumValue("Blocker")
});

const GenderType = Object.freeze({
    None:       -1,
    Male:       0,
    Female:     1,
    Herm:       2,
});

const SlotType = Object.freeze({
    None:       EnumValue("None"),
    Mouth:      EnumValue("Mouth"),
    Nipple:     EnumValue("Nipple"),
    Tits:       EnumValue("Tits"),
    Genitals:   EnumValue("Genitals"),
    Ass:        EnumValue("Ass")
});

export {EnumValue, RarityType, RaceType, CardType, GenderType, SlotType, MapTypes}