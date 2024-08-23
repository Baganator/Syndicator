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
    local classID, subClassID = select(6, C_Item.GetItemInfoInstant(details.itemID))
    details.classID = classID
    details.subClassID = subClassID
  end
end

local function PetCheck(details)
  GetClassSubClass(details)
  return details.classID == Enum.ItemClass.Battlepet or (details.classID == Enum.ItemClass.Miscellaneous and details.subClassID == Enum.ItemMiscellaneousSubclass.CompanionPet)
end

local ReagentCheck
if Syndicator.Constants.IsClassic then
  ReagentCheck = function(details)
    GetClassSubClass(details)
    -- Trade good that isn't an explosive or device
    return details.classID == 7 and details.subClassID ~= 2 and details.subClassID ~= 3
  end
else
  ReagentCheck = function(details)
    return (select(17, C_Item.GetItemInfo(details.itemID)))
  end
end

local function SetCheck(details)
  return details.setInfo ~= nil
end

local function EngravableCheck(details)
  return details.isEngravable == true
end

local function EngravedCheck(details)
  return details.engravingInfo ~= nil
end

local function EquipmentCheck(details)
  GetClassSubClass(details)
  return details.classID == Enum.ItemClass.Armor or details.classID == Enum.ItemClass.Weapon
end

local function FoodCheck(details)
  GetClassSubClass(details)
  return details.classID == Enum.ItemClass.Consumable and details.subClassID == 5
end

local function PotionCheck(details)
  GetClassSubClass(details)
  return details.classID == Enum.ItemClass.Consumable and (details.subClassID == 1 or details.subClassID == 2 or details.subClassID == 3)
end

local function CosmeticCheck(details)
  if not details.itemLink:match("item:") then
    return false
  end
  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return nil
  end
  details.isCosmetic = C_Item.IsCosmeticItem(details.itemLink)
  return details.isCosmetic
end

local function AxeCheck(details)
  GetClassSubClass(details)
  return details.classID == Enum.ItemClass.Weapon and (details.subClassID == Enum.ItemWeaponSubclass.Axe2H or details.subClassID == Enum.ItemWeaponSubclass.Axe1H)
end

local function MaceCheck(details)
  GetClassSubClass(details)
  return details.classID == Enum.ItemClass.Weapon and (details.subClassID == Enum.ItemWeaponSubclass.Mace2H or details.subClassID == Enum.ItemWeaponSubclass.Mace1H)
end

local function SwordCheck(details)
  GetClassSubClass(details)
  return details.classID == Enum.ItemClass.Weapon and (details.subClassID == Enum.ItemWeaponSubclass.Sword2H or details.subClassID == Enum.ItemWeaponSubclass.Sword1H)
end

local function StaffCheck(details)
  GetClassSubClass(details)
  return details.classID == Enum.ItemClass.Weapon and (details.subClassID == Enum.ItemWeaponSubclass.Stave)
end

local function MountCheck(details)
  GetClassSubClass(details)
  return details.classID == Enum.ItemClass.Miscellaneous and details.subClassID == Enum.ItemMiscellaneousSubclass.Mount
end

local function RelicCheck(details)
  GetClassSubClass(details)
  return details.classID == Enum.ItemClass.Gem and details.subClassID == Enum.ItemGemSubclass.Artifactrelic
end

local function StackableCheck(details)
  if details.isStackable ~= nil then
    return details.isStackable
  end

  local stackCount = C_Item.GetItemMaxStackSizeByID(details.itemID)
  if stackCount ~= nil then
    details.isStackable = stackCount > 1
  end
  return details.isStackable
end

local function SocketedCheck(details)
  local gem1, gem2, gem3, gem4 = details.itemLink:match("item:%d+:[^:]*:(%d*):(%d*):(%d*):(%d*):")
  if tonumber(gem1) or tonumber(gem2) or tonumber(gem3) or tonumber(gem4) then
    return true
  else
    return false
  end
end

local function GetSourceID(itemLink)
  local _, sourceID = C_TransmogCollection.GetItemInfo(itemLink)
  if sourceID then
    return sourceID
  end
  local _, sourceID = C_TransmogCollection.GetItemInfo((C_Item.GetItemInfoInstant(itemLink)))
  return sourceID
end

