Syndicator.Search.Constants = {}

local ClassData = {
  [1] = {
    [1] = { -- Warrior, Arms
      {4, 4}, -- Plate
      {2, 1}, -- Two-Handed Axes
      {2, 5}, -- Two-Handed Maces
      {2, 8}, -- Two-Handed Swords
      {2, 6}, -- Polearms
    },
    [2] = { -- Warrior, Fury
      {4, 4}, -- Plate
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 7}, -- One-Handed Swords
      {2, 1}, -- Two-Handed Axes
      {2, 5}, -- Two-Handed Maces
      {2, 8}, -- Two-Handed Swords
      {2, 13}, --Fist Weapons  
      {2, 6}, -- Polearms
    },
    [3] = { -- Warrior, Protection
      {4, 4}, -- Plate
      {4, 6}, -- Shields
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 7}, -- One-Handed Swords
    },
  },
  [2] = {
    [1] = { -- Paladin, Holy
      {4, 4}, -- Plate
      {4, 6}, -- Shields
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 7}, -- One-Handed Swords
    },
    [2] = { -- Paladin, Protection
      {4, 4}, -- Plate
      {4, 6}, -- Shields
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 7}, -- One-Handed Swords
    },
    [3] = { -- Paladin, Retribution
      {4, 4}, -- Plate
      {4, 6}, -- Shields
      {2, 1}, -- Two-Handed Axes
      {2, 5}, -- Two-Handed Maces
      {2, 8}, -- Two-Handed Swords
    },
  },
  [3] = {
    [1] = { -- Hunter, Beast Mastery
      {4, 3}, -- Mail
      {2, 2}, -- Bows
      {2, 18}, -- Crossbows
      {2, 3}, -- Guns
    },
    [2] = { -- Hunter, Marksmanship
      {4, 3}, -- Mail
      {2, 2}, -- Bows
      {2, 18}, -- Crossbows
      {2, 3}, -- Guns
    },
    [3] = { -- Hunter, Survival
      {4, 3}, -- Mail
      {2, 6}, -- Polearms
      {2, 10}, -- Staves
      {2, 8}, -- Two-Handed Swords
      {2, 1}, -- Two-Handed Axes
    },
  },
  [4] = {
    [1] = { -- Rogue, Assassination
      {4, 2}, -- Leather
      {2, 15}, -- Daggers
      {2, 13}, --Fist Weapons
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 7}, -- One-Handed Swords
    },
    [2] = { -- Rogue, Combat
      {4, 2}, -- Leather
      {2, 15}, -- Daggers
      {2, 13}, --Fist Weapons
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 7}, -- One-Handed Swords
    },
    [3] = { -- Rogue, Subtlety
      {4, 2}, -- Leather
      {2, 15}, -- Daggers
      {2, 13}, --Fist Weapons
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 7}, -- One-Handed Swords

    },
  },
  [5] = {
    [1] = { -- Priest, Discipline
      {4, 1}, -- Cloth
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 4}, -- One-Handed Maces
      {2, 10}, -- Staves
    },
    [2] = { -- Priest, Holy
      {4, 1}, -- Cloth
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 4}, -- One-Handed Maces
      {2, 10}, -- Staves
    },
    [3] = { -- Priest, Shadow
      {4, 1}, -- Cloth
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 4}, -- One-Handed Maces
      {2, 10}, -- Staves
    },
  },
  [6] = {
    [1] = { -- Death Knight, Blood
      {4, 4}, -- Plate
      {2, 6}, -- Polearms
      {2, 1}, -- Two-Handed Axes
      {2, 5}, -- Two-Handed Maces
      {2, 8}, -- Two-Handed Swords
    },
    [2] = { -- Death Knight, Frost
      {4, 4}, -- Plate
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 7}, -- One-Handed Swords
      {2, 6}, -- Polearms
      {2, 1}, -- Two-Handed Axes
      {2, 5}, -- Two-Handed Maces
      {2, 8}, -- Two-Handed Swords
    },
    [3] = { -- Death Knight, Unholy
      {4, 4}, -- Plate
      {2, 6}, -- Polearms
      {2, 1}, -- Two-Handed Axes
      {2, 5}, -- Two-Handed Maces
      {2, 8}, -- Two-Handed Swords
    },
  },
  [7] = {
    [1] = { -- Shaman, Elemental
      {4, 3}, -- Mail
      {4, 6}, -- Shields
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 13}, --Fist Weapons
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 10}, -- Staves
    },
    [2] = { -- Shaman, Enhancement
      {2, 15}, -- Daggers
      {2, 13}, --Fist Weapons
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
    },
    [3] = { -- Shaman, Restoration
      {4, 3}, -- Mail
      {4, 6}, -- Shields
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 13}, --Fist Weapons
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
    },
  },
  [8] = {
    [1] = { -- Mage, Arcane
      {4, 1}, -- Cloth
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 7}, -- One-Handed Swords
      {2, 10}, -- Staves
    },
    [2] = { -- Mage, Fire
      {4, 1}, -- Cloth
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 7}, -- One-Handed Swords
      {2, 10}, -- Staves
    },
    [3] = { -- Mage, Frost
      {4, 1}, -- Cloth
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 7}, -- One-Handed Swords
      {2, 10}, -- Staves
    },
  },
  [9] = {
    [1] = { -- Warlock, Affliction
      {4, 1}, -- Cloth
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 7}, -- One-Handed Swords
      {2, 10}, -- Staves
    },
    [2] = { -- Warlock, Demonology
      {4, 1}, -- Cloth
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 7}, -- One-Handed Swords
      {2, 10}, -- Staves
    },
    [3] = { -- Warlock, Destruction
      {4, 1}, -- Cloth
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 7}, -- 1h sword
      {2, 15}, -- daggers
      {2, 10}, -- staves
    },
  },
  [10] = {
    [1] = { -- Monk, Brewmaster
      {4, 2}, -- Leather
      {2, 13}, -- fist
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 7}, -- One-Handed Swords
      {2, 6}, -- Polearms
      {2, 10}, -- Staves
    },
    [2] = { -- Monk, Mistweaver
      {4, 2}, -- Leather
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 13}, -- fist
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 7}, -- One-Handed Swords
      {2, 6}, -- Polearms
      {2, 10}, -- Staves
    },
    [3] = { -- Monk, Windwalker
      {4, 2}, -- Leather
      {2, 13}, -- fist
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 7}, -- One-Handed Swords
      {2, 6}, -- Polearms
      {2, 10}, -- Staves
    },
  },
  [11] = {
    [1] = { -- Druid, Balance
      {4, 2}, -- Leather
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 13}, -- Fist Weapons
      {2, 4}, -- One-Handed Maces
      {2, 6}, -- Polearms
      {2, 10}, -- Staves
      {2, 5}, -- Two-Handed Maces
    },
    [2] = { -- Druid, Feral
      {4, 2}, -- Leather
      {2, 15}, -- Daggers
      {2, 13}, -- Fist Weapons
      {2, 4}, -- One-Handed Maces
      {2, 6}, -- Polearms
      {2, 10}, -- Staves
      {2, 5}, -- Two-Handed Maces
      {2, 12}, -- cat claws
    },
    [3] = { -- Druid, Guardian
      {4, 2}, -- Leather
      {2, 6}, -- Polearms
      {2, 10}, -- Staves
      {2, 5}, -- Two-Handed Maces
      {2, 11}, -- bear claws
    },
    [4] = { -- Druid, Restoration
      {4, 2}, -- Leather
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 13}, -- Fist Weapons
      {2, 4}, -- One-Handed Maces
      {2, 6}, -- Polearms
      {2, 10}, -- Staves
      {2, 5}, -- Two-Handed Maces
    },
  },
  [12] = {
    [1] = { -- Demon Hunter, Havoc
      {4, 2}, -- Leather
      {2, 0}, -- 1h axe
      {2, 7}, -- 1h sword
      {2, 9}, -- glaive
      {2, 15}, -- dagger
      {2, 13}, -- fist
    },
    [2] = { -- Demon Hunter, Vengeance
      {4, 2}, -- Leather
      {2, 0}, -- 1h axe
      {2, 7}, -- 1h sword
      {2, 9}, -- glaive
      {2, 15}, -- dagger
      {2, 13}, -- fist
    },
  },
  [13] = {
    [1] = { -- Evoker, Devastation
      {4, 3}, -- Mail
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 13}, -- Fist Weapons
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 7}, -- One-Handed Swords
      {2, 10}, -- Staves
    },
    [2] = { -- Evoker, Preservation
      {4, 3}, -- Mail
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 13}, -- Fist Weapons
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 7}, -- One-Handed Swords
      {2, 10}, -- Staves
    },
    [3] = { -- Evoker, Augmentation
      {4, 3}, -- Mail
      {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
      {2, 15}, -- Daggers
      {2, 13}, -- Fist Weapons
      {2, 0}, -- One-Handed Axes
      {2, 4}, -- One-Handed Maces
      {2, 7}, -- One-Handed Swords
      {2, 10}, -- Staves
    }
  }
}

Syndicator.Search.Constants.ClassGear = {}

local currentClass = select(3, UnitClass("player"))

Syndicator.Search.Constants.ClassGear = {}
local classDetails = ClassData[currentClass]
for spec, specDetails in pairs(classDetails) do
  Syndicator.Search.Constants.ClassGear[spec] = {}
  for _, typeDetails in ipairs(specDetails) do
    Syndicator.Search.Constants.ClassGear[typeDetails[1]] = Syndicator.Search.Constants.ClassGear[typeDetails[1]] or {}
    Syndicator.Search.Constants.ClassGear[typeDetails[1]][typeDetails[2]] = Syndicator.Search.Constants.ClassGear[typeDetails[1]][typeDetails[2]] or {}
    if typeDetails[3] then
      Syndicator.Search.Constants.ClassGear[typeDetails[1]][typeDetails[2]][typeDetails[3]] = true
    end
  end
end
