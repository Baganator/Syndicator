Syndicator.Constants = {
  AllBagIndexes = {
    Enum.BagIndex.Backpack,
    Enum.BagIndex.Bag_1,
    Enum.BagIndex.Bag_2,
    Enum.BagIndex.Bag_3,
    Enum.BagIndex.Bag_4,
  },
  AllBankIndexes = {},
  AllWarbandIndexes = {},

  IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
  IsClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE,
  IsMists = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC,
  IsCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC,
  IsWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC,
  IsBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC,
  IsEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC,

  IsLegacyAH = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC or IsUsingLegacyAuctionClient ~= nil and IsUsingLegacyAuctionClient(),

  BattlePetCageID = 82800,

  BankBagSlotsCount = 0,

  MaxGuildBankTabItemSlots = 98,

  EquippedInventorySlotOffset = 1,

  WarbandBankActive = false,

  MailExpiryDuration = 30 * 24 * 60 * 60,
}

Syndicator.Constants.IsBrokenTooltipScanning = false

if Syndicator.Constants.IsRetail then
  Syndicator.Constants.WarbandBankActive = true
  Syndicator.Constants.CharacterBankTabsActive = Enum.BagIndex.CharacterBankTab_1 ~= nil
  table.insert(Syndicator.Constants.AllBagIndexes, Enum.BagIndex.ReagentBag)
  Syndicator.Constants.BagSlotsCount = 5
  Syndicator.Constants.MaxBagSize = 42
  if Syndicator.Constants.CharacterBankTabsActive then
    Syndicator.Constants.AllBankIndexes = {
      Enum.BagIndex.CharacterBankTab_1,
      Enum.BagIndex.CharacterBankTab_2,
      Enum.BagIndex.CharacterBankTab_3,
      Enum.BagIndex.CharacterBankTab_4,
      Enum.BagIndex.CharacterBankTab_5,
      Enum.BagIndex.CharacterBankTab_6,
    }
    Syndicator.Constants.BankBagSlotsCount = 0
  else
    Syndicator.Constants.AllBankIndexes = {
      Enum.BagIndex.Bank,
      Enum.BagIndex.BankBag_1,
      Enum.BagIndex.BankBag_2,
      Enum.BagIndex.BankBag_3,
      Enum.BagIndex.BankBag_4,
      Enum.BagIndex.BankBag_5,
      Enum.BagIndex.BankBag_6,
      Enum.BagIndex.BankBag_7,
      Enum.BagIndex.Reagentbank,
    }
    Syndicator.Constants.BankBagSlotsCount = 7
  end
  Syndicator.Constants.AllWarbandIndexes = {
    Enum.BagIndex.AccountBankTab_1,
    Enum.BagIndex.AccountBankTab_2,
    Enum.BagIndex.AccountBankTab_3,
    Enum.BagIndex.AccountBankTab_4,
    Enum.BagIndex.AccountBankTab_5,
  }
end

if Syndicator.Constants.IsEra or KeyRingButtonIDToInvSlotID then
  table.insert(Syndicator.Constants.AllBagIndexes, Enum.BagIndex.Keyring)
end
if Syndicator.Constants.IsEra then
  Syndicator.Constants.BankBagSlotsCount = 6
elseif Syndicator.Constants.IsClassic then
  Syndicator.Constants.BankBagSlotsCount = 7
end
if Syndicator.Constants.IsClassic then
  Syndicator.Constants.AllBankIndexes = {
    Enum.BagIndex.Bank,
  }
  -- Workaround for the enum containing the wrong values for the bank bag slots
  for i = 1, Syndicator.Constants.BankBagSlotsCount do
    Syndicator.Constants.AllBankIndexes[i + 1] = NUM_BAG_SLOTS + i
  end
  Syndicator.Constants.BagSlotsCount = 4
  Syndicator.Constants.MaxBagSize = 36
end

Syndicator.Constants.Events = {
  "CharacterDeleted",
  "GuildDeleted",

  "BagCacheUpdate",
  "WarbandBankCacheUpdate",
  "MailCacheUpdate",
  "CurrencyCacheUpdate",
  "WarbandCurrencyCacheUpdate",
  "GuildCacheUpdate",
  "GuildNameSet",
  "EquippedCacheUpdate",
  "VoidCacheUpdate",
  "AuctionsCacheUpdate",

  "Ready",

  "AuctionValueSourceChanged"
}

-- Hidden currencies for all characters tooltips as they are shared between characters
Syndicator.Constants.SharedCurrencies = {
  2032, -- Trader's Tender
}

local AccountBoundTooltipLines = {
  ITEM_BIND_TO_BNETACCOUNT,
  ITEM_BNETACCOUNTBOUND,
  ITEM_BIND_TO_ACCOUNT,
  ITEM_ACCOUNTBOUND,
}
local AccountBoundTooltipLinesNotBound = {
  ITEM_ACCOUNTBOUND_UNTIL_EQUIP,
  ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP,
}
Syndicator.Constants.AccountBoundTooltipLines = {}
Syndicator.Constants.AccountBoundTooltipLinesNotBound = {}
-- Done this way because not all the lines exist on all clients
for _, line in pairs(AccountBoundTooltipLines) do
  table.insert(Syndicator.Constants.AccountBoundTooltipLines, line)
end
for _, line in pairs(AccountBoundTooltipLinesNotBound) do
  table.insert(Syndicator.Constants.AccountBoundTooltipLinesNotBound, line)
end
