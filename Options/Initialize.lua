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
    type = "checkbox",
    text = SYNDICATOR_L_SAME_CONNECTED_REALMS,
    option = "tooltips_connected_realms_only",
  },
  {
    type = "checkbox",
    text = SYNDICATOR_L_SAME_FACTION,
    option = "tooltips_faction_only",
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

  for _, entry in ipairs(TOOLTIP_OPTIONS) do
    if entry.check == nil or entry.check() then
      if entry.type == "header" then
        local header = optionsFrame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
        header:SetPoint("TOPLEFT", lastItem, "BOTTOMLEFT", 0, -10)
        header:SetText(entry.text)
        lastItem = header
      elseif entry.type == "checkbox" then
        local checkButton = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
        checkButton:SetPoint("TOPLEFT", lastItem, "BOTTOMLEFT", 0, -5)
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
        sliderWrapper:SetPoint("TOPLEFT", lastItem, "BOTTOMLEFT", -5)
        sliderWrapper:SetPoint("RIGHT", optionsFrame)
        sliderWrapper:SetHeight(60)
        local slider = CreateFrame("Slider", nil, sliderWrapper, "OptionsSliderTemplate")
        slider:SetPoint("RIGHT", sliderWrapper, -30, -10)
        slider:SetPoint("LEFT", sliderWrapper, 30, -10)
        slider:SetMinMaxValues(entry.min, entry.max)
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
    end
  end

  optionsFrame.OnCommit = function() end
  optionsFrame.OnDefault = function() end
  optionsFrame.OnRefresh = function() end

  local category = Settings.RegisterCanvasLayoutCategory(optionsFrame, SYNDICATOR_L_SYNDICATOR)
  category.ID = SYNDICATOR_L_SYNDICATOR
  Settings.RegisterAddOnCategory(category)
end
