local function GetItemName(details)
  if details.itemName then
    return
  end

  if details.itemID == Syndicator.Constants.BattlePetCageID then
    local petID = details.itemLink:match("battlepet:(%d+)")
    details.itemName = C_PetJournal.GetPetInfoBySpeciesID(tonumber(petID))
  elseif C_Item.IsItemDataCachedByID(details.itemID) then
    details.itemName = C_Item.GetItemNameByID(details.itemLink) or C_Item.GetItemNameByID(details.itemID)
  end

  if not details.itemName then
    C_Item.RequestLoadItemDataByID(details.itemID)
  end
end

local function GetClassSubClass(details)
  if details.classID then
    return
  end

  if details.itemID == Syndicator.Constants.BattlePetCageID then
    local petID = details.itemLink:match("battlepet:(%d+)")
    local itemName, _, petType = C_PetJournal.GetPetInfoBySpeciesID(tonumber(petID))
    details.classID = Enum.ItemClass.Battlepet
    details.subClassID = petType - 1
  else
    local classID, subClassID = select(6, C_Item.GetItemInfoInstant(details.itemLink))
    if not classID then
      classID, subClassID = C_Item.GetItemInfoInstant(details.itemID)
    end
    details.classID = classID
    details.subClassID = subClassID
  end
end

local function PetCheck(details)
  return details.classID == Enum.ItemClass.Battlepet or (details.classID == Enum.ItemClass.Miscellaneous and details.subClassID == Enum.ItemMiscellaneousSubclass.CompanionPet)
end

local function ReagentCheck(details)
  return (select(17, C_Item.GetItemInfo(details.itemID)))
end

local function SetCheck(details)
  return details.setInfo ~= nil
end

local function EngravableCheck(details)
  return details.isEngravable
end

local function EngravedCheck(details)
  return details.engravingInfo ~= nil
end

local function BindOnEquipCheck(details)
  return not details.isBound and (Syndicator.Utilities.IsEquipment(details.itemLink) or details.classID == Enum.ItemClass.Container)
end

local function EquipmentCheck(details)
  GetClassSubClass(details)
  return details.classID == Enum.ItemClass.Armor or details.classID == Enum.ItemClass.Weapon
end

local function FoodCheck(details)
  return details.classID == Enum.ItemClass.Consumable and details.subClassID == 5
end

local function PotionCheck(details)
  return details.classID == Enum.ItemClass.Consumable and (details.subClassID == 1 or details.subClassID == 2)
end

local function CosmeticCheck(details)
  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return nil
  end
  details.isCosmetic = IsCosmeticItem(details.itemLink)
  return details.isCosmetic
end

local function GetQualityCheck(quality)
  return function(details)
    return details.quality == quality
  end
end

local function AxeCheck(details)
  return details.classID == Enum.ItemClass.Weapon and (details.subClassID == Enum.ItemWeaponSubclass.Axe2H or details.subClassID == Enum.ItemWeaponSubclass.Axe1H)
end

local function MaceCheck(details)
  return details.classID == Enum.ItemClass.Weapon and (details.subClassID == Enum.ItemWeaponSubclass.Mace2H or details.subClassID == Enum.ItemWeaponSubclass.Mace1H)
end

local function SwordCheck(details)
  return details.classID == Enum.ItemClass.Weapon and (details.subClassID == Enum.ItemWeaponSubclass.Sword2H or details.subClassID == Enum.ItemWeaponSubclass.Sword1H)
end

local function StaffCheck(details)
  return details.classID == Enum.ItemClass.Weapon and (details.subClassID == Enum.ItemWeaponSubclass.Stave)
end

local function MountCheck(details)
  return details.classID == Enum.ItemClass.Miscellaneous and details.subClassID == Enum.ItemMiscellaneousSubclass.Mount
end

local function RelicCheck(details)
  return details.classID == Enum.ItemClass.Gem and details.subClassID == Enum.ItemGemSubclass.Artifactrelic
end

local function StackableCheck(details)
  details.isStackable = details.isStackable or C_Item.GetItemMaxStackSizeByID(details.itemID) > 1
  return details.isStackable
end

local function GetTooltipInfoSpell(details)
  if details.tooltipInfoSpell then
    return
  end

  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return
  end

  local _, spellID = C_Item.GetItemSpell(details.itemID)
  if spellID and not C_Spell.IsSpellDataCached(spellID) then
    C_Spell.RequestLoadSpellData(spellID)
    return
  end

  details.tooltipInfoSpell = details.tooltipGetter() or {lines={}}
