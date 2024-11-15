local _, addonTable = ...

local cache = {}

local function CacheCharacter(character, callback)
  local waiting = 5 -- bags, bank, mail, equipped+containerInfo, void

  local function finishCheck(sourceType, results)
    for _, r in ipairs(results) do
      r.source = {character = character, container = sourceType}
      table.insert(cache, r)
    end
    waiting = waiting - 1
    if waiting == 0 then
      callback()
    end
  end

  local characterData = CopyTable(SYNDICATOR_DATA.Characters[character])

  local bagsList = {}
  for _, bag in ipairs(characterData.bags) do
    for _, item in ipairs(bag) do
      table.insert(bagsList, item)
    end
  end

  finishCheck("bag", Syndicator.Search.GetBaseInfoFromList(bagsList))

  local bankList = {}
  for _, bag in ipairs(characterData.bank) do
    for _, item in ipairs(bag) do
      table.insert(bankList, item)
    end
  end

  finishCheck("bank", Syndicator.Search.GetBaseInfoFromList(bankList))

  finishCheck("mail", Syndicator.Search.GetBaseInfoFromList(characterData.mail or {}))

  finishCheck("auctions", Syndicator.Search.GetBaseInfoFromList(characterData.auctions or {}))

  local equippedList = {}
  for _, slot in pairs(characterData.equipped or {}) do
    table.insert(equippedList, slot)
  end
  for label, containers in pairs(characterData.containerInfo or {}) do
    for _, item in pairs(containers) do
      table.insert(equippedList, item)
    end
  end

  finishCheck("equipped", Syndicator.Search.GetBaseInfoFromList(equippedList))

  local voidList = {}
  for _, tab in ipairs(characterData.void or {}) do
    for _, item in ipairs(tab) do
      table.insert(voidList, item)
    end
  end

  finishCheck("void", Syndicator.Search.GetBaseInfoFromList(voidList))
end

local function CacheGuild(guild, callback)
  local guildList = {}
  local linkToTabIndex = {}
  for tabIndex, tab in ipairs(CopyTable(SYNDICATOR_DATA.Guilds[guild].bank)) do
    for _, item in ipairs(tab.slots) do
      if item.itemLink then
        linkToTabIndex[item.itemLink] = tabIndex
      end
      table.insert(guildList, item)
    end
  end

  local results = Syndicator.Search.GetBaseInfoFromList(guildList)
  for _, r in ipairs(results) do
    r.source = {guild = guild, container = linkToTabIndex[r.itemLink]}
    table.insert(cache, r)
  end
  callback()
end

local function CacheWarband(warbandIndex, callback)
  local warbandList = {}
  local linkToTabIndex = {}
  for tabIndex, tab in ipairs(CopyTable(SYNDICATOR_DATA.Warband[warbandIndex].bank)) do
    for _, item in ipairs(tab.slots) do
      if item.itemLink then
        linkToTabIndex[item.itemLink] = tabIndex
      end
      table.insert(warbandList, item)
    end
  end

  local results = Syndicator.Search.GetBaseInfoFromList(warbandList)
  for _, r in ipairs(results) do
    r.source = {warband = warbandIndex, container = linkToTabIndex[r.itemLink]}
    table.insert(cache, r)
  end
  callback()
end

local pendingQueries = {}
local pending
local toPurge = {Characters = {}, Guilds = {}, Warband = {}}
local managingFrame = CreateFrame("Frame")

local searchMonitorPool = CreateFramePool("Frame", UIParent, "SyndicatorOfflineListSearchTemplate")

local function Query(searchTerm, callback)
  local monitor = searchMonitorPool:Acquire()
  monitor:Show()
  monitor:StartSearch(cache, searchTerm, function(matches)
    callback(matches)
    searchMonitorPool:Release(monitor)
  end)
end

local function CharacterCacheUpdate(_, character)
  if pending then
    pending.Characters[character] = true
    toPurge.Characters[character] = true
  end
end

Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate", CharacterCacheUpdate)
Syndicator.CallbackRegistry:RegisterCallback("MailCacheUpdate", CharacterCacheUpdate)
Syndicator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", CharacterCacheUpdate)
Syndicator.CallbackRegistry:RegisterCallback("VoidCacheUpdate", CharacterCacheUpdate)

Syndicator.CallbackRegistry:RegisterCallback("GuildCacheUpdate", function(_, guild)
  if pending then
    pending.Guilds[guild] = true
    toPurge.Guilds[guild] = true
  end
end)

Syndicator.CallbackRegistry:RegisterCallback("WarbandBankCacheUpdate", function(_, index)
  if pending then
    pending.Warband[index] = true
    toPurge.Warband[index] = true
  end
end)

