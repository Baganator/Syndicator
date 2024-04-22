if not Syndicator.Constants.IsRetail then
  return
end

SyndicatorAuctionCacheMixin = {}

local AUCTIONS_UPDATED_EVENTS = {
  "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
  "OWNED_AUCTIONS_UPDATED",
  "AUCTION_HOUSE_AUCTION_CREATED",
  "AUCTION_HOUSE_AUCTIONS_EXPIRED",
  "AUCTION_CANCELED",
  "AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION",
  "AUCTION_HOUSE_PURCHASE_COMPLETED",
  "COMMODITY_PURCHASE_SUCCEEDED",
}

function SyndicatorAuctionCacheMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, AUCTIONS_UPDATED_EVENTS)
  self.currentCharacter = Syndicator.Utilities.GetCharacterFullName()

  self.postedItemsQueue = {}
  self.lastPostedItem = {}
  hooksecurefunc(C_AuctionHouse, "PostItem", function(itemLocation)
    local itemLink = C_Item.GetItemLink(itemLocation)
    self.lastPostedItem = {
      itemLink = C_Item.GetItemLink(itemLocation),
      itemID = C_Item.GetItemID(itemLocation),
    }
    if not C_Item.IsItemDataCached(itemLocation) then
      local item = Item:CreateFromItemLocation(itemLocation)
      item:ContinueOnItemLoad(function()
        if C_Item.DoesItemExist(itemLocation) then
          self.lastPostedItem.itemLink = C_Item.GetItemLink(itemLocation)
        else
          self.lastPostedItem.itemLink = select(2, C_Item.GetItemInfo(self.lastPostedItem.itemLink))
        end
      end)
    end
  end)
  hooksecurefunc(C_AuctionHouse, "PostCommodity", function(itemLocation, _, itemCount)
    self.postedCommodity = {
      itemID = C_Item.GetItemID(itemLocation),
      itemCount = itemCount,
    }
  end)

  hooksecurefunc(C_AuctionHouse, "PlaceBid", function(auctionID)
    local auctionInfo = C_AuctionHouse.GetAuctionInfoByID(auctionID)
    auctionInfo.auctionID = auctionID
    self.purchasedItem = {
      auctionInfo = auctionInfo,
      itemCount = 1,
    }
    -- Ensure we have a perfect item link
    if not C_Item.IsItemDataCachedByID(auctionInfo.itemKey.itemID) then
      local item = Item:CreateFromItemID(auctionInfo.itemKey.itemID)
      item:ContinueOnItemLoad(function()
        local auctionInfo = C_AuctionHouse.GetAuctionInfoByID(auctionID)
        if not auctionInfo then
          if self.purchasedItem.auctionInfo.itemLink then
            self.purchasedItem.auctionInfo.itemLink = select(2, C_Item.GetItemInfo(self.purchasedItem.auctionInfo.itemLink))
          end
        else
          auctionInfo.auctionID = auctionID
          self.purchasedItem.auctionInfo = auctionInfo
        end
      end)
    end
  end)
  hooksecurefunc(C_AuctionHouse, "ConfirmCommoditiesPurchase", function(itemID, itemCount)
    self.purchasedCommodity = {
      itemID = itemID,
      itemCount = itemCount,
    }
  end)
end

local function ConvertAuctionInfoToItem(auctionInfo, itemCount)
  local itemInfo = {C_Item.GetItemInfo(auctionInfo.itemLink or auctionInfo.itemKey.itemID)}
  local itemLink = auctionInfo.itemLink or itemInfo[2]
  local iconTexture = itemInfo[10]
  local quality = itemInfo[3] 

  if auctionInfo.itemKey.itemID == Syndicator.Constants.BattlePetCageID then
    local speciesIDText, qualityText = itemLink:match("battlepet:(%d+):%d+:(%d+)")
    iconTexture = select(2, C_PetJournal.GetPetInfoBySpeciesID(tonumber(speciesIDText)))
    quality = tonumber(qualityText)
  end

  return {
    itemID = auctionInfo.itemKey.itemID,
    itemCount = itemCount,
    iconTexture = iconTexture,
    itemLink = itemLink,
    quality = quality,
    isBound = false,
  }
end

function SyndicatorAuctionCacheMixin:AddToMail(item)
  table.insert(SYNDICATOR_DATA.Characters[self.currentCharacter].mail, item)
  Syndicator.CallbackRegistry:TriggerEvent("MailCacheUpdate", self.currentCharacter)
end

function SyndicatorAuctionCacheMixin:AddAuction(auctionInfo, itemCount)
  local item = ConvertAuctionInfoToItem(auctionInfo, itemCount)
  item.auctionID = auctionInfo.auctionID
  table.insert(
    SYNDICATOR_DATA.Characters[self.currentCharacter].auctions,
    item
  )
  Syndicator.CallbackRegistry:TriggerEvent("AuctionsCacheUpdate", self.currentCharacter)