end

local JUNK_PATTERN = "^" .. SELL_PRICE
local function JunkCheck(details)
  if details.isJunk ~= nil then
    return details.isJunk
  end

  if details.quality ~= Enum.ItemQuality.Poor then
    return false
  end

  GetTooltipInfoSpell(details)

  if details.tooltipInfoSpell then
    for _, row in ipairs(details.tooltipInfoSpell.lines) do
      if row.leftText:match(JUNK_PATTERN) then
        return false
      end
    end
    return true
  end
end

local function BindOnAccountCheck(details)
  if not details.isBound then
    return false
  end

  GetTooltipInfoSpell(details)

  if details.tooltipInfoSpell then
    for _, row in ipairs(details.tooltipInfoSpell.lines) do
      if tIndexOf(Syndicator.Constants.AccountBoundTooltipLines, row.leftText) ~= nil then
        return true
      end
    end
    return false
  end
end

local function BindOnUseCheck(details)
  if details.isBound then
    return false
  end

  if C_ToyBox and C_ToyBox.GetToyInfo(details.itemID) then
    return true
  end

  GetTooltipInfoSpell(details)

  if details.tooltipInfoSpell then
    for _, row in ipairs(details.tooltipInfoSpell.lines) do
      if row.leftText == ITEM_BIND_ON_USE then
        return true
      end
    end
    return false
  end
end

local function SoulboundCheck(details)
  if not details.isBound then
    return false
  end

  local bindOnAccount = BindOnAccountCheck(details)

  if bindOnAccount == nil then
    return
  else
    return not bindOnAccount
  end
end

local function UseCheck(details)
  GetTooltipInfoSpell(details)

  local usableSeen = false
  if details.tooltipInfoSpell then
    for _, row in ipairs(details.tooltipInfoSpell.lines) do
      if row.leftColor.r == 0 and row.leftColor.g == 1 and row.leftColor.b == 0 and row.leftText:match("^" .. USE_COLON) then
        usableSeen = true
      elseif row.leftColor.r == 1 and row.leftColor.g < 0.5 and row.leftColor.b < 0.5 then
        return false
      end
    end
    return usableSeen
  end
end

local function OpenCheck(details)
  if not details.itemLink:find("item:", nil, true) then
    return false
  end

  GetTooltipInfoSpell(details)

  if details.tooltipInfoSpell then
    for _, row in ipairs(details.tooltipInfoSpell.lines) do
      if row.leftText == ITEM_OPENABLE then
        return true
      end
    end
    return false
  end
end

--[[local function ManuscriptCheck(details)
  GetTooltipInfoSpell(details)

  if details.tooltipInfoSpell then
    for _, row in ipairs(details.tooltipInfoSpell.lines) do
      if row.leftText:lower():find(SYNDICATOR_L_KEYWORD_MANUSCRIPT, nil, true) then
        return true
      end
    end
    return false
  end
end]]

local GetItemStats = C_Item.GetItemStats or GetItemStats

local function SaveGearStats(details)
  if not Syndicator.Utilities.IsEquipment(details.itemLink) then
    details.itemStats = {}
    return
  end

  details.itemStats = GetItemStats(details.itemLink)
end

local function SocketCheck(details)
  SaveGearStats(details)
  if not details.itemStats then
    return nil
  end
  for key in pairs(details.itemStats) do
    if key:find("EMPTY_SOCKET", nil, true) then
      return true
    end
  end
  return false
end

local function ToyCheck(details)
  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return nil
  end

  return C_ToyBox.GetToyInfo(details.itemID) ~= nil
end

local TRADEABLE_LOOT_PATTERN = BIND_TRADE_TIME_REMAINING:gsub("([^%w])", "%%%1"):gsub("%%%%s", ".*")

local function IsTradeableLoot(details)
  if not details.isBound then
    return false
  end

  GetTooltipInfoSpell(details)

  if not details.tooltipInfoSpell then
    return
  end

  for _, row in ipairs(details.tooltipInfoSpell.lines) do
    if row.leftText:match(TRADEABLE_LOOT_PATTERN) then
      return true
    end
  end
  return false
end

