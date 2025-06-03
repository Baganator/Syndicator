---@meta

WOW_PROJECT_MISTS_CLASSIC = -1
---@param id number
KeyRingButtonIDToInvSlotID = function(id) end

BAGANATOR_SUMMARIES = {}
BAGANATOR_DATA = {}

---@param index number
---@param reagentIndex number
---@return string
GetCraftReagentItemLink = function(index, reagentIndex) end

---@return boolean
IsAddOnLoaded = function(name) end

---@return boolean
IsUsingLegacyAuctionClient = function() end
GetOwnerAuctionItems = function() end
---@param mode "owner"|"list"|"owner"
GetNumAuctionItems = function(mode) end
---@param mode "owner"|"list"|"owner"
---@param index number
GetAuctionItemInfo = function(mode, index) end
---@param mode "owner"|"list"|"owner"
---@param index number
GetAuctionItemLink = function(mode, index) end

GetBackpackCurrencyInfo = function(index) end
---@return number
GetCurrencyListSize = function() end
ManageBackpackTokenFrame = {}
---@param index number
---@return string, boolean, boolean, boolean, number, string, number, number, number, nil, number
GetCurrencyListInfo = function(index) end
---@param index number
---@param state 0|1
ExpandCurrencyList = function(index, state) end
---@param index number
---@param state 0|1
SetCurrencyBackpack = function(index, state) end

---@param currencyID number
---@return string
GetCurrencyLink = function(currencyID) end

---@param tabIndex number
---@param slotIndex number
---@return string
GetGuildBankItemLink = function(tabIndex, slotIndex) end
---@param tabIndex number
---@param slotIndex number
---@return number?, number?, boolean?, boolean?, number?
GetGuildBankItemInfo = function(tabIndex, slotIndex) end

---@param bagID number
---@param slotID number
---@return ContainerItemInfo?
C_Container.GetContainerItemInfo = function(bagID, slotID) end

---@return number
GetCurrentGuildBankTab = function() end

--Searches
ItemVersion = {}
ATTC = {}
---@return table
GetItemStats = function() end

FramePool_HideAndClearAnchors = function(frame) end

--Tooltips
CUSTOM_CLASS_COLORS = {}

-- Lifted from the type definitions in Numy's Transmog Upgrade Master addon
TransmogUpgradeMaster_API = {}
--- @return boolean isCacheWarmedUp
--- @return number progress # a number between 0 and 1, where 1 means caching has finished
function TransmogUpgradeMaster_API.IsCacheWarmedUp()
end

--- @param itemLink string
--- @param classID number? # defaults to the player's class
--- @return boolean? canCatalyse # whether the item can be catalysed; if false, the catalystAppearanceMissing return values will be nil
--- @return boolean? canUpgrade # whether the item can be upgraded to the next tier; if false, the upgradeAppearanceMissing return values will be nil
--- @return boolean? catalystAppearanceMissing # true if the item will teach a new appearance when catalysed
--- @return boolean? catalystUpgradeAppearanceMissing # true if the item will teach a new appearance when catalysed AND upgraded to the next tier
--- @return boolean? upgradeAppearanceMissing # true if the item will teach a new appearance when upgraded to the next tier
function TransmogUpgradeMaster_API.IsAppearanceMissing(itemLink, classID)
end
