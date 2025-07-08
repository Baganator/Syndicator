function Syndicator.Search.GetBaseInfo(cacheData)
  local info = {}

  info.itemLink = cacheData.itemLink
  info.itemID = cacheData.itemID
  info.quality = cacheData.quality or 0
  info.itemCount = cacheData.itemCount or 1
  info.isBound = cacheData.isBound or false
  info.hasLoot = cacheData.hasLoot or false

  if Syndicator.Constants.IsBrokenTooltipScanning then
    info.tooltipGetter = function() return {lines = {}} end
  elseif C_TooltipInfo then
    info.tooltipGetter = function() return C_TooltipInfo.GetHyperlink(cacheData.itemLink) end
  elseif cacheData.itemID == Syndicator.Constants.BattlePetCageID then
    info.tooltipGetter = function() return nil end
  else
    info.tooltipGetter = function() return Syndicator.Search.DumpClassicTooltip(function(t) t:SetHyperlink(cacheData.itemLink) end) end
  end

  return info
end

--[[
You can potentially add the following keys after calling this function to alter
search results (any may be left as nil to be ignored):
- setInfo: array, with entries {name: string} for equipment sets the item is in, leave nil if the array would be empty
- isUpgrade: boolean -- Is the item (usually gear) an upgrade compared to current equipped
- isEngravable: boolean -- Does the item support runes (classic Season of Discovery)
- engravingInfo: table -- Any details about the SoD runes currently applied on the item, leave nil if no runes applied
- isJunk: boolean -- Is this item junk to just be sold to a vendor (used for junk status overrides)
- tooltipGetter: function() return {lines: {{leftText: string, rightText:string?, leftColor: ColorMixin, rightColor: ColorMixin?}}} end
    - Used to get live tooltip information, a hyperlink based tooltipGetter is supplied by default.
- itemLocation: {bagID, slotIndex} OR {equipmentSlotIndex} (ie an ItemLocation), used for data only available live
]]