function Syndicator.Search.RequestMegaSearchResults(searchTerm, callback)
  if pending == nil then
    pending = {
      Characters = {},
      Guilds = {},
      Warband = {},
    }

    for c in pairs(SYNDICATOR_DATA.Characters) do
      pending.Characters[c] = true
    end

    for g in pairs(SYNDICATOR_DATA.Guilds) do
      pending.Guilds[g] = true
    end

    for i in pairs(SYNDICATOR_DATA.Warband) do
      pending.Warband[i] = true
    end
  end

  local function PendingCheck()
    if next(pending.Characters) == nil and (not Syndicator.Config.Get(Syndicator.Config.Options.SHOW_GUILD_BANKS_IN_TOOLTIPS) or next(pending.Guilds) == nil) and next(pending.Warband) == nil then
      managingFrame:SetScript("OnUpdate", nil)
      for _, query in ipairs(pendingQueries) do
        Query(unpack(query))
      end
      pendingQueries = {}
      return
    end
    cache = tFilter(cache, function(item) return toPurge.Characters[item.source.character] == nil and toPurge.Guilds[item.source.guild] == nil and toPurge.Warband[item.source.warband] == nil end, true)
    toPurge = {Characters = {}, Guilds = {}, Warband = {}}
    managingFrame:SetScript("OnUpdate", nil)
    local waiting = 0
    local complete = false
    for character in pairs(pending.Characters) do
      waiting = waiting + 1
      CacheCharacter(character, function()
        pending.Characters[character] = nil
        waiting = waiting - 1
        if complete and waiting == 0 then
          managingFrame:SetScript("OnUpdate", PendingCheck)
        end
      end)
    end
    if Syndicator.Config.Get(Syndicator.Config.Options.SHOW_GUILD_BANKS_IN_TOOLTIPS) then
      for guild in pairs(pending.Guilds) do
        waiting = waiting + 1
        CacheGuild(guild, function()
          pending.Guilds[guild] = nil
          waiting = waiting - 1
          if complete and waiting == 0 then
            managingFrame:SetScript("OnUpdate", PendingCheck)
          end
        end)
      end
    end
    for warbandIndex in pairs(pending.Warband) do
      waiting = waiting + 1
      CacheWarband(warbandIndex, function()
        pending.Warband[warbandIndex] = nil
        waiting = waiting - 1
        if complete and waiting == 0 then
          managingFrame:SetScript("OnUpdate", PendingCheck)
        end
      end)
    end
    complete = true
    if waiting == 0 then
      PendingCheck()
    end
  end

  if next(pending.Characters) or next(pending.Guilds) or next(pending.Warband) then
    managingFrame:SetScript("OnUpdate", PendingCheck)
    table.insert(pendingQueries, {searchTerm, callback})
  else
    Query(searchTerm, callback)
  end
end

local function GetKeys(results, callback)
  local waiting = #results
  for _, r in ipairs(results) do
    local key = Syndicator.Search.GetGroupingKey(r, function(key)
      r.key = key
      waiting = waiting - 1
      if waiting == 0 then
        callback()
      end
    end)
  end
  if #results == 0 then
    callback()
  end
end

function Syndicator.Search.CombineMegaSearchResults(results, callback)
  local items = {}
  local seenCharacters = {}
  local seenGuilds = {}
  local seenWarband = {}

  GetKeys(results, function()
    for _, r in ipairs(results) do
      local key = r.key
      if not items[key] then
        items[key] = CopyTable(r)
        items[key].itemCount = 0
        items[key].sources = {}
        seenCharacters[key] = {}
        seenGuilds[key] = {}
        seenWarband[key] = {}
      end
      local source = CopyTable(r.source)
      source.itemCount = r.itemCount
      if source.character then
        local characterData = SYNDICATOR_DATA.Characters[source.character]
        if not characterData.details.hidden and (source.container ~= "equipped" or Syndicator.Config.Get(Syndicator.Config.Options.SHOW_EQUIPPED_ITEMS_IN_TOOLTIPS)) then
          if seenCharacters[key][source.character .. "_" .. source.container] then
            local entry = items[key].sources[seenCharacters[key][source.character .. "_" .. source.container]]
            entry.itemCount = entry.itemCount + source.itemCount
          else
            table.insert(items[key].sources, source)
            source.itemLink = r.itemLink
            source.itemNameLower = r.itemNameLower
            seenCharacters[key][source.character .. "_" .. source.container] = #items[key].sources
          end
          items[key].itemCount = items[key].itemCount + r.itemCount
        end
      elseif source.guild then
        local guildData = SYNDICATOR_DATA.Guilds[source.guild]
        if not guildData.details.hidden then
          if seenGuilds[key][source.guild] then
            local entry = items[key].sources[seenGuilds[key][source.guild]]
            entry.itemCount = entry.itemCount + source.itemCount
          else
            table.insert(items[key].sources, source)
            source.itemLink = r.itemLink
            source.itemNameLower = r.itemNameLower
            seenGuilds[key][source.guild] = #items[key].sources
          end
          items[key].itemCount = items[key].itemCount + r.itemCount
        end
      elseif source.warband then
        local warbandData = SYNDICATOR_DATA.Warband[source.warband]
        if seenWarband[key][source.warband] then
          local entry = items[key].sources[seenWarband[key][source.warband]]
          entry.itemCount = entry.itemCount + source.itemCount
        else
          table.insert(items[key].sources, source)
          source.itemLink = r.itemLink
          source.itemNameLower = r.itemNameLower
          seenGuilds[key][source.warband] = #items[key].sources
        end
        items[key].itemCount = items[key].itemCount + r.itemCount
      end
    end

    local keys = {}
    for key in pairs(items) do
      table.insert(keys, key)
    end
    table.sort(keys)

    local final = {}
    for _, key in ipairs(keys) do
      if #items[key].sources > 0 then
        table.insert(final, items[key])
        table.sort(items[key].sources, function(a, b)
          if a.itemCount == b.itemCount then
            return tostring(a.container) < tostring(b.container)
          else
            return a.itemCount > b.itemCount
          end
        end)
      end
    end

    callback(final)
  end)
