-- Creates all the search keyword functions and binds them to locale dependent
-- keywords and the English equivalent

local function GetItemName(details)
  if details.itemName then
    return
  end

  if details.itemID == Syndicator.Constants.BattlePetCageID and details.itemLink:find("battlepet:") then
    local petID = details.itemLink:match("battlepet:(%d+)")
    details.itemName = C_PetJournal.GetPetInfoBySpeciesID(tonumber(petID))
  elseif C_Item.IsItemDataCachedByID(details.itemID) then
    details.itemName = C_Item.GetItemNameByID(details.itemLink) or C_Item.GetItemNameByID(details.itemID)
  end

  if not details.itemName then
    C_Item.RequestLoadItemDataByID(details.itemID)
  end
end

local GetClassSubClass
if Syndicator.Constants.IsEra then
  GetClassSubClass = function(details)
    if details.classID then
      return
    end

    local override = Syndicator.Search.Constants.TypeOverridesMap[details.itemID]
    if override then
      details.classID = override.classID
      details.subClassID = override.subClassID
    else
      local _
      _, _, _, details.invType, _, details.classID, details.subClassID = C_Item.GetItemInfoInstant(details.itemID)
      if details.invType == "INVTYPE_CLOAK" then
        details.subClassID = 0
      end
    end
  end
else
  GetClassSubClass = function(details)
    if details.classID then
      return
    end

    if details.itemID == Syndicator.Constants.BattlePetCageID and details.itemLink:find("battlepet:") then
      local petID = details.itemLink:match("battlepet:(%d+)")
      local _, _, petType = C_PetJournal.GetPetInfoBySpeciesID(tonumber(petID))
      details.classID = Enum.ItemClass.Battlepet
      details.subClassID = petType - 1
    else
      local _
      _, _, _, details.invType, _, details.classID, details.subClassID = C_Item.GetItemInfoInstant(details.itemID)
      if details.invType == "INVTYPE_CLOAK" then
        details.subClassID = 0
      end
    end
  end
end
Syndicator.Search.GetClassSubClass = GetClassSubClass

local function GetInvType(details)
  if details.invType then
    return
  end
  local _
  _, _, _, details.invType = C_Item.GetItemInfoInstant(details.itemID)
  details.invType = details.invType or "NONE"
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

local function RefundableCheck(details)
  if details.refundable == nil and details.itemLocation and C_Item.DoesItemExist(details.itemLocation) then
    details.refundable = C_Item.CanBeRefunded(details.itemLocation)
  elseif details.refundable == nil then
    details.refundable = false
  end
  return details.refundable, details.refundable
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

local function RingCheck(details)
  GetInvType(details)
  return details.invType == "INVTYPE_FINGER"
end

local function StaffCheck(details)
  GetClassSubClass(details)
  return details.classID == Enum.ItemClass.Weapon and (details.subClassID == 10)
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

-- Compare item spell details to determine if this item's spell is one for
-- profession knowledge, using base spell for the spell's name
local baseKnowledgeSpell, baseKnowledgeName = 384372, nil
local function KnowledgeCheck(details)
  if baseKnowledgeName == nil then -- cache the comparison name
    if not C_Spell.IsSpellDataCached(baseKnowledgeSpell) then
      C_Spell.RequestLoadSpellData(baseKnowledgeSpell)
      return nil
    end
    baseKnowledgeName = C_Spell.GetSpellInfo(baseKnowledgeSpell).name
  end
  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return nil
  end
  local spellName, spellID = C_Item.GetItemSpell(details.itemID)
  if spellID == nil then
    return false
  end
  if spellID and not spellName then
    C_Spell.RequestLoadSpellData(spellID)
    return nil
  end
  local spellInfo = C_Spell.GetSpellInfo(spellID)
  -- Check it has the right name and the appropriate icon (which should be
  -- enough to guarantee its a knowledge item)
  return spellName == baseKnowledgeName and (spellInfo.iconID == 236225 or spellInfo.iconID == 136175)
end

local function EnsembleCheck(details)
  GetInvType(details)
  GetClassSubClass(details)

  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return nil
  end

  if details.classID == Enum.ItemClass.Consumable and details.invType == "INVTYPE_NON_EQUIP_IGNORE" and (C_Item.IsDressableItemByID or IsDressableItem)(details.itemID) then
    if details.setSources == nil then
      local setID = C_Item.GetItemLearnTransmogSet(details.itemLink)
      if setID then
        details.setSources = C_Transmog.GetAllSetAppearancesByID(setID)
      end
    end
    if not details.setSources then
      return true
    end
    local invSlot = details.setSources[1].invSlot + 1
    return invSlot ~= 16 and invSlot ~= 17
  end
  return false
end

local function ArsenalCheck(details)
  GetInvType(details)
  GetClassSubClass(details)

  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return nil
  end

  if details.classID == Enum.ItemClass.Consumable and details.invType == "INVTYPE_NON_EQUIP_IGNORE" and (C_Item.IsDressableItemByID or IsDressableItem)(details.itemID) then
    if details.setSources == nil then
      local setID = C_Item.GetItemLearnTransmogSet(details.itemLink)
      if setID then
        details.setSources = C_Transmog.GetAllSetAppearancesByID(setID)
      end
    end
    if not details.setSources then
      return false
    end
    local invSlot = details.setSources[1].invSlot + 1
    return invSlot == 16 or invSlot == 17
  end
  return false
end

local function GetSourceID(itemLink)
  local _, sourceID = C_TransmogCollection.GetItemInfo(itemLink)
  if sourceID then
    return sourceID
  end
  _, sourceID = C_TransmogCollection.GetItemInfo((C_Item.GetItemInfoInstant(itemLink)))
  if sourceID then
    return sourceID
  end
  return Syndicator.Search.RecoverTransmogInfo(itemLink)
end

local function IsTMogCollectedCompletionist(itemLink)
  local sourceID = GetSourceID(itemLink)
  if not sourceID or not select(2, C_TransmogCollection.AccountCanCollectSource(sourceID)) then
    return nil
  else
    return C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance(sourceID)
  end
end

local function IsTMogCollectedUnique(itemLink)
  local sourceID = GetSourceID(itemLink)
  if not sourceID or not select(2, C_TransmogCollection.AccountCanCollectSource(sourceID)) then
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
  if speciesID == nil then
    return
  end
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

local function CatalystCheck(details)
  if not TransmogUpgradeMaster_API then
    return false
  end

  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return nil
  end

  if not TransmogUpgradeMaster_API.IsCacheWarmedUp() then
    return false, true
  end

  return select(3, TransmogUpgradeMaster_API.IsAppearanceMissing(details.itemLink)) == true
end