local KEYWORDS_TO_CHECK = {
  [SYNDICATOR_L_KEYWORD_PET] = PetCheck,
  [SYNDICATOR_L_KEYWORD_BATTLE_PET] = PetCheck,
  [SYNDICATOR_L_KEYWORD_SOULBOUND] = SoulboundCheck,
  [SYNDICATOR_L_KEYWORD_BOP] = SoulboundCheck,
  [SYNDICATOR_L_KEYWORD_BOE] = BindOnEquipCheck,
  [SYNDICATOR_L_KEYWORD_BOU] = BindOnUseCheck,
  [SYNDICATOR_L_KEYWORD_EQUIPMENT] = EquipmentCheck,
  [SYNDICATOR_L_KEYWORD_GEAR] = EquipmentCheck,
  [SYNDICATOR_L_KEYWORD_AXE] = AxeCheck,
  [SYNDICATOR_L_KEYWORD_MACE] = MaceCheck,
  [SYNDICATOR_L_KEYWORD_SWORD] = SwordCheck,
  [SYNDICATOR_L_KEYWORD_STAFF] = StaffCheck,
  [SYNDICATOR_L_KEYWORD_REAGENT] = ReagentCheck,
  [SYNDICATOR_L_KEYWORD_FOOD] = FoodCheck,
  [SYNDICATOR_L_KEYWORD_DRINK] = FoodCheck,
  [SYNDICATOR_L_KEYWORD_POTION] = PotionCheck,
  [SYNDICATOR_L_KEYWORD_SET] = SetCheck,
  [SYNDICATOR_L_KEYWORD_ENGRAVABLE] = EngravableCheck,
  [SYNDICATOR_L_KEYWORD_ENGRAVED] = EngravedCheck,
  [SYNDICATOR_L_KEYWORD_SOCKET] = SocketCheck,
  [SYNDICATOR_L_KEYWORD_JUNK] = JunkCheck,
  [SYNDICATOR_L_KEYWORD_TRASH] = JunkCheck,
  --[SYNDICATOR_L_KEYWORD_REPUTATION] = ReputationCheck,
  [SYNDICATOR_L_KEYWORD_BOA] = BindOnAccountCheck,
  [SYNDICATOR_L_KEYWORD_ACCOUNT_BOUND] = BindOnAccountCheck,
  [SYNDICATOR_L_KEYWORD_USE] = UseCheck,
  [SYNDICATOR_L_KEYWORD_OPEN] = OpenCheck,
  [MOUNT:lower()] = MountCheck,
  [SYNDICATOR_L_KEYWORD_TRADEABLE_LOOT] = IsTradeableLoot,
  [SYNDICATOR_L_KEYWORD_TRADABLE_LOOT] = IsTradeableLoot,
  [SYNDICATOR_L_KEYWORD_RELIC] = RelicCheck,
  [SYNDICATOR_L_KEYWORD_STACKS] = StackableCheck,
  [SYNDICATOR_L_KEYWORD_STACKABLE] = StackableCheck,
}

if Syndicator.Constants.IsRetail then
  KEYWORDS_TO_CHECK[SYNDICATOR_L_KEYWORD_COSMETIC] = CosmeticCheck
  --KEYWORDS_TO_CHECK[SYNDICATOR_L_KEYWORD_MANUSCRIPT] = ManuscriptCheck
  KEYWORDS_TO_CHECK[TOY:lower()] = ToyCheck
end

local function AddKeyword(keyword, check)
  local old = KEYWORDS_TO_CHECK[keyword]
  if old then
    KEYWORDS_TO_CHECK[keyword] = function(...) return old(...) or check(...) end
  else
    KEYWORDS_TO_CHECK[keyword] = check
  end
end

local function PetCollectedCheck(details)
  local speciesID
  if details.itemID == Syndicator.Constants.BattlePetCageID then
    speciesID = tonumber((details.itemLink:match("battlepet:(%d+)")))
  elseif C_PetJournal.GetPetInfoByItemID(details.itemID) ~= nil then
    speciesID = select(13, C_PetJournal.GetPetInfoByItemID(details.itemID))
  end
  if speciesID then
    return C_PetJournal.GetNumCollectedInfo(speciesID) == 0
  else
    return false
  end
end

