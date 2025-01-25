local function GetKeywordGroups()
  local searchTerms = Syndicator.Search.GetKeywords()
  local groupsList = {}
  local groups = {}
  local seenInGroup = {}
  for _, term in ipairs(searchTerms) do
    groups[term.group] = groups[term.group] or {}
    seenInGroup[term.group] = seenInGroup[term.group] or {}

    if not seenInGroup[term.group][term.keyword] then
      table.insert(groups[term.group], term.keyword)
      seenInGroup[term.group][term.keyword] = true
    end
  end

  local result = {}
  for _, groupTitle in ipairs(Syndicator.Search.Constants.KeywordGroupOrder) do
    if groups[groupTitle] then
      table.sort(groups[groupTitle])
      table.insert(result, {
        label = groupTitle,
        elements = groups[groupTitle],
      })
    end
  end

  return result
end

local function GetMatches(text)
  local searchTerms = Syndicator.Search.GetKeywords()
  local result = {}
  local seen = {}

  for _, term in ipairs(searchTerms) do
    if term.keyword:sub(1, #text) == text and not seen[term.keyword] then
      seen[term.keyword] = true
      table.insert(result, term.keyword)
    end
  end

  table.sort(result)
  return result
end

local groups

local RootType = {
  Term = 1,
  Operator = 2,
}

local TermType = {
  Keyword = 1,
  Custom = 2,
}

local OperatorType = {
  Any = 1,
  All = 2,
  Not = 3,
}

local ComponentMixin = {}
function ComponentMixin:Init(mainType, subType, value)
  self.type = mainType
  self.subType = subType
  self.value = value
end

local function GetComponent(text)
  if text == "&" then
    return CreateAndInitFromMixin(ComponentMixin, RootType.Operator, OperatorType.All, {})
  elseif text == "|" then
    return CreateAndInitFromMixin(ComponentMixin, RootType.Operator, OperatorType.Any, {})
  elseif text == "!" then
    return CreateAndInitFromMixin(ComponentMixin, RootType.Operator, OperatorType.Not, {})
  elseif text:sub(1, 1) == "#" then
    return CreateAndInitFromMixin(ComponentMixin, RootType.Term, TermType.Keyword, text:sub(2))
  elseif text ~= "(" and text ~= ")" then
    return CreateAndInitFromMixin(ComponentMixin, RootType.Term, TermType.Custom, text)
  end
end

local function GetByIndex(root, index)
  if #index == 0 then
    return root
  else
    local place = root
    for j = 1, #index do
      place = place.value[index[j]]
    end
    return place
  end
end

-- Convert a search term into the flattest possible tree of ComponentMixin[s]
local function ProcessTerms(rawText)
  local tokens = {}

  do
    rawText = rawText:gsub("^%s*(.-)%s*$", "%1") -- remove surrounding whitespace
    -- Slightly changed parser from Search/CheckItem.lua
    local index = 1
    rawText = rawText:gsub("||", "|")
    while index < #rawText do
      -- Find operators and any surrounding whitespace
      local opIndexStart, opIndexEnd, op = rawText:find("%s*([%~%&%|%(%)%!])%s*", index)
      if op then
        local lead = rawText:sub(index, opIndexStart - 1)
        if lead ~= "" then
          table.insert(tokens, lead)
        end
        table.insert(tokens, op)
        index = opIndexEnd + 1
      else
        break
      end
    end
    local tail = rawText:sub(index, #rawText)
    if tail ~= "" then
      table.insert(tokens, tail)
    end
  end

  local root = GetComponent("|")
  local current = root
  local index = {} --- Used to track level of nested position in tree

  if #tokens == 1 and tokens[1] == "" then -- Nothing in the search term
    return root
  end

  for _, t in ipairs(tokens) do
    -- Unwrap any NOT, if they've had a component assigned
    while current.subType == OperatorType.Not and #current.value > 0 do
      table.remove(index)
      current = GetByIndex(root, index)
      if #index == 0 then
        break
      end
    end

    local c = GetComponent(t)
    if t == "(" then
      -- Generic ANY for brackets, will get replaced later if needed
      c = GetComponent("|")
      c.brackets = true
      table.insert(current.value, c)
      table.insert(index, #current.value)
      current = c
    elseif t == ")" then
      table.remove(index)
      current = GetByIndex(root, index)
    elseif t == "!" then
      -- Start the NOT (only contains one component)
      if current == root and #root.value == 0 then
        root = c
      else
        table.insert(current.value, c)
        table.insert(index, #current.value)
      end
      current = c
    elseif t == "|" then
      -- Replace the root with the current operator if there's no difference
      if current.subType == OperatorType.All and #current.value <= 1 then
        c.value = current.value
        c.brackets = current.brackets
        if #index > 0 then
          local tmpIndex = CopyTable(index)
          table.remove(tmpIndex)
          local tmp = GetByIndex(root, tmpIndex)
          tmp.value[index[#index]] = c
        else
          root = c
        end
        current = c
      -- Apply tighter binding of "&" over "|"
      elseif current.subType ~= OperatorType.Any then
        if #index == 0 then
          c.value = {root}
          current = c
          root = c
        else
          table.insert(c.value, current)
          local tmpIndex = CopyTable(index)
          table.remove(tmpIndex)
          local tmp = GetByIndex(root, tmpIndex)
          tmp.value[index[#index]] = c
          current = c
        end
      end
    elseif t == "&" then
      -- Replace the root with the current operator if there's no difference
      if current.subType == OperatorType.Any and #current.value <= 1 then
        c.value = current.value
        c.brackets = current.brackets
        if #index > 0 then
          local tmpIndex = CopyTable(index)
          table.remove(tmpIndex)
          local tmp = GetByIndex(root, tmpIndex)
          tmp.value[index[#index]] = c
        else
          root = c
        end
        current = c
      -- Apply looser binding of "&" over "|"
      elseif current.subType == OperatorType.Any then
        table.insert(c.value, table.remove(current.value))
        table.insert(current.value, c)
        table.insert(index, #current.value)
        current = c
      -- Apply tighter binding of "&" over "|"
      elseif current.subType == OperatorType.Not then
        if #index == 0 then
          c.value = {root}
          current = c
          root = c
        else
          table.insert(c.value, current)
          local tmpIndex = CopyTable(index)
          table.remove(tmpIndex)
          local tmp = GetByIndex(root, tmpIndex)
          tmp.value[index[#index]] = c
          current = c
        end
      end
    elseif c and c.type == RootType.Term then
      table.insert(current.value, c)
    end
  end

  return root
end

local OperatorMap = {
  [OperatorType.Any] = {label = SYNDICATOR_L_ANY_UPPER, tooltip = SYNDICATOR_L_ANY_TOOLTIP_TEXT, color = CreateColor(185/255, 225/255, 146/255)},
  [OperatorType.All] = {label = SYNDICATOR_L_ALL_UPPER, tooltip = SYNDICATOR_L_ALL_TOOLTIP_TEXT, color = CreateColor(179/255, 199/255, 247/255)},
  [OperatorType.Not] = {label = SYNDICATOR_L_NOT_UPPER, tooltip = SYNDICATOR_L_NOT_TOOLTIP_TEXT, color = CreateColor(241/255, 148/255, 184/255)},
}

local function SetupTextures(self)
  self.HoverTexture = self:CreateTexture(nil, "BACKGROUND")
  self.HoverTexture:SetColorTexture(0.5, 0.5, 0.5, 0.3)
  self.HoverTexture:SetPoint("TOPLEFT", -5, 0)
  self.HoverTexture:SetPoint("BOTTOMRIGHT", 5, 0)
end

local function GetOperatorMenu(rootDescription, index, callbackRegistry, event)
  rootDescription:CreateButton(OperatorMap[OperatorType.All].label, function()
    callbackRegistry:TriggerEvent(event, CreateAndInitFromMixin(ComponentMixin, RootType.Operator, OperatorType.All, {}), index)
  end)
  rootDescription:CreateButton(OperatorMap[OperatorType.Any].label, function()
    callbackRegistry:TriggerEvent(event, CreateAndInitFromMixin(ComponentMixin, RootType.Operator, OperatorType.Any, {}), index)
  end)
  rootDescription:CreateButton(OperatorMap[OperatorType.Not].label, function()
    callbackRegistry:TriggerEvent(event, CreateAndInitFromMixin(ComponentMixin, RootType.Operator, OperatorType.Not, {}), index)
  end)
end

local function GetKeywordMenu(rootDescription, index, callbackRegistry, event)
  rootDescription:CreateButton(SYNDICATOR_L_CUSTOM_SEARCH, function()
    callbackRegistry:TriggerEvent(event, CreateAndInitFromMixin(ComponentMixin, RootType.Term, TermType.Custom, ""), index)
  end)
  rootDescription:CreateDivider()
  for _, group in ipairs(groups) do
    local root = rootDescription:CreateButton(group.label)
    for _, entry in ipairs(group.elements) do
      root:CreateButton(entry, function()
        callbackRegistry:TriggerEvent(event, CreateAndInitFromMixin(ComponentMixin, RootType.Term, TermType.Keyword, entry), index)
      end)
    end
  end
end

local TermButtonMixin = {}

local function GetTermButton(parent)
  local result = CreateFrame("Button", nil, parent)
  Mixin(result, TermButtonMixin)
  result:OnLoad()

  return result
end

function TermButtonMixin:OnLoad()
  self:SetHeight(22)
  self:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  self:SetScript("OnEnter", self.OnEnter)
  self:SetScript("OnLeave", self.OnLeave)

  self:SetScript("OnClick", self.OnClick)

  SetupTextures(self)

  self.KeywordText = self:CreateFontString(nil, nil, "GameFontHighlight")
  self.KeywordText:SetPoint("TOPLEFT")
  self.KeywordText:SetHeight(22)

  self.CustomInput = CreateFrame("EditBox", nil, self)
  self.CustomInput:SetFontObject(GameFontHighlight)
  self.CustomInput:SetHeight(22)
  self.CustomInput:SetAutoFocus(false)
  self.CustomInput:SetScript("OnEscapePressed", function()
    self.CustomInput:ClearFocus()
    self.callbackRegistry:TriggerEvent("OnChange")
  end)
  self.CustomInput:SetScript("OnEnterPressed", function()
    self.CustomInput:ClearFocus()
    self.CustomInput:Hide()
    self.callbackRegistry:TriggerEvent("OnChange")
  end)
  self.CustomInput:SetScript("OnEditFocusLost", function()
    if self:IsVisible() then
      self.callbackRegistry:TriggerEvent("OnChange")
    end
  end)
  self.CustomInput:HookScript("OnEnter", function()
    self:OnEnter()
  end)
  self.CustomInput:HookScript("OnLeave", function()
    self:OnLeave()
  end)
  self.CustomInput:HookScript("OnMouseUp", function(_, button)
    self:OnClick(button)
  end)

  self.CustomInput.Prefix = self.CustomInput:CreateFontString(nil, nil, "GameFontNormal")
  self.CustomInput.Prefix:SetText("\"")
  self.CustomInput.Prefix:SetHeight(22)
  self.CustomInput.WidthChecker = self.CustomInput:CreateFontString(nil, nil, "GameFontHighlight")
  self.CustomInput.WidthChecker:Hide()
  self.CustomInput.Suffix = self.CustomInput:CreateFontString(nil, nil, "GameFontNormal")
  self.CustomInput.Suffix:SetText("\"")
  self.CustomInput.Suffix:SetHeight(22)

  self.CustomInput.Prefix:SetPoint("TOPLEFT", self)
  self.CustomInput.WidthChecker:SetPoint("TOPLEFT", self.CustomInput.Prefix, "TOPRIGHT")
  self.CustomInput:SetPoint("TOPLEFT", self.CustomInput.Prefix, "TOPRIGHT")
  self.CustomInput.Suffix:SetPoint("TOPLEFT", self.CustomInput.WidthChecker, "TOPRIGHT")

  self.CustomInput:SetScript("OnTextChanged", function()
    self.component.value = self.CustomInput:GetText()
    self.CustomInput:SetText(self.component.value)
    if self.CustomInput:GetText() == "" then
      self.CustomInput.WidthChecker:SetText("    ")
      self.CustomInput:SetWidth(self.CustomInput.WidthChecker:GetUnboundedStringWidth())
      self:SetWidth(self.CustomInput.WidthChecker:GetUnboundedStringWidth() + self.CustomInput.Prefix:GetWidth() + self.CustomInput.Suffix:GetWidth())
    else
      self.CustomInput.WidthChecker:SetText(self.CustomInput:GetText())
      self.CustomInput:SetWidth(self.CustomInput.WidthChecker:GetUnboundedStringWidth() + 20)
      self:SetWidth(self.CustomInput.WidthChecker:GetUnboundedStringWidth() + self.CustomInput.Prefix:GetWidth() + self.CustomInput.Suffix:GetWidth())
    end
    self.onResizeFunc()
  end)
end
function TermButtonMixin:OnEnter()
  self.HoverTexture:Show()
end
function TermButtonMixin:OnLeave()
  self.HoverTexture:Hide()
end
function TermButtonMixin:Setup(callbackRegistry, component, index, color)
  self.onResizeFunc = function() end
  self.callbackRegistry = callbackRegistry

  self.HoverTexture:Hide()
  self:SetAlpha(1)

  self.KeywordText:Hide()
  self.CustomInput:Hide()

  self.component = component
  self.index = index

  if component.subType == TermType.Keyword then
    self.KeywordText:Show()
    self.KeywordText:SetText(component.value)
    self.KeywordText:SetTextColor(color.r, color.g, color.b)
    self:SetWidth(self.KeywordText:GetUnboundedStringWidth())
  elseif component.subType == TermType.Custom then
    self.CustomInput:Show()
    self.CustomInput:SetText(component.value)
    self.CustomInput:SetTextColor(color.r, color.g, color.b)
    self.CustomInput.Prefix:SetTextColor(color.r, color.g, color.b)
    self.CustomInput.Suffix:SetTextColor(color.r, color.g, color.b)
    self.CustomInput:GetScript("OnTextChanged")(self.CustomInput)
    self.CustomInput:SetCursorPosition(0)
    if component.isAdding then
      self.CustomInput:SetFocus()
    end
    self.CustomInput:SetEnabled(callbackRegistry.enabled)
  end
  component.isAdding = false
end
function TermButtonMixin:OnClick(button)
  if not self.callbackRegistry.enabled then
    return
  end

  if self.component.subType == TermType.Keyword or (self.component.subType == TermType.Custom and button == "RightButton") then
    local index = self.index
    MenuUtil.CreateContextMenu(self, function(_, rootDescription)
      rootDescription:CreateTitle("Swap")
      GetKeywordMenu(rootDescription, index, self.callbackRegistry, SYNDICATOR_L_SWAP)
      rootDescription:CreateDivider()
      local wrapButton = rootDescription:CreateButton(SYNDICATOR_L_WRAP_WITH)
      GetOperatorMenu(wrapButton, index, self.callbackRegistry, "Wrap")
      rootDescription:CreateDivider()
      local button = rootDescription:CreateButton(SYNDICATOR_L_COPY, function()
        self.callbackRegistry:TriggerEvent("Copy", self.component)
      end)
      local button = rootDescription:CreateButton(SYNDICATOR_L_CUT, function()
        self.callbackRegistry:TriggerEvent("Copy", self.component)
        self.callbackRegistry:TriggerEvent("Delete", index)
      end)
      local button = rootDescription:CreateButton(DELETE, function()
        self.callbackRegistry:TriggerEvent("Delete", index)
      end)
      button:SetOnEnter(function()
        self:SetAlpha(0.4)
      end)
      button:SetOnLeave(function()
        self:SetAlpha(1)
      end)
    end)
  end
end

local OperatorButtonMixin = {}

local function GetOperatorButton(parent)
  local result = CreateFrame("Button", nil, parent)
  Mixin(result, OperatorButtonMixin)
  result:OnLoad()

  return result
end

function OperatorButtonMixin:OnLoad()
  self:SetHeight(22)
  self:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  self:SetScript("OnClick", self.OnClick)

  SetupTextures(self)

  self.AddButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
  self.AddButton:SetSize(26, 24)
  self.AddButton.Icon = self.AddButton:CreateTexture(nil, "ARTWORK")
  self.AddButton.Icon:SetAtlas("Garr_Building-AddFollowerPlus")
  self.AddButton.Icon:SetSize(19, 19)
  self.AddButton.Icon:SetPoint("CENTER")
  self.AddButton:SetPoint("TOPLEFT")
  self.AddButton:SetScript("OnClick", function()
    self.AddInput:SetText("")
    self.AddInput:Show()
    self.AddInput:SetFocus()
    self.AddButton:Hide()
    self.AddContextMenu:OpenMenu()
    self:Resize()
  end)

  self.AddInput = CreateFrame("EditBox", nil, self)
  self.AddInput:SetFontObject(GameFontHighlight)
  self.AddInput:SetHeight(22)
  self.AddInput:SetAutoFocus(false)
  local function ApplyAddInput(raw, index)
    local text = raw:lower():gsub("[()|&#]", "")
    if not index then
      index = CopyTable(self.index)
      table.insert(index, #self.component.value + 1)
    end
    local component
    if text == "any" or raw == "|" then
      component = CreateAndInitFromMixin(ComponentMixin, RootType.Operator, OperatorType.Any, {})
    elseif text == "all" or raw == "&" then
      component = CreateAndInitFromMixin(ComponentMixin, RootType.Operator, OperatorType.All, {})
    elseif text == "not" or raw == "!" then
      component = CreateAndInitFromMixin(ComponentMixin, RootType.Operator, OperatorType.Not, {})
    elseif text:match("\".*\"") then
      text = text:match("\"(.*)\"")
      component = CreateAndInitFromMixin(ComponentMixin, RootType.Term, TermType.Custom, text)
    elseif not text:match("^%s*$") then
      local matches = GetMatches(text)
      if matches[1] then
        component = CreateAndInitFromMixin(ComponentMixin, RootType.Term, TermType.Keyword, matches[1])
      else
        component = CreateAndInitFromMixin(ComponentMixin, RootType.Term, TermType.Custom, text)
      end
    end
    if component then
      self.callbackRegistry:TriggerEvent("Insert", component, index)
    else
      self.AddButton:Show()
      self.AddInput:Hide()
      self:Resize()
    end
  end
  self.AddInput:SetScript("OnEscapePressed", function()
    self.AddContextMenu:CloseMenu()
  end)
  local enterPressed = false
  self.AddInput:SetScript("OnEnterPressed", function()
    enterPressed = true
    self.AddContextMenu:CloseMenu()
    enterPressed = false
  end)

  self.AddInput.WidthChecker = self.AddInput:CreateFontString(nil, nil, "GameFontNormal")
  self.AddInput:SetScript("OnTextChanged", function()
    if not self:IsVisible() then
      return
    end
    local text = self.AddInput:GetText():gsub("[()|&#]", "")
    self.AddInput:SetText(text)
    if self.AddInput:GetText() == "" then
      self.AddInput.WidthChecker:SetText("")
      self.AddInput.WidthChecker:SetWidth(self.AddButton:GetWidth())
      self.AddInput:SetWidth(self.AddInput.WidthChecker:GetUnboundedStringWidth() + 40)
      self:Resize()
    else
      self.AddInput.WidthChecker:SetText(self.AddInput:GetText())
      self.AddInput.WidthChecker:SetWidth(self.AddInput.WidthChecker:GetUnboundedStringWidth())
      self.AddInput:SetWidth(self.AddInput.WidthChecker:GetUnboundedStringWidth() + 40)
      self:Resize()
    end

    if not self.AddInput:GetText():match("^%s*$") then
      self.AddContextMenu:GenerateMenu()
    end
  end)
  self.AddInput:SetHeight(22)

  self.AddContextMenu = CreateFrame("DropdownButton", nil, self)
  self.AddContextMenu:SetAllPoints(self.AddButton)
  self.AddContextMenu:SetFrameStrata("LOW")
  self.AddContextMenu:SetupMenu(function(_, rootDescription)
    if self.index == nil then
      return
    end
    local insertIndex = CopyTable(self.index)
    table.insert(insertIndex, #self.component.value + 1)

    if self.AddInput:GetText():match("^%s*$") then
      rootDescription:CreateTitle(SYNDICATOR_L_INSERT)
      GetOperatorMenu(rootDescription, insertIndex, self.callbackRegistry, "Insert")
      rootDescription:CreateDivider()
      GetKeywordMenu(rootDescription, insertIndex, self.callbackRegistry, "Insert")
      rootDescription:CreateDivider()
      local button = rootDescription:CreateButton(SYNDICATOR_L_PASTE, function()
        self.callbackRegistry:TriggerEvent("Paste", insertIndex)
      end)
    else
      local matches = GetMatches(self.AddInput:GetText())
      for _, match in ipairs(matches) do
        rootDescription:CreateButton(match, function()
          ApplyAddInput(match, insertIndex)
        end)
      end
      if #matches == 0 then
        rootDescription:CreateTitle(RED_FONT_COLOR:WrapTextInColorCode(SYNDICATOR_L_NO_MATCHING_KEYWORDS))
      end
    end
  end)
  self.AddContextMenu:RegisterCallback("OnMenuClose", function()
    if not self.AddInput:IsVisible() then
      return
    end
    self.component.isAdding = enterPressed and self.AddInput:GetText() ~= "" and self.component.subType ~= OperatorType.Not
    ApplyAddInput(self.AddInput:GetText())
  end)
  self.skinned = false

  self.termPool = CreateObjectPool(function(pool)
    local ab = GetTermButton(self)
    return ab
  end, FramePool_HideAndClearAnchors or Pool_HideAndClearAnchors)

  self.operatorPool = CreateObjectPool(function(pool)
    local ab = GetOperatorButton(self)
    return ab
  end, FramePool_HideAndClearAnchors or Pool_HideAndClearAnchors)

  self.commaPool = CreateFontStringPool(self, "ARTWORK", 0, "GameFontNormal")

  self.OperatorText = self:CreateFontString(nil, nil, "GameFontNormal")
  self.OperatorText:SetPoint("TOPLEFT")
  self.OperatorText:SetHeight(22)
  self.OperatorText:SetScript("OnEnter", function()
    self:OnEnter()
  end)
  self.OperatorText:SetScript("OnLeave", function()
    self:OnLeave()
  end)
  self.OperatorText:SetScript("OnMouseUp", function(_, button)
    self:OnClick(button)
  end)

  self.TailText = self:CreateFontString(nil, nil, "GameFontNormal")
  self.TailText:SetPoint("TOPRIGHT")
  self.TailText:SetHeight(22)
  self.TailText:SetText(" )")
end
function OperatorButtonMixin:OnEnter()
  self.HoverTexture:Show()
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  local display = OperatorMap[self.component.subType]
  GameTooltip:SetText(display.tooltip, display.color.r, display.color.g, display.color.b)
  GameTooltip:Show()
end
function OperatorButtonMixin:OnLeave()
  self.HoverTexture:Hide()
  GameTooltip:Hide()
end
function OperatorButtonMixin:Setup(callbackRegistry, component, index)
  local operator, elements = component.subType, component.value
  self.onResizeFunc = function() end
  self.callbackRegistry = callbackRegistry

  if not self.skinned then
    self.skinned = true
    self.callbackRegistry:TriggerEvent("OnSkin", "IconButton", self.AddButton)
  end

  self.HoverTexture:Hide()
  self:SetAlpha(1)

  self.AddButton:Hide()
  self.AddInput:Hide()

  self.component = component
  self.index = index

  local display = OperatorMap[operator]
  self.OperatorText:SetText(display.label .. "( ")
  self.OperatorText:SetTextColor(display.color.r, display.color.g, display.color.b)
  self.TailText:SetTextColor(display.color.r, display.color.g, display.color.b)

  self.regions = {self.OperatorText}

  self.operatorPool:ReleaseAll()
  self.termPool:ReleaseAll()
  self.commaPool:ReleaseAll()

  for i, entry in ipairs(elements) do
    local newIndex = CopyTable(index)
    table.insert(newIndex, i)
    local frame
    if entry.type == RootType.Operator then
      frame = self.operatorPool:Acquire()
    else
      frame = self.termPool:Acquire()
    end
    frame:Show()
    frame:Setup(self.callbackRegistry, entry, newIndex, display.color)

    frame:SetPoint("TOPLEFT", self.regions[#self.regions], "TOPRIGHT")

    frame.onResizeFunc = function()
      self:Resize()
    end

    table.insert(self.regions, frame)

    if i ~= #elements then
      local comma = self.commaPool:Acquire()
      comma:SetText(", ")
      comma:SetHeight(22)
      comma:SetPoint("TOPLEFT", self.regions[#self.regions], "TOPRIGHT")
      comma:SetTextColor(display.color.r, display.color.g, display.color.b)
      comma:Show()

      table.insert(self.regions, comma)
    end
  end

  if self.callbackRegistry.enabled and (operator ~= OperatorType.Not or #elements == 0) then
    if #elements > 0 then
      local comma = self.commaPool:Acquire()
      comma:SetText(", ")
      comma:SetHeight(22)
      comma:SetPoint("TOPLEFT", self.regions[#self.regions], "TOPRIGHT")
      comma:SetTextColor(display.color.r, display.color.g, display.color.b)
      comma:Show()
      table.insert(self.regions, comma)
    end

    self.AddInput:SetPoint("TOPLEFT", self.regions[#self.regions], "TOPRIGHT", 0, 0)
    self.AddInput:SetText("")
    self.AddButton:Show()
    self.AddButton:SetPoint("TOPLEFT", self.regions[#self.regions], "TOPRIGHT", 0, 1)
    table.insert(self.regions, self.AddButton)
  end
  table.insert(self.regions, self.TailText)

  if component.isAdding then
    self.AddButton:Hide()
    C_Timer.After(0, function()
      self.AddButton:Click()
    end)
  end
  self.component.isAdding = false

  self:Resize()
end

function OperatorButtonMixin:Resize()
  local width = 0
  for _, r in ipairs(self.regions) do
    width = width + r:GetWidth()
  end
  if self.AddInput:IsShown() then
    width = width + self.AddInput.WidthChecker:GetWidth()
    width = width - self.AddButton:GetWidth()
  end
  self:SetWidth(width)

  self.onResizeFunc()
end

function OperatorButtonMixin:OnClick(button)
  if not self.callbackRegistry.enabled then
    return
  end

  if self.OperatorText:IsMouseOver() then
    local index = self.index
    MenuUtil.CreateContextMenu(self, function(_, rootDescription)
      rootDescription:CreateTitle(REPLACE)
      GetOperatorMenu(rootDescription, index, self.callbackRegistry, "Swap")
      rootDescription:CreateDivider()
      local wrapButton = rootDescription:CreateButton(SYNDICATOR_L_WRAP_WITH)
      GetOperatorMenu(wrapButton, index, self.callbackRegistry, "Wrap")
      if self.component.value[1] and (#index > 0 or self.component.value[1].type == RootType.Operator) then
        rootDescription:CreateDivider()
        rootDescription:CreateButton(SYNDICATOR_L_UNWRAP, function() self.callbackRegistry:TriggerEvent("Unwrap", self.component, index) end)
      end
      rootDescription:CreateDivider()
      local button = rootDescription:CreateButton(SYNDICATOR_L_COPY, function()
        self.callbackRegistry:TriggerEvent("Copy", self.component)
      end)
      local button = rootDescription:CreateButton(SYNDICATOR_L_CUT, function()
        self.callbackRegistry:TriggerEvent("Copy", self.component)
        self.callbackRegistry:TriggerEvent("Delete", index)
      end)
      local deleteButton = rootDescription:CreateButton(DELETE, function()
        self.callbackRegistry:TriggerEvent("Delete", index)
      end)
      deleteButton:SetOnEnter(function()
        self:SetAlpha(0.4)
      end)
      deleteButton:SetOnLeave(function()
        self:SetAlpha(1)
      end)
    end)
  end
end

local function CombineForOutput(joiner, elements)
  local result = ""
  for index, entry in ipairs(elements) do
    if entry.type == RootType.Term then
      if entry.subType == TermType.Custom then
        result = result .. entry.value
      else
        result = result .. "#" .. entry.value
      end
    else
      if entry.subType == OperatorType.Any then
        if joiner == "&" or joiner == "!" or entry.brackets then
          result = result .. "(" .. CombineForOutput("|", entry.value) .. ")"
        else
          result = result .. CombineForOutput("|", entry.value)
        end
      elseif entry.subType == OperatorType.All then
        if joiner == "!" or entry.brackets then
          result = result .. "(" .. CombineForOutput("&", entry.value) .. ")"
        else
          result = result .. CombineForOutput("&", entry.value)
        end
      elseif entry.subType == OperatorType.Not then
        result = result .. "!" .. CombineForOutput("!", entry.value)
      end
    end

    if index ~= #elements then
      result = result .. joiner
    end
  end

  return result
end

function Syndicator.Search.GetSearchBuilder(parent)
  if not groups then
    groups = GetKeywordGroups()
  end
  local frame = CreateFrame("Frame", nil, parent)
  frame.enabled = true
  Mixin(frame, CallbackRegistryMixin)
  local cb = frame
  cb:OnLoad()
  cb:GenerateCallbackEvents({
    "Insert", "Swap", "Delete", "Wrap", "Unwrap", "Copy", "Paste", "OnChange", "OnResize", "OnSkin",
  })

  local root = CreateAndInitFromMixin(ComponentMixin, RootType.Operator, OperatorType.Any, {})
  local clipboard = CopyTable(root)

  function frame:SetText(rawText)
    root = ProcessTerms(rawText)
    cb:TriggerEvent("OnChange")
  end

  function frame:GetText()
    return CombineForOutput("", {root})
  end

  function frame:Disable()
    frame.enabled = false
    cb:TriggerEvent("OnChange")
  end

  function frame:SetEnabled(state)
    frame.enabled = not not state
    cb:TriggerEvent("OnChange")
  end

  function frame:Enable()
    frame.enabled = true
    cb:TriggerEvent("OnChange")
  end

  local rootFrame = GetOperatorButton(frame)
  rootFrame:SetPoint("LEFT")

  cb:RegisterCallback("OnChange", function()
    rootFrame:Setup(cb, root, {})
    frame:SetSize(rootFrame:GetSize())
    rootFrame.onResizeFunc = function()
      frame:SetSize(rootFrame:GetSize())
      cb:TriggerEvent("OnResize")
    end
    rootFrame:onResizeFunc()
  end)

  cb:RegisterCallback("Insert", function(_, component, index)
    local place = root
    if #index > 1 then
      for j = 1, #index - 1 do
        place = place.value[index[j]]
      end
    end
    component.isAdding = true
    table.insert(place.value, index[#index], component)
    cb:TriggerEvent("OnChange")
  end)

  cb:RegisterCallback("Delete", function(_, index)
    if #index == 0 then
      root = CreateAndInitFromMixin(ComponentMixin, RootType.Operator, OperatorType.Any, {})
    else
      local place = root
      if #index > 1 then
        for j = 1, #index - 1 do
          place = place.value[index[j]]
        end
      end
      table.remove(place.value, index[#index])
    end
    cb:TriggerEvent("OnChange")
  end)

  cb:RegisterCallback("Swap", function(_, component, index)
    if #index == 0 then
      assert(component.type == RootType.Operator)
      root.subType = component.subType
      if component.subType == OperatorType.Not then
        root.value = {root.value[1]}
      end
      cb:TriggerEvent("OnChange")
      return
    end

    local place = root
    if #index > 1 then
      for j = 1, #index - 1 do
        place = place.value[index[j]]
      end
    end
    local target = place.value[index[#index]]
    if target.type == RootType.Operator and component.type == RootType.Operator then
      target.subType = component.subType
      if component.subType == OperatorType.Not then
        target.value = {target.value[1]}
      end
    else
      place.value[index[#index]] = component
    end
    cb:TriggerEvent("OnChange")
  end)

  cb:RegisterCallback("Wrap", function(_, component, index)
    assert(component.type == RootType.Operator)
    if #index == 0 then
      component.value = {root}
      root = component

      cb:TriggerEvent("OnChange")
      return
    end

    local place = root
    if #index > 1 then
      for j = 1, #index - 1 do
        place = place.value[index[j]]
      end
    end
    component.value = {place.value[index[#index]]}
    place.value[index[#index]] = component

    cb:TriggerEvent("OnChange")
  end)

  cb:RegisterCallback("Unwrap", function(_, component, index)
    if #index == 0 then
      root = component.value[1]
      cb:TriggerEvent("OnChange")
      return
    end

    local place = root
    if #index > 1 then
      for j = 1, #index - 1 do
        place = place.value[index[j]]
      end
    end
    if place.subType ~= OperatorType.Not then
      table.remove(place.value, index[#index])
      for i = 1, #component.value do
        table.insert(place.value, index[#index] + i - 1, component.value[i])
      end
    else
      place.value[index[#index]] = component.value[1]
    end
    cb:TriggerEvent("OnChange")
  end)

  cb:RegisterCallback("Copy", function(_, component)
    clipboard = CopyTable(component)
  end)

  cb:RegisterCallback("Paste", function(_, index)
    local component = CopyTable(clipboard)
    cb:TriggerEvent("Insert", component, index)
  end)

  return frame
end
