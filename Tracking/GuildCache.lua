SyndicatorGuildCacheMixin = {}

local function InitGuild(key, guild, realm)
  if not SYNDICATOR_DATA.Guilds[key] then
    SYNDICATOR_DATA.Guilds[key] = {
      bank = {},
      money = 0,
      details = {
        guild = guild,
        faction = UnitFactionGroup("player"),
        hidden = false,
        visited = false,
        realm = realm,
      },
    }
  end
  SYNDICATOR_DATA.Guilds[key].details.realms = nil
  SYNDICATOR_DATA.Guilds[key].details.realm = realm
end

local seenGuilds = {}

local GUILD_OPEN_EVENTS = {
  "GUILDBANKBAGSLOTS_CHANGED",
  "GUILDBANK_UPDATE_TABS",
  "GUILDBANK_UPDATE_MONEY",
}

function SyndicatorGuildCacheMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, {
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
    "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
    "GUILD_ROSTER_UPDATE",
    "PLAYER_GUILD_UPDATE",
  })

  self:GetGuildKey()
  self.lastTabPickups = {}

  local function UpdateForPickup(tabIndex, slotID)
    table.insert(self.lastTabPickups, tabIndex)
    while #self.lastTabPickups > 2 do
      table.remove(self.lastTabPickups, 1)
    end
  end
  hooksecurefunc("PickupGuildBankItem", UpdateForPickup)
  hooksecurefunc("SplitGuildBankItem", UpdateForPickup)
end

function SyndicatorGuildCacheMixin:GetGuildKey()
  if not IsInGuild() then
    Syndicator.CallbackRegistry:TriggerEvent("GuildNameSet", nil)
    return
  end

  local guildName = GetGuildInfo("player")

  if not guildName then
    return
  end

  if seenGuilds[guildName] then
    return seenGuilds[guildName]
  end

  local oldGuild = self.currentGuild

  self.currentGuild = nil

  local gm, gmGUID
  for i = 1, GetNumGuildMembers() do
    local name, _, rankIndex, _, _, _, _, _, _, _, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(i)
    if rankIndex == 0 then
      gm, gmGUID = name, gmGUID
    end
  end

  local _, gmRealm
  if gm then
    _, gmRealm = strsplit("-", gm)
  end

  if not gmRealm then
    if gmGUID then
      print("guid")
      GetPlayerInfoByGUID(gmGUID)
    else
      C_GuildInfo.GuildRoster()
    end
    C_Timer.After(0, function()
      if self.currentGuild == nil then
        self:GetGuildKey()
      end
    end)
    return
  end

  local gmKey = guildName .. "-" .. gmRealm

  -- No guild found cached, create it
  InitGuild(gmKey, guildName, gmRealm)
  seenGuilds[guildName] = gmKey

  self.currentGuild = gmKey

  if oldGuild ~= self.currentGuild then
    Syndicator.CallbackRegistry:TriggerEvent("GuildNameSet", self.currentGuild)
  end
end

function SyndicatorGuildCacheMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
    local interactionType = ...
    if interactionType == Enum.PlayerInteractionType.GuildBanker and self.currentGuild ~= nil then
      self.isUpdatePending = true
      FrameUtil.RegisterFrameForEvents(self, GUILD_OPEN_EVENTS)
      self:ExamineGeneralTabInfo()
      self:StartFullBankScan()
    end
  elseif eventName == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
    local interactionType = ...
    if interactionType == Enum.PlayerInteractionType.GuildBanker then
      FrameUtil.UnregisterFrameForEvents(self, GUILD_OPEN_EVENTS)
    end
  elseif eventName == "GUILDBANKBAGSLOTS_CHANGED" then
    self.isUpdatePending = true
    self:SetScript("OnUpdate", self.OnUpdate)
  elseif eventName == "GUILDBANK_UPDATE_TABS" then
    self.isUpdatePending = true
    self:ExamineGeneralTabInfo()
  elseif eventName == "GUILDBANK_UPDATE_MONEY" then
    self:GetGuildKey()
    local data = SYNDICATOR_DATA.Guilds[self.currentGuild]
    if data then
      data.money = GetGuildBankMoney()
      Syndicator.CallbackRegistry:TriggerEvent("GuildCacheUpdate", self.currentGuild)
    end
  -- Potential change to guild name
  elseif eventName == "GUILD_ROSTER_UPDATE" or eventName == "PLAYER_GUILD_UPDATE" then
    local oldGuild = self.currentGuild
    self:GetGuildKey()
  end
end

function SyndicatorGuildCacheMixin:StartFullBankScan()
  local bank = SYNDICATOR_DATA.Guilds[self.currentGuild].bank

  if GetNumGuildBankTabs() > 0 then
    self.toScan = {}
    local originalTab = GetCurrentGuildBankTab()
    for tabIndex = 1, GetNumGuildBankTabs() do
      if bank[tabIndex].isViewable and tabIndex ~= originalTab then
        QueryGuildBankTab(tabIndex)
      end
    end
    if bank[originalTab].isViewable then
      QueryGuildBankTab(originalTab)
    end
  end
end

function SyndicatorGuildCacheMixin:OnUpdate()
  self:SetScript("OnUpdate", nil)
  self:ExamineAllBankTabs()
end