local sockets = {
  "EMPTY_SOCKET_BLUE",
  "EMPTY_SOCKET_COGWHEEL",
  "EMPTY_SOCKET_CYPHER",
  "EMPTY_SOCKET_DOMINATION",
  "EMPTY_SOCKET_HYDRAULIC",
  "EMPTY_SOCKET_META",
  "EMPTY_SOCKET_NO_COLOR",
  "EMPTY_SOCKET_PRIMORDIAL",
  "EMPTY_SOCKET_PRISMATIC",
  "EMPTY_SOCKET_PUNCHCARDBLUE",
  "EMPTY_SOCKET_PUNCHCARDRED",
  "EMPTY_SOCKET_PUNCHCARDYELLOW",
  "EMPTY_SOCKET_RED",
  "EMPTY_SOCKET_TINKER",
  "EMPTY_SOCKET_YELLOW",
}

for _, key in ipairs(sockets) do
  local global = _G[key]
  if global then
    AddKeyword(global:lower(), function(details)
      SaveGearStats(details)
      if details.itemStats then
        return details.itemStats[key] ~= nil
      end
      return nil
    end)
  end
end

local inventorySlots = {
  "INVTYPE_HEAD",
  "INVTYPE_NECK",
  "INVTYPE_SHOULDER",
  "INVTYPE_BODY",
  "INVTYPE_WAIST",
  "INVTYPE_LEGS",
  "INVTYPE_FEET",
  "INVTYPE_WRIST",
  "INVTYPE_HAND",
  "INVTYPE_FINGER",
  "INVTYPE_TRINKET",
  "INVTYPE_WEAPON",
  "INVTYPE_RANGED",
  "INVTYPE_CLOAK",
  "INVTYPE_2HWEAPON",
  "INVTYPE_BAG",
  "INVTYPE_TABARD",
  "INVTYPE_WEAPONMAINHAND",
  "INVTYPE_WEAPONOFFHAND",
  "INVTYPE_HOLDABLE",
  "INVTYPE_AMMO",
  "INVTYPE_THROWN",
  "INVTYPE_RANGEDRIGHT",
  "INVTYPE_QUIVER",
  "INVTYPE_RELIC",
  "INVTYPE_PROFESSION_TOOL",
  "INVTYPE_PROFESSION_GEAR",
  "INVTYPE_CHEST",
  "INVTYPE_ROBE",
}

local function GetInvType(details)
  if details.invType then
    return
  end
  details.invType = (select(4, C_Item.GetItemInfoInstant(details.itemID))) or "NONE"
end

for _, slot in ipairs(inventorySlots) do
  local text = _G[slot]
  if text ~= nil then
    AddKeyword(text:lower(),  function(details) GetInvType(details) return details.invType == slot end)
  end
end

do
  AddKeyword(SYNDICATOR_L_KEYWORD_OFF_HAND, function(details)
    GetInvType(details)
    return details.invType == "INVTYPE_HOLDABLE" or details.invType == "INVTYPE_SHIELD"
  end)
end

local moreSlotMappings = {
  [SYNDICATOR_L_KEYWORD_HELM] = "INVTYPE_HEAD",
  [SYNDICATOR_L_KEYWORD_CLOAK] = "INVTYPE_CLOAK",
  [SYNDICATOR_L_KEYWORD_BRACERS] = "INVTYPE_WRIST",
  [SYNDICATOR_L_KEYWORD_GLOVES] = "INVTYPE_HAND",
  [SYNDICATOR_L_KEYWORD_BELT] = "INVTYPE_WAIST",
  [SYNDICATOR_L_KEYWORD_BOOTS] = "INVTYPE_FEET",
}

for keyword, slot in pairs(moreSlotMappings) do
  AddKeyword(keyword, function(details) GetInvType(details) return details.invType == slot end)
end

if Syndicator.Constants.IsRetail then
  AddKeyword(SYNDICATOR_L_KEYWORD_AZERITE, function(details)
    return C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(details.itemID)
  end)
end

local TextToExpansion = {
  ["classic"] = 0,
  ["vanilla"] = 0,
  ["bc"] = 1,
  ["burning crusade"] = 1,
  ["tbc"] = 1,
  ["wrath"] = 2,
  ["wotlk"] = 2,
  ["cataclysm"] = 3,
  ["mop"] = 4,
  ["mists of pandaria"] = 4,
  ["wod"] = 5,
  ["draenor"] = 5,
  ["legion"] = 6,
  ["bfa"] = 7,
  ["battle for azeroth"] = 7,
  ["sl"] = 8,
  ["shadowlands"] = 8,
  ["df"] = 9,
  ["dragonflight"] = 9,
}

