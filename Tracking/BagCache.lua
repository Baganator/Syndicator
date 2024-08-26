SyndicatorBagCacheMixin = {}

local craftingItemUpdateDelay = 2
local bankBags = {}
local bagBags = {}
local warbandBags = {}
for index, key in ipairs(Syndicator.Constants.AllBagIndexes) do
  bagBags[key] = index
end
for index, key in ipairs(Syndicator.Constants.AllBankIndexes) do
  bankBags[key] = index
end
for index, key in ipairs(Syndicator.Constants.AllWarbandIndexes) do
  warbandBags[key] = index
end

local function GetEmptyPending()
  return {
    bags = {},
    bank = {},
    warband = {},
    reagentBankSlots = {},
    containerBags = {
      bags = false,
      bank = false,
      warband = false
    }
  }
end

-- Assumed to run after PLAYER_LOGIN
function SyndicatorBagCacheMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, {
    -- Regular bag items updating
    "BAG_UPDATE",
    -- Bag replaced
    "BAG_CONTAINER_UPDATE",

    -- Bank open/close (used to determine whether to cache or not)
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
    "PLAYERBANKSLOTS_CHANGED",
    "PLAYERBANKBAGSLOTS_CHANGED",
  })
  if Syndicator.Constants.IsRetail then
    -- Bank items reagent bank updating
    self:RegisterEvent("REAGENTBANK_UPDATE")
    self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
    self:RegisterEvent("TRADE_SKILL_ITEM_CRAFTED_RESULT")
    -- Keystone level changing due to start/end of an M+ dungeon
    self:RegisterEvent("ITEM_CHANGED")
    self:RegisterEvent("CHALLENGE_MODE_START")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED")

    if Syndicator.Constants.WarbandBankActive then
      self:RegisterEvent("BANK_TABS_CHANGED")
      self:RegisterEvent("BANK_TAB_SETTINGS_UPDATED")
      self:RegisterEvent("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED")
    end
  end

  self.craftingTime = 0

  self.currentCharacter = Syndicator.Utilities.GetCharacterFullName()

  while #SYNDICATOR_DATA.Characters[self.currentCharacter].bags > #Syndicator.Constants.AllBagIndexes do
    table.remove(SYNDICATOR_DATA.Characters[self.currentCharacter].bags)
  end

  self:SetupPending()

  for bagID in pairs(bagBags) do
    self.pending.bags[bagID] = true
  end

  self:ScanContainerBagSlots()
  self:QueueCaching()
end

function SyndicatorBagCacheMixin:QueueCaching()
  self.isUpdatePending = true
  self:SetScript("OnUpdate", self.OnUpdate)
end

function SyndicatorBagCacheMixin:OnEvent(eventName, ...)
  if eventName == "BAG_UPDATE" then
    local bagID = ...
    if bagBags[bagID] then
      self.pending.bags[bagID] = true
    elseif bankBags[bagID] and self.bankOpen then
      self.pending.bank[bagID] = true
    elseif warbandBags[bagID] and self.bankOpen then
      self.pending.warband[bagID] = true
    end
    self:QueueCaching()

  elseif eventName == "PLAYERBANKSLOTS_CHANGED" then
    if self.bankOpen then
      self.pending.bank[Enum.BagIndex.Bank] = true
      self:QueueCaching()
    end

  elseif eventName == "PLAYERREAGENTBANKSLOTS_CHANGED" then
    if self.bankOpen or time() - self.craftingTime < craftingItemUpdateDelay then
      self.pending.bank[Enum.BagIndex.Reagentbank] = true
      if not self.bankOpen then -- can only scan changed slots when bank is closed
        self.pending.reagentBankSlots[...] = true
      end
      self:QueueCaching()
    end

  elseif eventName == "REAGENTBANK_UPDATE" then
    self.pending.bank[Enum.BagIndex.Reagentbank] = true
    if self.bankOpen then
      self:QueueCaching()
    end

  elseif eventName == "BAG_CONTAINER_UPDATE" then
    self:UpdateContainerSlots()

  elseif eventName == "PLAYERBANKBAGSLOTS_CHANGED" then
    self:UpdateContainerSlots()

  elseif eventName == "BANK_TAB_SETTINGS_UPDATED" then
    if self.bankOpen then
      self:ScanWarbandSlots()
      self:QueueCaching()
    end

  -- Guessing that these events may be fired when a new warband tab is purchased
  elseif eventName == "BANK_TABS_CHANGED" or eventName == "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED" then
    if self.bankOpen or time() - self.craftingTime < craftingItemUpdateDelay then
      self:ScanWarbandSlots()
      for bagID in pairs(warbandBags) do
        self.pending.warband[bagID] = true
      end
      self:QueueCaching()
    end

  elseif eventName == "BANKFRAME_OPENED" then
    self.bankOpen = true
    for bagID in pairs(bankBags) do
      self.pending.bank[bagID] = true
    end
    for bagID in pairs(warbandBags) do
      self.pending.warband[bagID] = true
    end
    self:ScanContainerBagSlots()
    self:ScanWarbandSlots()
    self:QueueCaching()

  elseif eventName == "BANKFRAME_CLOSED" then
    self.bankOpen = false

  elseif eventName == "ITEM_CHANGED" or eventName == "CHALLENGE_MODE_START" or eventName == "CHALLENGE_MODE_COMPLETED" then
    C_Timer.After(1, function()
      for bagID in pairs(bagBags) do
        self.pending.bags[bagID] = true
      end
      if self.bankOpen then
        for bagID in pairs(bankBags) do
          self.pending.bank[bagID] = true
        end
      end
      self:QueueCaching()
    end)
  -- We keep the time of the last crafted item to avoid processing spurious bank
  -- update events during and shortly after loading screens.
  elseif eventName == "TRADE_SKILL_ITEM_CRAFTED_RESULT" then
    self.craftingTime = time()
  end
