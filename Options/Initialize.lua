local addonName = ...

local TOOLTIP_OPTIONS = {
  {
    type = "header",
    text = Syndicator.Locales.TOOLTIP_SETTINGS,
  },
  {
    type = "checkbox",
    text = Syndicator.Locales.SHOW_INVENTORY,
    option = "show_inventory_tooltips",
  },
  {
    type = "checkbox",
    text = Syndicator.Locales.SHOW_EQUIPPED,
    option = "show_equipped_items_in_tooltips",
  },
  {
    type = "checkbox",
    text = Syndicator.Locales.SHOW_GUILD_BANKS,
    option = "show_guild_banks_in_tooltips",
    check = function() return not Syndicator.Constants.IsEra end,
  },
  {
    type = "checkbox",
    text = Syndicator.Locales.SHOW_CURRENCY,
    option = "show_currency_tooltips",
    check = function() return C_CurrencyInfo ~= nil end,
  },
  {
    type = "spacing",
  },
  {
    type = "checkbox",
    text = Syndicator.Locales.SAME_CONNECTED_REALMS,
    option = "tooltips_connected_realms_only_2",
  },
  {
    type = "checkbox",
    text = Syndicator.Locales.SAME_FACTION,
    option = "tooltips_faction_only",
  },
  {
    type = "spacing",
  },
  {
    type = "checkbox",
    text = Syndicator.Locales.SHOW_RACE_ICONS,
    option = "show_character_race_icons",
  },
  {
    type = "checkbox",
    text = Syndicator.Locales.SORT_BY_NAME,
    option = "tooltips_sort_by_name",
  },
  {
    type = "checkbox",
    text = Syndicator.Locales.HOLD_SHIFT_TO_DISPLAY,
    option = "show_tooltips_on_shift",
  },
  {
  type = "checkbox",
  text = Syndicator.Locales.SHOW_BLANK_LINE_BEFORE_INVENTORY,
  option = "show_blank_line_before_inventory",
  },
  {
  type = "checkbox",
  text = Syndicator.Locales.SHOW_TOTAL_LINE_AFTER_CHARACTERS,
  option = "show_total_line_after_characters",
  },
  {
    type = "slider",
    min = 1,
    max = 40,
    lowText = "1",
    highText = "40",
    valuePattern = Syndicator.Locales.X_CHARACTERS_SHOWN,
    option = "tooltips_character_limit",
  },
}

local hiddenColor = CreateColor(1, 0, 0)

local inventoryIcon = "banker"
local goldIcon = "coin-gold"
if C_Texture.GetAtlasInfo(goldIcon) == nil then
  goldIcon = "auctionhouse-icon-coin-gold"
end

