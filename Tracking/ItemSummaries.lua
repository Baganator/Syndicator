SyndicatorItemSummariesMixin = {}

function SyndicatorItemSummariesMixin:OnLoad()
  if BAGANATOR_SUMMARIES ~= nil and SYNDICATOR_SUMMARIES == nil then
    SYNDICATOR_SUMMARIES = BAGANATOR_SUMMARIES
  end
  if SYNDICATOR_SUMMARIES == nil or SYNDICATOR_SUMMARIES.Version < 3 then
    SYNDICATOR_SUMMARIES = {
      Version = 3,
      Characters = {
        ByRealm = {},
        Pending = {},
      },
      Guilds = {
        ByRealm = {},
        Pending = {},
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
  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate", self.CharacterCacheUpdate, self)
  Syndicator.CallbackRegistry:RegisterCallback("MailCacheUpdate", self.CharacterCacheUpdate, self)
  Syndicator.CallbackRegistry:RegisterCallback("GuildCacheUpdate", self.GuildCacheUpdate, self)
  Syndicator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", self.CharacterCacheUpdate, self)
  Syndicator.CallbackRegistry:RegisterCallback("VoidCacheUpdate", self.CharacterCacheUpdate, self)
  Syndicator.CallbackRegistry:RegisterCallback("AuctionsCacheUpdate", self.CharacterCacheUpdate, self)
end

function SyndicatorItemSummariesMixin:CharacterCacheUpdate(characterName)
  self.SV.Characters.Pending[characterName] = true
end

function SyndicatorItemSummariesMixin:GuildCacheUpdate(guildName)
  self.SV.Guilds.Pending[guildName] = true
end

function SyndicatorItemSummariesMixin:GenerateCharacterSummary(characterName)
  local summary = {}
  local details = SYNDICATOR_DATA.Characters[characterName]

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

  if not self.SV.Characters.ByRealm[details.details.realmNormalized] then
    self.SV.Characters.ByRealm[details.details.realmNormalized] = {}
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

  if not self.SV.Guilds.ByRealm[details.details.realms[1]] then
    self.SV.Guilds.ByRealm[details.details.realms[1]] = {}
  end
  self.SV.Guilds.ByRealm[details.details.realms[1]][details.details.guild] = summary
end

function SyndicatorItemSummariesMixin:GetTooltipInfo(key, sameConnectedRealm, sameFaction)
  if next(self.SV.Characters.Pending) then
    local start = debugprofilestop()
    for character in pairs(self.SV.Characters.Pending) do
      self.SV.Characters.Pending[character] = nil
      self:GenerateCharacterSummary(character)
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

  return result
end