for key, quality in pairs(Enum.ItemQuality) do
  local term = _G["ITEM_QUALITY" .. quality .. "_DESC"]
  if term then
    AddKeyword(term:lower(), function(details) return details.quality == quality end)
  end
end

if Syndicator.Constants.IsRetail then
  function Syndicator.Search.GetExpansion(details)
    if details.itemID == Syndicator.Constants.BattlePetCageID then
      return -1
    end

    if ItemVersion then
      local itemVersionDetails = ItemVersion.API:getItemVersion(details.itemID, true)
      if itemVersionDetails then
        return itemVersionDetails.major - 1
      end
    end
    return (select(15, C_Item.GetItemInfo(details.itemID)))
  end
  for key, expansionID in pairs(TextToExpansion) do
    AddKeyword(key, function(details)
      details.expacID = details.expacID or Syndicator.Search.GetExpansion(details)
      return details.expacID and details.expacID == expansionID
    end)
  end
end

local BAG_TYPES = {
  [SYNDICATOR_L_KEYWORD_SOUL] = 12,
  [SYNDICATOR_L_KEYWORD_ENCHANTING] = 7,
  [SYNDICATOR_L_KEYWORD_ENGINEERING] = 8,
  [SYNDICATOR_L_KEYWORD_MINING] = 11,
  [SYNDICATOR_L_KEYWORD_INSCRIPTION] = 5,
  [SYNDICATOR_L_KEYWORD_FISHING] = 16,
  [SYNDICATOR_L_KEYWORD_COOKING] = 17,
  [SYNDICATOR_L_KEYWORD_JEWELCRAFTING] = 25,
}

for keyword, bagBit in pairs(BAG_TYPES) do
  local bagFamily = bit.lshift(1, bagBit - 1)
  AddKeyword(keyword, function(details)
    local itemFamily = C_Item.GetItemFamily(details.itemID)
    if itemFamily == nil then
      return
    else
      return bit.band(bagFamily, itemFamily) ~= 0
    end
  end)
end

local function GetGearStatCheck(statKey)
  return function(details)
    SaveGearStats(details)
    if not details.itemStats then
      return
    end

    for key, value in pairs(details.itemStats) do
      if key:find(statKey, nil, true) ~= nil then
        return true
      end
    end
    return false
  end
end

local function GetGemStatCheck(statKey)
  local PATTERN1 = "%+" .. statKey -- Retail remix gems
  local PATTERN2 = "%+%d+ " .. statKey -- Normal gems
  return function(details)
    GetClassSubClass(details)

    if not details.classID == Enum.ItemClass.Gem then
      return false
    end

    GetTooltipInfoSpell(details)

    if details.tooltipInfoSpell then
      for _, line in ipairs(details.tooltipInfoSpell.lines) do
        if line.leftText:match(PATTERN1) or line.leftText:match(PATTERN2) then
          return true
        end
      end
      return false
    end
  end
end

-- Based off of GlobalStrings.db2
local stats = {
  "AGILITY",
  "ATTACK_POWER",
  "BLOCK_RATING",
  "CORRUPTION",
  "CRAFTING_SPEED",
  "CR_AVOIDANCE",
  "CRIT_MELEE_RATING",
  "CRIT_RANGED_RATING",
  "CRIT_RATING",
  "CRIT_SPELL_RATING",
  "CRIT_TAKEN_RATING",
  "CR_LIFESTEAL",
  "CR_MULTISTRIKE",
  "CR_SPEED",
  "CR_STURDINESS",
  "DAMAGE_PER_SECOND",
  "DEFENSE_SKILL_RATING",
  "DEFTNESS",
  "DODGE_RATING",
  "EXTRA_ARMOR",
  "FINESSE",
  "HASTE_RATING",
  "HEALTH_REGENERATION",
  "HIT_MELEE_RATING",
  "HIT_RANGED_RATING",
  "HIT_SPELL_RATING",
  "HIT_RATING",
  "HIT_TAKEN_RATING",
  "INTELLECT",
  "MANA_REGENERATION",
  "MANA",
  "MASTERY_RATING",
  "MULTICRAFT",
  "PARRY_RATING",
  "PERCEPTION",
  "PVP_POWER",
  "RANGED_ATTACK_POWER",
  "RESILIENCE_RATING",
  "RESOURCEFULNESS",
  "SPELL_DAMAGE_DONE",
  "SPELL_HEALING_DONE",
  "SPELL_PENETRATION",
  "SPELL_POWER",
  "SPIRIT",
  "STAMINA",
  "STRENGTH",
  "VERSATILITY",
}

