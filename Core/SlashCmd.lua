Syndicator.SlashCmd = {}

function Syndicator.SlashCmd.Initialize()
  SlashCmdList["Syndicator"] = Syndicator.SlashCmd.Handler
  SLASH_Syndicator1 = "/syndicator"
  SLASH_Syndicator2 = "/syn"
end

local INVALID_OPTION_VALUE = "Wrong config value type %s (required %s)"
function Syndicator.SlashCmd.Config(optionName, value1, ...)
  if optionName == nil then
    Syndicator.Utilities.Message("No config option name supplied")
    for _, name in pairs(Syndicator.Config.Options) do
      Syndicator.Utilities.Message(name .. ": " .. tostring(Syndicator.Config.Get(name)))
    end
    return
  end

  local currentValue = Syndicator.Config.Get(optionName)
  if currentValue == nil then
    Syndicator.Utilities.Message("Unknown config: " .. optionName)
    return
  end

  if value1 == nil then
    Syndicator.Utilities.Message("Config " .. optionName .. ": " .. tostring(currentValue))
    return
  end

  if type(currentValue) == "boolean" then
    if value1 ~= "true" and value1 ~= "false" then
      Syndicator.Utilities.Message(INVALID_OPTION_VALUE:format(type(value1), type(currentValue)))
      return
    end
    Syndicator.Config.Set(optionName, value1 == "true")
  elseif type(currentValue) == "number" then
    if tonumber(value1) == nil then
      Syndicator.Utilities.Message(INVALID_OPTION_VALUE:format(type(value1), type(currentValue)))
      return
    end
    Syndicator.Config.Set(optionName, tonumber(value1))
  elseif type(currentValue) == "string" then
    Syndicator.Config.Set(optionName, strjoin(" ", value1, ...))
  else
    Syndicator.Utilities.Message("Unable to edit option type " .. type(currentValue))
    return
  end
  Syndicator.Utilities.Message("Now set " .. optionName .. ": " .. tostring(Syndicator.Config.Get(optionName)))
end

function Syndicator.SlashCmd.Debug(...)
  Syndicator.Config.Set(Syndicator.Config.Options.DEBUG, not Syndicator.Config.Get(Syndicator.Config.Options.DEBUG))
  if Syndicator.Config.Get(Syndicator.Config.Options.DEBUG) then
    Syndicator.Utilities.Message("Debug mode on")
  else
    Syndicator.Utilities.Message("Debug mode off")
  end
end

function Syndicator.SlashCmd.RemoveCharacter(characterName)
  local success = pcall(Syndicator.API.DeleteCharacter, characterName)

  if not success then
    Syndicator.Utilities.Message("Unrecognised or current character")
  else
    Syndicator.Utilities.Message("Character '" .. characterName .. "' removed.")
  end
end

function Syndicator.SlashCmd.RemoveGuild(...)
  local guildName = strjoin(" ", ...)
  local success = pcall(Syndicator.API.DeleteGuild, guildName)

  if not success then
    Syndicator.Utilities.Message("Unrecognised or current guild")
  else
    Syndicator.Utilities.Message("Guild '" .. guildName .. "' removed.")
  end
end

function Syndicator.SlashCmd.HideCharacter(characterName)
  local success = pcall(Syndicator.API.ToggleCharacterHidden, characterName)
  if not success then
    Syndicator.Utilities.Message("Unrecognised character")
  else
    local characterData = Syndicator.API.GetByCharacterFullName(characterName)
    Syndicator.Utilities.Message("Character '" .. characterName .. "' hidden: " .. tostring(characterData.details.hidden))
  end
end

function Syndicator.SlashCmd.HideGuild(...)
  local guildName = strjoin(" ", ...)
  local success = pcall(Syndicator.API.ToggleGuildHidden, guildName)

  if not success then
    Syndicator.Utilities.Message("Unrecognised guild")
  else
    local guildData = Syndicator.API.GetByGuildFullName(guildName)
    Syndicator.Utilities.Message("Guild '" .. guildName .. "' hidden: " .. tostring(guildData.details.hidden))
  end
end

function Syndicator.SlashCmd.CustomiseUI()
  Syndicator.CallbackRegistry:TriggerEvent("ShowCustomise")
end

local COMMANDS = {
  ["c"] = Syndicator.SlashCmd.Config,
  ["config"] = Syndicator.SlashCmd.Config,
  ["d"] = Syndicator.SlashCmd.Debug,
  ["debug"] = Syndicator.SlashCmd.Debug,
  ["remove"] = Syndicator.SlashCmd.RemoveCharacter,
  ["removecharacter"] = Syndicator.SlashCmd.RemoveCharacter,
  ["removeguild"] = Syndicator.SlashCmd.RemoveGuild,
  ["hide"] = Syndicator.SlashCmd.HideCharacter,
  ["hidecharacter"] = Syndicator.SlashCmd.HideCharacter,
  ["hideguild"] = Syndicator.SlashCmd.HideGuild,
}
function Syndicator.SlashCmd.Handler(input)
  local split = {strsplit("\a", (input:gsub("%s+","\a")))}

  local root = split[1]
  if root == "" then
    Syndicator.Utilities.Message("Command missing")
  elseif COMMANDS[root] ~= nil then
    table.remove(split, 1)
    COMMANDS[root](unpack(split))
  else
    Syndicator.Utilities.Message("Unknown command '" .. root .. "'")
  end
end
