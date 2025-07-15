---@class addonTableSyndicator
local addonTable = select(2, ...)

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

  local characterData = CopyTable(Syndicator.API.GetCharacter(character))

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
  if characterData.bankTabs then
    for _, tab in ipairs(characterData.bankTabs) do
      for _, item in ipairs(tab.slots) do
        table.insert(bankList, item)
      end
    end
  end

  finishCheck("bank", Syndicator.Search.GetBaseInfoFromList(bankList))

  finishCheck("mail", Syndicator.Search.GetBaseInfoFromList(characterData.mail or {}))

  finishCheck("auctions", Syndicator.Search.GetBaseInfoFromList(characterData.auctions or {}))

  local equippedList = {}
  for _, slot in pairs(characterData.equipped or {}) do
    table.insert(equippedList, slot)
  end
  for _, containers in pairs(characterData.containerInfo or {}) do
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
  for tabIndex, tab in ipairs(CopyTable(Syndicator.API.GetGuild(guild).bank)) do
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

function Syndicator.Search.RequestSearchEverywhereResults(searchTerm, callback)
  if pending == nil then
    pending = {
      Characters = {},
      Guilds = {},
      Warband = {},
    }

    for _, c in ipairs(Syndicator.API.GetAllCharacters()) do
      pending.Characters[c] = true
    end

    for _, g in ipairs(Syndicator.API.GetAllGuilds()) do
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
    Syndicator.Search.GetGroupingKey(r, function(key)
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

function Syndicator.Search.CombineSearchEverywhereResults(results, callback)
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
        local characterData = Syndicator.API.GetCharacter(source.character)
        if not characterData.details.hidden and (source.container ~= "equipped" or Syndicator.Config.Get(Syndicator.Config.Options.SHOW_EQUIPPED_ITEMS_IN_TOOLTIPS)) then
          if seenCharacters[key][source.character .. "_" .. source.container] then
            local entry = items[key].sources[seenCharacters[key][source.character .. "_" .. source.container]]
            entry.itemCount = entry.itemCount + source.itemCount
          else
            table.insert(items[key].sources, source)
            source.itemLink = r.itemLink
            source.itemNameLower = r.itemNameLower
            source.realm = characterData.details.realmNormalized
            seenCharacters[key][source.character .. "_" .. source.container] = #items[key].sources
          end
          items[key].itemCount = items[key].itemCount + r.itemCount
        end
      elseif source.guild then
        local guildData = Syndicator.API.GetGuild(source.guild)
        if not guildData.details.hidden then
          if seenGuilds[key][source.guild] then
            local entry = items[key].sources[seenGuilds[key][source.guild]]
            entry.itemCount = entry.itemCount + source.itemCount
          else
            table.insert(items[key].sources, source)
            source.itemLink = r.itemLink
            source.itemNameLower = r.itemNameLower
            source.realm = guildData.details.realm
            seenGuilds[key][source.guild] = #items[key].sources
          end
          items[key].itemCount = items[key].itemCount + r.itemCount
        end
      elseif source.warband then
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
            if a.realm == b.realm then
              if a.container == b.container then
                if a.character then
                  return a.character < b.character
                elseif a.guild then
                  return a.guild < b.guild
                else
                  return false
                end
              else
                return tostring(a.container) < tostring(b.container)
              end
            elseif a.realm and not b.realm then
              return false
            elseif b.realm and not a.realm then
              return true
            else
              return a.realm < b.realm
            end
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
    text = Syndicator.Locales.WARBAND
  else
    return text
  end
  -- Modify item link so it doesn't break the addon link
  local moddedLink = source.itemLink:gsub(":", "("):gsub("%|",")")
  local moddedTerm = searchTerm:gsub(":", "(")
  return "|Haddon:SyndicatorSearch:" .. moddedTerm .. ":" .. mode .. ":" .. source[mode] .. ":" .. source.container .. ":" .. moddedLink .. "|h" .. "[" .. text .. "]" .. "|h"
end

local CONTAINER_TYPE_TO_TEXT = {
  bag = Syndicator.Locales.BAGS_LOWER,
  bank = Syndicator.Locales.BANK_LOWER,
  mail = Syndicator.Locales.MAIL_LOWER,
  equipped = Syndicator.Locales.EQUIPPED_LOWER,
  void = Syndicator.Locales.VOID_LOWER,
  auctions = Syndicator.Locales.AUCTIONS_LOWER,
}

local function PrintSource(indent, source, searchTerm)
  local count = BLUE_FONT_COLOR:WrapTextInColorCode(" x" .. FormatLargeNumber(source.itemCount))
  if source.character then
    local character = source.character
    if addonTable.ShowItemLocationCallback then
      character = GetLink(source, searchTerm, source.character)
    end
    local characterData = Syndicator.API.GetCharacter(source.character)
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
    print(indent, Syndicator.Locales.GUILD_LOWER .. count, TRANSMOGRIFY_FONT_COLOR:WrapTextInColorCode(guild))
  elseif source.warband then
    local warband = source.warband
    if addonTable.ShowItemLocationCallback then
      warband = GetLink(source, searchTerm, source.warband)
    end
    print(indent, Syndicator.Locales.WARBAND_LOWER .. count, PASSIVE_SPELL_FONT_COLOR:WrapTextInColorCode(warband))
  end
end

EventRegistry:RegisterCallback("SetItemRef", function(_, link)
    local linkType, addonName, searchText, mode, entity, container, itemLink = strsplit(":", link)
    if linkType == "addon" and addonName == "SyndicatorSearch" then
      -- Revert changes to item link to make it fit in the addon link
      itemLink = itemLink:gsub("%(", ":"):gsub("%)", "|")
      searchText = searchText:gsub("%(", ":")
      addonTable.ShowItemLocationCallback(mode, entity, container, itemLink, searchText)
    end
end)

function Syndicator.Search.SearchEverywhereAndPrintResults(searchTerm)
  if searchTerm:match("|H") then
    Syndicator.Utilities.Message(Syndicator.Locales.CANNOT_SEARCH_BY_ITEM_LINK)
    return
  end
  searchTerm = searchTerm:lower()
  Syndicator.Search.RequestSearchEverywhereResults(searchTerm, function(results)
    print(GREEN_FONT_COLOR:WrapTextInColorCode(Syndicator.Locales.SEARCHED_EVERYWHERE_COLON) .. " " .. YELLOW_FONT_COLOR:WrapTextInColorCode(searchTerm))
    Syndicator.Search.CombineSearchEverywhereResults(results, function(combinedResults)
      local indent = "       "
      for _, r in ipairs(combinedResults) do
        print("   " .. r.itemLink, BLUE_FONT_COLOR:WrapTextInColorCode("x" .. FormatLargeNumber(r.itemCount)))
        for _, s in ipairs(r.sources) do
          PrintSource(indent, s, s.itemNameLower)
        end
      end
      if #combinedResults == 0 then
        print(indent, RED_FONT_COLOR:WrapTextInColorCode(Syndicator.Locales.NO_RESULTS_FOUND))
      end
    end)
  end)
end
-- Compatibility
Syndicator.Search.RunMegaSearchAndPrintResults = Syndicator.Search.SearchEverywhereAndPrintResults
