function Syndicator.Search.GetBaseInfoFromList(cachedItems, callback)
  local results = {}

  local waiting = #cachedItems
  for _, item in ipairs(cachedItems) do
    if item.itemID ~= nil then
      Syndicator.Search.GetBaseInfo(item, function(info)
        table.insert(results, info)
      end, function(info)
        waiting = waiting - 1
        if waiting == 0 then
          callback(results)
        end
      end)
    else
      waiting = waiting - 1
      if waiting == 0 then
        callback(results)
      end
    end
  end

  if #cachedItems == 0 then
    callback(results)
  end
end

if Syndicator.Constants.IsClassic then
  function Syndicator.Search.ClassicHasItemLevel(details)
    return details.classID == Enum.ItemClass.Armor or details.classID == Enum.ItemClass.Weapon
  end

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