for _, s in ipairs(stats) do
  local keyword = _G["ITEM_MOD_" .. s .. "_SHORT"] or _G["ITEM_MOD_" .. s]
  if keyword ~= nil then
    AddKeyword(keyword:lower(), GetGearStatCheck(s))
    AddKeyword(keyword:lower(), GetGemStatCheck(keyword))
  end
end
AddKeyword(STAT_ARMOR:lower(), GetGemStatCheck(STAT_ARMOR))

-- Sorted in initialize function later
local sortedKeywords = {}

local function BinarySmartSearch(text)
  local startIndex, endIndex = 1, #sortedKeywords
  local middle
  while startIndex < endIndex do
    local middleIndex = math.floor((endIndex + startIndex)/2)
    middle = sortedKeywords[middleIndex]
    if middle < text then
      startIndex = middleIndex + 1
    else
      endIndex = middleIndex
    end
  end

  local allKeywords = {}
  while startIndex <= #sortedKeywords and sortedKeywords[startIndex]:sub(1, #text) == text do
    table.insert(allKeywords, sortedKeywords[startIndex])
    startIndex = startIndex + 1
  end
  return allKeywords
end

local GetItemLevel

if Syndicator.Constants.IsRetail then
  -- On retail a lot of items have item levels that aren't gear so tooltip scans
  -- are used.
  local ITEM_LEVEL_PATTERN = ITEM_LEVEL:gsub("%%d", "(%%d+)")
  GetItemLevel = function(details)
    if details.itemID == Syndicator.Constants.BattlePetCageID then
      if details.itemLevel then
        return
      end

      local _, level = details.itemLink:match("battlepet:(%d+):(%d*)")

      if level and level ~= "" then
        details.itemLevel = tonumber(level)
      end
    end

    GetTooltipInfoSpell(details)

    if not details.tooltipInfoSpell then
      return
    end

    if details.itemLevel then
      return details.itemLevel ~= -1
    end

    for _, line in ipairs(details.tooltipInfoSpell.lines) do
      local level = line.leftText:match(ITEM_LEVEL_PATTERN)
      if level then
        details.itemLevel = tonumber(level)
        return true
      end
    end

    -- Set something so that the tooltip scan doesn't repeat on later searches on
    -- items without an item level
    details.itemLevel = -1

    return false
  end
else
  local function HasItemLevel(details)
    return details.classID == Enum.ItemClass.Armor or details.classID == Enum.ItemClass.Weapon
  end

  GetItemLevel = function(details)
    GetClassSubClass(details)

    if not HasItemLevel(details) then
      return false
    end

    details.itemLevel = details.itemLevel or C_Item.GetDetailedItemLevelInfo(details.itemLink)
  end
end

local function ItemLevelPatternCheck(details, text)
  if GetItemLevel(details) == false then
    return false
  end

  local wantedItemLevel = tonumber(text)
  return details.itemLevel and details.itemLevel == wantedItemLevel
end

local function ExactItemLevelPatternCheck(details, text)
  return ItemLevelPatternCheck(details, (text:match("%d+")))
end

local function ItemLevelRangePatternCheck(details, text)
  if GetItemLevel(details) == false then
    return false
  end

  local minText, maxText = text:match("(%d+)%-(%d+)")
  return details.itemLevel and details.itemLevel >= tonumber(minText) and details.itemLevel <= tonumber(maxText)
end

local function ItemLevelMinPatternCheck(details, text)
  if GetItemLevel(details) == false then
    return false
  end

  local minText = text:match("%d+")
  return details.itemLevel and details.itemLevel <= tonumber(minText)
end

local function ItemLevelMaxPatternCheck(details, text)
  if GetItemLevel(details) == false then
    return false
  end

  local maxText = text:match("%d+")
  return details.itemLevel and details.itemLevel >= tonumber(maxText)
end

local patterns = {
  ["^%d+$"] = ItemLevelPatternCheck,
  ["^=%d+$"] = ExactItemLevelPatternCheck,
  ["^%d+%-%d+$"] = ItemLevelRangePatternCheck,
  ["^%>%d+$"] = ItemLevelMaxPatternCheck,
  ["^%<%d+$"] = ItemLevelMinPatternCheck,
}

