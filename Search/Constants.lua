Syndicator.Search.Constants = {}

local ClassData = {
  [1] = { -- Warrior
    {4, 4}, -- Plate
    {4, 6}, -- Shields
    {2, 0}, -- One-Handed Axes
    {2, 4}, -- One-Handed Maces
    {2, 7}, -- One-Handed Swords
    {2, 15}, -- Daggers
    {2, 13}, -- Fist Weapons
    {2, 1}, -- Two-Handed Axes
    {2, 5}, -- Two-Handed Maces
    {2, 8}, -- Two-Handed Swords
    {2, 6}, -- Polearms
    {2, 10}, -- Staves
  },
  [2] = { -- Paladin
    {4, 4}, -- Plate
    {4, 6}, -- Shields
    {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
    {2, 0}, -- One-Handed Axes
    {2, 4}, -- One-Handed Maces
    {2, 7}, -- One-Handed Swords
    {2, 1}, -- Two-Handed Axes
    {2, 5}, -- Two-Handed Maces
    {2, 8}, -- Two-Handed Swords
    {2, 6}, -- Polearms
  },
  [3] = { -- Hunter
    {4, 3}, -- Mail
    {2, 2}, -- Bows
    {2, 18}, -- Crossbows
    {2, 3}, -- Guns
    {2, 6}, -- Polearms
    {2, 10}, -- Staves
    {2, 8}, -- Two-Handed Swords
    {2, 1}, -- Two-Handed Axes
  },
  [4] = { -- Rogue
    {4, 2}, -- Leather
    {2, 15}, -- Daggers
    {2, 13}, --Fist Weapons
    {2, 0}, -- One-Handed Axes
    {2, 4}, -- One-Handed Maces
    {2, 7}, -- One-Handed Swords
  },
  [5] = { -- Priest
    {4, 1}, -- Cloth
    {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
    {2, 15}, -- Daggers
    {2, 4}, -- One-Handed Maces
    {2, 10}, -- Staves
  },
  [6] = { -- Death Knight
    {4, 4}, -- Plate
    {2, 0}, -- One-Handed Axes
    {2, 4}, -- One-Handed Maces
    {2, 7}, -- One-Handed Swords
    {2, 1}, -- Two-Handed Axes
    {2, 5}, -- Two-Handed Maces
    {2, 8}, -- Two-Handed Swords
    {2, 6}, -- Polearms
  },
  [7] = { -- Shaman
    {4, 3}, -- Mail
    {4, 6}, -- Shields
    {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
    {2, 0}, -- One-Handed Axes
    {2, 4}, -- One-Handed Maces
    {2, 15}, -- Daggers
    {2, 13}, --Fist Weapons
    {2, 10}, -- Staves
  },
  [8] = { -- Mage
    {4, 1}, -- Cloth
    {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
    {2, 15}, -- Daggers
    {2, 7}, -- One-Handed Swords
    {2, 10}, -- Staves
  },
  [9] = { -- Warlock
    {4, 1}, -- Cloth
    {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
    {2, 15}, -- Daggers
    {2, 7}, -- One-Handed Swords
    {2, 10}, -- Staves
  },
  [10] = { -- Monk
    {4, 2}, -- Leather
    {2, 13}, -- fist
    {2, 0}, -- One-Handed Axes
    {2, 4}, -- One-Handed Maces
    {2, 7}, -- One-Handed Swords
    {2, 6}, -- Polearms
    {2, 10}, -- Staves
    {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
  },
  [11] = { -- Druid
    {4, 2}, -- Leather
    {4, 0, "INVTYPE_HOLDABLE"}, -- off hand
    {2, 4}, -- One-Handed Maces
    {2, 15}, -- Daggers
    {2, 13}, -- Fist Weapons
    {2, 12}, -- Cat Claws
    {2, 11}, -- Bear Claws
    {2, 5}, -- Two-Handed Maces
    {2, 6}, -- Polearms
    {2, 10}, -- Staves
  },
  [12] = { -- Demon Hunter
    {4, 2}, -- Leather
    {2, 0}, -- One-Handed Axes
    {2, 7}, -- One-Handed Swords
    {2, 9}, -- Warglaives
    {2, 15}, -- Daggers
    {2, 13}, -- Fist Weapons
  },
  [13] = { -- Evoker
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

Syndicator.Search.Constants.ClassGear = {}

local currentClass = select(3, UnitClass("player"))

Syndicator.Search.Constants.ClassGear = {}
local classDetails = ClassData[currentClass]
for _, typeDetails in ipairs(classDetails) do
  Syndicator.Search.Constants.ClassGear[typeDetails[1]] = Syndicator.Search.Constants.ClassGear[typeDetails[1]] or {}
  Syndicator.Search.Constants.ClassGear[typeDetails[1]][typeDetails[2]] = Syndicator.Search.Constants.ClassGear[typeDetails[1]][typeDetails[2]] or {}
  if typeDetails[3] then
    Syndicator.Search.Constants.ClassGear[typeDetails[1]][typeDetails[2]][typeDetails[3]] = true
  end
end
