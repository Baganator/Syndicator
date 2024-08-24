SyndicatorItemSummariesMixin = {}

local CharacterUpdates = {
  All = 1,
  Bags = 2,
}

function SyndicatorItemSummariesMixin:OnLoad()
  if BAGANATOR_SUMMARIES ~= nil and SYNDICATOR_SUMMARIES == nil then
    SYNDICATOR_SUMMARIES = BAGANATOR_SUMMARIES
  end
  if SYNDICATOR_SUMMARIES ~= nil and SYNDICATOR_SUMMARIES.Version == 4 then
    SYNDICATOR_SUMMARIES.Version = 5
    SYNDICATOR_SUMMARIES.Warband = {
      Summary = {},
      Pending = { true },
    }
  end
  if SYNDICATOR_SUMMARIES == nil or SYNDICATOR_SUMMARIES.Version < 5 then
    SYNDICATOR_SUMMARIES = {
      Version = 5,
      Characters = {
        ByRealm = {},
        Pending = {},
      },
      Guilds = {
        ByRealm = {},
        Pending = {},
      },
      Warband = {
        Summary = {},
        Pending = { true },
      },
    }
    for character, data in pairs(SYNDICATOR_DATA.Characters) do
      SYNDICATOR_SUMMARIES.Characters.Pending[character] = true
    end
    for guild, data in pairs(SYNDICATOR_DATA.Guilds) do
      SYNDICATOR_SUMMARIES.Guilds.Pending[guild] = true
    end
  end
  self.SV = SYNDICATOR_SUMMARIES
  -- Optimisation as bags are most frequently updated container
  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate", function(_, characterName, updates)
    if next(updates.bags) and not next(updates.bank) and not self.SV.Characters.Pending[characterName] and updates.containerBags and not updates.containerBags.bags and not updates.containerBags.bank then
      self.SV.Characters.Pending[characterName] = CharacterUpdates.Bags
    else
      self.SV.Characters.Pending[characterName] = CharacterUpdates.All
    end
  end)
  Syndicator.CallbackRegistry:RegisterCallback("WarbandBankCacheUpdate", self.WarbandCacheUpdate, self)
  Syndicator.CallbackRegistry:RegisterCallback("MailCacheUpdate", self.CharacterCacheUpdate, self)
  Syndicator.CallbackRegistry:RegisterCallback("GuildCacheUpdate", self.GuildCacheUpdate, self)
  Syndicator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", self.CharacterCacheUpdate, self)
  Syndicator.CallbackRegistry:RegisterCallback("VoidCacheUpdate", self.CharacterCacheUpdate, self)
  Syndicator.CallbackRegistry:RegisterCallback("AuctionsCacheUpdate", self.CharacterCacheUpdate, self)

  self:Cleanup()
end

-- Tidy up summaries from removed characters and guilds (work around unknown
-- deletion bug)
function SyndicatorItemSummariesMixin:Cleanup()
  for realm, realmData in pairs(self.SV.Characters.ByRealm) do
    for character in pairs(realmData) do
      if not SYNDICATOR_DATA.Characters[character .. "-" .. realm] then
        realmData[character] = nil
      end
    end
  end
  for realm, realmData in pairs(self.SV.Guilds.ByRealm) do
    for guild in pairs(realmData) do
      if not SYNDICATOR_DATA.Guilds[guild .. "-" .. realm] then
        realmData[guild] = nil
      end
    end
  end
end

function SyndicatorItemSummariesMixin:CharacterCacheUpdate(characterName)
  self.SV.Characters.Pending[characterName] = CharacterUpdates.All
end

function SyndicatorItemSummariesMixin:WarbandCacheUpdate(index)
  self.SV.Warband.Pending[index] = true
end

function SyndicatorItemSummariesMixin:GuildCacheUpdate(guildName)
  self.SV.Guilds.Pending[guildName] = true
end

