function Syndicator.Utilities.Message(text)
  print(NORMAL_FONT_COLOR:WrapTextInColorCode("Syndicator") .. ": " .. text)
end

do
  local callbacksPending = {}
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("ADDON_LOADED")
  frame:SetScript("OnEvent", function(self, eventName, addonName)
    if callbacksPending[addonName] then
      for _, cb in ipairs(callbacksPending[addonName]) do
        cb()
      end
      callbacksPending[addonName] = nil
    end
  end)

  -- Necessary because cannot nest EventUtil.ContinueOnAddOnLoaded
  function Syndicator.Utilities.OnAddonLoaded(addonName, callback)
    if select(2, C_AddOns.IsAddOnLoaded(addonName)) then
      callback()
    else
      callbacksPending[addonName] = callbacksPending[addonName] or {}
      table.insert(callbacksPending[addonName], callback)
    end
  end
end

function Syndicator.Utilities.GetCharacterFullName()
  local characterName, realm = UnitFullName("player")
  return characterName .. "-" .. realm
end

if Syndicator.Constants.IsClassic then
  local tooltip = CreateFrame("GameTooltip", "BaganatorUtilitiesScanTooltip", nil, "GameTooltipTemplate")
  tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

  function Syndicator.Utilities.DumpClassicTooltip(tooltipSetter)
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

local pendingItems = {}
local itemFrame = CreateFrame("Frame")
itemFrame.elapsed = 0
itemFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
itemFrame:SetScript("OnEvent", function(_, _, itemID)
  if pendingItems[itemID] ~= nil then
    for _, callback in ipairs(pendingItems[itemID]) do
      callback()
    end
    pendingItems[itemID] = nil
  end
end)
itemFrame.OnUpdate = function(self, elapsed)
  itemFrame.elapsed = itemFrame.elapsed + elapsed
  if itemFrame.elapsed > 0.4 then
    for itemID in pairs(pendingItems) do
      C_Item.RequestLoadItemDataByID(itemID)
    end
    itemFrame.elapsed = 0
  end

  if next(pendingItems) == nil then
    itemFrame.elapsed = 0
    self:SetScript("OnUpdate", nil)
    self:UnregisterEvent("ITEM_DATA_LOAD_RESULT")
  end
end

function Syndicator.Utilities.LoadItemData(itemID, callback)
  pendingItems[itemID] = pendingItems[itemID] or {}
  table.insert(pendingItems[itemID], callback)
  itemFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
  itemFrame:SetScript("OnUpdate", itemFrame.OnUpdate)
  C_Item.RequestLoadItemDataByID(itemID)
end
