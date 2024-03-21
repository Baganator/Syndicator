Syndicator.Constants = {
  AllBagIndexes = {
    Enum.BagIndex.Backpack,
    Enum.BagIndex.Bag_1,
    Enum.BagIndex.Bag_2,
    Enum.BagIndex.Bag_3,
    Enum.BagIndex.Bag_4,
  },
  AllBankIndexes = {
    Enum.BagIndex.Bank,
    Enum.BagIndex.BankBag_1,
    Enum.BagIndex.BankBag_2,
    Enum.BagIndex.BankBag_3,
    Enum.BagIndex.BankBag_4,
    Enum.BagIndex.BankBag_5,
    Enum.BagIndex.BankBag_6,
    Enum.BagIndex.BankBag_7,
  },
  IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
  IsClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE,

  BattlePetCageID = 82800,

  BankBagSlotsCount = 7,

  MaxGuildBankTabItemSlots = 98,

  EquippedInventorySlotOffset = 1,
}

if not Syndicator.Constants.IsRetail then
  table.insert(Syndicator.Constants.AllBagIndexes, Enum.BagIndex.Keyring)
end
if Syndicator.Constants.IsRetail then
  table.insert(Syndicator.Constants.AllBagIndexes, Enum.BagIndex.ReagentBag)
  table.insert(Syndicator.Constants.AllBankIndexes, Enum.BagIndex.Reagentbank)
  Syndicator.Constants.BagSlotsCount = 5
  Syndicator.Constants.MaxBagSize = 42
end
if Syndicator.Constants.IsClassic then
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
  "MailCacheUpdate",
  "CurrencyCacheUpdate",
  "GuildCacheUpdate",
  "GuildNameSet",
  "EquippedCacheUpdate",
  "VoidCacheUpdate",
  "AuctionsCacheUpdate",

  "Ready",
}

-- Hidden currencies for all characters tooltips as they are shared between characters
Syndicator.Constants.SharedCurrencies = {
  2032, -- Trader's Tender
}

Syndicator.Constants.AccountBoundTooltipLines = {
  ITEM_BIND_TO_BNETACCOUNT,
  ITEM_BNETACCOUNTBOUND,
  ITEM_BIND_TO_ACCOUNT,
  ITEM_ACCOUNTBOUND,
}
