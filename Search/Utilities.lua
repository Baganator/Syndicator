function Syndicator.Search.GetBaseInfoFromList(cachedItems)
  local results = {}
  for _, item in ipairs(cachedItems) do
    if item.itemID ~= nil and C_Item.GetItemInfoInstant(item.itemID) ~= nil then
      local info = Syndicator.Search.GetBaseInfo(item)
      table.insert(results, info)
    end
  end
  return results
end

function Syndicator.Search.GetExpansionInfo(itemID)
  if ItemVersion then
    local itemVersionDetails = ItemVersion.API:getItemVersion(itemID, true)
    if itemVersionDetails then
      return itemVersionDetails.major
    end
  end
  if ATTC and ATTC.SearchForField then
    local results = ATTC.SearchForField("itemID", itemID)
    if #results > 0 then
      local parent = results[1]
      local xpac
      while parent and not xpac do
        if parent.expansionID then
          xpac = math.floor(parent.expansionID)
        end
        parent = parent.parent
      end
      if xpac then
        return xpac
      end
    end
  end
end

-- Compatibility
Syndicator.Search.DumpClassicTooltip = Syndicator.Utilities.DumpClassicTooltip

if Syndicator.Constants.IsRetail then
  local modelScene = CreateFrame("ModelScene", nil, UIParent, "ModelSceneMixinTemplate")
  modelScene:TransitionToModelSceneID(596, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true)
  modelScene:Hide()
  local frame = CreateFrame("Frame")
  frame:SetScript("OnUpdate", function()
    if not modelScene:GetPlayerActor() or modelScene:GetPlayerActor():SetModelByUnit("player") then
      frame:SetScript("OnUpdate", nil)
    end
  end)

  -- Get the first spot the transmog preview will show the item on
  local SlotMap = {
    INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2,
    INVTYPE_SHOULDER = 3,
    INVTYPE_BODY = 4,
    INVTYPE_CHEST = 5,
    INVTYPE_WAIST = 6,
    INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8,
    INVTYPE_WRIST = 9,
    INVTYPE_HAND = 10,
    INVTYPE_WEAPON = 16,
    INVTYPE_SHIELD = 17,
    INVTYPE_RANGED = 16,
    INVTYPE_CLOAK = 15,
    INVTYPE_2HWEAPON = 16,
    INVTYPE_TABARD = 19,
    INVTYPE_ROBE = 5,
    INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_WEAPONOFFHAND = 16,
    INVTYPE_HOLDABLE = 17,
    INVTYPE_RANGEDRIGHT = 16,
  }

  local cache = {}

  -- Used to get appearance source ID for transmog when the C_TransmogCollection
  -- APIs don't work.
  function Syndicator.Search.RecoverTransmogInfo(itemLink)
    if not C_Item.IsDressableItemByID(itemLink) then
      return nil
    end
    if cache[itemLink] then
      return cache[itemLink]
    end

    local playerActor = modelScene:GetPlayerActor()
    local invType = select(4, C_Item.GetItemInfoInstant(itemLink))
    local slot = SlotMap[invType]
    if slot then
      local mainHandOverride = invType == "INVTYPE_WEAPON" or invType == "INVTYPE_RANGEDRIGHT"
      local result
      if mainHandOverride then
        result = playerActor:TryOn(itemLink, "MAINHANDSLOT")
      else
        result = playerActor:TryOn(itemLink)
      end
      if result == Enum.ItemTryOnReason.Success then
        local info = playerActor:GetItemTransmogInfo(slot)
        if info then
          cache[itemLink] = info.appearanceID
          return info.appearanceID
        end
      end
    end

    return nil
  end
else
  function Syndicator.Search.RecoverTransmogInfo(itemLink)
    return nil
  end
end

do
  local priceSources = {}
  priceSources["none"] = {
    func = function(itemLink)
      return -2 -- special value, says everything matches this price
    end,
    priority = 1000,
    validation = function() return true end
  }
  priceSources["auctionator-latest"] = {
    func = function(itemLink)
      return Auctionator.API.v1.GetAuctionPriceByItemLink("Syndicator", itemLink)
    end,
    priority = 100,
    validation = function() return Auctionator ~= nil end
  }
  priceSources["tradeskillmaster-dbmarket"] = {
    func = function(itemLink)
      return TSM_API.GetCustomPriceValue("dbmarket", TSM_API.ToItemString(itemLink))
    end,
    priority = 30,
    validation = function() return TSM_API ~= nil end
  }
  priceSources["tradeskillmaster-dbrecent"] = {
    func = function(itemLink)
      return TSM_API.GetCustomPriceValue("dbrecent", TSM_API.ToItemString(itemLink))
    end,
    validation = function() return TSM_API ~= nil end
  }
  priceSources["tradeskillmaster-dbregionmarketavg"] = {
    func = function(itemLink)
      return TSM_API.GetCustomPriceValue("dbregionmarketavg", TSM_API.ToItemString(itemLink))
    end,
    validation = function() return TSM_API ~= nil end
  }
  priceSources["tradeskillmaster-dbregionsaleavg"] = {
    func = function(itemLink)
      return TSM_API.GetCustomPriceValue("dbregionmarketavg", TSM_API.ToItemString(itemLink))
    end,
    validation = function() return TSM_API ~= nil end
  }
  priceSources["undermineexchange-realm"] = {
    func = function(itemLink)
      local o = {}
      OEMarketInfo(itemLink, o)
      return o["market"] or o["region"]
    end,
    priority = 50,
    validation = function() return OEMarketInfo ~= nil end
  }
  priceSources["undermineexchange-region"] = {
    func = function(itemLink)
      local o = {}
      OEMarketInfo(itemLink, o)
      return o["region"]
    end,
    validation = function() return OEMarketInfo ~= nil end
  }
  priceSources["recrystallize"] = {
    func = function(itemLink)
      return (RECrystallize_PriceCheck(itemLink))
    end,
    validation = function() return RECrystallize_PriceCheck ~= nil end,
    priority = 40,
  }

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:SetScript("OnEvent", function()
    local key = Syndicator.Config.Get(Syndicator.Config.Options.AUCTION_VALUE_SOURCE)
    local current = priceSources[key]
    if not current or not current.validation() or (key == "none" and not Syndicator.Config.Get(Syndicator.Config.Options.NO_AUCTION_VALUE_SOURCE)) then
      local options = {}
      for key, details in pairs(priceSources) do
        if details.priority and details.validation() then
          details.key = key
          table.insert(options, details)
        end
      end
      table.sort(options, function(a, b) return a.priority < b.priority end)
      if #options > 0 then
        current = options[1]
        Syndicator.Config.Set(Syndicator.Config.Options.AUCTION_VALUE_SOURCE, options[1].key)
      else
        error("unexpected missing \"none\" price source")
      end
    end
    Syndicator.Search.GetAuctionValue = current.func
  end)
  Syndicator.CallbackRegistry:RegisterCallback("AuctionValueSourceChanged", function()
    local key = Syndicator.Config.Get(Syndicator.Config.Options.AUCTION_VALUE_SOURCE)
    Syndicator.Config.Set(Syndicator.Config.Options.NO_AUCTION_VALUE_SOURCE, key == "none")
    local current = priceSources[key]
    Syndicator.Search.GetAuctionValue = current.func
  end)
end
