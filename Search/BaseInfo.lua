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
