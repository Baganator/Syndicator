Syndicator.Config = {}

Syndicator.Config.Options = {
  SHOW_CHARACTER_RACE_ICONS = "show_character_race_icons",

  SHOW_INVENTORY_TOOLTIPS = "show_inventory_tooltips",
  SHOW_GUILD_BANKS_IN_TOOLTIPS = "show_guild_banks_in_tooltips",
  SHOW_EQUIPPED_ITEMS_IN_TOOLTIPS = "show_equipped_items_in_tooltips",
  SHOW_CURRENCY_TOOLTIPS = "show_currency_tooltips",
  SHOW_TOOLTIPS_ON_SHIFT = "show_tooltips_on_shift",
  TOOLTIPS_CONNECTED_REALMS_ONLY = "tooltips_connected_realms_only_2",
  TOOLTIPS_FACTION_ONLY = "tooltips_faction_only",
  TOOLTIPS_CHARACTER_LIMIT = "tooltips_character_limit",
  TOOLTIPS_SORT_BY_NAME = "tooltips_sort_by_name",

  DEBUG = "debug",
  DEBUG_TIMERS = "debug_timers",
}

Syndicator.Config.Defaults = {
  [Syndicator.Config.Options.SHOW_INVENTORY_TOOLTIPS] = true,
  [Syndicator.Config.Options.SHOW_GUILD_BANKS_IN_TOOLTIPS] = true,
  [Syndicator.Config.Options.SHOW_EQUIPPED_ITEMS_IN_TOOLTIPS] = true,
  [Syndicator.Config.Options.SHOW_CURRENCY_TOOLTIPS] = true,
  [Syndicator.Config.Options.SHOW_TOOLTIPS_ON_SHIFT] = false,
  [Syndicator.Config.Options.TOOLTIPS_CONNECTED_REALMS_ONLY] = not Syndicator.Constants.IsRetail,
  [Syndicator.Config.Options.TOOLTIPS_SORT_BY_NAME] = false,
  [Syndicator.Config.Options.TOOLTIPS_FACTION_ONLY] = false,
  [Syndicator.Config.Options.TOOLTIPS_CHARACTER_LIMIT] = 4,
  [Syndicator.Config.Options.SHOW_CHARACTER_RACE_ICONS] = true,

  [Syndicator.Config.Options.DEBUG] = false,
  [Syndicator.Config.Options.DEBUG_TIMERS] = false,
}

function Syndicator.Config.IsValidOption(name)
  for _, option in pairs(Syndicator.Config.Options) do
    if option == name then
      return true
    end
  end
  return false
end

function Syndicator.Config.Create(constant, name, defaultValue)
  Syndicator.Config.Options[constant] = name

  Syndicator.Config.Defaults[Syndicator.Config.Options[constant]] = defaultValue

  if SYNDICATOR_CONFIG ~= nil and SYNDICATOR_CONFIG[name] == nil then
    SYNDICATOR_CONFIG[name] = defaultValue
  end
end

function Syndicator.Config.Set(name, value)
  if SYNDICATOR_CONFIG == nil then
    error("JOURNALATOR_CONFIG not initialized")
  elseif not Syndicator.Config.IsValidOption(name) then
    error("Invalid option '" .. name .. "'")
  else
    local oldValue = SYNDICATOR_CONFIG[name]
    SYNDICATOR_CONFIG[name] = value
  end
end

function Syndicator.Config.ResetOne(name)
  local newValue = Syndicator.Config.Defaults[name]
  if type(newValue) == "table" then
    newValue = CopyTable(newValue)
  end
  Syndicator.Config.Set(name, newValue)
end

function Syndicator.Config.Reset()
  SYNDICATOR_CONFIG = {}
  for option, value in pairs(Syndicator.Config.Defaults) do
    SYNDICATOR_CONFIG[option] = value
  end
end

function Syndicator.Config.InitializeData()
  if SYNDICATOR_CONFIG == nil then
    Syndicator.Config.Reset()
  else
    for option, value in pairs(Syndicator.Config.Defaults) do
      if SYNDICATOR_CONFIG[option] == nil then
        SYNDICATOR_CONFIG[option] = value
      end
    end
  end
end

function Syndicator.Config.Get(name)
  -- This is ONLY if a config is asked for before variables are loaded
  if SYNDICATOR_CONFIG == nil then
    return Syndicator.Config.Defaults[name]
  else
    return SYNDICATOR_CONFIG[name]
  end
end
