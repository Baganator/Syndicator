function Syndicator.Search.GetSearchEverywhereInterface(parent, skinner)
  local frame = CreateFrame("Frame", nil, parent, "ButtonFrameTemplate")
  Mixin(frame, CallbackRegistryMixin)
  local cb = frame
  cb:OnLoad()
  cb:GenerateCallbackEvents({
    "OnSkin",
  })
  if skinner then
    cb:RegisterCallback("OnSkin", skinner)
  end

  ButtonFrameTemplate_HidePortrait(frame)
  ButtonFrameTemplate_HideButtonBar(frame)
  frame.Inset:Hide()
  frame:RegisterForDrag("LeftButton")
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetUserPlaced(false)
  frame:SetSize(400, 700)

  frame:SetScript("OnDragStart", function(self)
    self:StartMoving()
    self:SetUserPlaced(false)
  end)

  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self:SetUserPlaced(false)
  end)

  cb:TriggerEvent("OnSkin", "ButtonFrame", frame, {"searchEverywhere"})

  return frame
end
