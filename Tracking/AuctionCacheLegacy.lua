SyndicatorAuctionCacheLegacyMixin = {}

local AUCTIONS_UPDATED_EVENTS = {
  "AUCTION_OWNED_LIST_UPDATE",
  "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
}

function SyndicatorAuctionCacheLegacyMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, AUCTIONS_UPDATED_EVENTS)
  self.currentCharacter = Syndicator.Utilities.GetCharacterFullName()

  self.lastBid = nil
  hooksecurefunc("PlaceAuctionBid", function(listType, index, amount)
    local auctionInfo = {GetAuctionItemInfo(listType, index)}
    if auctionInfo[10] and auctionInfo[10] == amount then
      self.lastBid = {
        itemID = auctionInfo[17],
        itemCount = auctionInfo[3],
        iconTexture = auctionInfo[2],
        itemLink = GetAuctionItemLink(listType, index),
        quality = auctionInfo[4],
        isBound = false,
      }
      self.lastBidTime = GetTimePreciseSec()
      self:RegisterEvent("CHAT_MSG_SYSTEM")
    else
      self.lastBid = nil
      self.lastBidTime = 0
      self:UnregisterEvent("CHAT_MSG_SYSTEM")
    end
  end)
end

function SyndicatorAuctionCacheLegacyMixin:AddAuction(auctionInfo, itemLink)
  table.insert(
    SYNDICATOR_DATA.Characters[self.currentCharacter].auctions,
    {
        itemID = auctionInfo[17],
        itemCount = auctionInfo[3],
        iconTexture = auctionInfo[2],
        itemLink = itemLink,
        quality = auctionInfo[4],
        isBound = false,
    }
  )
  Syndicator.CallbackRegistry:TriggerEvent("AuctionsCacheUpdate", self.currentCharacter)
end

function SyndicatorAuctionCacheLegacyMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
    local interactType = ...
    if interactType == Enum.PlayerInteractionType.Auctioneer then
      GetOwnerAuctionItems()
    end
  elseif eventName == "AUCTION_OWNED_LIST_UPDATE" then
    SYNDICATOR_DATA.Characters[self.currentCharacter].auctions = {}

    for index = 1, GetNumAuctionItems("owner") do
      local auctionInfo = { GetAuctionItemInfo("owner", index) }
      local itemID = auctionInfo[17]
      if C_Item.IsItemDataCachedByID(itemID) then
        self:AddAuction(auctionInfo, GetAuctionItemLink("owner", index))
      else
        Syndicator.Utilities.LoadItemData(itemID, function()
          auctionInfo = { GetAuctionItemInfo("owner", index) }
          self:AddAuction(auctionInfo, GetAuctionItemLink("owner", index))
        end)
      end
    end
  elseif eventName == "CHAT_MSG_SYSTEM" then
    if GetTimePreciseSec() - self.lastBidTime > 20 then
      self.lastBid = nil
      self:UnregisterEvent("CHAT_MSG_SYSTEM")
      return
    end
    local message = ...
    if message == ERR_AUCTION_BID_PLACED then
      local item = self.lastBid
      self:UnregisterEvent("CHAT_MSG_SYSTEM")
      self.lastBid = nil
      item.expirationTime = time() + Syndicator.Constants.MailExpiryDuration
      table.insert(SYNDICATOR_DATA.Characters[self.currentCharacter].mail, item)
      Syndicator.CallbackRegistry:TriggerEvent("MailCacheUpdate", self.currentCharacter)
    end
  end
end
