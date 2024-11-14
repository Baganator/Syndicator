local addonName = ...

local TOOLTIP_OPTIONS = {
  {
    type = "header",
    text = SYNDICATOR_L_TOOLTIP_SETTINGS,
  },
  {
    type = "checkbox",
    text = SYNDICATOR_L_SHOW_INVENTORY,
    option = "show_inventory_tooltips",
  },
  {
    type = "checkbox",
    text = SYNDICATOR_L_SHOW_EQUIPPED,
    option = "show_equipped_items_in_tooltips",
  },
  {
    type = "checkbox",
    text = SYNDICATOR_L_SHOW_GUILD_BANKS,
    option = "show_guild_banks_in_tooltips",
    check = NotIsEraCheck,
  },
  {
    type = "checkbox",
    text = SYNDICATOR_L_SHOW_CURRENCY,
    option = "show_currency_tooltips",
    check = function() return C_CurrencyInfo ~= nil end,
  },
  {
    type = "spacing",
  },
  {
    type = "checkbox",
    text = SYNDICATOR_L_SAME_CONNECTED_REALMS,
    option = "tooltips_connected_realms_only_2",
  },
  {
    type = "checkbox",
    text = SYNDICATOR_L_SAME_FACTION,
    option = "tooltips_faction_only",
  },
  {
    type = "spacing",
  },
  {
    type = "checkbox",
    text = SYNDICATOR_L_SHOW_RACE_ICONS,
    option = "show_character_race_icons",
  },
  {
    type = "checkbox",
    text = SYNDICATOR_L_SORT_BY_NAME,
    option = "tooltips_sort_by_name",
  },
  {
    type = "checkbox",
    text = SYNDICATOR_L_HOLD_SHIFT_TO_DISPLAY,
    option = "show_tooltips_on_shift",
  },
  {
    type = "slider",
    min = 1,
    max = 40,
    lowText = "1",
    highText = "40",
    valuePattern = SYNDICATOR_L_X_CHARACTERS_SHOWN,
    option = "tooltips_character_limit",
  },
}

local hiddenColor = CreateColor(1, 0, 0)
local shownColor = CreateColor(0, 1, 0)

local function MakeCharacterEditor(parent)
  local function SetHideButton(frame)
    frame.HideButton = CreateFrame("Button", nil, frame)
    frame.HideButton:SetNormalAtlas("socialqueuing-icon-eye")
    frame.HideButton:SetPoint("TOPLEFT", 8, -2.5)
    frame.HideButton:SetSize(15, 15)
    frame.HideButton:SetScript("OnClick", function()
      Syndicator.API.ToggleCharacterHidden(frame.fullName)
      GameTooltip:Hide()
      frame:UpdateHideVisual()
    end)
    frame.HideButton:SetScript("OnEnter", function()
      GameTooltip:SetOwner(frame.HideButton, "ANCHOR_RIGHT")
      if Syndicator.API.GetCharacter(frame.fullName).details.hidden then
        GameTooltip:SetText(SYNDICATOR_L_SHOW_IN_TOOLTIPS)
      else
        GameTooltip:SetText(SYNDICATOR_L_HIDE_IN_TOOLTIPS)
      end
      GameTooltip:Show()
      frame.HideButton:SetAlpha(0.5)
    end)
    frame.HideButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
      frame.HideButton:SetAlpha(1)
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
      GameTooltip:SetText(SYNDICATOR_L_DELETE_CHARACTER)
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
    frame.RaceIcon:SetPoint("TOPLEFT", 35, -2.5)
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
    end
    if elementData.race then
      frame.RaceIcon:SetText(Syndicator.Utilities.GetCharacterIcon(elementData.race, elementData.sex))
    end
    frame:SetText(frame.fullName)
    frame:GetFontString():SetPoint("LEFT", 52, 0)
    frame:GetFontString():SetPoint("RIGHT", -20, 0)
    frame:GetFontString():SetJustifyH("LEFT")
    if elementData.className then
      local classColor = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[elementData.className]
      frame:GetFontString():SetTextColor(classColor.r, classColor.g, classColor.b)
    else
      frame:GetFontString():SetTextColor(1, 1, 1)
    end
    frame.UpdateHideVisual = function()
      if Syndicator.API.GetCharacter(frame.fullName).details.hidden then
        frame.HideButton:GetNormalTexture():SetVertexColor(hiddenColor.r, hiddenColor.g, hiddenColor.b)
      else
        frame.HideButton:GetNormalTexture():SetVertexColor(shownColor.r, shownColor.g, shownColor.b)
      end
    end
    if not frame.HideButton then
      SetHideButton(frame)
      SetDeleteButton(frame)
    end
    frame.DeleteButton:SetShown(frame.fullName ~= Syndicator.API.GetCurrentCharacter())
    frame:UpdateHideVisual()
  end)
  ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

  return container
