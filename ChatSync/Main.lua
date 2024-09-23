local package = {}

function Syndicator.ChatSync.Initialize()
  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate", function(_, character, updatedBags)
  end)
end