local function IsTMogCollectedCompletionist(itemLink)
  local sourceID = GetSourceID(itemLink)
  if not sourceID then
    return nil
  else
    return C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance(sourceID)
  end
end

local function IsTMogCollectedUnique(itemLink)
  local sourceID = GetSourceID(itemLink)
  if not sourceID then
    return
  else
    local subClass = select(7, C_Item.GetItemInfoInstant(itemLink))
    local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
    local allSources = C_TransmogCollection.GetAllAppearanceSources(sourceInfo.visualID)
    if #allSources == 0 then
      allSources = {sourceID}
    end
    local anyCollected = false
    for _, alternateSourceID in ipairs(allSources) do
      local altInfo = C_TransmogCollection.GetSourceInfo(alternateSourceID)
      local altSubClass = select(7, C_Item.GetItemInfoInstant(altInfo.itemID))
      if altInfo.isCollected and altSubClass == subClass then
        anyCollected = true
        break
      end
    end
    return anyCollected
  end
end

local function IsPetCollected(itemLink)
  local speciesID = tonumber((itemLink:match("battlepet:(%d+)")))
  local numCollected = C_PetJournal.GetNumCollectedInfo(speciesID)
  return numCollected > 0
end

local function IsToyCollected(itemID)
  local hasToy = PlayerHasToy(itemID)
  return hasToy
end

local function IsMountCollected(itemID)
  local mountID = C_MountJournal.GetMountFromItem(itemID)
  if mountID then
    return (select(11, C_MountJournal.GetMountInfoByID(mountID)))
  end
end

local function CollectedCheck(details)
  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return nil
  end

  local result = nil

  if C_TransmogCollection and Syndicator.Utilities.IsEquipment(details.itemLink) then
    if ATTC and ATTC.Settings and ATTC.Settings.Get and ATTC.Settings:Get("Completionist") then
      result = IsTMogCollectedCompletionist(details.itemLink)
    else
      result = IsTMogCollectedUnique(details.itemLink)
    end
  end
  if C_PetJournal and details.itemID == Syndicator.Constants.BattlePetCageID then
    result = IsPetCollected(details.itemLink)
  end
  if C_ToyBox and C_ToyBox.GetToyInfo(details.itemID) ~= nil then
    result = IsToyCollected(details.itemID)
  end
  if C_MountJournal and C_MountJournal.GetMountFromItem(details.itemID) then
    result = IsMountCollected(details.itemID)
  end

  return result or false, result == false
end

local function UncollectedCheck(details)
  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return nil
  end

  local result = nil

  if C_TransmogCollection and Syndicator.Utilities.IsEquipment(details.itemLink) then
    if ATTC and ATTC.Settings and ATTC.Settings.Get and ATTC.Settings:Get("Completionist") then
      result = IsTMogCollectedCompletionist(details.itemLink)
    else
      result = IsTMogCollectedUnique(details.itemLink)
    end
  end
  if C_PetJournal and details.itemID == Syndicator.Constants.BattlePetCageID then
    result = IsPetCollected(details.itemLink)
  end
  if C_ToyBox and C_ToyBox.GetToyInfo(details.itemID) ~= nil then
    result = IsToyCollected(details.itemID)
  end
  if C_MountJournal and C_MountJournal.GetMountFromItem(details.itemID) then
    result = IsMountCollected(details.itemID)
  end

  if result ~= nil then
    result = not result
  end

  return result or false, result == true
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

local function BindOnEquipCheck(details)
  if details.isBound or (not Syndicator.Utilities.IsEquipment(details.itemLink) and details.classID ~= Enum.ItemClass.Container) then
    return false
  end

  GetTooltipInfoSpell(details)

  if details.tooltipInfoSpell then
    for _, row in ipairs(details.tooltipInfoSpell.lines) do
      if row.leftText == ITEM_BIND_ON_EQUIP then
        return true
      end
    end
    return false
  end
end

local function BindOnAccountCheck(details)
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

local function WarboundUntilEquippedCheck(details)
  GetTooltipInfoSpell(details)

  if details.tooltipInfoSpell then
    for _, row in ipairs(details.tooltipInfoSpell.lines) do
      if row.leftText == ITEM_ACCOUNTBOUND_UNTIL_EQUIP then
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
      if row.leftColor.r == 0 and row.leftColor.g == 1 and row.leftColor.b == 0 and row.leftText:match("^" .. ITEM_SPELL_TRIGGER_ONUSE) then
        usableSeen = true
      elseif row.leftColor.r == 1 and row.leftColor.g < 0.2 and row.leftColor.b < 0.2 then
        return false
      end
    end
    return usableSeen
  end