local function CatalystUpgradeCheck(details)
  if not TransmogUpgradeMaster_API then
    return false
  end

  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return nil
  end

  if not TransmogUpgradeMaster_API.IsCacheWarmedUp() then
    return false, true
  end

  return select(4, TransmogUpgradeMaster_API.IsAppearanceMissing(details.itemLink)) == true
end


local alwaysMatchClass = {
  ["INVTYPE_CLOAK"] = true,
  ["INVTYPE_TRINKET"] = true,
  ["INVTYPE_FINGER"] = true,
  ["INVTYPE_NECK"] = true,
}

local function MyClassCheck(details)
  if not EquipmentCheck(details) then
    return false
  end

  GetClassSubClass(details)
  GetInvType(details)

  if alwaysMatchClass[details.invType] then
    return true
  end

  local classGear = Syndicator.Search.Constants.ClassGear
  if classGear[details.classID] and classGear[details.classID][details.subClassID]
    and (next(classGear[details.classID][details.subClassID]) == nil or
      classGear[details.classID][details.subClassID][details.invType]) then
    return true
  end
  return false
end

local function GetTooltipInfoLink(details)
  if details.tooltipInfoLink then
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

  if C_TooltipInfo then
    details.tooltipInfoLink = C_TooltipInfo.GetHyperlink(details.itemLink) or {lines={}}
  elseif details.itemID == Syndicator.Constants.BattlePetCageID then
    info.tooltipInfoLink = {lines = {}}
  else
    details.tooltipInfoLink = Syndicator.Utilities.DumpClassicTooltip(function(tooltip) tooltip:SetHyperlink(details.itemLink) end)
  end
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

Syndicator.Search.GetTooltipInfoLink = GetTooltipInfoLink
Syndicator.Search.GetTooltipInfoSpell = GetTooltipInfoSpell

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

local function UpgradeCheck(details)
  if details.isUpgrade ~= nil then
    return details.isUpgrade
  end
  return false
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
  if details.accountBound ~= nil then
    return details.accountBound
  end

  GetTooltipInfoSpell(details)

  if details.tooltipInfoSpell then
    details.accountBound = false
    for _, row in ipairs(details.tooltipInfoSpell.lines) do
      if tIndexOf(Syndicator.Constants.AccountBoundTooltipLines, row.leftText) ~= nil or
          (not details.isBound and tIndexOf(Syndicator.Constants.AccountBoundTooltipLinesNotBound, row.leftText) ~= nil) then
        details.accountBound = true
        break
      end
    end
    return details.accountBound
  end
end

local function WarboundUntilEquippedCheck(details)
  GetTooltipInfoSpell(details)

  if details.tooltipInfoSpell then
    if not details.isBound then
      for _, row in ipairs(details.tooltipInfoSpell.lines) do
        if not details.isBound and tIndexOf(Syndicator.Constants.AccountBoundTooltipLinesNotBound, row.leftText) ~= nil then
          return true
        end
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

