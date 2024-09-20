SyndicatorCurrencyCacheMixin = {}

-- Assumed to run after PLAYER_LOGIN
function SyndicatorCurrencyCacheMixin:OnLoad()
  self:RegisterEvent("PLAYER_MONEY")

  if Syndicator.Constants.WarbandBankActive then
    self:RegisterEvent("ACCOUNT_MONEY")
    self:RegisterEvent("BANKFRAME_OPENED")
  end

  self.currentCharacter = Syndicator.Utilities.GetCharacterFullName()

  SYNDICATOR_DATA.Characters[self.currentCharacter].money = GetMoney()

  if C_CurrencyInfo then
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:ScanAllCurrencies()
  end
  if Syndicator.Constants.IsRetail then
    self:RegisterEvent("CURRENCY_TRANSFER_FAILED")
    hooksecurefunc(C_CurrencyInfo, "RequestCurrencyFromAccountCharacter", function(sourceGUID, currencyID, amount)
      if type(sourceGUID) ~= "string" then
        return
      end

      local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
      if not info then
        return
      end

      local possibilities = C_CurrencyInfo.FetchCurrencyDataFromAccountCharacters(currencyID)
      for _, option in ipairs(possibilities) do
        if option.characterGUID == sourceGUID then
          self:RegisterEvent("CURRENCY_TRANSFER_LOG_UPDATE")

          self.pendingTransfer = {
            sourceCharacter = option.fullCharacterName,
            currencyID = currencyID,
            quantity = math.ceil(amount * (100 / info.transferPercentage)),
          }
        end
      end
    end)
  end
end

function SyndicatorCurrencyCacheMixin:OnEvent(eventName, ...)
  if eventName == "CURRENCY_DISPLAY_UPDATE" then
    -- We do not use the quantity argument in the event as it is wrong for
    -- Conquest currency changes
    local currencyID = ...
    if currencyID ~= nil then
      if SYNDICATOR_DATA.Characters[self.currentCharacter].currencies[currencyID] == nil then
        self:ScanAllCurrencies() -- used to get header information
      else
        local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
        SYNDICATOR_DATA.Characters[self.currentCharacter].currencies[currencyID] = info.quantity
        self:SetScript("OnUpdate", self.OnUpdate)
      end
    elseif not self.scannedLate then
      self.scannedLate = true
      self:ScanAllCurrencies()
    end
  elseif eventName == "PLAYER_MONEY" then
    SYNDICATOR_DATA.Characters[self.currentCharacter].money = GetMoney()
    Syndicator.CallbackRegistry:TriggerEvent("CurrencyCacheUpdate", self.currentCharacter)
  elseif eventName == "ACCOUNT_MONEY" or eventName == "BANKFRAME_OPENED" then
    SYNDICATOR_DATA.Warband[1].money = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
    Syndicator.CallbackRegistry:TriggerEvent("WarbandCurrencyCacheUpdate", 1)
  elseif eventName == "CURRENCY_TRANSFER_LOG_UPDATE" then
    local sourceCharacter = self.pendingTransfer.sourceCharacter
    if SYNDICATOR_DATA.Characters[sourceCharacter] then
      local oldValue = SYNDICATOR_DATA.Characters[sourceCharacter].currencies[self.pendingTransfer.currencyID]
      if oldValue ~= nil then
        SYNDICATOR_DATA.Characters[sourceCharacter].currencies[self.pendingTransfer.currencyID] = oldValue - self.pendingTransfer.quantity

        self:SetScript("OnUpdate", self.OnUpdate)
      end
    end
    self:UnregisterEvent("CURRENCY_TRANSFER_LOG_UPDATE")
  elseif eventName == "CURRENCY_TRANSFER_FAILED" then
    self.pendingTransfer = nil
    self:UnregisterEvent("CURRENCY_TRANSFER_LOG_UPDATE")
  end
end

function SyndicatorCurrencyCacheMixin:ScanAllCurrencies()
  local currencies = {}
  local currencyByHeader = { { name = UNKNOWN, currencies = {} } }

  if Syndicator.Constants.IsRetail then
    local index = 0
    local toCollapse = {}
    while index < C_CurrencyInfo.GetCurrencyListSize() do
      index = index + 1
      local info = C_CurrencyInfo.GetCurrencyListInfo(index)
      if info.isHeader then
        table.insert(currencyByHeader, {
          header = info.name,
          currencies = {},
        })
        if not info.isHeaderExpanded then
          table.insert(toCollapse, index)
          C_CurrencyInfo.ExpandCurrencyList(index, true)
        end
      else
        local link = C_CurrencyInfo.GetCurrencyListLink(index)
        if link ~= nil then
          local currencyID = C_CurrencyInfo.GetCurrencyIDFromLink(link)
          currencies[currencyID] = info.quantity
          table.insert(currencyByHeader[#currencyByHeader].currencies, currencyID)
        end
      end
    end

    if #toCollapse > 0 then
      for index = #toCollapse, 1, -1 do
        C_CurrencyInfo.ExpandCurrencyList(toCollapse[index], false)
      end
    end
  else -- Only versions of classic with currency (due to checks earlier)
    local index = 0
    local toCollapse = {}
    while index < GetCurrencyListSize() do
      index = index + 1
      local name, isHeader, isHeaderExpanded, _, _, quantity = GetCurrencyListInfo(index)
      if isHeader then
        table.insert(currencyByHeader, {
          header = name,
          currencies = {},
        })
        if not isHeaderExpanded then
          table.insert(toCollapse, index)
          ExpandCurrencyList(index, 1)
        end
      else
        local link = C_CurrencyInfo.GetCurrencyListLink(index)
        if link ~= nil then
          local currencyID = tonumber((link:match("|Hcurrency:(%d+)")))
          currencies[currencyID] = quantity
          table.insert(currencyByHeader[#currencyByHeader].currencies, currencyID)
        end
      end
    end

    if #toCollapse > 0 then
      for index = #toCollapse, 1, -1 do
        ExpandCurrencyList(toCollapse[index], 0)
      end
    end
  end

  SYNDICATOR_DATA.Characters[self.currentCharacter].currencies = currencies
  SYNDICATOR_DATA.Characters[self.currentCharacter].currencyByHeader = currencyByHeader

  self:SetScript("OnUpdate", self.OnUpdate)
end

-- Event is fired in OnUpdate to avoid multiple events per-frame
function SyndicatorCurrencyCacheMixin:OnUpdate()
  self:SetScript("OnUpdate", nil)

  Syndicator.CallbackRegistry:TriggerEvent("CurrencyCacheUpdate", self.currentCharacter)
end