end

local function GetLink(source, searchTerm, text)
  local mode
  if source.guild then
    mode = "guild"
  elseif source.character then
    mode = "character"
  elseif source.warband then
    mode = "warband"
    text = SYNDICATOR_L_WARBAND
  else
    return text
  end
  -- Modify item link so it doesn't break the addon link
  local moddedLink = source.itemLink:gsub(":", "("):gsub("%|",")")
  local moddedTerm = searchTerm:gsub(":", "(")
  return "|Haddon:SyndicatorSearch:" .. moddedTerm .. ":" .. mode .. ":" .. source[mode] .. ":" .. source.container .. ":" .. moddedLink .. "|h" .. "[" .. text .. "]" .. "|h"
end

local CONTAINER_TYPE_TO_TEXT = {
  bag = SYNDICATOR_L_BAGS_LOWER,
  bank = SYNDICATOR_L_BANK_LOWER,
  mail = SYNDICATOR_L_MAIL_LOWER,
  equipped = SYNDICATOR_L_EQUIPPED_LOWER,
  void = SYNDICATOR_L_VOID_LOWER,
  auctions = SYNDICATOR_L_AUCTIONS_LOWER,
}

local function PrintSource(indent, source, searchTerm)
  local count = BLUE_FONT_COLOR:WrapTextInColorCode(" x" .. FormatLargeNumber(source.itemCount))
  if source.character then
    local character = source.character
    if addonTable.ShowItemLocationCallback then
      character = GetLink(source, searchTerm, source.character)
    end
    local characterData = SYNDICATOR_DATA.Characters[source.character]
    local className = characterData.details.className
    if className then
      character = "|c" .. (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[className].colorStr .. character .. "|r"
    end
    print(indent, PASSIVE_SPELL_FONT_COLOR:WrapTextInColorCode(CONTAINER_TYPE_TO_TEXT[source.container]) .. count, character)
  elseif source.guild then
    local guild = source.guild
    if addonTable.ShowItemLocationCallback then
      guild = GetLink(source, searchTerm, source.guild)
    end
    print(indent, SYNDICATOR_L_GUILD_LOWER .. count, TRANSMOGRIFY_FONT_COLOR:WrapTextInColorCode(guild))
  elseif source.warband then
    local warband = source.warband
    if addonTable.ShowItemLocationCallback then
      warband = GetLink(source, searchTerm, source.warband)
    end
    print(indent, SYNDICATOR_L_WARBAND_LOWER .. count, PASSIVE_SPELL_FONT_COLOR:WrapTextInColorCode(warband))
  end
end

EventRegistry:RegisterCallback("SetItemRef", function(_, link, text, button, chatFrame)
    local linkType, addonName, searchText, mode, entity, container, itemLink = strsplit(":", link)
    if linkType == "addon" and addonName == "SyndicatorSearch" then
      -- Revert changes to item link to make it fit in the addon link
      itemLink = itemLink:gsub("%(", ":"):gsub("%)", "|")
      searchText = searchText:gsub("%(", ":")
      addonTable.ShowItemLocationCallback(mode, entity, container, itemLink, searchText)
    end
end)

function Syndicator.Search.RunMegaSearchAndPrintResults(searchTerm)
  if searchTerm:match("|H") then
    Syndicator.Utilities.Message(SYNDICATOR_L_CANNOT_SEARCH_BY_ITEM_LINK)
    return
  end
  searchTerm = searchTerm:lower()
  Syndicator.Search.RequestMegaSearchResults(searchTerm, function(results)
    print(GREEN_FONT_COLOR:WrapTextInColorCode(SYNDICATOR_L_SEARCHED_EVERYWHERE_COLON) .. " " .. YELLOW_FONT_COLOR:WrapTextInColorCode(searchTerm))
    Syndicator.Search.CombineMegaSearchResults(results, function(results)
      local indent = "       "
      for _, r in ipairs(results) do
        print("   " .. r.itemLink, BLUE_FONT_COLOR:WrapTextInColorCode("x" .. FormatLargeNumber(r.itemCount)))
        for _, s in ipairs(r.sources) do
          PrintSource(indent, s, s.itemNameLower)
        end
      end
      if #results == 0 then
        print(indent, RED_FONT_COLOR:WrapTextInColorCode(SYNDICATOR_L_NO_RESULTS_FOUND))
      end
    end)
  end)
end
