local function AddItemCheck()
  return Syndicator.Config.Get(Syndicator.Config.Options.SHOW_INVENTORY_TOOLTIPS) and (not Syndicator.Config.Get(Syndicator.Config.Options.SHOW_TOOLTIPS_ON_SHIFT) or IsShiftKeyDown()) 
end

local function AddToItemTooltip(tooltip, summaries, itemLink)
  Syndicator.Tooltips.AddItemLines(tooltip, summaries, itemLink)
end

local function AddCurrencyCheck()
  return Syndicator.Config.Get(Syndicator.Config.Options.SHOW_CURRENCY_TOOLTIPS) and (not Syndicator.Config.Get(Syndicator.Config.Options.SHOW_TOOLTIPS_ON_SHIFT) or IsShiftKeyDown())
end

local function AddToCurrencyTooltip(tooltip, currencyID)
  Syndicator.Tooltips.AddCurrencyLines(tooltip, currencyID)
end

local function InitializeSavedVariables()
  if BAGANATOR_DATA ~= nil and SYNDICATOR_DATA == nil then
    SYNDICATOR_DATA = BAGANATOR_DATA
  end
  if SYNDICATOR_DATA == nil then
    SYNDICATOR_DATA = {
      Version = 1,
      Characters = {},
      Guilds = {},
    }
  end
  SYNDICATOR_DATA.Warband = SYNDICATOR_DATA.Warband or { { bank = {}, money = 0 } }
  if SYNDICATOR_DATA.Warband.bank then
    SYNDICATOR_DATA.Warband = { { bank = SYNDICATOR_DATA.Warband.bank } }
  end
  SYNDICATOR_DATA.Warband[1].money = SYNDICATOR_DATA.Warband[1].money or 0
end

local currentCharacter
local function InitCurrentCharacter()
  currentCharacter = Syndicator.Utilities.GetCharacterFullName()

  if SYNDICATOR_DATA.Characters[currentCharacter] == nil or SYNDICATOR_DATA.Characters[currentCharacter].details.realmNormalized == nil then
    SYNDICATOR_DATA.Characters[currentCharacter] = {
      bags = {},
      bank = {},
      money = 0,
      details = {
        realmNormalized = GetNormalizedRealmName(),
        realm = GetRealmName(),
        character = UnitName("player"),
        hidden = false,
      }
    }
  end

  local characterData = SYNDICATOR_DATA.Characters[currentCharacter]
  characterData.details.className, characterData.details.class = select(2, UnitClass("player"))
  characterData.details.faction = UnitFactionGroup("player")
  characterData.details.race = select(2, UnitRace("player"))
  characterData.details.sex = UnitSex("player")
  characterData.mail = characterData.mail or {}
  characterData.equipped = characterData.equipped or {}
  characterData.containerInfo = characterData.containerInfo or {}
  characterData.currencies = characterData.currencies or {}
  characterData.currencyByHeader = characterData.currencyByHeader or {}
  characterData.void = characterData.void or {}
  characterData.auctions = characterData.auctions or {}
end

local function SetupCacheMixin(mixin, key)
  xpcall(function()
    local cache = CreateFrame("Frame")
    Mixin(cache, mixin)
    cache:OnLoad()
    cache:SetScript("OnEvent", cache.OnEvent)
    Syndicator[key] = cache
  end, CallErrorHandler)
end

local function SetupDataProcessing()
  Syndicator.Utilities.CacheConnectedRealms()

  SetupCacheMixin(SyndicatorBagCacheMixin, "BagCache")

  SetupCacheMixin(SyndicatorMailCacheMixin, "MailCache")

  SetupCacheMixin(SyndicatorEquippedCacheMixin, "EquippedCache")

  SetupCacheMixin(SyndicatorCurrencyCacheMixin, "CurrencyCache")

  SetupCacheMixin(SyndicatorVoidCacheMixin, "VoidCache")

  SetupCacheMixin(SyndicatorGuildCacheMixin, "GuildCache")

  SetupCacheMixin(SyndicatorAuctionCacheMixin, "AuctionCache")
end

local function SetupItemSummaries()
  local summaries = CreateFrame("Frame")
  Mixin(summaries, SyndicatorItemSummariesMixin)
  summaries:OnLoad()
  Syndicator.ItemSummaries = summaries
end