function SyndicatorGuildCacheMixin:ProcessTransfers(changed)
  if next(changed) == nil then
    return
  end
  if #self.lastTabPickups > 1 then
    local indexes = {}
    for _, tabIndex in ipairs(self.lastTabPickups) do
      indexes[tabIndex] = true
    end
    indexes[GetCurrentGuildBankTab()] = nil
    for tabIndex in pairs(changed) do
      indexes[tabIndex] = nil
    end
    -- If an item has been moved from another tab that hasn't reported a change
    -- query that tab to get the the change
    if next(indexes) ~= nil then
      for tabIndex in pairs(indexes) do
        QueryGuildBankTab(tabIndex)
      end
      QueryGuildBankTab(GetCurrentGuildBankTab())
    end
    self.lastTabPickups = {}
  end
end

function SyndicatorGuildCacheMixin:ExamineGeneralTabInfo()
  local start = debugprofilestop()

  local data = SYNDICATOR_DATA.Guilds[self.currentGuild]

  data.money = GetGuildBankMoney()
  data.details.visited = true

  local numTabs = GetNumGuildBankTabs()

  if numTabs == 0 then
    data.bank = {}
    if Syndicator.Config.Get(Syndicator.Config.Options.DEBUG_TIMERS) then
      print("guild clear took", debugprofilestop() - start)
    end
    Syndicator.CallbackRegistry:TriggerEvent("GuildCacheUpdate", self.currentGuild)
    self.isUpdatePending = false
    return
  end

  for tabIndex = 1, numTabs do
    local name, icon, isViewable = GetGuildBankTabInfo(tabIndex)
    if data.bank[tabIndex] == nil then
      data.bank[tabIndex] = {
        slots = {}
      }
    end
    local tab = data.bank[tabIndex]
    tab.isViewable = isViewable
    tab.name = name
    tab.iconTexture = icon
  end

  if Syndicator.Config.Get(Syndicator.Config.Options.DEBUG_TIMERS) then
    print("guild general", debugprofilestop() - start)
  end
  self.isUpdatePending = false
  Syndicator.CallbackRegistry:TriggerEvent("GuildCacheUpdate", self.currentGuild)
end

function SyndicatorGuildCacheMixin:ExamineAllBankTabs()
  local start = debugprofilestop()
  local waiting = GetNumGuildBankTabs()
  if waiting == 0 then
    self.isUpdatePending = false
    return
  end
  local finished = false
  local changed = {}
  local anythingChanged = false
  for tabIndex = 1, GetNumGuildBankTabs() do
    self:ExamineBankTab(tabIndex, function(tabIndex, anyChanges)
      changed[tabIndex] = anyChanges or nil
      waiting = waiting - 1
      if waiting == 0 then
        self:ProcessTransfers(changed)
        if Syndicator.Config.Get(Syndicator.Config.Options.DEBUG_TIMERS) then
          print("guild full scan", debugprofilestop() - start)
        end
        self.isUpdatePending = false
        Syndicator.CallbackRegistry:TriggerEvent("GuildCacheUpdate", self.currentGuild, changed)
      end
    end)
  end
end

function SyndicatorGuildCacheMixin:ExamineBankTab(tabIndex, callback)
  local start = debugprofilestop()

  local data = SYNDICATOR_DATA.Guilds[self.currentGuild]

  local tab = data.bank[tabIndex]
  local oldSlots = tab.slots

  local function FireGuildChange()
    local changed = false
    for index, item in ipairs(tab.slots) do
      local oldItem = oldSlots[index]
      if not oldItem or item.itemID ~= oldItem.itemID or item.itemLink ~= oldItem.itemLink or item.itemCount ~= oldItem.itemCount then
        changed = true
        break
      end
    end
    if Syndicator.Config.Get(Syndicator.Config.Options.DEBUG_TIMERS) then
      print("guild tab " .. tabIndex .. " took", debugprofilestop() - start)
    end
    callback(tabIndex, changed)
  end

  tab.slots = {}
  local waiting = 0
  if tab.isViewable then
    local function DoSlot(slotIndex, itemID)
      local itemLink = GetGuildBankItemLink(tabIndex, slotIndex)

      if itemLink == nil then
        return
      end

      local texture, itemCount, locked, isFiltered, quality = GetGuildBankItemInfo(tabIndex, slotIndex)

      if itemID == Syndicator.Constants.BattlePetCageID then
        local tooltipInfo = C_TooltipInfo.GetGuildBankItem(tabIndex, slotIndex)
        itemLink, quality = Syndicator.Utilities.RecoverBattlePetLink(tooltipInfo, itemLink, quality)
      end

      tab.slots[slotIndex] = {
        itemID = itemID,
        iconTexture = texture,
        itemCount = itemCount,
        itemLink = itemLink,
        quality = quality,
      }
    end

    local loopComplete = false
    for slotIndex = 1, Syndicator.Constants.MaxGuildBankTabItemSlots do
      local itemLink = GetGuildBankItemLink(tabIndex, slotIndex)
      tab.slots[slotIndex] = {}
      if itemLink ~= nil then
        local itemID = C_Item.GetItemInfoInstant(itemLink)
        if C_Item.IsItemDataCachedByID(itemID) then
          DoSlot(slotIndex, itemID)
        else
          waiting = waiting + 1
          Syndicator.Utilities.LoadItemData(itemID, function()
            DoSlot(slotIndex, itemID)
            waiting = waiting - 1
            if loopComplete and waiting == 0 then
              FireGuildChange()
            end
          end)
        end
      end
    end
    loopComplete = true
  end
  if waiting == 0 then
    FireGuildChange()
  end
end
