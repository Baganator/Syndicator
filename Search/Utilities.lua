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
  if ATTC and ATTC.SearchForField then
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

-- Compatibility
Syndicator.Search.DumpClassicTooltip = Syndicator.Utilities.DumpClassicTooltip