local function MakeCharacterEditor(parent)
  local function SetShowInventoryButton(frame)
    frame.ShowInventoryButton = CreateFrame("Button", nil, frame)
    frame.ShowInventoryButton:SetNormalAtlas(inventoryIcon)
    frame.ShowInventoryButton:SetPoint("TOPLEFT", 8, -2.5)
    frame.ShowInventoryButton:SetSize(15, 15)
    frame.ShowInventoryButton:SetScript("OnClick", function()
      Syndicator.API.ToggleCharacterHidden(frame.fullName)
      GameTooltip:Hide()
      frame:UpdateHideVisual()
    end)
    frame.ShowInventoryButton:SetScript("OnEnter", function()
      GameTooltip:SetOwner(frame.ShowInventoryButton, "ANCHOR_RIGHT")
      if Syndicator.API.GetCharacter(frame.fullName).details.show.inventory then
        GameTooltip:SetText(Syndicator.Locales.HIDE_IN_INVENTORY_TOOLTIPS)
      else
        GameTooltip:SetText(Syndicator.Locales.SHOW_IN_INVENTORY_TOOLTIPS)
      end
      GameTooltip:Show()
      frame.ShowInventoryButton:SetAlpha(0.5)
    end)
    frame.ShowInventoryButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
      frame.ShowInventoryButton:SetAlpha(1)
    end)
  end

  local function SetShowGoldButton(frame)
    frame.ShowGoldButton = CreateFrame("Button", nil, frame)
    frame.ShowGoldButton:SetNormalAtlas(goldIcon)
    local tex = frame.ShowGoldButton:GetNormalTexture()
    tex:ClearAllPoints()
    tex:SetSize(11, 11)
    tex:SetPoint("CENTER")
    frame.ShowGoldButton:SetPoint("TOPLEFT", 27, -2.5)
    frame.ShowGoldButton:SetSize(15, 15)
    frame.ShowGoldButton:SetScript("OnClick", function()
      local characterData = Syndicator.API.GetCharacter(frame.fullName)
      characterData.details.show.gold = not characterData.details.show.gold
      GameTooltip:Hide()
      frame:UpdateHideVisual()
    end)
    frame.ShowGoldButton:SetScript("OnEnter", function()
      GameTooltip:SetOwner(frame.ShowGoldButton, "ANCHOR_RIGHT")
      if Syndicator.API.GetCharacter(frame.fullName).details.show.gold then
        GameTooltip:SetText(Syndicator.Locales.HIDE_IN_GOLD_SUMMARY)
      else
        GameTooltip:SetText(Syndicator.Locales.SHOW_IN_GOLD_SUMMARY)
      end
      GameTooltip:Show()
      frame.ShowGoldButton:SetAlpha(0.5)
    end)
    frame.ShowGoldButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
      frame.ShowGoldButton:SetAlpha(1)
    end)
  end

  local function SetDeleteButton(frame)
    frame.DeleteButton = CreateFrame("Button", nil, frame)
    frame.DeleteButton:SetNormalAtlas("transmog-icon-remove")
    frame.DeleteButton:SetPoint("TOPRIGHT", -5, -2.5)
    frame.DeleteButton:SetSize(15, 15)
    frame.DeleteButton:SetScript("OnClick", function()
      Syndicator.API.DeleteCharacter(frame.fullName)
    end)
    frame.DeleteButton:SetScript("OnEnter", function()
      GameTooltip:SetOwner(frame.DeleteButton, "ANCHOR_RIGHT")
      GameTooltip:SetText(Syndicator.Locales.DELETE_CHARACTER)
      GameTooltip:Show()
      frame.DeleteButton:SetAlpha(0.5)
    end)
    frame.DeleteButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
      frame.DeleteButton:SetAlpha(1)
    end)
  end

  local function SetRaceIcon(frame)
    frame.RaceIcon = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
    frame.RaceIcon:SetSize(15, 15)
    frame.RaceIcon:SetPoint("TOPLEFT", 47, -2.5)
  end

  local container = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")

  local scrollBar = CreateFrame("EventFrame", nil, container, "MinimalScrollBar")
  scrollBar:SetPoint("TOPRIGHT", -10, -5)
  scrollBar:SetPoint("BOTTOMRIGHT", -10, 5)
  local scrollBox = CreateFrame("Frame", nil, container, "WowScrollBoxList")
  scrollBox:SetPoint("TOPLEFT", 2, -2)
  scrollBox:SetPoint("BOTTOMRIGHT", scrollBar, "BOTTOMLEFT", -3, 0)

  local function UpdateList()
    local allCharacters = {}
    for _, character in ipairs(Syndicator.API.GetAllCharacters()) do
      local info = Syndicator.API.GetCharacter(character)
      table.insert(allCharacters, {
        fullName = character,
        className = info.details.className,
        race = info.details.race,
        sex = info.details.sex,
        realm = info.details.realm,
      })
    end
    table.sort(allCharacters, function(a, b)
      if a.realm == b.realm then
        return a.fullName < b.fullName
      else
        return a.realm < b.realm
      end
    end)
    scrollBox:SetDataProvider(CreateDataProvider(allCharacters), true)
  end

  container:SetScript("OnShow", function()
    UpdateList()
  end)

  Syndicator.CallbackRegistry:RegisterCallback("CharacterDeleted", function()
    UpdateList()
  end)

  local view = CreateScrollBoxListLinearView()
  view:SetElementExtent(20)
  view:SetElementInitializer("Button", function(frame, elementData)
    frame:SetPushedTextOffset(0, 0)
    frame:SetHighlightAtlas("search-highlight")
    frame:SetNormalFontObject(GameFontHighlight)
    frame.fullName = elementData.fullName
    if not frame.RaceIcon then
      SetRaceIcon(frame)
      SetShowInventoryButton(frame)
      SetShowGoldButton(frame)
      SetDeleteButton(frame)
    end
    if elementData.race then
      frame.RaceIcon:SetText(Syndicator.Utilities.GetCharacterIcon(elementData.race, elementData.sex))
    else
      frame.RaceIcon:SetText("")
    end
    frame:SetText(frame.fullName)
    frame:GetFontString():SetPoint("LEFT", 66, 0)
    frame:GetFontString():SetPoint("RIGHT", -20, 0)
    frame:GetFontString():SetJustifyH("LEFT")
    if elementData.className then
      local classColor = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[elementData.className]
      frame:GetFontString():SetTextColor(classColor.r, classColor.g, classColor.b)
    else
      frame:GetFontString():SetTextColor(1, 1, 1)
    end
    frame.UpdateHideVisual = function()
      if Syndicator.API.GetCharacter(frame.fullName).details.show.inventory then
        frame.ShowInventoryButton:GetNormalTexture():SetVertexColor(1, 1, 1)
      else
        frame.ShowInventoryButton:GetNormalTexture():SetVertexColor(hiddenColor.r, hiddenColor.g, hiddenColor.b)
      end
      if Syndicator.API.GetCharacter(frame.fullName).details.show.gold then
        frame.ShowGoldButton:GetNormalTexture():SetVertexColor(1, 1, 1)
      else
        frame.ShowGoldButton:GetNormalTexture():SetVertexColor(hiddenColor.r, hiddenColor.g, hiddenColor.b)
      end
    end
    frame.DeleteButton:SetShown(frame.fullName ~= Syndicator.API.GetCurrentCharacter())
    frame:UpdateHideVisual()
  end)
  ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

  return container