end

function SyndicatorAuctionCacheMixin:RemoveAuctionByID(auctionID, addToMail)
  for index, item in ipairs(SYNDICATOR_DATA.Characters[self.currentCharacter].auctions) do
    if item.auctionID == auctionID then
      table.remove(SYNDICATOR_DATA.Characters[self.currentCharacter].auctions, index)
      Syndicator.CallbackRegistry:TriggerEvent("AuctionsCacheUpdate", self.currentCharacter)
      item.auctionID = nil
      if addToMail then
        self:AddToMail(item)
      end
      break
    end
  end
end

function SyndicatorAuctionCacheMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
    local interactType = ...
    if interactType == Enum.PlayerInteractionType.Auctioneer then
      -- Register for the throttle event to only request the owned auctions
      -- after the default auction house queries have succeeded - the favourites
      -- list view.
      self:RegisterEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
    end
  elseif eventName == "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" then
    C_AuctionHouse.QueryOwnedAuctions({})
    self:UnregisterEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")

  elseif eventName == "OWNED_AUCTIONS_UPDATED" then
    self:ClearAuctionPending()

    -- All owned auctions, replace any existing auctions in the cache as this is
    -- the complete list
    SYNDICATOR_DATA.Characters[self.currentCharacter].auctions = {}
    for index = 1, C_AuctionHouse.GetNumOwnedAuctions() do
      local auctionInfo = C_AuctionHouse.GetOwnedAuctionInfo(index)
      if auctionInfo.status == Enum.AuctionStatus.Active then
        if C_Item.IsItemDataCachedByID(auctionInfo.itemKey.itemID) then
          self:AddAuction(auctionInfo, auctionInfo.quantity)
        else
          local item = Item:CreateFromItemID(auctionInfo.itemKey.itemID)
          item:ContinueOnItemLoad(function()
            local auctionInfo = C_AuctionHouse.GetOwnedAuctionInfo(index)
            if not auctionInfo then
              return
            end
            self:AddAuction(auctionInfo, auctionInfo.quantity)
          end)
        end
      end
    end

  elseif eventName == "AUCTION_HOUSE_AUCTION_CREATED" then
    local auctionID = ...
    self:ProcessAuctionCreated(auctionID)

  elseif eventName == "AUCTION_HOUSE_NEW_RESULTS_RECEIVED" then
    local itemKey = ...
    if itemKey == nil then
      return
    end
    -- Slight delay to allow C_AuctionHouse.GetAuctionInfoByID to populate info
    C_Timer.After(0, function()
      self:ProcessPostedItemsQueue(itemKey)
    end)

  elseif eventName == "AUCTION_HOUSE_AUCTIONS_EXPIRED" or eventName == "AUCTION_CANCELED" then
    -- Expired and cancelled have the same behaviour, remove from the auctions
    -- list and add to the mail cache
    local auctionID = ...
    self:RemoveAuctionByID(auctionID, true)

  elseif eventName == "AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION" then
    local notification, text, auctionID = ...
    if notification == Enum.AuctionHouseNotification.AuctionSold or notification == Enum.AuctionHouseNotification.AuctionExpired then
      self:RemoveAuctionByID(auctionID, notification ~= Enum.AuctionHouseNotification.AuctionSold)
    end

  elseif eventName == "AUCTION_HOUSE_PURCHASE_COMPLETED" then
    -- This event will also fire on successful commodity purchases, we will
    -- ignore them in this event handler
    local auctionID = ...
    self:ProcessItemPurchase(auctionID)
  elseif eventName == "COMMODITY_PURCHASE_SUCCEEDED" then
    self:ProcessCommodityPurchase()
  end
end

