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
    Rare:       EnumValue("Rare")
});

const RaceType = Object.freeze({
    Earth:      EnumValue("Earth"),
    Unicorn:    EnumValue("Unicorn"),
    Pegasus:    EnumValue("Pegasus"),
    Alicorn:    EnumValue("Alicorn"),
    Changeling: EnumValue("Changeling"),
});

const CardType = Object.freeze({
    Action:     EnumValue("Action")
});

const GenderType = Object.freeze({
    None:       -1,
    Male:       0,
    Female:     1,
    Herm:       2,
});

export {EnumValue, RarityType, RaceType, CardType, GenderType, MapTypes}