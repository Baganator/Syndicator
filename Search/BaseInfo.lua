local ticker
local pending = {}

local function RerequestItemData()
  for info in pairs(pending) do
    if C_Item.IsItemDataCachedByID(info.itemID) then
      pending[info] = nil
    else
      C_Item.RequestLoadItemDataByID(info.itemID)
    end
  end
  if not next(pending) then
    ticker:Cancel()
    ticker = nil
  end
end

local function GetExpansion(info, itemInfo)
  if ItemVersion then
    local details = ItemVersion.API:getItemVersion(info.itemID, true)
    if details then
      return details.major - 1
    end
  end
  return itemInfo[15]
end

function Syndicator.Search.GetBaseInfo(cacheData)
  local info = {}

  info.itemLink = cacheData.itemLink
  info.itemID = cacheData.itemID
  info.quality = cacheData.quality
  info.itemCount = cacheData.itemCount or 1
  info.isBound = cacheData.isBound or false

  if C_TooltipInfo then
    info.tooltipGetter = function() return C_TooltipInfo.GetHyperlink(cacheData.itemLink) end
  else
    info.tooltipGetter = function() return Syndicator.Search.DumpClassicTooltip(function(t) t:SetHyperlink(cacheData.itemLink) end) end
  end

  return info
end
