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
end

function SyndicatorCurrencyCacheMixin:OnEvent(eventName, ...)
  if eventName == "CURRENCY_DISPLAY_UPDATE" then
    -- We do not use the quantity argument in the event as it is wrong for
    -- Conquest currency changes
    local currencyID = ...
    if currencyID ~= nil then
      local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
      SYNDICATOR_DATA.Characters[self.currentCharacter].currencies[currencyID] = info.quantity

      self:SetScript("OnUpdate", self.OnUpdate)
    else
      self:ScanAllCurrencies()
    end
  elseif eventName == "PLAYER_MONEY" then
    SYNDICATOR_DATA.Characters[self.currentCharacter].money = GetMoney()
    Syndicator.CallbackRegistry:TriggerEvent("CurrencyCacheUpdate", self.currentCharacter)
  elseif eventName == "ACCOUNT_MONEY" or eventName == "BANKFRAME_OPENED" then
    SYNDICATOR_DATA.Warband[1].money = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
    Syndicator.CallbackRegistry:TriggerEvent("WarbandCurrencyCacheUpdate", 1)
  end
end

function SyndicatorCurrencyCacheMixin:ScanAllCurrencies()
  local currencies = {}

  if Syndicator.Constants.IsRetail then
    local index = 0
    local toCollapse = {}
    while index < C_CurrencyInfo.GetCurrencyListSize() do
      index = index + 1
      local info = C_CurrencyInfo.GetCurrencyListInfo(index)
      if info.isHeader then
        if not info.isHeaderExpanded then
          table.insert(toCollapse, index)
          C_CurrencyInfo.ExpandCurrencyList(index, true)
        end
      else
        local link = C_CurrencyInfo.GetCurrencyListLink(index)
        if link ~= nil then
          local currencyID = C_CurrencyInfo.GetCurrencyIDFromLink(link)
          currencies[currencyID] = info.quantity
        end
      end
    end

    if #toCollapse > 0 then
      for index = #toCollapse, 1 do
        C_CurrencyInfo.ExpandCurrencyList(toCollapse[index], false)
      end
    end
  else -- Only versions of classic with currency (due to checks earlier)
    local index = 0
    local toCollapse = {}
    while index < GetCurrencyListSize() do
      index = index + 1
      local _, isHeader, isHeaderExpanded, _, _, quantity = GetCurrencyListInfo(index)
      if isHeader then
        if not isHeaderExpanded then
          table.insert(toCollapse, index)
          ExpandCurrencyList(index, 1)
        end
      else
        local link = C_CurrencyInfo.GetCurrencyListLink(index)
        if link ~= nil then
          local currencyID = tonumber((link:match("|Hcurrency:(%d+)")))
          if currencyID ~= nil then
            currencies[currencyID] = quantity
          end
        end
      end
    end

    if #toCollapse > 0 then
      for index = #toCollapse, 1 do
        ExpandCurrencyList(toCollapse[index], 0)
      end
    end
  end

  SYNDICATOR_DATA.Characters[self.currentCharacter].currencies = currencies

  self:SetScript("OnUpdate", self.OnUpdate)
end

-- Event is fired in OnUpdate to avoid multiple events per-frame
function SyndicatorCurrencyCacheMixin:OnUpdate()
  self:SetScript("OnUpdate", nil)

  Syndicator.CallbackRegistry:TriggerEvent("CurrencyCacheUpdate", self.currentCharacter)
end