end

local function MakeGuildEditor(parent)
  local function SetShowInventoryButton(frame)
    frame.ShowInventoryButton = CreateFrame("Button", nil, frame)
    frame.ShowInventoryButton:SetNormalAtlas(inventoryIcon)
    frame.ShowInventoryButton:SetPoint("TOPLEFT", 8, -2.5)
    frame.ShowInventoryButton:SetSize(15, 15)
    frame.ShowInventoryButton:SetScript("OnClick", function()
      Syndicator.API.ToggleGuildHidden(frame.fullName)
      GameTooltip:Hide()
      frame:UpdateHideVisual()
    end)
    frame.ShowInventoryButton:SetScript("OnEnter", function()
      GameTooltip:SetOwner(frame.ShowInventoryButton, "ANCHOR_RIGHT")
      if Syndicator.API.GetGuild(frame.fullName).details.show.inventory then
        GameTooltip:SetText(Syndicator.Locales.HIDE_IN_INVENTORY_TOOLTIPS)
      else
        GameTooltip:SetText(Syndicator.Locales.SHOW_IN_INVENTORY_TOOLTIPS)
      end
      GameTooltip:Show()
      frame.ShowInventoryButton:SetAlpha(0.5)
    end)
    frame.ShowInventoryButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
      frame.ShowInventoryButton:SetAlpha(1)
    end)
  end

  local function SetShowGoldButton(frame)
    frame.ShowGoldButton = CreateFrame("Button", nil, frame)
    frame.ShowGoldButton:SetNormalAtlas(goldIcon)
    local tex = frame.ShowGoldButton:GetNormalTexture()
    tex:ClearAllPoints()
    tex:SetSize(11, 11)
    tex:SetPoint("CENTER")
    frame.ShowGoldButton:SetPoint("TOPLEFT", 27, -2.5)
    frame.ShowGoldButton:SetSize(15, 15)
    frame.ShowGoldButton:SetScript("OnClick", function()
      local guildData = Syndicator.API.GetGuild(frame.fullName)
      guildData.details.show.gold = not guildData.details.show.gold
      GameTooltip:Hide()
      frame:UpdateHideVisual()
    end)
    frame.ShowGoldButton:SetScript("OnEnter", function()
      GameTooltip:SetOwner(frame.ShowGoldButton, "ANCHOR_RIGHT")
      if Syndicator.API.GetGuild(frame.fullName).details.show.gold then
        GameTooltip:SetText(Syndicator.Locales.HIDE_IN_GOLD_SUMMARY)
      else
        GameTooltip:SetText(Syndicator.Locales.SHOW_IN_GOLD_SUMMARY)
      end
      GameTooltip:Show()
      frame.ShowGoldButton:SetAlpha(0.5)
    end)
    frame.ShowGoldButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
      frame.ShowGoldButton:SetAlpha(1)
    end)
  end

  local function SetDeleteButton(frame)
    frame.DeleteButton = CreateFrame("Button", nil, frame)
    frame.DeleteButton:SetNormalAtlas("transmog-icon-remove")
    frame.DeleteButton:SetPoint("TOPRIGHT", -5, -2.5)
    frame.DeleteButton:SetSize(15, 15)
    frame.DeleteButton:SetScript("OnClick", function()
      Syndicator.API.DeleteGuild(frame.fullName)
    end)
    frame.DeleteButton:SetScript("OnEnter", function()
      GameTooltip:SetOwner(frame.DeleteButton, "ANCHOR_RIGHT")
      GameTooltip:SetText(Syndicator.Locales.DELETE_GUILD)
      GameTooltip:Show()
      frame.DeleteButton:SetAlpha(0.5)
    end)
    frame.DeleteButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
      frame.DeleteButton:SetAlpha(1)
    end)
  end

  local function SetGuildIcon(frame)
    frame.GuildIcon = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
    frame.GuildIcon:SetSize(15, 15)
    frame.GuildIcon:SetPoint("TOPLEFT", 47, -5)
    frame.GuildIcon:SetText(Syndicator.Utilities.GetGuildIcon())
  end

  local container = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")

  local scrollBar = CreateFrame("EventFrame", nil, container, "MinimalScrollBar")
  scrollBar:SetPoint("TOPRIGHT", -10, -5)
  scrollBar:SetPoint("BOTTOMRIGHT", -10, 5)
  local scrollBox = CreateFrame("Frame", nil, container, "WowScrollBoxList")
  scrollBox:SetPoint("TOPLEFT", 2, -2)
  scrollBox:SetPoint("BOTTOMRIGHT", scrollBar, "BOTTOMLEFT", -3, 0)

  local function UpdateList()
    local allGuilds = {}
    for _, guild in ipairs(Syndicator.API.GetAllGuilds()) do
      local info = Syndicator.API.GetGuild(guild)
      table.insert(allGuilds, {
        fullName = guild,
        guild = info.details.guild,
        realm = info.details.realm or guild, -- Fallback value for legacy format
      })
    end
    table.sort(allGuilds, function(a, b)
      if a.realm == b.realm then
        return a.fullName < b.fullName
      else
        return a.realm < b.realm
      end
    end)
    scrollBox:SetDataProvider(CreateDataProvider(allGuilds), true)
  end

  container:SetScript("OnShow", function()
    UpdateList()
  end)

  Syndicator.CallbackRegistry:RegisterCallback("GuildDeleted", function()
    UpdateList()
  end)

  local view = CreateScrollBoxListLinearView()
  view:SetElementExtent(20)
  view:SetElementInitializer("Button", function(frame, elementData)
    frame:SetPushedTextOffset(0, 0)
    frame:SetHighlightAtlas("search-highlight")
    frame:SetNormalFontObject(GameFontHighlight)
    frame.fullName = elementData.fullName
    frame:SetText(TRANSMOGRIFY_FONT_COLOR:WrapTextInColorCode(elementData.guild) .. "-" .. NORMAL_FONT_COLOR:WrapTextInColorCode(elementData.realm))
    frame:GetFontString():SetPoint("LEFT", 66, 0)
    frame:GetFontString():SetPoint("RIGHT", -20, 0)
    frame:GetFontString():SetJustifyH("LEFT")
    frame.UpdateHideVisual = function()
      if Syndicator.API.GetGuild(frame.fullName).details.show.inventory then
        frame.ShowInventoryButton:GetNormalTexture():SetVertexColor(1, 1, 1)
      else
        frame.ShowInventoryButton:GetNormalTexture():SetVertexColor(hiddenColor.r, hiddenColor.g, hiddenColor.b)
      end
      if Syndicator.API.GetGuild(frame.fullName).details.show.gold then
        frame.ShowGoldButton:GetNormalTexture():SetVertexColor(1, 1, 1)
      else
        frame.ShowGoldButton:GetNormalTexture():SetVertexColor(hiddenColor.r, hiddenColor.g, hiddenColor.b)
      end
    end
    if not frame.ShowInventoryButton then
      SetShowInventoryButton(frame)
      SetShowGoldButton(frame)
      SetDeleteButton(frame)
      SetGuildIcon(frame)
    end
    frame.DeleteButton:SetShown(frame.fullName ~= Syndicator.API.GetCurrentGuild())
    frame:UpdateHideVisual()
  end)
  ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

  return container