end

function SyndicatorBagCacheMixin:SetupPending()
  -- Used to batch updates until the next OnUpdate tick
  self.pending = GetEmptyPending()
end

function SyndicatorBagCacheMixin:UpdateContainerSlots()
  if not self.currentCharacter then
    return
  end

  local bags = SYNDICATOR_DATA.Characters[self.currentCharacter].bags
  for index, bagID in ipairs(Syndicator.Constants.AllBagIndexes) do
    local numSlots = C_Container.GetContainerNumSlots(bagID)
    if (bags[index] and numSlots ~= #bags[index]) or (bags[index] == nil and numSlots > 0) then
      self.pending.bags[bagID] = true
    end
  end

  if self.bankOpen then
    local bank = SYNDICATOR_DATA.Characters[self.currentCharacter].bank
    for index, bagID in ipairs(Syndicator.Constants.AllBankIndexes) do
      local numSlots = C_Container.GetContainerNumSlots(bagID)
      if (bank[index] and numSlots ~= #bank[index]) or (bank[index] == nil and numSlots > 0) then
        self.pending.bank[bagID] = true
      end
    end
  end

  self:ScanContainerBagSlots()
  self:QueueCaching()
end

function SyndicatorBagCacheMixin:ScanWarbandSlots()
  if C_Bank == nil or C_Bank.FetchPurchasedBankTabData == nil then
    return
  end

  local allTabs = C_Bank.FetchPurchasedBankTabData(Enum.BankType.Account)

  local warband = SYNDICATOR_DATA.Warband[1]

  for index, tabDetails in ipairs(allTabs) do
    if not warband.bank[index] then
      warband.bank[index] = { slots = {}, iconTexture = QUESTION_MARK_ICON, name = "", depositFlags = 0 }
    end
    warband.bank[index].iconTexture = tabDetails.icon
    warband.bank[index].name = tabDetails.name
    warband.bank[index].depositFlags = tabDetails.depositFlags
  end
  self.pending.containerBags.warband = true
end

function SyndicatorBagCacheMixin:ScanContainerBagSlots()
  local function DoBagSlot(inventorySlot)
    local location = {equipmentSlotIndex = inventorySlot}
    local itemID = GetInventoryItemID("player", inventorySlot)
    if not itemID then
      return {}
    else
      return {
        itemID = itemID,
        itemCount = 1,
        iconTexture = GetInventoryItemTexture("player", inventorySlot),
        itemLink = GetInventoryItemLink("player", inventorySlot),
        quality = GetInventoryItemQuality("player", inventorySlot),
        isBound = C_Item.IsBound(location),
      }
    end
  end
  local containerInfo = SYNDICATOR_DATA.Characters[self.currentCharacter].containerInfo
  do
    containerInfo.bags = {}
    for index = 1, Syndicator.Constants.BagSlotsCount do
      local inventorySlot = C_Container.ContainerIDToInventoryID(index)
      local itemID = GetInventoryItemID("player", inventorySlot)
      if itemID ~= nil then
        if C_Item.IsItemDataCachedByID(itemID) then
          containerInfo.bags[index] = DoBagSlot(inventorySlot)
        else
          Syndicator.Utilities.LoadItemData(itemID, function()
            containerInfo.bags[index] = DoBagSlot(inventorySlot)
          end)
        end
      else
        containerInfo.bags[index] = {}
      end
    end
    self.pending.containerBags.bags = true
  end

  if self.bankOpen then
    containerInfo.bank = {}
    for index = 1, Syndicator.Constants.BankBagSlotsCount do
      local inventorySlot = BankButtonIDToInvSlotID(index, 1)
      local itemID = GetInventoryItemID("player", inventorySlot)
      if itemID ~= nil then
        if C_Item.IsItemDataCachedByID(itemID) then
          containerInfo.bank[index] = DoBagSlot(inventorySlot)
        else
          Syndicator.Utilities.LoadItemData(itemID, function()
            containerInfo.bank[index] = DoBagSlot(inventorySlot)
          end)
        end
      else
        containerInfo.bank[index] = {}
      end
    end
    self.pending.containerBags.bank = true
  end
end

function SyndicatorBagCacheMixin:OnUpdate()
  self:SetScript("OnUpdate", nil)
  if self.currentCharacter == nil then
    return
  end

  local start = debugprofilestop()

  local pendingCopy = CopyTable(self.pending)
  pendingCopy.reagentBankSlots = nil

  local function FireBagChange()
    if Syndicator.Config.Get(Syndicator.Config.Options.DEBUG_TIMERS) then
      print("caching took", debugprofilestop() - start)
    end
    self.isUpdatePending = false
    if next(pendingCopy.bank) or next(pendingCopy.bags) or pendingCopy.containerBags.bags or pendingCopy.containerBags.bank then
      Syndicator.CallbackRegistry:TriggerEvent("BagCacheUpdate", self.currentCharacter, {
        bags = pendingCopy.bags,
        bank = pendingCopy.bank,
        containerBags = {
          bags = pendingCopy.containerBags.bags,
          bank = pendingCopy.containerBags.bank,
        }
      })
    end
    if next(pendingCopy.warband) or pendingCopy.containerBags.warband then
      Syndicator.CallbackRegistry:TriggerEvent("WarbandBankCacheUpdate", 1, {bags = pendingCopy.warband, tabInfo = pendingCopy.containerBags.warband})
    end
  end

  local waiting = 0
  local loopsFinished = false

  local function GetInfo(slotInfo)
    return {
      itemID = slotInfo.itemID,
      itemCount = slotInfo.stackCount,
      iconTexture = slotInfo.iconFileID,
      itemLink = slotInfo.hyperlink,
      quality = slotInfo.quality,
      isBound = slotInfo.isBound,
    }
  end


  local function DoSlot(bagID, slotID, bag)
    -- Create raw location as optimisation (~20% time saving)
    -- Equivalent to ItemLocation:CreateFromBagAndSlot(bagID, slotID)
    local location = {bagID = bagID, slotIndex = slotID}
    local itemID = C_Item.DoesItemExist(location) and C_Item.GetItemID(location)
    bag[slotID] = {}
    if itemID then
      if C_Item.IsItemDataCachedByID(itemID) then
        local slotInfo = C_Container.GetContainerItemInfo(bagID, slotID)
        if slotInfo then
          bag[slotID] = GetInfo(slotInfo)
        end
      else
        waiting = waiting + 1
        Syndicator.Utilities.LoadItemData(itemID, function()
          local slotInfo = C_Container.GetContainerItemInfo(bagID, slotID)
          if slotInfo and slotInfo.itemID == itemID then
            bag[slotID] = GetInfo(slotInfo)
          end
          waiting = waiting - 1
          if loopsFinished and waiting == 0 then
            FireBagChange()
          end
        end)
      end
    end
  end

  local bags = SYNDICATOR_DATA.Characters[self.currentCharacter].bags

  for bagID in pairs(self.pending.bags) do
    local bagIndex = bagBags[bagID]
    bags[bagIndex] = {}
    local bagData = bags[bagIndex]
    for slotID = 1, C_Container.GetContainerNumSlots(bagID) do
      DoSlot(bagID, slotID, bagData)
    end
  end

  local bank = SYNDICATOR_DATA.Characters[self.currentCharacter].bank

  if self.bankOpen then
    for bagID in pairs(self.pending.bank) do
      local bagIndex = bankBags[bagID]
      bank[bagIndex] = {}
      local bagData = bank[bagIndex]
      if bagID ~= Enum.BagIndex.Reagentbank or IsReagentBankUnlocked() then
        for slotID = 1, C_Container.GetContainerNumSlots(bagID) do
          DoSlot(bagID, slotID, bagData)
        end
      end
    end
  elseif self.pending.bank[Enum.BagIndex.Reagentbank] and bank[bankBags[Enum.BagIndex.Reagentbank]] and IsReagentBankUnlocked() then
    local reagentBankData = bank[bankBags[Enum.BagIndex.Reagentbank]]
    for slotID in pairs(self.pending.reagentBankSlots) do
      if #reagentBankData >= slotID then
        DoSlot(Enum.BagIndex.Reagentbank, slotID, reagentBankData)
      end
    end
  end

  local warband = SYNDICATOR_DATA.Warband[1]

  for bagID in pairs(self.pending.warband) do
    local bagIndex = warbandBags[bagID]
    if warband.bank[bagIndex] then
      warband.bank[bagIndex].slots = {}
      local bagData = warband.bank[bagIndex].slots
      for slotID = 1, C_Container.GetContainerNumSlots(bagID) do
        DoSlot(bagID, slotID, bagData)
      end
    end
  end

  loopsFinished = true

  self:SetupPending()

  if waiting == 0 then
    FireBagChange()
  end
end
