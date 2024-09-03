SyndicatorVoidCacheMixin = {}

local VOID_STORAGE_EVENTS = {
  "VOID_TRANSFER_DONE",
  "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
}
local VOID_STORAGE_PAGES = 2
local VOID_STORAGE_MAX = 80

-- Assumed to run after PLAYER_LOGIN
function SyndicatorVoidCacheMixin:OnLoad()
  if CanUseVoidStorage == nil then
    return
  end

  FrameUtil.RegisterFrameForEvents(self, VOID_STORAGE_EVENTS)

  self.currentCharacter = Syndicator.Utilities.GetCharacterFullName()
end

function SyndicatorVoidCacheMixin:OnEvent(eventName, ...)
  if CanUseVoidStorage() and C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.VoidStorageBanker) then
    self:ScanVoidStorage()
  end
end

function SyndicatorVoidCacheMixin:ScanVoidStorage()
  local start = debugprofilestop()

  local void = {}

  local function FireVoidChange()
    if Syndicator.Config.Get(Syndicator.Config.Options.DEBUG_TIMERS) then
      print("void took", debugprofilestop() - start)
    end
    Syndicator.CallbackRegistry:TriggerEvent("VoidCacheUpdate", self.currentCharacter)
  end

  local function DoSlot(page, slot)
    local itemID, iconTexture, _, _, _, quality = GetVoidItemInfo(page, slot)
    if itemID == nil then
      return
    end
    local itemLink = GetVoidItemHyperlinkString((page - 1) * VOID_STORAGE_MAX + slot)

    void[page][slot] = {
      itemID = itemID,
      iconTexture = iconTexture,
      itemCount = 1,
      itemLink = itemLink,
      quality = quality,
    }
  end

  local waiting = 0
  local loopsFinished = false
  for page = 1, VOID_STORAGE_PAGES do
    void[page] = {}
    for slot = 1, VOID_STORAGE_MAX do
      void[page][slot] = {}
      local itemID, iconTexture, _, _, _, quality = GetVoidItemInfo(page, slot)
      if itemID ~= nil then
        if C_Item.IsItemDataCachedByID(itemID) then
          DoSlot(page, slot)
        else
          Syndicator.Utilities.LoadItemData(itemID, function()
            DoSlot(page, slot)

            if loopsFinished and waiting == 0 then
              FireVoidChange()
            end
          end)
        end
      end
    end
  end
  loopsFinished = true

  if waiting == 0 then
    FireVoidChange()
  end

  SYNDICATOR_DATA.Characters[self.currentCharacter].void = void
end