-- Used to prevent equipment and use returning results based on partial words in
-- tooltip data
local EXCLUSIVE_KEYWORDS_NO_TOOLTIP_TEXT = {
  [SYNDICATOR_L_KEYWORD_USE] = true,
  [SYNDICATOR_L_KEYWORD_EQUIPMENT] = true,
}

local UPGRADE_PATH_PATTERN = ITEM_UPGRADE_TOOLTIP_FORMAT_STRING and "^" .. ITEM_UPGRADE_TOOLTIP_FORMAT_STRING:gsub("%%s", ".*"):gsub("%%d", ".*")

local function GetTooltipSpecialTerms(details)
  if details.searchKeywords then
    return
  end

  GetTooltipInfoSpell(details)
  GetClassSubClass(details)
  GetItemName(details)

  if not details.tooltipInfoSpell or not details.classID or not details.itemName then
    return
  end

  details.searchKeywords = {details.itemName:lower()}

  for _, line in ipairs(details.tooltipInfoSpell.lines) do
    local term = line.leftText:match("^|cFF......(.*)|r$")
    if term then
      table.insert(details.searchKeywords, term:lower())
    else
      local match = line.leftText:match("^" .. USE_COLON) or line.leftText:match("^" .. ITEM_SPELL_TRIGGER_ONEQUIP) or (UPGRADE_PATH_PATTERN and line.leftText:match(UPGRADE_PATH_PATTERN))
      if details.classID ~= Enum.ItemClass.Recipe and match then
        table.insert(details.searchKeywords, line.leftText:lower())
      end
    end
  end

  if details.setInfo then
    for _, info in ipairs(details.setInfo) do
      if type(info.name) == "string" then
        table.insert(details.searchKeywords, info.name:lower())
      end
    end
  end
end

local function MatchesText(details, searchString)
  GetTooltipSpecialTerms(details)

  if not details.searchKeywords then
    return nil
  end

  for _, term in ipairs(details.searchKeywords) do
    if term:find(searchString, nil, true) ~= nil then
      return true
    end
  end
  return false
end

local function MatchesTextExclusive(details, searchString)
  GetItemName(details)

  if not details.itemName then
    return
  end

  if details.itemNameLower == nil then
    details.itemNameLower = details.itemName:lower()
  end

  return details.itemNameLower:find(searchString, nil, true) ~= nil
end

local function PatternSearch(searchString)
  for pat, check in pairs(patterns) do
    if searchString:match(pat) then
      return function(...)
        return MatchesTextExclusive(...) or check(...)
      end
    end
  end
end

-- Previously found search terms checks by keyword or pattern
local matches = {}
-- Search terms with no keyword or pattern match
local rejects = {}

-- Each keyword/pattern check function returns nil if the data needed to
-- complete the check doesn't exist yet. Then the item will be queued for
-- checking again on a later frame. If the data is available either true or
-- false is returned.
local function ApplyKeyword(searchString)
  local check = matches[searchString]
  if check then
    return check
  elseif not rejects[searchString] then
    local keywords = BinarySmartSearch(searchString)
    if #keywords > 0 then
      local matchesTextToUse = MatchesText
      for _, k in ipairs(keywords) do
        if EXCLUSIVE_KEYWORDS_NO_TOOLTIP_TEXT[k] then
          matchesTextToUse = MatchesTextExclusive
          break
        end
      end
      -- Work through each keyword that matches the search string and check if
      -- the details match the keyword's criteria
      local check = function(details)
        local matches = matchesTextToUse(details, searchString)
        if matches == nil then
          return nil
        elseif matches then
          return true
        end
        -- Cache results for each keyword to speed up continuing searches
        if not details.matchInfo then
          details.matchInfo = {}
        end
        local miss = false
        for _, k in ipairs(keywords) do
          if details.matchInfo[k] == nil then
            -- Keyword results not cached yet
            local result = KEYWORDS_TO_CHECK[k](details, searchString)
            if result then
              details.matchInfo[k] = true
              return true
            elseif result ~= nil then
              details.matchInfo[k] = false
            else
              miss = true
            end
          elseif details.matchInfo[k] then
            -- got a positive result cached, we're done
            return true
          end
        end
        if miss then
          return nil
        else
          return false
        end
      end
      matches[searchString] = check
      return check
    end

    -- See if a pattern matches, e.g. item level range
    local patternChecker = PatternSearch(searchString)
    if patternChecker then
      matches[searchString] = patternChecker
      return function(details)
        return patternChecker(details, searchString)
      end
    end

    -- Couldn't find anything that matched
    rejects[searchString] = true
  end
  return MatchesText