local function SetupTooltips()
  if TooltipDataProcessor and C_TooltipInfo then
    local function ValidateTooltip(tooltip)
      return tooltip == GameTooltip or tooltip == GameTooltipTooltip or tooltip == ItemRefTooltip or tooltip == GarrisonShipyardMapMissionTooltipTooltip or (not tooltip:IsForbidden() and (tooltip:GetName() or ""):match("^NotGameTooltip"))
    end

    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
      if ValidateTooltip(tooltip) and Syndicator.ItemSummaries then
        local itemName, itemLink = TooltipUtil.GetDisplayedItem(tooltip)

        -- Fix to get recipes to show the inventory data for the recipe when
        -- tooltip shown via a hyperlink
        local info = tooltip.processingInfo
        if info and info.getterName == "GetHyperlink" then
          local _, newItemLink = C_Item.GetItemInfo(info.getterArgs[1])
          if newItemLink ~= nil then
            itemLink = newItemLink
          end
        -- Auction house
        elseif info and info.getterName == "GetItemKey" then
          local itemID = info.getterArgs[1]
          local _, newItemLink = C_Item.GetItemInfo(itemID)
          if newItemLink ~= nil and itemID ~= C_Item.GetItemInfoInstant(itemLink) then
            itemLink = newItemLink
          end
        elseif info and info.getterName == "GetGuildBankItem" then
          local newItemLink = GetGuildBankItemLink(info.getterArgs[1], info.getterArgs[2])
          if newItemLink ~= nil then
            itemLink = newItemLink
          end
        end

        if itemLink and AddItemCheck() then
          AddToItemTooltip(tooltip, Syndicator.ItemSummaries, itemLink)
        end
      end
    end)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency, function(tooltip, data)
      if ValidateTooltip(tooltip) and Syndicator.ItemSummaries then
        local data = tooltip:GetPrimaryTooltipData()
        if AddCurrencyCheck() then
          AddToCurrencyTooltip(tooltip, data.id)
        end
      end
    end)
  else
    local function SetItemTooltipHandler(tooltip)
      local ready = true
      tooltip:HookScript("OnTooltipSetItem", function(tooltip)
        if not ready or not Syndicator.ItemSummaries then
          return
        end
        local _, itemLink = tooltip:GetItem()
        if AddItemCheck() then
          AddToItemTooltip(tooltip, Syndicator.ItemSummaries, itemLink)
        end
        ready = false
      end)
      tooltip:HookScript("OnTooltipCleared", function(tooltip)
        ready = true
      end)
    end
    SetItemTooltipHandler(GameTooltip)
    SetItemTooltipHandler(ItemRefTooltip)
    local function CurrencyTooltipHandler(tooltip, index)
      local link = C_CurrencyInfo.GetCurrencyListLink(index)
      if link ~= nil then
        local currencyID = tonumber((link:match("|Hcurrency:(%d+)")))
        if currencyID ~= nil and AddCurrencyCheck() then
          AddToCurrencyTooltip(tooltip, currencyID)
        end
      end
    end
    hooksecurefunc(GameTooltip, "SetCurrencyToken", CurrencyTooltipHandler)
    hooksecurefunc(ItemRefTooltip, "SetCurrencyToken", CurrencyTooltipHandler)
    if GameTooltip.SetCurrencyByID then
      hooksecurefunc(GameTooltip, "SetCurrencyByID", AddToCurrencyTooltip)
    end
    if ItemRefTooltip.SetCurrencyByID then -- Doesn't currently exist on classic
      hooksecurefunc(ItemRefTooltip, "SetCurrencyByID", AddToCurrencyTooltip)
    end
    -- Fix enchant crafting reagent tooltips on Era/SoD
    if GameTooltip.SetCraftItem then
      hooksecurefunc(GameTooltip, "SetCraftItem", function(_, recipeIndex, reagentIndex)
        if AddItemCheck() then
          AddToItemTooltip(GameTooltip, Syndicator.ItemSummaries, GetCraftReagentItemLink(recipeIndex, reagentIndex))
        end
      end)
    end
  end

  if BattlePetToolTip_Show then
    local function PetTooltipShow(tooltip, speciesID, level, breedQuality, maxHealth, power, speed, ...)
      if not AddItemCheck() or not Syndicator.ItemSummaries then
        return
      end
      -- Reconstitute item link from tooltip arguments
      local name, icon, petType = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
      local itemString = "battlepet"
      for _, part in ipairs({speciesID, level, breedQuality, maxHealth, power, speed}) do
        itemString = itemString .. ":" .. part
      end

      local quality = ITEM_QUALITY_COLORS[breedQuality].color
      local itemLink = quality:WrapTextInColorCode("|H" .. itemString .. "|h[" .. name .. "]|h")

      AddToItemTooltip(tooltip, Syndicator.ItemSummaries, itemLink)
    end
    hooksecurefunc("BattlePetToolTip_Show", function(...)
      PetTooltipShow(BattlePetTooltip, ...)
    end)
    hooksecurefunc("FloatingBattlePet_Toggle", function(...)
      if FloatingBattlePetTooltip:IsShown() then
        PetTooltipShow(FloatingBattlePetTooltip, ...)
      end
    end)
  end
end

function Syndicator.Tracking.Initialize()
  local frame = CreateFrame("Frame")
  -- We initialize everything at PLAYER_LOGIN for 2 reasons
  -- 1. Character normalized realm name is only available at this point
  -- 2. To ensure data from Baganator is imported
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", function()
    frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    C_Timer.After(0, function()
      InitializeSavedVariables()
      InitCurrentCharacter()
      SetupDataProcessing()
      SetupItemSummaries()

      Syndicator.CallbackRegistry:TriggerEvent("Ready")
      Syndicator.Tracking.isReady = true
    end)
  end)

  Syndicator.CallbackRegistry:RegisterCallback("CharacterDeleted", function(_, name)
    if name == currentCharacter then
      InitCurrentCharacter()
    end
  end)

  Syndicator.CallbackRegistry:RegisterCallback("GuildNameSet", function(_, guild)
    SYNDICATOR_DATA.Characters[Syndicator.BagCache.currentCharacter].details.guild = guild
  end)

  xpcall(SetupTooltips, CallErrorHandler)
end