end

function Syndicator.Options.Initialize()
  local optionsFrame = CreateFrame("Frame")
  optionsFrame:Hide()

  local header = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
  header:SetPoint("TOPLEFT", optionsFrame, 15, -10)
  header:SetText(NORMAL_FONT_COLOR:WrapTextInColorCode(Syndicator.Locales.SYNDICATOR))

  local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
  local versionText = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  versionText:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
  versionText:SetText(WHITE_FONT_COLOR:WrapTextInColorCode(Syndicator.Locales.VERSION_COLON_X:format(version)))

  local lastItem = versionText

  local yOffset = 0
  local spacing = 2

  do
    local dropdownWrapper = CreateFrame("Frame", nil, optionsFrame)
    dropdownWrapper:SetHeight(30)
    dropdownWrapper:SetPoint("TOPLEFT", lastItem, "BOTTOMLEFT", 0, -spacing - 10 + yOffset)
    dropdownWrapper:SetPoint("RIGHT", optionsFrame)
    local text = dropdownWrapper:CreateFontString("ARTWORK", nil, "GameFontHighlight")
    text:SetText(SYNDICATOR_L_AUCTION_VALUE_SOURCE)
    text:SetPoint("LEFT", dropdownWrapper)
    local dropdown = CreateFrame("DropdownButton", nil, dropdownWrapper, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(250)
    dropdown:SetPoint("LEFT", text, "RIGHT", 15, 0)
    dropdown:SetupMenu(function(_, rootDescription)
      local entries = {}
      table.insert(entries, {label = NONE, value = "none"})
      if Auctionator then
        table.insert(entries, {label = "Auctionator", value = "auctionator-latest"})
      end
      if TSM_API then
        table.insert(entries, {label = "TradeSkillMaster DBMarket", value = "tradeskillmaster-dbmarket"})
        table.insert(entries, {label = "TradeSkillMaster DBRecent", value = "tradeskillmaster-dbrecent"})
        table.insert(entries, {label = "TradeSkillMaster DBRegionMarketAvg", value = "tradeskillmaster-dbregionmarketavg"})
        table.insert(entries, {label = "TradeSkillMaster DBRegionSaleAvg", value = "tradeskillmaster-dbregionsaleavg"})
      end
      if OEMarketInfo then
        table.insert(entries, {label = "Undermine Exchange Realm", value = "undermineexchange-realm"})
        table.insert(entries, {label = "Undermine Exchange Region", value = "undermineexchange-region"})
      end
      if RECrystallize_PriceCheck then
        table.insert(entries, {label = "Recrystallize", value = "recrystallize"})
      end

      for _, entry in ipairs(entries) do
        rootDescription:CreateRadio(entry.label, function()
          return Syndicator.Config.Get(Syndicator.Config.Options.AUCTION_VALUE_SOURCE) == entry.value
        end, function()
          Syndicator.Config.Set(Syndicator.Config.Options.AUCTION_VALUE_SOURCE, entry.value)
          Syndicator.CallbackRegistry:TriggerEvent("AuctionValueSourceChanged")
        end)
      end
    end)
    lastItem = dropdownWrapper
  end

  for _, entry in ipairs(TOOLTIP_OPTIONS) do
    if entry.check == nil or entry.check() then
      if entry.type == "header" then
        local headerText = optionsFrame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
        headerText:SetPoint("TOPLEFT", lastItem, "BOTTOMLEFT", 0, -10 + yOffset)
        headerText:SetText(entry.text)
        lastItem = headerText
      elseif entry.type == "checkbox" then
        local checkButton = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
        checkButton:SetPoint("TOPLEFT", lastItem, "BOTTOMLEFT", 0, -spacing + yOffset)
        checkButton:SetScript("OnClick", function(self)
          Syndicator.Config.Set(entry.option, self:GetChecked())
        end)
        checkButton:SetScript("OnShow", function(self)
          self:SetChecked(Syndicator.Config.Get(entry.option))
        end)
        checkButton:SetScript("OnHide", function(self)
          self:UnlockHighlight()
        end)
        local text = checkButton:CreateFontString("ARTWORK", nil, "GameFontHighlight")
        text:SetText(entry.text)
        text:SetPoint("LEFT", checkButton, "RIGHT", 5, 2)
        text:SetScript("OnMouseUp", function()
          checkButton:Click()
        end)
        text:SetScript("OnEnter", function()
          checkButton:LockHighlight()
        end)
        text:SetScript("OnLeave", function()
          checkButton:UnlockHighlight()
        end)
        lastItem = checkButton
      elseif entry.type == "slider" then
        local sliderWrapper = CreateFrame("Frame", nil, optionsFrame)
        sliderWrapper:SetPoint("TOPLEFT", lastItem, "BOTTOMLEFT", -spacing + yOffset)
        sliderWrapper:SetPoint("RIGHT", optionsFrame)
        sliderWrapper:SetHeight(55)
        local slider = CreateFrame("Slider", nil, sliderWrapper, "UISliderTemplate")
        slider:SetHeight(20)
        slider:SetPoint("RIGHT", sliderWrapper, -30, -10)
        slider:SetPoint("LEFT", sliderWrapper, 30, -10)
        slider:SetMinMaxValues(entry.min, entry.max)
        slider.High = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        slider.High:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT")
        slider.Low = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        slider.Low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT")
        slider.Text = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        slider.Text:SetPoint("BOTTOM", slider, "TOP")
        slider.High:SetText(entry.highText)
        slider.Low:SetText(entry.lowText)
        slider:SetValueStep(1)
        slider:SetObeyStepOnDrag(true)

        slider:SetScript("OnValueChanged", function()
          local value = slider:GetValue()
          if entry.scale then
            value = value / entry.scale
          end
          Syndicator.Config.Set(entry.option, value)
          slider.Text:SetText(entry.valuePattern:format(math.floor(slider:GetValue())))
        end)
        slider:SetScript("OnShow", function(self)
          self:SetValue(Syndicator.Config.Get(entry.option) * (entry.scale or 1))
        end)
        lastItem = sliderWrapper
      end
      yOffset = 0
      if entry.type == "spacing" then
        yOffset = -17
      end
    end
  end

  optionsFrame.OnCommit = function() end
  optionsFrame.OnDefault = function() end
  optionsFrame.OnRefresh = function() end

  local characterEditor = MakeCharacterEditor(optionsFrame)
  characterEditor:SetPoint("TOPRIGHT", optionsFrame, -15, -115)
  characterEditor:SetSize(320, 210)
  local characterHeader = optionsFrame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
  characterHeader:SetPoint("BOTTOMLEFT", characterEditor, "TOPLEFT", 0, 5)
  characterHeader:SetText(Syndicator.Locales.CHARACTERS)

  local guildEditor = MakeGuildEditor(optionsFrame)
  guildEditor:SetPoint("TOPRIGHT", optionsFrame, -15, -360)
  guildEditor:SetSize(320, 130)
  local guildHeader = optionsFrame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
  guildHeader:SetPoint("BOTTOMLEFT", guildEditor, "TOPLEFT", 0, 5)
  guildHeader:SetText(Syndicator.Locales.GUILDS)

  local category = Settings.RegisterCanvasLayoutCategory(optionsFrame, Syndicator.Locales.SYNDICATOR)
  category.ID = Syndicator.Locales.SYNDICATOR
  Settings.RegisterAddOnCategory(category)
end