function SyndicatorAuctionCacheMixin:ProcessPostedItemsQueue(itemKey)
  for auctionID, details in pairs(self.postedItemsQueue) do
    local auctionInfo = C_AuctionHouse.GetAuctionInfoByID(auctionID)
    if auctionInfo ~= nil then
      -- Always works when posting just one item, or when using the Auctionator
      -- UI
      self.postedItemsQueue[auctionID] = nil
      if C_Item.IsItemDataCachedByID(auctionInfo.itemKey.itemID) then
        self:AddAuction(auctionInfo, 1)
      else
        local item = Item:CreateFromItemID(auctionInfo.itemKey.itemID)
        item:ContinueOnItemLoad(function()
          local auctionInfo = C_AuctionHouse.GetAuctionInfoByID(auctionID)
          if auctionInfo ~= nil then
            self:AddAuction(auctionInfo, 1)
          end
        end)
      end
    elseif itemKey.itemID == details.itemID then
      -- The Blizzard UI doesn't request all the auctions separately so we have
      -- to guess when the auction has been created
      self.postedItemsQueue[auctionID] = nil
      local itemLink = details.itemLink
      local function DoItem()
        local itemInfo = {C_Item.GetItemInfo(itemLink)}
        local item = {
          itemID = itemID,
          itemCount = 1,
          iconTexture = itemInfo[10],
          itemLink = itemLink,
          quality = itemInfo[3],
          isBound = false,
        }
        item.auctionID = details.auctionID
        table.insert(
          SYNDICATOR_DATA.Characters[self.currentCharacter].auctions,
          item
        )
        Syndicator.CallbackRegistry:TriggerEvent("AuctionsCacheUpdate", self.currentCharacter)
      end
      if C_Item.IsItemDataCachedByID(details.itemID) then
        DoItem()
      else
        local item = Item:CreateFromItemID(details.itemID)
        item:ContinueOnItemLoad(function()
          DoItem()
        end)
      end
    end
  end

  if next(self.postedItemsQueue) == nil then
    self:UnregisterEvent("AUCTION_HOUSE_NEW_RESULTS_RECEIVED")
  end
end

function SyndicatorAuctionCacheMixin:ProcessItemPurchase(auctionID)
  if not self.purchasedItem or not self.purchasedItem.auctionInfo or self.purchasedItem.auctionInfo.auctionID ~= auctionID then
    return
  end

  local auctionInfo = self.purchasedItem.auctionInfo

  local itemCount = self.purchasedItem.itemCount

  if C_Item.IsItemDataCachedByID(auctionInfo.itemKey.itemID) then
    local item = ConvertAuctionInfoToItem(auctionInfo, itemCount)
    self:AddToMail(item)
  else
    local item = Item:CreateFromItemID(auctionInfo.itemKey.itemID)
    item:ContinueOnItemLoad(function()
      local item = ConvertAuctionInfoToItem(auctionInfo, itemCount)
      self:AddToMail(item)
    end)
  end

  self.purchasedItem = nil
end

function SyndicatorAuctionCacheMixin:ProcessCommodityPurchase()
  if not self.purchasedCommodity and not self.purchasedCommodity.itemID then
    return
  end

  local itemID = self.purchasedCommodity.itemID
  local itemCount = self.purchasedCommodity.itemCount

  local function GetItem()
    local itemInfo = {C_Item.GetItemInfo(self.purchasedCommodity.itemID)}
    return {
      itemID = itemID,
      itemCount = itemCount,
      iconTexture = itemInfo[10],
      itemLink = itemInfo[2],
      quality = itemInfo[3],
      isBound = false,
    }
  end

  if C_Item.IsItemDataCachedByID(itemID) then
    local item = GetItem()
    self:AddToMail(item)
  else
    local item = Item:CreateFromItemID(itemID)
    item:ContinueOnItemLoad(function()
      local item = GetItem()
      self:AddToMail(item)
    end)
  end

  self.purchasedCommodity = nil
end

function SyndicatorAuctionCacheMixin:ProcessAuctionCreated(auctionID)
  if self.postedCommodity then
    local itemCount = self.postedCommodity.itemCount
    local itemID = self.postedCommodity.itemID

    local function DoItem()
      local itemInfo = {C_Item.GetItemInfo(itemLink or itemID)}
      local item = {
        itemID = itemID,
        itemCount = itemCount,
        iconTexture = itemInfo[10],
        itemLink = itemInfo[2],
        quality = itemInfo[3],
        isBound = false,
      }
      item.auctionID = auctionID
      table.insert(
        SYNDICATOR_DATA.Characters[self.currentCharacter].auctions,
        item
      )
      Syndicator.CallbackRegistry:TriggerEvent("AuctionsCacheUpdate", self.currentCharacter)
    end

    if C_Item.IsItemDataCachedByID(itemID) then
      DoItem()
    else
      local item = Item:CreateFromItemID(itemID)
      item:ContinueOnItemLoad(function()
        DoItem()
      end)
    end
    self.postedCommodity = nil
  elseif self.lastPostedItem then
    self:RegisterEvent("AUCTION_HOUSE_NEW_RESULTS_RECEIVED")
    self.postedItemsQueue[auctionID] = {itemID = self.lastPostedItem.itemID, itemLink = self.lastPostedItem.itemLink}
  end
end

function SyndicatorAuctionCacheMixin:ClearAuctionPending()
  self.postedItemsQueue = {}
  self.postedCommodity = nil
  self.lastPostedItem = nil

  self:UnregisterEvent("AUCTION_HOUSE_NEW_RESULTS_RECEIVED")
end