end

local function MakeGuildEditor(parent)
  local function SetHideButton(frame)
    frame.HideButton = CreateFrame("Button", nil, frame)
    frame.HideButton:SetNormalAtlas("socialqueuing-icon-eye")
    frame.HideButton:SetPoint("TOPLEFT", 8, -2.5)
    frame.HideButton:SetSize(15, 15)
    frame.HideButton:SetScript("OnClick", function()
      Syndicator.API.ToggleGuildHidden(frame.fullName)
      GameTooltip:Hide()
      frame:UpdateHideVisual()
    end)
    frame.HideButton:SetScript("OnEnter", function()
      GameTooltip:SetOwner(frame.HideButton, "ANCHOR_RIGHT")
      if Syndicator.API.GetGuild(frame.fullName).details.hidden then
        GameTooltip:SetText(SYNDICATOR_L_SHOW_IN_TOOLTIPS)
      else
        GameTooltip:SetText(SYNDICATOR_L_HIDE_IN_TOOLTIPS)
      end
      GameTooltip:Show()
      frame.HideButton:SetAlpha(0.5)
    end)
    frame.HideButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
      frame.HideButton:SetAlpha(1)
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
      GameTooltip:SetText(SYNDICATOR_L_DELETE_GUILD)
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
    frame.GuildIcon:SetPoint("TOPLEFT", 35, -2.5)
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
        realm = info.details.realm,
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
    frame:GetFontString():SetPoint("LEFT", 52, 0)
    frame:GetFontString():SetPoint("RIGHT", -20, 0)
    frame:GetFontString():SetJustifyH("LEFT")
    frame.UpdateHideVisual = function()
      if Syndicator.API.GetGuild(frame.fullName).details.hidden then
        frame.HideButton:GetNormalTexture():SetVertexColor(hiddenColor.r, hiddenColor.g, hiddenColor.b)
      else
        frame.HideButton:GetNormalTexture():SetVertexColor(shownColor.r, shownColor.g, shownColor.b)
      end
    end
    if not frame.HideButton then
      SetHideButton(frame)
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
  header:SetPoint("TOPLEFT", optionsFrame, 15, -15)
  header:SetText(NORMAL_FONT_COLOR:WrapTextInColorCode(SYNDICATOR_L_SYNDICATOR))

  local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
  local versionText = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  versionText:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
  versionText:SetText(WHITE_FONT_COLOR:WrapTextInColorCode(SYNDICATOR_L_VERSION_COLON_X:format(version)))

  local lastItem = versionText

  local yOffset = 0
  for _, entry in ipairs(TOOLTIP_OPTIONS) do
    if entry.check == nil or entry.check() then
      if entry.type == "header" then
        local header = optionsFrame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
        header:SetPoint("TOPLEFT", lastItem, "BOTTOMLEFT", 0, -10 + yOffset)
        header:SetText(entry.text)
        lastItem = header
      elseif entry.type == "checkbox" then
        local checkButton = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
        checkButton:SetPoint("TOPLEFT", lastItem, "BOTTOMLEFT", 0, -5 + yOffset)
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
        sliderWrapper:SetPoint("TOPLEFT", lastItem, "BOTTOMLEFT", -5 + yOffset)
        sliderWrapper:SetPoint("RIGHT", optionsFrame)
        sliderWrapper:SetHeight(60)
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
        yOffset = -20
      end
    end
  end

  optionsFrame.OnCommit = function() end
  optionsFrame.OnDefault = function() end
  optionsFrame.OnRefresh = function() end

  local characterEditor = MakeCharacterEditor(optionsFrame)
  characterEditor:SetPoint("TOPRIGHT", optionsFrame, -15, -80)
  characterEditor:SetSize(320, 210)
  local characterHeader = optionsFrame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
  characterHeader:SetPoint("BOTTOMLEFT", characterEditor, "TOPLEFT", 0, 5)
  characterHeader:SetText(SYNDICATOR_L_CHARACTERS)

  local guildEditor = MakeGuildEditor(optionsFrame)
  guildEditor:SetPoint("TOPRIGHT", optionsFrame, -15, -320)
  guildEditor:SetSize(320, 130)
  local guildHeader = optionsFrame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
  guildHeader:SetPoint("BOTTOMLEFT", guildEditor, "TOPLEFT", 0, 5)
  guildHeader:SetText(SYNDICATOR_L_GUILDS)

  local category = Settings.RegisterCanvasLayoutCategory(optionsFrame, SYNDICATOR_L_SYNDICATOR)
  category.ID = SYNDICATOR_L_SYNDICATOR
  Settings.RegisterAddOnCategory(category)
end
