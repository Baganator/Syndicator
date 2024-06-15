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
      return itemVersionDetails.major, itemVersionDetails.minor, itemVersionDetails.patch
    end
  end
  if ATTC then
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


local rootATTHeaders= {
  [ATTC.HeaderConstants.ACHIEVEMENTS] = true,
  [ATTC.HeaderConstants.QUESTS] = true,
  [ATTC.HeaderConstants.FACTIONS] = true,
  [ATTC.HeaderConstants.QUESTS] = true,
  [ATTC.HeaderConstants.ZONE_DROPS] = true,
  [ATTC.HeaderConstants.SCENARIO_COMPLETION] = true,
  [ATTC.HeaderConstants.BONUS_OBJECTIVES] = true,
  [ATTC.HeaderConstants.BUILDINGS] = true,
  [ATTC.HeaderConstants.COMMON_BOSS_DROPS] = true,
  [ATTC.HeaderConstants.EMISSARY_QUESTS] = true,
  [ATTC.HeaderConstants.FLIGHT_PATHS] = "flightPathID",
  [ATTC.HeaderConstants.HOLIDAYS] = "eventID",
  [ATTC.HeaderConstants.PROFESSIONS] = "professionID",
  [ATTC.HeaderConstants.PVP] = true,
  [ATTC.HeaderConstants.RARES] = true,
  [ATTC.HeaderConstants.SECRETS] = true,
  [ATTC.HeaderConstants.SPECIAL] = true,
  [ATTC.HeaderConstants.TREASURES] = "objectID",
  [ATTC.HeaderConstants.VENDORS] = true,
  [ATTC.HeaderConstants.WEEKLY_HOLIDAYS] = true,
  [ATTC.HeaderConstants.WORLD_QUESTS] = true,
  [ATTC.HeaderConstants.ZONE_REWARDS] = true,
  [ATTC.HeaderConstants.REWARDS] = true,
}

function Syndicator.Search.GetWantedATTHeader(entry)
  if not entry then
    return
  end


  local current, prev = entry, entry
  while current do
    if rootATTHeaders[current.headerID] then
      if current.parent then
        return ATTC.L.HEADER_NAMES[ATTC.GetRelativeValue(current.parent, "headerID")]
      else
        return nil
      end
    end
    current, prev = current.parent, current
  end
  return ATTC.L.HEADER_NAMES[prev.headerID]
end

function Syndicator.Search.GetATTItemsFromEntry(entry, details, items)
  if entry.g then
    for _, possibility in ipairs(entry.g or {}) do
      Syndicator.Search.GetATTItemsFromEntry(possibility, details, items)
    end
  end

  if entry.itemID then
    table.insert(items, entry.itemID)
    details.isCurrency = true
  elseif entry.questID then
    details.isQuestObjectiveItem = true
  end
end

function Syndicator.Search.AnyDifferentATTHeaders(entries)
  local prevHeader, differentHeaders = nil, false
  for _, entry in ipairs(entries) do
    local nextHeader = Syndicator.Search.GetWantedATTHeader(entry)
    if nextHeader ~= nil then
      if prevHeader ~= nil and prevHeader ~= nextHeader then
        differentHeaders = true
        break
      end
      prevHeader = nextHeader
    end
  end
  return differentHeaders
end