end

local function ApplyCombinedTerms(fullSearchString)
  if fullSearchString:match("[|]") then
    local checks = {}
    local checkPart = {}
    for part in fullSearchString:gmatch("[^|]+") do
      table.insert(checks, ApplyCombinedTerms(part))
      table.insert(checkPart, part)
    end
    return function(details)
      for index, check in ipairs(checks) do
        local result = check(details, checkPart[index])
        if result then
          return true
        elseif result == nil then
          return nil
        end
      end
      return false
    end
  elseif fullSearchString:match("[&]") then
    local checks = {}
    local checkPart = {}
    for part in fullSearchString:gmatch("[^&]+") do
      table.insert(checks, ApplyCombinedTerms(part))
      table.insert(checkPart, part)
    end
    return function(details)
      for index, check in ipairs(checks) do
        local result = check(details, checkPart[index])
        if result == false then
          return false
        elseif result == nil then
          return nil
        end
      end
      return true
    end
  elseif fullSearchString:match("^[~!]") then
    local newSearchString = fullSearchString:sub(2, #fullSearchString)
    local nested = ApplyCombinedTerms(newSearchString)
    return function(details)
      local result = nested(details, newSearchString)
      if result ~= nil then
        return not result
      end
      return nil
    end
  else
    return ApplyKeyword(fullSearchString)
  end
end

function Syndicator.Search.CheckItem(details, searchString)
  details.matchInfo = details.matchInfo or {}
  local result = details.matchInfo[searchString]
  if result ~= nil then
    return details.matchInfo[searchString]
  end

  local check = matches[searchString]
  if not check then
    check = ApplyCombinedTerms(searchString)
    matches[searchString] = check
  end

  result = check(details, searchString)
  details.matchInfo[searchString] = result
  return result
end

function Syndicator.Search.ClearCache()
  matches = {}
  rejects = {}
end

function Syndicator.Search.InitializeSearchEngine()
  for i = 0, Enum.ItemClassMeta.NumValues-1 do
    local name = C_Item.GetItemClassInfo(i)
    if name then
      local classID = i
      AddKeyword(name:lower(), function(details)
        return details.classID == classID
      end)
    end
  end

  local tradeGoodsToCheck = {
    5, -- cloth
    6, -- leather
    7, -- metal and stone
    8, -- cooking
    9, -- herb
    10, -- elemental
  }
  for _, subClass in ipairs(tradeGoodsToCheck) do
    local keyword = C_Item.GetItemSubClassInfo(7, subClass)
    if keyword ~= nil then
      AddKeyword(keyword:lower(), function(details)
        return details.classID == 7 and details.subClassID == subClass
      end)
    end
  end

  local armorTypesToCheck = {
    1, -- cloth
    2, -- leather
    3, -- mail
    4, -- plate
    6, -- shield
    7, -- libram
    8, -- idol
    9, -- totem
    10,-- sigil
    11,-- relic
  }
  for _, subClass in ipairs(armorTypesToCheck) do
    local keyword = C_Item.GetItemSubClassInfo(Enum.ItemClass.Armor, subClass)
    if keyword ~= nil then
      AddKeyword(keyword:lower(), function(details)
        return details.classID == Enum.ItemClass.Armor and details.subClassID == subClass
      end)
    end
  end

  -- All weapons + fishingpole
  for subClass = 0, 20 do
    local keyword = C_Item.GetItemSubClassInfo(Enum.ItemClass.Weapon, subClass)
    if keyword ~= nil then
      AddKeyword(keyword:lower(), function(details)
        return details.classID == Enum.ItemClass.Weapon and details.subClassID == subClass
      end)
    end
  end

  if C_PetJournal then
    for subClass = 0, 9 do
      local keyword = C_Item.GetItemSubClassInfo(Enum.ItemClass.Battlepet, subClass)
      if keyword ~= nil then
        AddKeyword(keyword:lower(), function(details)
          return details.classID == Enum.ItemClass.Battlepet and details.subClassID == subClass
        end)
      end
    end
  end

  Syndicator.Search.RebuildKeywordList()
end

function Syndicator.Search.RebuildKeywordList()
  for key in pairs(KEYWORDS_TO_CHECK) do
    table.insert(sortedKeywords, key)
  end
  table.sort(sortedKeywords)
end