function SyndicatorItemSummariesMixin:GenerateCharacterSummary(characterName, state)
  local details = SYNDICATOR_DATA.Characters[characterName]

  -- Edge case sometimes removed characters are leftover in the queue, so check
  -- details exist
  if details == nil then
    return
  end

  if not self.SV.Characters.ByRealm[details.details.realmNormalized] then
    self.SV.Characters.ByRealm[details.details.realmNormalized] = {}
  end

  local summary = {}
  if state == CharacterUpdates.Bags then
    summary = self.SV.Characters.ByRealm[details.details.realmNormalized][details.details.character] or summary
    for key, details in pairs(summary) do
      details.bags = 0
    end
  end

  -- Edge case sometimes removed characters are leftover in the queue, so check
  -- details exist
  if details == nil then
    return
  end

  local function GenerateBase(key)
    if not summary[key] then
      summary[key] = {
        bags = 0,
        bank = 0,
        mail = 0,
        equipped = 0,
        void = 0,
        auctions = 0,
      }
    end
  end

  for _, bag in pairs(details.bags) do
    for _, item in pairs(bag) do
      if item.itemLink then
        local key = Syndicator.Utilities.GetItemKey(item.itemLink)
        GenerateBase(key)
        summary[key].bags = summary[key].bags + item.itemCount
      end
    end
  end

  if state == CharacterUpdates.All then
    if details.containerInfo then
      for _, item in ipairs(details.containerInfo.bags or {}) do
        if item.itemLink then
          local key = Syndicator.Utilities.GetItemKey(item.itemLink)
          GenerateBase(key)
          summary[key].equipped = summary[key].equipped + item.itemCount
        end
      end

      for _, item in ipairs(details.containerInfo.bank or {}) do
        if item.itemLink then
          local key = Syndicator.Utilities.GetItemKey(item.itemLink)
          GenerateBase(key)
          summary[key].equipped = summary[key].equipped + item.itemCount
        end
      end
    end

    for _, bag in pairs(details.bank) do
      for _, item in pairs(bag) do
        if item.itemLink then
          local key = Syndicator.Utilities.GetItemKey(item.itemLink)
          GenerateBase(key)
          summary[key].bank = summary[key].bank + item.itemCount
        end
      end
    end

    -- or because the mail is a newer key that might not exist on another
    -- character yet
    for _, item in pairs(details.mail or {}) do
      if item.itemLink then
        local key = Syndicator.Utilities.GetItemKey(item.itemLink)
        GenerateBase(key)
        summary[key].mail = summary[key].mail + item.itemCount
      end
    end

    -- or because the equipped is a newer key that might not exist on another
    -- character yet
    for _, item in pairs(details.equipped or {}) do
      if item.itemLink then
        local key = Syndicator.Utilities.GetItemKey(item.itemLink)
        GenerateBase(key)
        summary[key].equipped = summary[key].equipped + item.itemCount
      end
    end

    -- or because the void is a newer key that might not exist on another
    -- character yet
    for _, page in pairs(details.void or {}) do
      for _, item in ipairs(page) do
        if item.itemLink then
          local key = Syndicator.Utilities.GetItemKey(item.itemLink)
          GenerateBase(key)
          summary[key].void = summary[key].void + item.itemCount
        end
      end
    end

    -- or because the mail is a newer key that might not exist on another
    -- character yet
    for _, item in pairs(details.auctions or {}) do
      if item.itemLink then
        local key = Syndicator.Utilities.GetItemKey(item.itemLink)
        GenerateBase(key)
        summary[key].auctions = summary[key].auctions + item.itemCount
      end
    end
  end

  self.SV.Characters.ByRealm[details.details.realmNormalized][details.details.character] = summary
end

function SyndicatorItemSummariesMixin:GenerateGuildSummary(guildName)
  local summary = {}
  local details = SYNDICATOR_DATA.Guilds[guildName]

  -- Edge case sometimes removed guilds are leftover in the queue, so check
  -- details exist
  if details == nil then
    return
  end

  for _, tab in pairs(details.bank) do
    if tab.isViewable then
      for _, item in pairs(tab.slots) do
        if item.itemLink then
          local key = Syndicator.Utilities.GetItemKey(item.itemLink)
          if not summary[key] then
            summary[key] = {
              bank = 0,
            }
          end
          summary[key].bank = summary[key].bank + item.itemCount
        end
      end
    end
  end

  if not self.SV.Guilds.ByRealm[details.details.realm] then
    self.SV.Guilds.ByRealm[details.details.realm] = {}
  end
  self.SV.Guilds.ByRealm[details.details.realm][details.details.guild] = summary
end

function SyndicatorItemSummariesMixin:GenerateWarbandSummary()
  local summary = {}
  local details = SYNDICATOR_DATA.Warband[1].bank

  for _, tab in ipairs(details) do
    for _, item in ipairs(tab.slots) do
      if item.itemLink then
        local key = Syndicator.Utilities.GetItemKey(item.itemLink)
        if not summary[key] then
          summary[key] = 0
        end
        summary[key] = summary[key] + item.itemCount
      end
    end
  end

  self.SV.Warband.Summary[1] = summary
  self.SV.Warband.Pending[1] = false
