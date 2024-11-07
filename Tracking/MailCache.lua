SyndicatorMailCacheMixin = {}

local PENDING_OUTGOING_EVENTS = {
  "MAIL_SEND_SUCCESS",
  "MAIL_FAILED",
  "MAIL_SUCCESS",
}

local PENDING_NEW_MAIL_OUTGOING_EVENTS = {
  "MAIL_SEND_SUCCESS",
  "MAIL_FAILED",
}

-- Convert an attachment to a battle pet link as by default only the cage item
-- is supplied on the attachment link, missing all the battle pet stats (retail
-- only)
local function ExtractBattlePetLink(mailIndex, attachmentIndex, itemLink, quality)
  local tooltipInfo = C_TooltipInfo.GetInboxItem(mailIndex, attachmentIndex)
  return Syndicator.Utilities.RecoverBattlePetLink(tooltipInfo, itemLink, quality)
end

local function DoAttachment(attachments, mailIndex, attachmentIndex)
  local _, itemID, texture, count, quality, canUse = GetInboxItem(mailIndex, attachmentIndex)
  if itemID == nil then
    return
  end
  local itemLink = GetInboxItemLink(mailIndex, attachmentIndex)
  if itemID == Syndicator.Constants.BattlePetCageID then
    itemLink, quality = ExtractBattlePetLink(mailIndex, attachmentIndex, itemLink, quality)
  end
  table.insert(attachments, {
    itemID = itemID,
    itemCount = count,
    iconTexture = texture,
    itemLink = itemLink,
    quality = quality,
  })
end

-- Assumed to run after PLAYER_LOGIN
function SyndicatorMailCacheMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, {
    "MAIL_INBOX_UPDATE",
  })

  self.currentCharacter = Syndicator.Utilities.GetCharacterFullName()

  -- Track outgoing mail to alts
  hooksecurefunc("SendMail", function(recipient, subject, body)
    if not recipient:find("-", nil, true) then
      recipient = recipient .. "-" .. GetNormalizedRealmName()
    end

    local mail = {
      recipient = recipient,
      items = {},
    }

    if not SYNDICATOR_DATA.Characters[mail.recipient] then
      return
    end

    for index = 1, ATTACHMENTS_MAX_SEND do
      local itemLink = GetSendMailItemLink(index)
      if itemLink ~= nil then
        local _, itemID, iconTexture, itemCount, quality = GetSendMailItem(index)
        table.insert(mail.items, {
          itemLink = itemLink,
          itemID = itemID,
          iconTexture = iconTexture,
          itemCount = itemCount,
          quality = quality,
        })
      end
    end

    if #mail.items == 0 then
      return
    end

    self.pendingOutgoingMail = mail
    FrameUtil.RegisterFrameForEvents(self, PENDING_NEW_MAIL_OUTGOING_EVENTS)
  end)

  hooksecurefunc("ReturnInboxItem", function(mailIndex)
    local recipient = select(3, GetInboxHeaderInfo(mailIndex))

    if type(recipient) ~= "string" then -- Hooked function called mistakenly
      return
    end

    if not recipient:find("-", nil, true) then
      recipient = recipient .. "-" .. GetNormalizedRealmName()
    end

    local mail = {
      recipient = recipient,
      items = {},
    }

    if not SYNDICATOR_DATA.Characters[mail.recipient] then
      return
    end

    local function OnComplete()
      self.pendingOutgoingMail = mail
      self:RegisterEvent("MAIL_SUCCESS")
    end

    local waiting = 0
    local loopComplete = false
    for attachmentIndex = 1, ATTACHMENTS_MAX do
      local _, itemID = GetInboxItem(mailIndex, attachmentIndex)
      if itemID ~= nil then
        if C_Item.IsItemDataCachedByID(itemID) then
          DoAttachment(mail.items, mailIndex, attachmentIndex)
        else
          waiting = waiting + 1
          Syndicator.Utilities.LoadItemData(itemID, function()
            DoAttachment(mail.items, mailIndex, attachmentIndex)
            waiting = waiting - 1
            if loopComplete and waiting == 0 then
              OnComplete()
            end
          end)
        end
      end
    end

    loopComplete = true
    if waiting == 0 then
      OnComplete()
    end
  end)
end

function SyndicatorMailCacheMixin:OnEvent(eventName, ...)
  if eventName == "MAIL_INBOX_UPDATE" then
    self:SetScript("OnUpdate", self.ScanMail)
  -- Sending to an another character failed
  elseif eventName == "MAIL_FAILED" then
    FrameUtil.UnregisterFrameForEvents(self, PENDING_OUTGOING_EVENTS)
    self.pendingOutgoingMail = nil
  -- Sending to an another character was successful.
  -- MAIL_SUCCESS is for returned mail, MAIL_SEND_SUCCESS is for new mails.
  elseif eventName == "MAIL_SEND_SUCCESS" or eventName == "MAIL_SUCCESS" then
    local characterData = SYNDICATOR_DATA.Characters[self.pendingOutgoingMail.recipient]
    characterData.mail = characterData.mail or {}
    for _, item in ipairs(self.pendingOutgoingMail.items) do
      table.insert(characterData.mail, item)
    end
    Syndicator.CallbackRegistry:TriggerEvent("MailCacheUpdate", self.pendingOutgoingMail.recipient)

    FrameUtil.UnregisterFrameForEvents(self, PENDING_OUTGOING_EVENTS)
    self.pendingOutgoingMail = nil
  end
end

-- General mailbox scan
function SyndicatorMailCacheMixin:ScanMail()
  self:SetScript("OnUpdate", nil)

  local start = debugprofilestop()

  local function FireMailChange(attachments)
    if Syndicator.Config.Get(Syndicator.Config.Options.DEBUG_TIMERS) then
      print("mail finish", debugprofilestop() - start)
    end
    SYNDICATOR_DATA.Characters[self.currentCharacter].mail = attachments
    Syndicator.CallbackRegistry:TriggerEvent("MailCacheUpdate", self.currentCharacter)
  end

  local attachments = {}

  local waiting = 0
  local loopsComplete = false
  for mailIndex = 1, (GetInboxNumItems()) do
    for attachmentIndex = 1, ATTACHMENTS_MAX do
      local _, itemID = GetInboxItem(mailIndex, attachmentIndex)
      if itemID ~= nil then
        if C_Item.IsItemDataCachedByID(itemID) then
          DoAttachment(attachments, mailIndex, attachmentIndex)
        else
          waiting = waiting + 1
          Syndicator.Utilities.LoadItemData(itemID, function()
            DoAttachment(attachments, mailIndex, attachmentIndex)
            waiting = waiting - 1
            if loopsComplete and waiting == 0 then
              FireMailChange(attachments)
            end
          end)
        end
      end
    end
  end
  loopsComplete = true
  if waiting == 0 then
    FireMailChange(attachments)
  end
end