end

local function UsableCheck(details)
  GetTooltipInfoSpell(details)

  if details.tooltipInfoSpell then
    for _, row in ipairs(details.tooltipInfoSpell.lines) do
      if row.leftColor.r == 1 and row.leftColor.g < 0.2 and row.leftColor.b < 0.2 then
        return false
      end
      if row.rightColor and row.rightColor.r == 1 and row.rightColor.g < 0.2 and row.rightColor.b < 0.2 then
        return false
      end
    end
    return true
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

local function UniqueCheck(details)
  GetTooltipInfoSpell(details)

  if not details.tooltipInfoSpell then
    return
  end

  for _, row in ipairs(details.tooltipInfoSpell.lines) do
    if row.leftText == ITEM_UNIQUE then
      return true
    end
  end
  return false
end

local function UseATTInfo(details)
  if details.ATTInfoAcquired or not ATTC or not ATTC.SearchForField then -- All The Things
    return
  end
  local ATTSearch = ATTC.SearchForField("itemIDAsCost", details.itemID)
  for _, entry in ipairs(ATTSearch) do
    if entry.itemID then
      details.isCurrency = true
      break
    elseif entry.questID then
      details.isQuestObjectiveItem = true
      break
    end
  end
  details.ATTInfoAcquired = true
end

local function CurrencyCheck(details)
  UseATTInfo(details)
  return details.isCurrency == true -- powered by ATT data
end

local function QuestObjectiveCheck(details)
  UseATTInfo(details)
  return details.isQuestObjectiveItem == true
end

local KEYWORDS_TO_CHECK = {}
local KEYWORD_AND_CATEGORY = {}

function Syndicator.Search.CleanKeyword(keyword)
  return keyword:gsub("[()&|~!]", " "):gsub("%s+", " "):gsub(" $", "")
end
local function AddKeyword(keyword, check, group)
  keyword = Syndicator.Search.CleanKeyword(keyword)
  local old = KEYWORDS_TO_CHECK[keyword]
  if old then
    KEYWORDS_TO_CHECK[keyword] = function(...) return old(...) or check(...) end
  else
    KEYWORDS_TO_CHECK[keyword] = check
  end
  KEYWORDS_TO_CHECK["_" .. keyword .. "_"] = KEYWORDS_TO_CHECK[keyword]
  KEYWORDS_TO_CHECK[keyword:gsub(" ", "-")] = KEYWORDS_TO_CHECK[keyword]

  table.insert(KEYWORD_AND_CATEGORY, {keyword = keyword, group = group or ""})
end

