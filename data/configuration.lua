return {
    changeCharacterCommand = "changecharacter", -- this is the command to open the ui again and change your character, set to false if you want to disable.

    characterLimit = 5, -- max amount of characters that a player can create.

    logo = "logo.png", -- character screen logo.

    backgrounds = { -- background will randomly be set to one of these images.
        "background1.png",
        "background2.png",
        "background3.png"
    },

    startingMoney = {
        cash = 2500,
        bank = 8000
    },
}