local function ActiveCheck(details)
  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return
  end
  if not Syndicator.Utilities.IsEquipment(details.itemLink) then
    return false
  end
  local upgradeInfo = C_Item.GetItemUpgradeInfo(details.itemLink)
  if not upgradeInfo or not upgradeInfo.trackString then
    return false
  end

  GetTooltipInfoSpell(details)

  if details.tooltipInfoSpell then
    for index = 1, math.min(#details.tooltipInfoSpell.lines, 4) do
      local row = details.tooltipInfoSpell.lines[index]
      local r, g, b = math.floor(row.leftColor.r * 100), math.floor(row.leftColor.g * 100), math.floor(row.leftColor.b * 100)
      if r == g and g == b and r < 60 then
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

local function ReadCheck(details)
  if not details.itemLink:find("item:", nil, true) then
    return false
  end

  GetTooltipInfoSpell(details)

  if details.tooltipInfoSpell then
    for _, row in ipairs(details.tooltipInfoSpell.lines) do
      if row.leftText == ITEM_READABLE then
        return true
      end
    end
    return false
  end
end

local function KeystoneCheck(details)
  return C_Item.IsItemKeystoneByID(details.itemID)
end

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

local function ConjuredCheck(details)
  GetTooltipInfoSpell(details)

  if not details.tooltipInfoSpell then
    return
  end

  for _, row in ipairs(details.tooltipInfoSpell.lines) do
    if row.leftText == ITEM_CONJURED then
      return true
    end
  end
  return false
end

local PVP_PATTERN = PVP_ITEM_LEVEL_TOOLTIP:gsub("%%d", ".*")
local function PvPCheck(details)
  if not Syndicator.Utilities.IsEquipment(details.itemLink) then
    return false
  end

  GetTooltipInfoSpell(details)

  if not details.tooltipInfoSpell then
    return
  end

  for _, row in ipairs(details.tooltipInfoSpell.lines) do
    if row.leftText:match(PVP_PATTERN) then
      return true
    end
  end
  return false
end

local function AnimaCheck(details)
  return C_Item.IsAnimaItemByID(details.itemID)
end

local function LockedCheck(details)
  if not details.hasLoot then
    return false
  end

  GetTooltipInfoSpell(details)

  if not details.tooltipInfoSpell then
    return
  end

  for _, row in ipairs(details.tooltipInfoSpell.lines) do
    if row.leftText == LOCKED then
      return true, true
    end
  end
  return false
end

local function CraftedCheck(details)
  return details.quality ~= 7 and details.classID ~= Enum.ItemClass.Questitem and details.itemLink:match("Player-") ~= nil
end

local function SetBonusCheck(details)
  if not Syndicator.Utilities.IsEquipment(details.itemLink) then
    return false
  end

  if C_Item.IsCosmeticItem then
    local result = CosmeticCheck(details)
    if result then
      return false
    elseif result == nil then
      return nil
    end
  end

  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return nil
  end

  -- We would use the specID in the item link, but that doesn't always
  -- correspond to the class that can use the item
  for _, specID in ipairs(Syndicator.Search.Constants.AllClassSpecializations) do
    if C_Item.GetSetBonusesForSpecializationByItemID(specID, details.itemID) ~= nil then
      return true
    end
  end
  return false
end

local classRestrictionsPattern = ITEM_CLASSES_ALLOWED:gsub("%%s", ".+")
local multipleUniquesPattern = ITEM_UNIQUE_MULTIPLE:gsub("%%d", ".+")
-- Check for items with the appropriate item class (which have a lot of
-- variation), not common (to exclude glyphs) and have a class restriction.
local function TierTokenCheck(details)
  GetInvType(details)
  GetClassSubClass(details)

  if details.quality <= 1 or details.invType ~= "INVTYPE_NON_EQUIP_IGNORE" or (details.classID ~= Enum.ItemClass.Consumable and details.classID ~= Enum.ItemClass.Armor and details.classID ~= Enum.ItemClass.Weapon and details.classID ~= Enum.ItemClass.Miscellaneous and details.classID ~= Enum.ItemClass.Reagent) then
    return false
  end

  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return nil
  end

  if (C_Item.IsDressableItemByID or IsDressableItem)(details.itemID) then
    return false
  end

  GetTooltipInfoLink(details)

  if details.tooltipInfoLink then
    for _, row in ipairs(details.tooltipInfoLink.lines) do
      if row.leftText == ITEM_UNIQUE or row.leftText:match(multipleUniquesPattern) then
        return false
      elseif row.leftText:match(classRestrictionsPattern) then
        return true
      end
    end
    return false
  end
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
local KEYWORD_AND_CATEGORY_ENGLISH = {}

function Syndicator.Search.CleanKeyword(keyword)
  return keyword:gsub("[()&|~!]", " "):gsub("%s+", " "):gsub(" $", "")
end
local function AddKeywordInternal(keyword, check)
  keyword = Syndicator.Search.CleanKeyword(keyword)
  local old = KEYWORDS_TO_CHECK[keyword]
  if old then
    KEYWORDS_TO_CHECK[keyword] = function(...) return old(...) or check(...) end
  else
    KEYWORDS_TO_CHECK[keyword] = check
  end
  KEYWORDS_TO_CHECK["_" .. keyword .. "_"] = KEYWORDS_TO_CHECK[keyword]
  KEYWORDS_TO_CHECK[keyword:gsub(" ", "-")] = KEYWORDS_TO_CHECK[keyword]

  return keyword
end

local function AddKeywordDirect(keyword, check, group)
  keyword = AddKeywordInternal(keyword, check)
  table.insert(KEYWORD_AND_CATEGORY, {keyword = keyword, group = group or ""})
  table.insert(KEYWORD_AND_CATEGORY_ENGLISH, {keyword = keyword, group = group or ""})
end

local function AddKeywordLocalised(key, check, group)
  local keyword = AddKeywordInternal(Syndicator.Locales[key], check)
  if keyword ~= SYNDICATOR_LOCALES.enUS[key] then
    local englishKeyword = AddKeywordInternal(SYNDICATOR_LOCALES.enUS[key], check)
    table.insert(KEYWORD_AND_CATEGORY_ENGLISH, {keyword = englishKeyword, group = group or ""})
  end

  table.insert(KEYWORD_AND_CATEGORY, {keyword = keyword, group = group or ""})
end

local function AddKeywordManual(keywordLocalised, keywordEnglish, check, group)
  local keyword = AddKeywordInternal(keywordLocalised, check)
  if keywordLocalised ~= keywordEnglish then
    assert(GetLocale() ~= "enUS", keywordLocalised, keywordEnglish)
    local englishKeyword = AddKeywordInternal(keywordEnglish, check)
    table.insert(KEYWORD_AND_CATEGORY_ENGLISH, {keyword = englishKeyword, group = group or ""})
  end

  table.insert(KEYWORD_AND_CATEGORY, {keyword = keyword, group = group or ""})
end

AddKeywordLocalised("KEYWORD_PET", PetCheck, Syndicator.Locales.GROUP_ITEM_TYPE)
AddKeywordLocalised("KEYWORD_BATTLE_PET", PetCheck, Syndicator.Locales.GROUP_ITEM_TYPE)
AddKeywordLocalised("KEYWORD_SOULBOUND", SoulboundCheck, Syndicator.Locales.GROUP_BINDING_TYPE)
AddKeywordLocalised("KEYWORD_BOP", SoulboundCheck, Syndicator.Locales.GROUP_BINDING_TYPE)
AddKeywordLocalised("KEYWORD_BOE", BindOnEquipCheck, Syndicator.Locales.GROUP_BINDING_TYPE)
AddKeywordLocalised("KEYWORD_BWE", BindOnEquipCheck, Syndicator.Locales.GROUP_BINDING_TYPE)
AddKeywordLocalised("KEYWORD_BOU", BindOnUseCheck, Syndicator.Locales.GROUP_BINDING_TYPE)
AddKeywordLocalised("KEYWORD_EQUIPMENT", EquipmentCheck, Syndicator.Locales.GROUP_ITEM_TYPE)
AddKeywordLocalised("KEYWORD_GEAR", EquipmentCheck, Syndicator.Locales.GROUP_ITEM_TYPE)
AddKeywordLocalised("KEYWORD_AXE", AxeCheck, Syndicator.Locales.GROUP_WEAPON_TYPE)
AddKeywordLocalised("KEYWORD_MACE", MaceCheck, Syndicator.Locales.GROUP_WEAPON_TYPE)
AddKeywordLocalised("KEYWORD_SWORD", SwordCheck, Syndicator.Locales.GROUP_WEAPON_TYPE)
AddKeywordLocalised("KEYWORD_STAFF", StaffCheck, Syndicator.Locales.GROUP_WEAPON_TYPE)
AddKeywordLocalised("KEYWORD_RING", RingCheck, Syndicator.Locales.GROUP_ARMOR_TYPE)
AddKeywordLocalised("KEYWORD_REAGENT", ReagentCheck, Syndicator.Locales.GROUP_ITEM_TYPE)
AddKeywordLocalised("KEYWORD_FOOD", FoodCheck, Syndicator.Locales.GROUP_ITEM_TYPE)
AddKeywordLocalised("KEYWORD_DRINK", FoodCheck, Syndicator.Locales.GROUP_ITEM_TYPE)
AddKeywordLocalised("KEYWORD_POTION", PotionCheck, Syndicator.Locales.GROUP_ITEM_TYPE)
AddKeywordLocalised("KEYWORD_SET", SetCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_EQUIPMENT_SET", SetCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_ENGRAVABLE", EngravableCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_ENGRAVED", EngravedCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_SOCKET", SocketCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_JUNK", JunkCheck, Syndicator.Locales.GROUP_QUALITY)
AddKeywordLocalised("KEYWORD_TRASH", JunkCheck, Syndicator.Locales.GROUP_QUALITY)
AddKeywordLocalised("KEYWORD_UPGRADE", UpgradeCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_BOA", BindOnAccountCheck, Syndicator.Locales.GROUP_BINDING_TYPE)
AddKeywordLocalised("KEYWORD_ACCOUNT_BOUND", BindOnAccountCheck, Syndicator.Locales.GROUP_BINDING_TYPE)
AddKeywordLocalised("KEYWORD_USE", UseCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_USABLE", UsableCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_OPEN", OpenCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_READ", ReadCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_TRADEABLE_LOOT", IsTradeableLoot, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_TRADABLE_LOOT", IsTradeableLoot, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_RELIC", RelicCheck, Syndicator.Locales.GROUP_ARMOR_TYPE)
AddKeywordLocalised("KEYWORD_STACKS", StackableCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_SOCKETED", SocketedCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_CURRENCY", CurrencyCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_OBJECTIVE", QuestObjectiveCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_COLLECTED", CollectedCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_UNCOLLECTED", UncollectedCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_MY_CLASS", MyClassCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_PVP", PvPCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordManual(ITEM_UNIQUE:lower(), "unique", UniqueCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_CONJURED", ConjuredCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_LOCKED", LockedCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_REFUNDABLE", RefundableCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_CRAFTED", CraftedCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
AddKeywordLocalised("KEYWORD_TIER_TOKEN", TierTokenCheck, Syndicator.Locales.GROUP_ITEM_TYPE)
AddKeywordLocalised("KEYWORD_ENSEMBLE", EnsembleCheck, Syndicator.Locales.GROUP_ITEM_TYPE)
AddKeywordLocalised("KEYWORD_ARSENAL", ArsenalCheck, Syndicator.Locales.GROUP_ITEM_TYPE)

if Syndicator.Constants.IsRetail then
  AddKeywordLocalised("KEYWORD_COSMETIC", CosmeticCheck, Syndicator.Locales.GROUP_QUALITY)
  AddKeywordManual(TOY:lower(), "toy", ToyCheck, Syndicator.Locales.GROUP_ITEM_TYPE)
  AddKeywordLocalised("KEYWORD_KEYSTONE", KeystoneCheck, Syndicator.Locales.GROUP_ITEM_TYPE)
  AddKeywordManual(WORLD_QUEST_REWARD_FILTERS_ANIMA:lower(), "anima", AnimaCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
  AddKeywordLocalised("KEYWORD_KNOWLEDGE", KnowledgeCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
  AddKeywordLocalised("KEYWORD_SET_BONUS", SetBonusCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
  AddKeywordLocalised("KEYWORD_CATALYST", CatalystCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
  AddKeywordLocalised("KEYWORD_CATALYST_UPGRADE", CatalystUpgradeCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
  AddKeywordLocalised("KEYWORD_ACTIVE_SEASON", ActiveCheck, Syndicator.Locales.GROUP_ITEM_DETAIL)
  if Syndicator.Constants.WarbandBankActive then
    AddKeywordManual(ITEM_ACCOUNTBOUND:lower(), "warbound", BindOnAccountCheck, Syndicator.Locales.GROUP_BINDING_TYPE)
    AddKeywordManual(ITEM_ACCOUNTBOUND_UNTIL_EQUIP:lower(), "warbound until equipped", WarboundUntilEquippedCheck, Syndicator.Locales.GROUP_BINDING_TYPE)
    AddKeywordLocalised("KEYWORD_WUE", WarboundUntilEquippedCheck, Syndicator.Locales.GROUP_BINDING_TYPE)
  end
end

local sockets = {
  ["EMPTY_SOCKET_BLUE"] = "blue socket",
  ["EMPTY_SOCKET_COGWHEEL"] = "cogwheel socket",
  ["EMPTY_SOCKET_CYPHER"] = "crystallic socket",
  ["EMPTY_SOCKET_DOMINATION"] = "domination socket",
  ["EMPTY_SOCKET_HYDRAULIC"] = "sha-touched",
  ["EMPTY_SOCKET_META"] = "meta socket",
  ["EMPTY_SOCKET_NO_COLOR"] = "prismatic socket",
  ["EMPTY_SOCKET_PRIMORDIAL"] = "primordial socket",
  ["EMPTY_SOCKET_PRISMATIC"] = "prismatic socket",
  ["EMPTY_SOCKET_PUNCHCARDBLUE"] = "blue punchcard socket",
  ["EMPTY_SOCKET_PUNCHCARDRED"] = "red punchcard socket",
  ["EMPTY_SOCKET_PUNCHCARDYELLOW"] = "yellow punchcard socket",
  ["EMPTY_SOCKET_RED"] = "red socket",
  ["EMPTY_SOCKET_TINKER"] = "tinker socket",
  ["EMPTY_SOCKET_YELLOW"] = "yellow socket",
  ["EMPTY_SOCKET_SINGINGSEA"] = "singing sea socket",
  ["EMPTY_SOCKET_SINGINGTHUNDER"] = "singing thunder socket",
  ["EMPTY_SOCKET_SINGINGWIND"] = "singing wind socket",
}

if Syndicator.Constants.IsCata then
  sockets["EMPTY_SOCKET_HYDRAULIC"] = "hydraulic socket"
end

for key, english in pairs(sockets) do
  local global = _G[key]
  if global then
    AddKeywordManual(global:lower(), english, function(details)
      SaveGearStats(details)
      if details.itemStats then
        return details.itemStats[key] ~= nil
      end
      return nil
    end, Syndicator.Locales.GROUP_SOCKET)
  end
end

local inventorySlots = {
  ["INVTYPE_HEAD"] = "head",
  ["INVTYPE_NECK"] = "neck",
  ["INVTYPE_SHOULDER"] = "shoulder",
  ["INVTYPE_BODY"] = "shirt",
  ["INVTYPE_WAIST"] = "waist",
  ["INVTYPE_LEGS"] = "legs",
  ["INVTYPE_FEET"] = "feet",
  ["INVTYPE_WRIST"] = "wrist",
  ["INVTYPE_HAND"] = "hands",
  ["INVTYPE_FINGER"] = "finger",
  ["INVTYPE_TRINKET"] = "trinket",
  ["INVTYPE_WEAPON"] = "one-hand",
  ["INVTYPE_RANGED"] = "ranged",
  ["INVTYPE_CLOAK"] = "back",
  ["INVTYPE_2HWEAPON"] = "two-hand",
  ["INVTYPE_BAG"] = "bag",
  ["INVTYPE_TABARD"] = "tabard",
  ["INVTYPE_WEAPONMAINHAND"] = "main hand",
  ["INVTYPE_WEAPONOFFHAND"] = "off hand",
  ["INVTYPE_HOLDABLE"] = "held in off-hand",
  ["INVTYPE_SHIELD"] = "off hand",
  ["INVTYPE_AMMO"] = "ammo",
  ["INVTYPE_THROWN"] = "thrown",
  ["INVTYPE_RANGEDRIGHT"] = "ranged",
  ["INVTYPE_QUIVER"] = "quiver",
  ["INVTYPE_RELIC"] = "relic",
  ["INVTYPE_PROFESSION_TOOL"] = "profession tool",
  ["INVTYPE_PROFESSION_GEAR"] = "profession equipment",
  ["INVTYPE_CHEST"] = "chest",
  ["INVTYPE_ROBE"] = "chest",
}

for slot, english in pairs(inventorySlots) do
  local text = _G[slot]
  if text ~= nil then
    AddKeywordManual(text:lower(), english, function(details) GetInvType(details) return details.invType == slot end, Syndicator.Locales.GROUP_SLOT)
  end
end

do
  AddKeywordLocalised("KEYWORD_OFF_HAND", function(details)
    GetInvType(details)
    return details.invType == "INVTYPE_HOLDABLE" or details.invType == "INVTYPE_SHIELD"
  end, Syndicator.Locales.GROUP_SLOT)
end

local moreSlotMappings = {
  ["KEYWORD_HELM"] = "INVTYPE_HEAD",
  ["KEYWORD_CLOAK"] = "INVTYPE_CLOAK",
  ["KEYWORD_BRACERS"] = "INVTYPE_WRIST",
  ["KEYWORD_GLOVES"] = "INVTYPE_HAND",
  ["KEYWORD_BELT"] = "INVTYPE_WAIST",
  ["KEYWORD_BOOTS"] = "INVTYPE_FEET",
}

for keyword, slot in pairs(moreSlotMappings) do
  AddKeywordLocalised(keyword, function(details) GetInvType(details) return details.invType == slot end, Syndicator.Locales.GROUP_SLOT)
end

if Syndicator.Constants.IsRetail then
  AddKeywordLocalised("KEYWORD_AZERITE", function(details)
    return C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(details.itemID)
  end, Syndicator.Locales.GROUP_ITEM_DETAIL)
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
    local _, _, _, _, _, _, _, _, _, _, _, _, _, _, xpac = C_Item.GetItemInfo(details.itemID)
    return xpac
  end
end
for key, expansionID in pairs(TextToExpansion) do
  AddKeywordDirect(key, function(details)
    details.expacID = details.expacID or Syndicator.Search.GetExpansion(details)
    return details.expacID and details.expacID == expansionID
  end, Syndicator.Locales.GROUP_EXPANSION)
end

local qualityToEnglish = {
  [0] = "poor",
  [1] = "common",
  [2] = "uncommon",
  [3] = "rare",
  [4] = "epic",
  [5] = "legendary",
  [6] = "artifact",
  [7] = "heirloom",
  [8] = "wow token",
}
for _, quality in pairs(Enum.ItemQuality) do
  local term = _G["ITEM_QUALITY" .. quality .. "_DESC"]
  if term then
    AddKeywordManual(term:lower(), qualityToEnglish[quality], function(details) return details.quality == quality end, Syndicator.Locales.GROUP_QUALITY)
  end
end

local keyringBagFamily = bit.lshift(1, 9 - 1)
AddKeywordLocalised("KEYWORD_KEY", function(details)
  local itemFamily = C_Item.GetItemFamily(details.itemID)
  if itemFamily == nil then
    return
  else
    return bit.band(keyringBagFamily, itemFamily) ~= 0
  end
end, Syndicator.Locales.GROUP_ITEM_TYPE)

local fishingBagFamily = bit.lshift(1, 16 - 1)
AddKeywordLocalised("KEYWORD_FISH", function(details)
  GetClassSubClass(details)
  local itemFamily = C_Item.GetItemFamily(details.itemID)
  if itemFamily == nil then
    return
  else
    return bit.band(fishingBagFamily, itemFamily) ~= 0 and details.classID == 7 and details.subClassID == 8
  end
end, Syndicator.Locales.GROUP_TRADE_GOODS)

local function GetGearStatCheck(statKey)
  return function(details)
    SaveGearStats(details)
    if not details.itemStats then
      return
    end

    for key, _ in pairs(details.itemStats) do
      if key:find(statKey, nil, true) ~= nil then
        return true
      end
    end
    return false
  end
end

if C_TradeSkillUI and C_TradeSkillUI.GetItemReagentQualityByItemInfo then
  for tier = 1, 5 do
    AddKeywordManual(Syndicator.Locales.KEYWORD_RX:format(tier), SYNDICATOR_LOCALES.enUS["KEYWORD_RX"]:format(tier), function(details)
      if not C_Item.IsItemDataCachedByID(details.itemID) then
        C_Item.RequestLoadItemDataByID(details.itemID)
        return nil
      end
      local craftedQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(details.itemID) or C_TradeSkillUI.GetItemCraftedQualityByItemInfo(details.itemLink)
      return craftedQuality == tier
    end, Syndicator.Locales.GROUP_QUALITY)
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
  ["AGILITY"] = "agility",
  ["ATTACK_POWER"] = "attack power",
  ["BLOCK_RATING"] = "block",
  ["CORRUPTION"] = "corruption",
  ["CRAFTING_SPEED"] = "crafting speed",
  ["CR_AVOIDANCE"] = "avoidance",
  ["CRIT_MELEE_RATING"] = "critical strike (melee)",
  ["CRIT_RANGED_RATING"] = "critical strike (ranged)",
  ["CRIT_RATING"] = "critical strike",
  ["CRIT_SPELL_RATING"] = "critical strike (spell)",
  ["CRIT_TAKEN_RATING"] = "critical strike avoidance",
  ["CR_LIFESTEAL"] = "leech",
  ["CR_MULTISTRIKE"] = "multistrike",
  ["CR_SPEED"] = "speed",
  ["CR_STURDINESS"] = "indestructible",
  ["DAMAGE_PER_SECOND"] = "damage per second",
  ["DEFENSE_SKILL_RATING"] = "defense",
  ["DEFTNESS"] = "deftness",
  ["DODGE_RATING"] = "dodge",
  ["EXTRA_ARMOR"] = "bonus armor",
  ["FINESSE"] = "finesse",
  ["HASTE_RATING"] = "haste",
  ["HEALTH_REGENERATION"] = "health regeneration",
  ["HIT_MELEE_RATING"] = "hit (melee)",
  ["HIT_RANGED_RATING"] = "hit (ranged)",
  ["HIT_SPELL_RATING"] = "hit (spell)",
  ["HIT_RATING"] = "hit",
  ["HIT_TAKEN_RATING"] = "hit avoidance",
  ["INTELLECT"] = "intellect",
  ["MANA_REGENERATION"] = "mana regeneration",
  ["MANA"] = "mana",
  ["MASTERY_RATING"] = "mastery",
  ["MULTICRAFT"] = "multicraft",
  ["PARRY_RATING"] = "parry",
  ["PERCEPTION"] = "perception",
  ["PVP_POWER"] = "pvp power",
  ["RANGED_ATTACK_POWER"] = "ranged attack power",
  ["RESILIENCE_RATING"] = "pvp resilience",
  ["RESOURCEFULNESS"] = "resourcefulness",
  ["SPELL_DAMAGE_DONE"] = "bonus damage",
  ["SPELL_HEALING_DONE"] = "bonus healing",
  ["SPELL_PENETRATION"] = "spell penetration",
  ["SPELL_POWER"] = "spell power",
  ["SPIRIT"] = "spirit",
  ["STAMINA"] = "stamina",
  ["STRENGTH"] = "strength",
  ["VERSATILITY"] = "versatility",
}

if Syndicator.Constants.IsWrath or Syndicator.Constants.IsCata then
  stats = {
    ["AGILITY"] = "agility",
    ["ATTACK_POWER"] = "attack power",
    ["BLOCK_RATING"] = "block rating",
    ["CORRUPTION"] = "corruption",
    ["CRAFTING_SPEED"] = "crafting speed",
    ["CR_AVOIDANCE"] = "avoidance",
    ["CRIT_MELEE_RATING"] = "critical strike rating (melee)",
    ["CRIT_RANGED_RATING"] = "critical strike rating (ranged)",
    ["CRIT_RATING"] = "critical strike rating",
    ["CRIT_SPELL_RATING"] = "critical strike rating (spell)",
    ["CRIT_TAKEN_RATING"] = "critical strike avoidance rating",
    ["CR_LIFESTEAL"] = "leech",
    ["CR_MULTISTRIKE"] = "multistrike",
    ["CR_SPEED"] = "speed",
    ["CR_STURDINESS"] = "indestructible",
    ["DAMAGE_PER_SECOND"] = "damage per second",
    ["DEFENSE_SKILL_RATING"] = "defense rating",
    ["DEFTNESS"] = "deftness",
    ["DODGE_RATING"] = "dodge rating",
    ["EXTRA_ARMOR"] = "bonus armor",
    ["FINESSE"] = "finesse",
    ["HASTE_RATING"] = "haste rating",
    ["HEALTH_REGENERATION"] = "health regeneration",
    ["HIT_MELEE_RATING"] = "hit rating (melee)",
    ["HIT_RANGED_RATING"] = "hit rating (ranged)",
    ["HIT_SPELL_RATING"] = "hit rating (spell)",
    ["HIT_RATING"] = "hit rating",
    ["HIT_TAKEN_RATING"] = "hit avoidance rating",
    ["INTELLECT"] = "intellect",
    ["MANA_REGENERATION"] = "mana regeneration",
    ["MANA"] = "mana",
    ["MASTERY_RATING"] = "mastery",
    ["MULTICRAFT"] = "multicraft",
    ["PARRY_RATING"] = "parry rating",
    ["PERCEPTION"] = "perception",
    ["PVP_POWER"] = "pvp power",
    ["RANGED_ATTACK_POWER"] = "ranged attack power",
    ["RESILIENCE_RATING"] = "resilience rating",
    ["RESOURCEFULNESS"] = "resourcefulness",
    ["SPELL_DAMAGE_DONE"] = "bonus damage",
    ["SPELL_HEALING_DONE"] = "bonus healing",
    ["SPELL_PENETRATION"] = "spell penetration",
    ["SPELL_POWER"] = "spell power",
    ["SPIRIT"] = "spirit",
    ["STAMINA"] = "stamina",
    ["STRENGTH"] = "strength",
    ["VERSATILITY"] = "versatility",
  }
end

for s, english in pairs(stats) do
  local keyword = _G["ITEM_MOD_" .. s .. "_SHORT"] or _G["ITEM_MOD_" .. s]
  if keyword ~= nil then
    AddKeywordManual(keyword:lower(), english, GetGearStatCheck(s), Syndicator.Locales.GROUP_STAT)
    AddKeywordManual(keyword:lower(), english, GetGemStatCheck(keyword), Syndicator.Locales.GROUP_STAT)
  end
end
AddKeywordManual(STAT_ARMOR:lower(), "armor", GetGemStatCheck(STAT_ARMOR), Syndicator.Locales.GROUP_STAT)
if Syndicator.Constants.IsClassic then
  local resistances = {
    "holy resistance",
    "fire resistance",
    "nature resistance",
    "frost resistance",
    "shadow resistance",
    "arcane resistance",
    [0] = "armor",
  }
  for i, english in pairs(resistances) do
    local keyword = _G["RESISTANCE" .. i .. "_NAME"]
    if keyword ~= nil then
      AddKeywordManual(keyword:lower(), english, GetResistanceStatCheck(keyword), Syndicator.Locales.GROUP_STAT)
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

  local operator, value = text:match("([><=]?)(%d+)")

  local wantedItemLevel = tonumber(value)

  if operator == "" or operator == "=" then
    return details.itemLevel and details.itemLevel == wantedItemLevel
  elseif operator == "<" then
  return details.itemLevel and details.itemLevel <= wantedItemLevel
  elseif operator == ">" then
    return details.itemLevel and details.itemLevel >= wantedItemLevel
  else
    error("Unexpected item level operator")
  end
end

local function ItemLevelRangePatternCheck(details, text)
  if GetItemLevel(details) == false then
    return false
  end

  local minText, maxText = text:match("(%d+)%-(%d+)")
  return details.itemLevel and details.itemLevel >= tonumber(minText) and details.itemLevel <= tonumber(maxText)
end

local function GetAuctionValue(details)
  if details.auctionValue then
    return details.auctionValue >= 0
  end
  BindOnAccountCheck(details)
  if details.accountBound == true or details.isBound then
    details.auctionValue = -1
    return false
  elseif details.accountBound == nil then
    return
  end
  if not C_Item.IsItemDataCachedByID(details.itemID) then
    C_Item.RequestLoadItemDataByID(details.itemID)
    return
  end

  details.auctionValue = Syndicator.Search.GetAuctionValue(details.itemLink) or -1

  return details.auctionValue >= 0
end

local function AHValuePatternCheck(details, text)
  if GetAuctionValue(details) == false then
    return details.auctionValue == -2
  end

  local operator, value, scale = text:match("^([><=]?)(%d+)([gsc])$")

  local wantedAuctionValue = tonumber(value)
  if scale == "g" then
    wantedAuctionValue = wantedAuctionValue * 10000
  elseif scale == "s" then
    wantedAuctionValue = wantedAuctionValue * 100
  end

  if operator == "" or operator == "=" then
    return details.auctionValue and details.auctionValue == wantedAuctionValue
  elseif operator == "<" then
    return details.auctionValue and details.auctionValue <= wantedAuctionValue
  elseif operator == ">" then
    return details.auctionValue and details.auctionValue >= wantedAuctionValue
  else
    error("Unexpected auction value operator")
  end
end

local function ExactKeywordCheck(details, text)
  local keyword = text:match("^#(.*)$")
  if KEYWORDS_TO_CHECK[keyword] ~= nil then
    return KEYWORDS_TO_CHECK[keyword](details)
  else
    return false
  end
end

local patterns = {
  ["^[><=]?%d+$"] = ItemLevelPatternCheck,
  ["^%d+%-%d+$"] = ItemLevelRangePatternCheck,

  ["^[><=]?%d+[gsc]$"] = AHValuePatternCheck,
  ["^%d+[gsc]%-%d+[gsc]$"] = AHValueRangePatternCheck,

  ["^%#.*$"] = ExactKeywordCheck,
}

-- Used to prevent equipment and use returning results based on partial words in
-- tooltip data
local EXCLUSIVE_KEYWORDS_NO_TOOLTIP_TEXT = {
  [Syndicator.Locales.KEYWORD_USE] = true,
  [SYNDICATOR_LOCALES.enUS["KEYWORD_USE"]] = true,
  [Syndicator.Locales.KEYWORD_EQUIPMENT] = true,
  [SYNDICATOR_LOCALES.enUS["KEYWORD_EQUIPMENT"]] = true,
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
        -- Cleanup special characters that interfere with typing in text for
        -- tooltip search
        table.insert(details.searchKeywords, (term:lower():gsub("\226\128\147", "-"):gsub("\194\160", " ")))
      else
        local match = line.leftText:match("^" .. ITEM_SPELL_TRIGGER_ONUSE) or line.leftText:match("^" .. ITEM_SPELL_TRIGGER_ONEQUIP) or (UPGRADE_PATH_PATTERN and line.leftText:match(UPGRADE_PATH_PATTERN))
        if details.classID ~= Enum.ItemClass.Recipe and match then
          table.insert(details.searchKeywords, (line.leftText:lower():gsub("\226\128\147", "-"):gsub("\194\160", " ")))
        end
      end
    end

    if #details.tooltipInfoSpell.lines > 1 then
      local color = details.tooltipInfoSpell.lines[2].leftColor
      if color ~= nil and math.floor(color.r * 100) == 52 and math.floor(color.g * 100) == 67 and color.b == 1 then
        table.insert(details.searchKeywords, (details.tooltipInfoSpell.lines[2].leftText:lower():gsub("\226\128\147", "-"):gsub("\194\160", " ")))
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
local savedMatches = {}
-- Search terms with no keyword or pattern match
local savedRejects = {}

-- Each keyword/pattern check function returns nil if the data needed to
-- complete the check doesn't exist yet. Then the item will be queued for
-- checking again on a later frame. If the data is available either true or
-- false is returned.
local function ApplyKeyword(searchString)
  local savedCheck = savedMatches[searchString]
  if savedCheck then
    return savedCheck
  elseif not savedRejects[searchString] then
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
      savedMatches[searchString] = check
      return check
    end

    -- See if a pattern matches, e.g. item level range
    local patternChecker = PatternSearch(searchString)
    if patternChecker then
      savedMatches[searchString] = patternChecker
      return function(details)
        return patternChecker(details, searchString)
      end
    end

    -- Couldn't find anything that matched
    savedRejects[searchString] = true
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

    index = 1
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

  local check = savedMatches[searchString]
  if not check then
    check = ProcessTerms(searchString)
    savedMatches[searchString] = check
  end

  local doNotCache
  result, doNotCache = check(details, searchString)
  if not doNotCache then
    details.fullMatchInfo[searchString] = result
  end
  return result
end

function Syndicator.Search.ClearCache()
  savedMatches = {}
  savedRejects = {}
end

function Syndicator.Search.InitializeSearchEngine()
  local classesToCheck = {
    [0] = "consumable",
    [1] = "container",
    [2] = "weapon",
    [3] = "gem",
    [4] = "armor",
    [5] = "reagent",
    [6] = "projectile",
    [7] = "tradeskill",
    [8] = "item enhancement",
    [9] = "recipe",
    --[10] = "money(obsolete)",
    [11] = "quiver",
    [12] = "quest",
    [13] = "key",
    --[14] = "permanent(obsolete)",
    [15] = "miscellaneous",
    [16] = "glyph",
    [17] = "battle pets",
    [18] = "wow token",
    [19] = "profession",
  }
  if Syndicator.Constants.IsClassic then
    classesToCheck[7] = "trade goods"
    classesToCheck[8] = nil
  end
  if Syndicator.Constants.IsEra then
    classesToCheck[3] = nil
  end
  for i, english in pairs(classesToCheck) do
    local name = C_Item.GetItemClassInfo(i)
    if name then
      local classID = i
      AddKeywordManual(name:lower(), english, function(details)
        GetClassSubClass(details)
        return details.classID == classID
      end, Syndicator.Locales.GROUP_ITEM_TYPE)
    end
  end

  if not Syndicator.Constants.IsEra then
    local tradeGoodsToCheck = {
      [1] = "parts",
      [4] = "jewelcrafting",
      [5] = "cloth",
      [6] = "leather",
      [7] = "metal & stone",
      [8] = "cooking",
      [9] = "herb",
      [10] = "elemental",
      [12] = "enchanting",
      [16] = "inscription",
      [18] = "optional reagents",
      [19] = "finishing reagents",
    }
    if Syndicator.Constants.IsClassic then
      tradeGoodsToCheck[2] = "explosives"
      tradeGoodsToCheck[3] = "devices"
    end
    if Syndicator.Constants.IsEra or Syndicator.Constants.IsBC or Syndicator.Constants.IsWrath or Syndicator.Constants.IsCata then
      tradeGoodsToCheck[8] = "meat"
    end
    for subClass, english in pairs(tradeGoodsToCheck) do
      local keyword = C_Item.GetItemSubClassInfo(7, subClass)
      if keyword ~= nil then
        AddKeywordManual(keyword:lower(), english, function(details)
          GetClassSubClass(details)
          return details.classID == 7 and details.subClassID == subClass
        end, Syndicator.Locales.GROUP_TRADE_GOODS)
      end
    end
  else
    local tradeGoodsToCheck = {
      [1] = "PARTS",
      [2] = "EXPLOSIVES",
      [3] = "DEVICES",
      [5] = "CLOTH",
      [6] = "LEATHER",
      [7] = "METAL_AND_STONE",
      [8] = "MEAT",
      [9] = "HERB",
      [10] = "ELEMENTAL",
      [12] = "ENCHANTING",
    }
    for subClass, localeString in pairs(tradeGoodsToCheck) do
      AddKeywordLocalised("KEYWORD_SUBCLASS_" .. localeString, function(details)
        GetClassSubClass(details)
        return details.classID == 7 and details.subClassID == subClass
      end, Syndicator.Locales.GROUP_TRADE_GOODS)
    end
  end

  local armorTypesToCheck = {
    [2] = "leather",
    [3] = "mail",
    [4] = "plate",
    [6] = "shields",
  }
  if Syndicator.Constants.IsEra then
    for subClass, english in pairs({
        [7] = "librams",
        [8] = "idols",
        [9] = "totems",
        [10] = "sigils",
        [11] = "relic",
      }) do
      armorTypesToCheck[subClass] = english
    end
  end
  for subClass, english in pairs(armorTypesToCheck) do
    local keyword = C_Item.GetItemSubClassInfo(Enum.ItemClass.Armor, subClass)
    if keyword ~= nil then
      AddKeywordManual(keyword:lower(), english, function(details)
        GetClassSubClass(details)
        return details.classID == Enum.ItemClass.Armor and details.subClassID == subClass
      end, Syndicator.Locales.GROUP_ARMOR_TYPE)
    end
  end
  -- cloth armor, but excluding cloaks
  AddKeywordManual(C_Item.GetItemSubClassInfo(Enum.ItemClass.Armor, 1):lower(), "cloth", function(details)
    GetClassSubClass(details)
    return details.classID == Enum.ItemClass.Armor and details.subClassID == Enum.ItemArmorSubclass.Cloth
  end, Syndicator.Locales.GROUP_ARMOR_TYPE)

  local weaponTypesToCheck = {
    "two-handed axes",
    "bows",
    "guns",
    "one-handed maces",
    "two-handed maces",
    "polearms",
    "one-handed swords",
    "two-handed swords",
    "warglaives",
    "staves",
    "bear claws",
    "catclaws",
    "fist weapons",
    "miscellaneous",
    "daggers",
    "thrown",
    "spears",
    "crossbows",
    "wands",
    "fishing poles",
    [0] = "one-handed axes",
  }
  if Syndicator.Constants.IsClassic then
    weaponTypesToCheck[9] = nil
    weaponTypesToCheck[11] = "one-handed exotics"
    weaponTypesToCheck[12] = "two-handed exotics"
  end
  if Syndicator.Constants.IsEra then
    weaponTypesToCheck[20] = "fishing pole"
  end
  -- All weapons + fishingpole
  for subClass, english in pairs(weaponTypesToCheck) do
    local keyword = C_Item.GetItemSubClassInfo(Enum.ItemClass.Weapon, subClass)
    if keyword ~= nil then
      AddKeywordManual(keyword:lower(), english, function(details)
        GetClassSubClass(details)
        return details.classID == Enum.ItemClass.Weapon and details.subClassID == subClass
      end, Syndicator.Locales.GROUP_WEAPON_TYPE)
    end
  end

  local recipeTypesToCheck = {
    "leatherworking",
    "tailoring",
    "engineering",
    "blacksmithing",
    "cooking",
    "alchemy",
    "first aid",
    "enchanting",
    "fishing",
    "jewelcrafting",
    "inscription",
  }
  for subClass, english in pairs(recipeTypesToCheck) do
    local keyword = C_Item.GetItemSubClassInfo(Enum.ItemClass.Recipe, subClass)
    if keyword ~= nil then
      AddKeywordManual(keyword:lower(), english, function(details)
        GetClassSubClass(details)
        return details.classID == Enum.ItemClass.Recipe and details.subClassID == subClass
      end, Syndicator.Locales.GROUP_RECIPE)
    end
  end

  if C_PetJournal then
    local petsToCheck = {
      "dragonkin",
      "flying",
      "undead",
      "critter",
      "magic",
      "elemental",
      "beast",
      "aquatic",
      "mechanical",
      [0] = "humanoid",
    }
    for subClass, english in pairs(petsToCheck) do
      local keyword = C_Item.GetItemSubClassInfo(Enum.ItemClass.Battlepet, subClass)
      if keyword ~= nil then
        AddKeywordManual(keyword:lower(), english, function(details)
        GetClassSubClass(details)
          return details.classID == Enum.ItemClass.Battlepet and details.subClassID == subClass
        end, Syndicator.Locales.GROUP_BATTLE_PET)
      end
    end
  end

  local glyphsToCheck = {
    "warrior",
    "paladin",
    "hunter",
    "rogue",
    "priest",
    "death knight",
    "shaman",
    "mage",
    "warlock",
    "monk",
    "druid",
    "demon hunter",
  }
  for subClass, english in pairs(glyphsToCheck) do
    local keyword = C_Item.GetItemSubClassInfo(Enum.ItemClass.Glyph, subClass)
    if keyword ~= nil then
      AddKeywordManual(keyword:lower(), english, function(details)
        GetClassSubClass(details)
        return details.classID == Enum.ItemClass.Glyph and details.subClassID == subClass
      end, Syndicator.Locales.GROUP_GLYPH)
    end
  end

  if not Syndicator.Constants.IsEra then
    local consumablesToCheck = {
      "potions",
      "elixirs",
      "flasks & phials",
      nil,
      "food & drink",
      nil,
      "bandages",
      "other",
      "vantus runes",
      "utility curio",
      "combat curio",
      [0] = "explosives and devices",
    }
    if Syndicator.Constants.IsClassic then
      consumablesToCheck[0] = nil
      consumablesToCheck[1] = "potion"
      consumablesToCheck[2] = "elixir"
      consumablesToCheck[3] = "flask"
      consumablesToCheck[4] = "scroll"
      consumablesToCheck[6] = "item enhancement"
      consumablesToCheck[7] = "bandage"
      consumablesToCheck[10] = nil
      consumablesToCheck[11] = nil
    end
    for subClass, english in pairs(consumablesToCheck) do
      local keyword = C_Item.GetItemSubClassInfo(Enum.ItemClass.Consumable, subClass)
      if keyword ~= nil then
        AddKeywordManual(keyword:lower(), english, function(details)
          GetClassSubClass(details)
          return details.classID == Enum.ItemClass.Consumable and details.subClassID == subClass
        end, Syndicator.Locales.GROUP_CONSUMABLE)
      end
    end
  else
    local consumablesToCheck = {
      [1] = "POTION",
      [2] = "ELIXIR",
      [3] = "FLASK",
      [4] = "SCROLL",
      [5] = "FOOD_AND_DRINK",
      [6] = "ITEM_ENHANCEMENT",
      [8] = "BANDAGES",
    }
    for subClass, localeString in pairs(consumablesToCheck) do
      AddKeywordLocalised("KEYWORD_SUBCLASS_" .. localeString, function(details)
        GetClassSubClass(details)
        return details.classID == Enum.ItemClass.Consumable and details.subClassID == subClass
      end, Syndicator.Locales.GROUP_CONSUMABLE)
    end
  end

  local mount = C_Item.GetItemSubClassInfo(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.Mount)
  if mount ~= nil then
    AddKeywordManual(mount:lower(), "mount", MountCheck, Syndicator.Locales.GROUP_ITEM_TYPE)
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

function Syndicator.Search.GetKeywordsEnglish()
  return KEYWORD_AND_CATEGORY_ENGLISH
end