end

function SyndicatorItemSummariesMixin:GetTooltipInfo(key, sameConnectedRealm, sameFaction)
  if next(self.SV.Characters.Pending) then
    local start = debugprofilestop()
    for character in pairs(self.SV.Characters.Pending) do
      local state = self.SV.Characters.Pending[character]
      self.SV.Characters.Pending[character] = nil
      self:GenerateCharacterSummary(character, state)
    end
    if Syndicator.Config.Get(Syndicator.Config.Options.DEBUG_TIMERS) then
      print("summaries char", debugprofilestop() - start)
    end
  end
  if next(self.SV.Guilds.Pending) then
    local start = debugprofilestop()
    for guild in pairs(self.SV.Guilds.Pending) do
      self.SV.Guilds.Pending[guild] = nil
      self:GenerateGuildSummary(guild)
    end
    if Syndicator.Config.Get(Syndicator.Config.Options.DEBUG_TIMERS) then
      print("summaries guild", debugprofilestop() - start)
    end
  end
  if self.SV.Warband.Pending[1] then
    local start = debugprofilestop()
    self:GenerateWarbandSummary()
    if Syndicator.Config.Get(Syndicator.Config.Options.DEBUG_TIMERS) then
      print("summaries warband", debugprofilestop() - start)
    end
  end

  local realms = {}
  if sameConnectedRealm then
    for _, r in ipairs(Syndicator.Utilities.GetConnectedRealms()) do
      realms[r] = true
    end
  else
    for r in pairs(self.SV.Characters.ByRealm) do
      realms[r] = true
    end
    for r in pairs(self.SV.Guilds.ByRealm) do
      realms[r] = true
    end
  end

  local result = {
    characters = {},
    guilds = {},
    warband = { 0 },
  }

  local currentFaction = UnitFactionGroup("player")

  for r in pairs(realms) do
    local charactersByRealm = self.SV.Characters.ByRealm[r]
    if charactersByRealm then
      for char, summary in pairs(charactersByRealm) do
        local byKey = summary[key]
        local characterDetails = SYNDICATOR_DATA.Characters[char .. "-" .. r].details
        if byKey ~= nil and not characterDetails.hidden and (not sameFaction or characterDetails.faction == currentFaction) then
          table.insert(result.characters, {
            character = char,
            realmNormalized = r,
            className = characterDetails.className,
            race = characterDetails.race,
            sex = characterDetails.sex,
            bags = byKey.bags or 0,
            bank = byKey.bank or 0,
            mail = byKey.mail or 0,
            equipped = byKey.equipped or 0,
            void = byKey.void or 0,
            auctions = byKey.auctions or 0,
          })
        end
      end
    end
    local guildsByRealm = self.SV.Guilds.ByRealm[r]
    if guildsByRealm then
      for guild, summary in pairs(guildsByRealm) do
        local byKey = summary[key]
        local guildDetails = SYNDICATOR_DATA.Guilds[guild .. "-" .. r].details
        if byKey ~= nil and not guildDetails.hidden and (not sameFaction or guildDetails.faction == currentFaction) then
          table.insert(result.guilds, {
            guild = guild,
            realmNormalized = r,
            bank = byKey.bank or 0
          })
        end
      end
    end
  end

  local currentGuild = Syndicator.API.GetCurrentGuild()
  if currentGuild then
    local currentGuildDetails = SYNDICATOR_DATA.Guilds[currentGuild].details
    if not FindInTableIf(result.guilds, function(a) return a.guild == currentGuildDetails.guild and a.realmNormalized == currentGuildDetails.realm end) and self.SV.Guilds.ByRealm[currentGuildDetails.realm] then
      local summary = self.SV.Guilds.ByRealm[currentGuildDetails.realm][currentGuildDetails.guild]
      if summary then
        local byKey = summary[key]
        if byKey ~= nil and not currentGuildDetails.hidden and (not sameFaction or currentGuildDetails.faction == currentFaction) then
          table.insert(result.guilds, {
            guild = currentGuildDetails.guild,
            realmNormalized = currentGuildDetails.realm,
            bank = byKey.bank or 0
          })
        end
      end
    end
  end

  if self.SV.Warband.Summary[1][key] then
    result.warband[1] = self.SV.Warband.Summary[1][key]
  end

  return result
end
