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
    return itemVersionDetails.major, itemVersionDetails.minor, itemVersionDetails.patch
  elseif ATTC then
    local attResults = ATTC.SearchForField("itemID", itemID)
    if #attResults > 0 then
      local parent = attResults[1]
      while parent and parent.awp == nil do -- awp: short for added with patch
        parent = parent.parent
      end
      local id = parent and parent.awp
      if not id then
        return
      end
      local major = math.floor(id / 10000)
      local minor = math.floor((id % 10000) / 100)
      local patch = math.floor(id % 100)
      return major, minor, patch
    end
  end
end

if Syndicator.Constants.IsClassic then
  local tooltip = CreateFrame("GameTooltip", "BaganatorUtilitiesScanTooltip", nil, "GameTooltipTemplate")
  tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

  function Syndicator.Search.DumpClassicTooltip(tooltipSetter)
    tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tooltipSetter(tooltip)

    local name = tooltip:GetName()
    local dump = {}

    local row = 1
    while _G[name .. "TextLeft" .. row] ~= nil do
      local leftFontString = _G[name .. "TextLeft" .. row]
      local rightFontString = _G[name .. "TextRight" .. row]

      local entry = {
        leftText = leftFontString:GetText(),
        leftColor = CreateColor(leftFontString:GetTextColor()),
        rightText = rightFontString:GetText(),
        rightColor = CreateColor(rightFontString:GetTextColor())
      }
      if entry.leftText or entry.rightText then
        table.insert(dump, entry)
      end

      row = row + 1
    end

    return {lines = dump}
  end
end

