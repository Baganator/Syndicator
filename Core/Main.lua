Syndicator.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
Syndicator.CallbackRegistry:OnLoad()
Syndicator.CallbackRegistry:GenerateCallbackEvents(Syndicator.Constants.Events)

Syndicator.Utilities.OnAddonLoaded("Syndicator", function()
  Syndicator.Config.InitializeData()
  Syndicator.SlashCmd.Initialize()
  Syndicator.Options.Initialize()

  Syndicator.Tracking.Initialize()

  Syndicator.Search.Initialize()
end)
