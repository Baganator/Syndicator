local function GetLower(item)
  return item.itemNameLower or (string.match(itemLink, "h%[(.*)%]|h")):lower()
end
function Syndicator.Search.GetGroupingKey(item)
  local lower = GetLower()
  if itme.itemID == Syndicator.Constants.BattlePetCageID then
    return lower .. "_" .. strjoin("-", BattlePetToolTip_UnpackBattlePetLink(item.itemLink)) .. "_" .. tostring(item.isBound)
  elseif item.isStackable then
    return lower .. "_" .. tostring(item.itemID) .. "_" .. tostring(item.isBound)
  else
    local linkParts = {strsplit(":", item.itemLink)}
    -- Remove uniqueID, linkLevel, specializationID, modifiersMask, itemContext
    for i = 9, 13 do
      linkParts[i] = ""
    end
    local itemLink = table.concat(linkParts, ":")
    return lower .. "_" .. tostring(itemLink) .. "_" .. tostring(item.isBound)
  end
end