AddKeyword(SYNDICATOR_L_KEYWORD_PET, PetCheck, SYNDICATOR_L_GROUP_ITEM_TYPE)
AddKeyword(SYNDICATOR_L_KEYWORD_BATTLE_PET, PetCheck, SYNDICATOR_L_GROUP_ITEM_TYPE)
AddKeyword(SYNDICATOR_L_KEYWORD_SOULBOUND, SoulboundCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_BOP, SoulboundCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_BOE, BindOnEquipCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_BOU, BindOnUseCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_EQUIPMENT, EquipmentCheck, SYNDICATOR_L_GROUP_ITEM_TYPE)
AddKeyword(SYNDICATOR_L_KEYWORD_GEAR, EquipmentCheck, SYNDICATOR_L_GROUP_ITEM_TYPE)
AddKeyword(SYNDICATOR_L_KEYWORD_AXE, AxeCheck, SYNDICATOR_L_GROUP_WEAPON_TYPE)
AddKeyword(SYNDICATOR_L_KEYWORD_MACE, MaceCheck, SYNDICATOR_L_GROUP_WEAPON_TYPE)
AddKeyword(SYNDICATOR_L_KEYWORD_SWORD, SwordCheck, SYNDICATOR_L_GROUP_WEAPON_TYPE)
AddKeyword(SYNDICATOR_L_KEYWORD_STAFF, StaffCheck, SYNDICATOR_L_GROUP_WEAPON_TYPE)
AddKeyword(SYNDICATOR_L_KEYWORD_REAGENT, ReagentCheck, SYNDICATOR_L_GROUP_ITEM_TYPE)
AddKeyword(SYNDICATOR_L_KEYWORD_FOOD, FoodCheck, SYNDICATOR_L_GROUP_ITEM_TYPE)
AddKeyword(SYNDICATOR_L_KEYWORD_DRINK, FoodCheck, SYNDICATOR_L_GROUP_ITEM_TYPE)
AddKeyword(SYNDICATOR_L_KEYWORD_POTION, PotionCheck, SYNDICATOR_L_GROUP_ITEM_TYPE)
AddKeyword(SYNDICATOR_L_KEYWORD_SET, SetCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_EQUIPMENT_SET, SetCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_ENGRAVABLE, EngravableCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_ENGRAVED, EngravedCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_SOCKET, SocketCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_JUNK, JunkCheck, SYNDICATOR_L_GROUP_QUALITY)
AddKeyword(SYNDICATOR_L_KEYWORD_TRASH, JunkCheck, SYNDICATOR_L_GROUP_QUALITY)
AddKeyword(SYNDICATOR_L_KEYWORD_BOA, BindOnAccountCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_ACCOUNT_BOUND, BindOnAccountCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_USE, UseCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_USABLE, UsableCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_OPEN, OpenCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_TRADEABLE_LOOT, IsTradeableLoot, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_TRADABLE_LOOT, IsTradeableLoot, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_RELIC, RelicCheck, SYNDICATOR_L_GROUP_ARMOR_TYPE)
AddKeyword(SYNDICATOR_L_KEYWORD_STACKS, StackableCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_SOCKETED, SocketedCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_CURRENCY, CurrencyCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_OBJECTIVE, QuestObjectiveCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_COLLECTED, CollectedCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(SYNDICATOR_L_KEYWORD_UNCOLLECTED, UncollectedCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
AddKeyword(ITEM_UNIQUE:lower(), UniqueCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)

if Syndicator.Constants.IsRetail then
  AddKeyword(SYNDICATOR_L_KEYWORD_COSMETIC, CosmeticCheck, SYNDICATOR_L_GROUP_QUALITY)
  AddKeyword(TOY:lower(), ToyCheck, SYNDICATOR_L_GROUP_ITEM_TYPE)
  if Syndicator.Constants.WarbandBankActive then
    AddKeyword(ITEM_ACCOUNTBOUND:lower(), BindOnAccountCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
    AddKeyword(ITEM_ACCOUNTBOUND_UNTIL_EQUIP:lower(), WarboundUntilEquippedCheck, SYNDICATOR_L_GROUP_ITEM_DETAIL)
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
    end, SYNDICATOR_L_GROUP_SOCKET)
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
  "INVTYPE_SHIELD",
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
    AddKeyword(text:lower(),  function(details) GetInvType(details) return details.invType == slot end, SYNDICATOR_L_GROUP_SLOT)
  end
end

do
  AddKeyword(SYNDICATOR_L_KEYWORD_OFF_HAND, function(details)
    GetInvType(details)
    return details.invType == "INVTYPE_HOLDABLE" or details.invType == "INVTYPE_SHIELD"
  end, SYNDICATOR_L_GROUP_SLOT)
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
  AddKeyword(keyword, function(details) GetInvType(details) return details.invType == slot end, SYNDICATOR_L_GROUP_SLOT)
end

if Syndicator.Constants.IsRetail then
  AddKeyword(SYNDICATOR_L_KEYWORD_AZERITE, function(details)
    return C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(details.itemID)
  end, SYNDICATOR_L_GROUP_ITEM_DETAIL)
end

local TextToExpansion = {
  ["classic"] = 0,
  ["vanilla"] = 0,
  ["bc"] = 1,
  ["burning crusade"] = 1,
  ["tbc"] = 1,
  ["the burning crusade"] = 1,
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
  ["tww"] = 10,
  ["war within"] = 10,
  ["the war within"] = 10,
}

for key, quality in pairs(Enum.ItemQuality) do
  local term = _G["ITEM_QUALITY" .. quality .. "_DESC"]
  if term then
    AddKeyword(term:lower(), function(details) return details.quality == quality end, SYNDICATOR_L_GROUP_QUALITY)
  end
end

function Syndicator.Search.GetExpansion(details)
  if details.itemID == Syndicator.Constants.BattlePetCageID then
    return -1
  end

  local major = Syndicator.Search.GetExpansionInfo(details.itemID)
  if major then
    return major - 1
  end
  if not Syndicator.Constants.IsRetail then
    return -1
  else
    return (select(15, C_Item.GetItemInfo(details.itemID)))
  end
end
for key, expansionID in pairs(TextToExpansion) do
  AddKeyword(key, function(details)
    details.expacID = details.expacID or Syndicator.Search.GetExpansion(details)
    return details.expacID and details.expacID == expansionID
  end, SYNDICATOR_L_GROUP_EXPANSION)
end

local keyringBagFamily = bit.lshift(1, 9 - 1)
AddKeyword(SYNDICATOR_L_KEYWORD_KEY, function(details)
  local itemFamily = C_Item.GetItemFamily(details.itemID)
  if itemFamily == nil then
    return
  else
    return bit.band(keyringBagFamily, itemFamily) ~= 0
  end
end, SYNDICATOR_L_GROUP_ITEM_TYPE)

local fishingBagFamily = bit.lshift(1, 16 - 1)
AddKeyword(SYNDICATOR_L_KEYWORD_FISH, function(details)
  GetClassSubClass(details)
  local itemFamily = C_Item.GetItemFamily(details.itemID)
  if itemFamily == nil then
    return
  else
    return bit.band(fishingBagFamily, itemFamily) ~= 0 and details.classID == 7 and details.subClassID == 8
  end
end, SYNDICATOR_L_GROUP_TRADE_GOODS)

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

if C_TradeSkillUI and C_TradeSkillUI.GetItemReagentQualityByItemInfo then
  for tier = 1, 5 do
    AddKeyword(SYNDICATOR_L_KEYWORD_RX:format(tier), function(details)
      if not C_Item.IsItemDataCachedByID(details.itemID) then
        C_Item.RequestLoadItemDataByID(details.itemID)
        return nil
      end
      local craftedQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(details.itemID) or C_TradeSkillUI.GetItemCraftedQualityByItemInfo(details.itemLink)
      return craftedQuality == tier
    end, SYNDICATOR_L_GROUP_QUALITY)
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

local function GetResistanceStatCheck(stat)
  return function(details)
    if not Syndicator.Utilities.IsEquipment(details.itemLink) then
      return false
    end

    GetTooltipInfoSpell(details)

    if details.tooltipInfoSpell then
      for _, line in ipairs(details.tooltipInfoSpell.lines) do
        if line.leftText:find(stat) then
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
    AddKeyword(keyword:lower(), GetGearStatCheck(s), SYNDICATOR_L_GROUP_STAT)
    AddKeyword(keyword:lower(), GetGemStatCheck(keyword), SYNDICATOR_L_GROUP_STAT)
  end
end
AddKeyword(STAT_ARMOR:lower(), GetGemStatCheck(STAT_ARMOR), SYNDICATOR_L_GROUP_STAT)
if Syndicator.Constants.IsClassic then
  for i = 0, 6 do
    local keyword = _G["RESISTANCE" .. i .. "_NAME"]
    if keyword ~= nil then
      AddKeyword(keyword:lower(), GetResistanceStatCheck(keyword), SYNDICATOR_L_GROUP_STAT)
    end
  end
end

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

local function ExpansionPatternCheck(details, text)
  local itemMajor, itemMinor, itemPatch = Syndicator.Search.GetExpansionInfo(details.itemID)
  if not itemMajor then
    return false
  end

  local major, minor, patch = text:match("(%d+)%.(%d*)%.?(%d*)")
  major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)

  if not minor then
    return major == itemMajor
  elseif not patch then
    return major == itemMajor and minor == itemMinor
  else
    return major == itemMajor and minor == itemMinor and patch == itemPatch
  end
end

local function ExpansionMinPatternCheck(details, text)
  local itemMajor, itemMinor, itemPatch = Syndicator.Search.GetExpansionInfo(details.itemID)
  if not itemMajor then
    return false
  end

  local major, minor, patch = text:match("(%d+)%.(%d*)%.?(%d*)")
  major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)

  if not minor then
    return major <= itemMajor
  elseif not patch then
    return major <= itemMajor and minor <= itemMinor
  else
    return major <= itemMajor and minor <= itemMinor and patch <= itemPatch
  end
end

local function ExpansionMaxPatternCheck(details, text)
  local itemMajor, itemMinor, itemPatch = Syndicator.Search.GetExpansionInfo(details.itemID)
  if not itemMajor then
    return false
  end

  local major, minor, patch = text:match("(%d+)%.(%d*)%.?(%d*)")
  major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)

  if not minor then
    return major >= itemMajor
  elseif not patch then
    return major >= itemMajor and minor >= itemMinor
  else
    return major >= itemMajor and minor >= itemMinor and patch >= itemPatch
  end
end

local function ExactKeywordCheck(details, text)
  local keyword = text:match("^#(.*)$")
  return KEYWORDS_TO_CHECK[keyword] ~= nil and KEYWORDS_TO_CHECK[keyword](details)
end

local patterns = {
  ["^%d+$"] = ItemLevelPatternCheck,
  ["^=%d+$"] = ExactItemLevelPatternCheck,
  ["^%d+%-%d+$"] = ItemLevelRangePatternCheck,
  ["^%>%d+$"] = ItemLevelMaxPatternCheck,
  ["^%<%d+$"] = ItemLevelMinPatternCheck,
  ["^%d+%.%d*%.?%d*$"] = ExpansionPatternCheck,
  ["^%>%d+%.%d*%.?%d*$"] = ExpansionMinPatternCheck,
  ["^%<%d+%.%d*%.?%d*$"] = ExpansionMaxPatternCheck,
  ["^%#.*$"] = ExactKeywordCheck,
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

  if not details.searchKeywords then
    details.searchKeywords = {details.itemName:lower()}

    for _, line in ipairs(details.tooltipInfoSpell.lines) do
      local term = line.leftText:match("^|cFF......(.*)|r$")
      if term then
        table.insert(details.searchKeywords, term:lower())
      else
        local match = line.leftText:match("^" .. ITEM_SPELL_TRIGGER_ONUSE) or line.leftText:match("^" .. ITEM_SPELL_TRIGGER_ONEQUIP) or (UPGRADE_PATH_PATTERN and line.leftText:match(UPGRADE_PATH_PATTERN))
        if details.classID ~= Enum.ItemClass.Recipe and match then
          table.insert(details.searchKeywords, line.leftText:lower())
        end
      end
    end

    if #details.tooltipInfoSpell.lines > 1 then
      local color = details.tooltipInfoSpell.lines[2].leftColor
      if color ~= nil and math.floor(color.r * 100) == 52 and math.floor(color.g * 100) == 67 and color.b == 1 then
        table.insert(details.searchKeywords, details.tooltipInfoSpell.lines[2].leftText:lower())
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
        local finalDoNotCache = false
        if matches == nil then
          return nil
        elseif matches then
          return true
        end
        -- Cache results for each keyword to speed up continuing searches
        if not details.keywordMatchInfo then
          details.keywordMatchInfo = {}
        end
        local miss = false
        for _, k in ipairs(keywords) do
          if details.keywordMatchInfo[k] == nil then
            -- Keyword results not cached yet
            local result, doNotCache = KEYWORDS_TO_CHECK[k](details, searchString)
            finalDoNotCache = doNotCache or finalDoNotCache
            if result then
              if not doNotCache then
                details.keywordMatchInfo[k] = true
              end
              return true, finalDoNotCache
            elseif result ~= nil then
              if not doNotCache then
                details.keywordMatchInfo[k] = false
              end
            else
              miss = true
            end
          elseif details.keywordMatchInfo[k] then
            -- got a positive result cached, we're done
            return true, finalDoNotCache
          end
        end
        if miss then
          return nil
        else
          return false, finalDoNotCache
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

local function BlendOperations(checks, checkPart, operator)
  if operator == "|" and #checks > 1 then
    return function(details)
      local finalDoNotCache = false
      for index, check in ipairs(checks) do
        local result, doNotCache = check(details, checkPart[index])
        finalDoNotCache = doNotCache or finalDoNotCache
        if result then
          return true, finalDoNotCache
        elseif result == nil then
          return nil
        end
      end
      return false, finalDoNotCache
    end
  elseif operator == "&" and #checks > 1 then
    return function(details)
      local finalDoNotCache = false
      for index, check in ipairs(checks) do
        local result, doNotCache = check(details, checkPart[index])
        finalDoNotCache = doNotCache or finalDoNotCache
        if result == false then
          return false, finalDoNotCache
        elseif result == nil then
          return nil, finalDoNotCache
        end
      end
      return true, finalDoNotCache
    end
  elseif (operator == "~" or operator == "!") and #checks > 0 then
    return function(details)
      local result, doNotCache = checks[1](details, checkPart[1])
      if result ~= nil then
        return not result, doNotCache
      else
        return nil
      end
    end
  elseif #checks == 1 then
    return function(details)
      return checks[1](details, checkPart[1])
    end
  else
    return function() return true end
  end
end

local levelToOp = {
  [0] = "|",
  [1] = "&",
  [2] = "~",
}

local function ApplyTokens(tokens, startIndex)
  local checks = {}
  local level = 0
  local checkLevel = {}
  local checkPart = {}
  -- Get the items part of the current group caused by an & or ~
  local function ScanBack(newLevel)
    while level > newLevel do
      local oldLevel = level
      level = level - 1
      local scanIndex = #checks
      while scanIndex > 0 and checkLevel[scanIndex] > level do
        scanIndex = scanIndex - 1
      end
      local checksTmp = {}
      local checkPartTmp = {}
      for i = #checks, scanIndex + 1, -1 do
        local c = checks[i]
        local cPart = checkPart[i]
        checks[i] = nil
        checkLevel[i] = nil
        checkPart[i] = nil
        table.insert(checksTmp, c)
        checkPartTmp[#checksTmp] = cPart
      end
      table.insert(checks, BlendOperations(checksTmp, checkPartTmp, levelToOp[oldLevel]))
      table.insert(checkLevel, level)
    end
    level = newLevel
  end
  local index = startIndex
  while index < #tokens do
    index = index + 1
    local t = tokens[index]
    if t == "~" or t == "!" then
      level = 2
    elseif t == "&" then
      ScanBack(1)
      checkLevel[#checkLevel] = level
    elseif t == "|" then
      ScanBack(0)
    elseif t == "(" then
      local newCheck, endIndex = ApplyTokens(tokens, index)
      table.insert(checks, newCheck)
      table.insert(checkLevel, level)
      index = endIndex
    elseif t == ")" then
      break
    else
      table.insert(checks, ApplyKeyword(t))
      checkPart[#checks] = t
      table.insert(checkLevel, level)
    end
  end

  ScanBack(0)

  return BlendOperations(checks, checkPart, levelToOp[level]), index
end

local function ProcessTerms(text)
  text = text:gsub("^%s*(.-)%s*$", "%1") -- remove surrounding whitespace
  local index = text:find("[~&|()!]")
  if index == nil then
    return ApplyKeyword(text)
  else
    local tokens = {}

    local index = 1
    text = text:gsub("||", "|")
    while index < #text do
      -- Find operators and any surrounding whitespace
      local opIndexStart, opIndexEnd, op = text:find("%s*([%~%&%|%(%)%!])%s*", index)
      if op then
        local lead = text:sub(index, opIndexStart - 1)
        if lead ~= "" then
          table.insert(tokens, lead)
        end
        table.insert(tokens, op)
        index = opIndexEnd + 1
      else
        break
      end
    end
    local tail = text:sub(index, #text)
    if tail ~= "" then
      table.insert(tokens, tail)
    end

    local result = ApplyTokens(tokens, 0)

    if not result then
      return function() return true end
    else
      return result
    end
  end
end

function Syndicator.Search.CheckItem(details, searchString)
  details.fullMatchInfo = details.fullMatchInfo or {}
  local result = details.fullMatchInfo[searchString]
  if result ~= nil then
    return details.fullMatchInfo[searchString]
  end

  local check = matches[searchString]
  if not check then
    check = ProcessTerms(searchString)
    matches[searchString] = check
  end

  local doNotCache
  result, doNotCache = check(details, searchString)
  if not doNotCache then
    details.fullMatchInfo[searchString] = result
  end
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
        GetClassSubClass(details)
        return details.classID == classID
      end, SYNDICATOR_L_GROUP_ITEM_TYPE)
    end
  end

  local tradeGoodsToCheck = {
    1, -- parts
    4, -- jewelcrafting
    5, -- cloth
    6, -- leather
    7, -- metal and stone
    8, -- cooking
    9, -- herb
    10, -- elemental
    12, -- enchanting
    16, -- inscription
    18, -- optional reagents
  }
  if Syndicator.Constants.IsClassic then
    tAppendAll(tradeGoodsToCheck, {
      2, -- explosive
      3, -- device
    })
  end
  for _, subClass in ipairs(tradeGoodsToCheck) do
    local keyword = C_Item.GetItemSubClassInfo(7, subClass)
    if keyword ~= nil then
      AddKeyword(keyword:lower(), function(details)
        GetClassSubClass(details)
        return details.classID == 7 and details.subClassID == subClass
      end, SYNDICATOR_L_GROUP_TRADE_GOODS)
    end
  end

  local armorTypesToCheck = {
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
        GetClassSubClass(details)
        return details.classID == Enum.ItemClass.Armor and details.subClassID == subClass
      end, SYNDICATOR_L_GROUP_ARMOR_TYPE)
    end
  end
  -- cloth armor, but excluding cloaks
  AddKeyword(C_Item.GetItemSubClassInfo(Enum.ItemClass.Armor, 1):lower(), function(details)
    GetClassSubClass(details)
    GetInvType(details)
    return details.classID == Enum.ItemClass.Armor and details.subClassID == 1 and details.invType ~= "INVTYPE_CLOAK"
  end, SYNDICATOR_L_GROUP_ARMOR_TYPE)

  -- All weapons + fishingpole
  for subClass = 0, 20 do
    local keyword = C_Item.GetItemSubClassInfo(Enum.ItemClass.Weapon, subClass)
    if keyword ~= nil then
      AddKeyword(keyword:lower(), function(details)
        GetClassSubClass(details)
        return details.classID == Enum.ItemClass.Weapon and details.subClassID == subClass
      end, SYNDICATOR_L_GROUP_WEAPON_TYPE)
    end
  end

  -- All weapons + fishingpole
  for subClass = 1, 11 do
    local keyword = C_Item.GetItemSubClassInfo(Enum.ItemClass.Recipe, subClass)
    if keyword ~= nil then
      AddKeyword(keyword:lower(), function(details)
        GetClassSubClass(details)
        return details.classID == Enum.ItemClass.Recipe and details.subClassID == subClass
      end, SYNDICATOR_L_GROUP_RECIPE)
    end
  end

  if C_PetJournal then
    for subClass = 0, 9 do
      local keyword = C_Item.GetItemSubClassInfo(Enum.ItemClass.Battlepet, subClass)
      if keyword ~= nil then
        AddKeyword(keyword:lower(), function(details)
        GetClassSubClass(details)
          return details.classID == Enum.ItemClass.Battlepet and details.subClassID == subClass
        end, SYNDICATOR_L_GROUP_BATTLE_PET)
      end
    end
  end

  for subClass = 1, 12 do
    local keyword = C_Item.GetItemSubClassInfo(Enum.ItemClass.Glyph, subClass)
    if keyword ~= nil then
      AddKeyword(keyword:lower(), function(details)
        GetClassSubClass(details)
        return details.classID == Enum.ItemClass.Glyph and details.subClassID == subClass
      end, SYNDICATOR_L_GROUP_GLYPH)
    end
  end

  for subClass = 0, 9 do
    local keyword = C_Item.GetItemSubClassInfo(Enum.ItemClass.Consumable, subClass)
    if keyword ~= nil then
      AddKeyword(keyword:lower(), function(details)
        GetClassSubClass(details)
        return details.classID == Enum.ItemClass.Consumable and details.subClassID == subClass
      end, SYNDICATOR_L_GROUP_CONSUMABLE)
    end
  end

  local mount = C_Item.GetItemSubClassInfo(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.Mount)
  if mount ~= nil then
    AddKeyword(mount:lower(), MountCheck, SYNDICATOR_L_GROUP_ITEM_TYPE)
  end

  Syndicator.Search.RebuildKeywordList()
end

function Syndicator.Search.RebuildKeywordList()
  for key in pairs(KEYWORDS_TO_CHECK) do
    table.insert(sortedKeywords, key)
  end
  table.sort(sortedKeywords)
end

function Syndicator.Search.GetKeywords()
  return KEYWORD_AND_CATEGORY
end
