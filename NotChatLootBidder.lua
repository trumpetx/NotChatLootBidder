local NotChatLootBidder = NotChatLootBidder_Frame
local gfind = string.gmatch or string.gfind
local addonName = "NotChatLootBidder"
local addonTitle = GetAddOnMetadata(addonName, "Title")
local addonNotes = GetAddOnMetadata(addonName, "Notes")
local addonVersion = GetAddOnMetadata(addonName, "Version")
local addonAuthor = GetAddOnMetadata(addonName, "Author")
local me = UnitName("player")
local myClass, myCLASS = UnitClass("player")
local myRace, _ = UnitRace("player")
local chatPrefix = "<BID> "
local frameId = 0
local maxFrames = 8
local needFrames = {}
local itemRegex = "|c.-|H.-|h|r"
local useable = {
  ["Priest"] = { "One-Handed Maces", "Staves", "Daggers", "Wands" },
  ["Mage"] = { "One-Handed Swords", "Staves", "Daggers", "Wands" },
  ["Warlock"] = { "One-Handed Swords", "Staves", "Daggers", "Wands" },
  ["Rogue"] = { "Leather", "Daggers", "One-Handed Swords", "One-Handed Maces", "Fist Weapons", "Bows", "Crossbows", "Guns", "Thrown", "Arrow", "Bullet" },
  ["Druid"] = { "Leather", "One-Handed Maces", "Two-Handed Maces", "Polearms", "Staves", "Daggers", "Fist Weapons", "Idols" },
  ["Hunter"] = { "Leather", "Mail",  "One-Handed Axes", "Two-Handed Axes", "One-Handed Swords", "Two-Handed Swords", "Polearms", "Staves", "Daggers", "Fist Weapons", "Bows", "Crossbows", "Guns", "Arrow", "Bullet" },
  ["Shaman"] = { "Leather", "Mail", "One-Handed Axes", "Two-Handed Axes", "One-Handed Maces", "Two-Handed Maces", "Staves", "Daggers", "Fist Weapons", "Shields", "Totems" },
  ["Warrior"] = { "Leather", "Mail", "Plate", "One-Handed Axes", "Two-Handed Axes", "One-Handed Swords", "Two-Handed Swords", "One-Handed Maces", "Two-Handed Maces", "Polearms", "Staves", "Daggers", "Fist Weapons", "Shields", "Bows", "Crossbows", "Guns", "Thrown", "Arrow", "Bullet" },
  ["Paladin"] = { "Leather", "Mail", "Plate", "One-Handed Axes", "Two-Handed Axes", "One-Handed Swords", "Two-Handed Swords", "One-Handed Maces", "Two-Handed Maces", "Polearms", "Shields", "Librams" },
  ["All"] = { "Trade Goods", "Junk", "Bag", "Miscellaneous", "Quest", "Consumable", "Cloth" }
}
-- convert useable arrays into sets
for k, v in pairs(useable) do
  local v2k = {}
  for _, v2 in pairs(v) do v2k[v2] = true end
  useable[k] = v2k
end
local noHealing = { ["Hunter"]=true, ["Warrior"]=true, ["Rogue"]=true, ["Mage"]=true, ["Warlock"]=true }
local noDamageOrHealing = { ["Hunter"]=true, ["Warrior"]=true, ["Rogue"]=true }
local noSpells = { ["Warrior"]=true, ["Rogue"]=true }
local noMelee = { ["Mage"]=true, ["Warlock"]=true, ["Priest"]=true }

local function IsTableEmpty(table)
  local next = next
  return next(table) == nil
end

local function Trim(str)
  local _start, _end, _match = string.find(str or "", '^%s*(.-)%s*$')
  return _match or ""
end

local function PrependSpaceIfContent(str)
  if (not str) or string.len(str) == 0 then
    return ""
  else
    return " " .. str
  end
end

local function Error(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff" .. chatPrefix .. "|cffff0000 "..message)
end

local function Message(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff".. chatPrefix .."|r "..message)
end

local function Debug(message)
  if NotChatLootBidder_Store.Debug then Message(message) end
end

local function LoadVariables()
  NotChatLootBidder_Store = NotChatLootBidder_Store or {}
  NotChatLootBidder_Store.Version = addonVersion
  NotChatLootBidder_Store.IgnoredItems = NotChatLootBidder_Store.IgnoredItems or {}
  NotChatLootBidder_Store.AutoIgnore = NotChatLootBidder_Store.AutoIgnore == true
  NotChatLootBidder_Store.Debug = NotChatLootBidder_Store.Debug == true
  NotChatLootBidder_Store.UIScale = NotChatLootBidder_Store.UIScale or 1
  NotChatLootBidder_Store.Messages = NotChatLootBidder_Store.Messages or {}
  NotChatLootBidder_Store.Alt = NotChatLootBidder_Store.Alt or {}
  NotChatLootBidder_Store.Messages[me] = Trim(NotChatLootBidder_Store.Messages[me])
  for _,i in pairs({"alt;","alt-","alt"}) do
    local len = string.len(i)
    if string.lower(string.sub(NotChatLootBidder_Store.Messages[me], 1, len)) == i then
      NotChatLootBidder:SetAlt(true)
      NotChatLootBidder_Store.Messages[me] = Trim(string.sub(NotChatLootBidder_Store.Messages[me], len + 1))
      return
    end
  end
end

local function ShowHelp()
  Message("/bid  - Open the placement frame")
  Message("/bid [item-link] [item-link2]  - Open test bid frames")
  Message("/bid scale [50-150]  - Set the UI scale percentage")
  Message("/bid autoignore  - Toggle 'auto-ignore' mode to ignore items your class cannot use")
  Message("/bid message  - Set a default message (per character)")
  Message("/bid ignore  - List all ignored items")
  Message("/bid ignore clear  - Clear the ignore list completely")
  Message("/bid ignore [item-link] [item-link2]  - Toggle 'Ignore' for loot windows of these item(s)")
  Message("/bid clear  - Clear all bid frames")
	Message("/bid info  - Show information about the add-on")
end

local function ShowInfo()
  Message("UI Scale is set to " .. NotChatLootBidder_Store.UIScale * 100 .. "%")
	Message(addonNotes .. " for bugs and suggestions")
	Message("Written by " .. addonAuthor)
end

local function NextFrameId()
  frameId = frameId + 1
  if frameId > maxFrames then frameId = 1 end
  return frameId
end

local function ResetFrameStack()
  local frameHeight = 0
  for _, frame in pairs(needFrames) do
    frame:SetPoint("TOP", NotChatLootBidder, "TOP", 0, frameHeight)
    frameHeight = frameHeight - 128
    frame:SetScale(NotChatLootBidder_Store.UIScale * UIParent:GetScale())
  end
end

local function ClearFrames(fadeTime, masterLooter)
  for _, f in pairs(needFrames) do
    local frame = f
    -- Don't let someone else hijack the frames
    if masterLooter == nil or frame.masterLooter == masterLooter then
      local fadeInfo = {};
      fadeInfo.mode = "OUT";
      fadeInfo.timeToFade = fadeTime;
      fadeInfo.startAlpha = 1;
      fadeInfo.endAlpha = 0;
      fadeInfo.finishedFunc = function() frame:Hide() end;
      UIFrameFade(frame, fadeInfo);
    end
  end
end

local function CreateBidFrame(bidFrameId)
  local bidFrameName = "BidFrame" .. bidFrameId
  local frame = CreateFrame("Frame", bidFrameName, NotChatLootBidder, "BidFrameTemplate")
  for _, t in {"MS", "OS", "ROLL"} do
    local tier = t
    getglobal(bidFrameName .. tier .."Button"):SetScript("OnClick", function()
      local f = this:GetParent()
      local amt = getglobal(f:GetName() .. "Bid"):GetText()
      if tier == "ROLL" or frame.mode ~= "DKP" then
        amt = ""
      else
        amt = tonumber(amt)
        if amt == nil then return end
        if amt < frame.minimumBid then return end
        amt = " " .. amt
      end
      local note = Trim(getglobal(f:GetName() .. "Note"):GetText())
      note = PrependSpaceIfContent(note)
      if NotChatLootBidder_Store.Alt[me] then
        if string.len(note) == 0 then
          note = " ALT"
        else
          note = " ALT; " .. note
        end
      end
      ChatThrottleLib:SendChatMessage("ALERT", addonName, f.itemLink .. " " .. tier .. amt .. note, "WHISPER", nil, f.masterLooter)
      frame:Hide()
    end)
  end
  getglobal(bidFrameName .. "Alt"):SetChecked(NotChatLootBidder:GetAlt())
  frame:SetScript("OnHide", function()
    needFrames[bidFrameId] = nil
    frame:ClearAllPoints()
    ResetFrameStack()
  end)
  return frame
end

local function IsAlliance()
  return myRace == "Gnome" or myRace == "Dwarf" or myRace == "Human" or myRace == "Night Elf" or myRace == "High Elf"
end

local function FilterOutType(t)
  if noDamageOrHealing[myClass] and string.find(t, "Increases damage and healing") then
    return true
  end
  if noHealing[myClass] and string.find(t, "Increases healing") then
    return true
  end
  if noSpells[myClass] and (string.find(t, "mana per 5") or string.find(t, "with spells")) then
    return true
  end
  if noMelee[myClass] and (string.find(t, "Agility") or string.find(t, "Strength") or string.find(t, "get a critical strike by") or string.find(t, "Atack Power") or string.find(t, "chance to hit by")) then
    return true
  end
end

local function UseableItem(itemLinkInfo, itemSubType, itemName)
  -- Onyxia/Nefarian heads for Twow
  if itemName ~= nil and string.find(itemName, "(Alliance)") then
    return IsAlliance()
  elseif itemName ~= nil and string.find(itemName, "(Horde)") then
    return not IsAlliance()
  end
  if itemLinkInfo then -- some items like mounts may not have linkInfo provided by the client
    BidFrameInfoTooltip:ClearLines()
    BidFrameInfoTooltip:SetOwner(NotChatLootBidder, "NONE", 0, 0)
    BidFrameInfoTooltip:SetHyperlink(itemLinkInfo)
    BidFrameInfoTooltip:Show()
    for i=1, BidFrameInfoTooltip:NumLines() do
      local text = getglobal("BidFrameInfoTooltipTextLeft"..i):GetText()
      local _, _, match = string.find(text, "Classes: (.+)")
      -- If classes are set on the item, it is definitive
      if match then
        BidFrameInfoTooltip:Hide()
        return string.find(match, myClass)
      end
      if FilterOutType(text) then
        BidFrameInfoTooltip:Hide()
        return false
      end
    end
    BidFrameInfoTooltip:Hide()
  end
  if itemSubType == nil or itemSubType == "" or useable["All"][itemSubType] == true then
    return true
  end
  -- print("Checking item sub type: " .. itemSubType)
  return useable[myClass][itemSubType] == true
end

local function LoadBidFrame(item, masterLooter, minimumBid, mode)
  local _, _ , itemKey = string.find(item, "(item:%d+:%d+:%d+:%d+)")
  local itemName, itemLinkInfo, itemRarity, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemKey)
  if itemLinkInfo == nil then
    -- This is a potentially unsafe operation and may cause disconnects according to API documentation
    -- No disconnects noticed in testing on twow's client
    itemLinkInfo = itemKey
  end
  if NotChatLootBidder_Store.AutoIgnore and not UseableItem(itemLinkInfo, itemSubType, itemName) then
    Debug("Ignoring " .. itemName)
    return
  end
  local bidFrameId = NextFrameId()
  local frame = getglobal("BidFrame" .. bidFrameId) or CreateBidFrame(bidFrameId)
  if frame:IsVisible() then Error("More than " .. maxFrames .. " bid frames loaded.  Overwriting " .. frame.itemLink .. " (" .. bidFrameId .. ")") end
  frame.itemLink = item
  frame.itemLinkInfo = itemLinkInfo
  frame.masterLooter = masterLooter
  frame.minimumBid = minimumBid or 1
  frame.mode = mode or "DKP"
  needFrames[bidFrameId] = frame
  getglobal(frame:GetName() .. "ItemIconItemName"):SetText(item)
  getglobal(frame:GetName() .. "ItemIcon"):SetNormalTexture(itemTexture or "Interface\\Icons\\Inv_misc_questionmark")
  getglobal(frame:GetName() .. "ItemIcon"):SetPushedTexture(itemTexture or "Interface\\Icons\\Inv_misc_questionmark")
  getglobal(frame:GetName() .. "Note"):SetText(NotChatLootBidder_Store.Messages[me] or "")
  local bidBox = getglobal(frame:GetName() .. "Bid")
  bidBox:SetText("")
  if frame.mode == "DKP" then
    bidBox:Show()
  else
    bidBox:Hide()
  end
  ResetFrameStack()
  UIFrameFadeIn(frame, .5, 0, 1)
end

local function GetItemLinks(str, start)
  local itemLinks = {}
  local _start, _end = nil, -1
  while true do
    _start, _end = string.find(str, itemRegex, _end + 1)
    if _start == nil then
      return itemLinks
    end
    table.insert(itemLinks, string.sub(str, _start, _end))
  end
end

local function ListIgnored(message)
  if IsTableEmpty(NotChatLootBidder_Store.IgnoredItems) then
    Message("No items are ignored")
    return
  end
  Message("The following items are ignored:")
  for item,_ in pairs(NotChatLootBidder_Store.IgnoredItems) do
    Message(item)
  end
end

local function ToggleIgnore(message)
  local ignoredItems = NotChatLootBidder_Store.IgnoredItems
  for _, item in GetItemLinks(message) do
    if ignoredItems[item] then
      ignoredItems[item] = nil
      Message(item .. " is no longer ignored")
    else
      ignoredItems[item] = true
      Message(item .. " is now ignored")
    end
  end
end

local function TogglePlacementFrame()
  local placementFrame = getglobal("NotChatLootBidder_FramePlacement")
  if placementFrame:IsVisible() then
    placementFrame:Hide()
  else
    placementFrame:SetScale(NotChatLootBidder_Store.UIScale * UIParent:GetScale())
    placementFrame:Show()
  end
end

local function SetMessage(message)
  if message == "" then
    Message("Default message has been unset")
    NotChatLootBidder_Store.Messages[me] = nil
  else
    Message("Default message is set to: " .. message)
    NotChatLootBidder_Store.Messages[me] = message
  end
end

local function InitSlashCommands()
	SLASH_NotChatLootBidder1 = "/bid"
	SlashCmdList[addonName] = function(message)
		local commandlist = { }
		local command
		for command in gfind(message, "[^ ]+") do
			table.insert(commandlist, command)
		end
    if commandlist[1] == nil then
      TogglePlacementFrame()
    elseif commandlist[1] == "help" then
			ShowHelp()
    elseif commandlist[1] == "info" then
			ShowInfo()
    elseif commandlist[1] == "clear" then
      ClearFrames(.2)
    elseif commandlist[1] == "autoignore" then
      NotChatLootBidder_Store.AutoIgnore = not NotChatLootBidder_Store.AutoIgnore
      Message("Auto-ignore mode is " .. (NotChatLootBidder_Store.AutoIgnore and "enabled" or "disabled"))
    elseif commandlist[1] == "message" then
			SetMessage(string.sub(message, 8))
    elseif commandlist[1] == "alt" then
      NotChatLootBidder:SetAlt(not NotChatLootBidder_Store.Alt[me])
    elseif commandlist[1] == "ignore" then
      if commandlist[2] == "clear" then
        NotChatLootBidder_Store.IgnoredItems = {}
        Message("The ignore list has been cleared!")
      elseif commandlist[2] ~= nil then
        ToggleIgnore(message)
      else
        ListIgnored()
      end
    elseif commandlist[1] == "scale" then
      local scale = tonumber(commandlist[2] or "")
      if scale ~= nil and scale >= 50 and scale <= 150 then scale = scale / 100 end -- convert whole numbers into decimal %
      if scale == nil or scale > 1.5 or scale < .5 then
        Error("Invalid scale value.  Use a number between 50 and 150.")
      else
        NotChatLootBidder_Store.UIScale = scale
        NotChatLootBidder.UI_SCALE_CHANGED()
      end
    else
      for _, i in GetItemLinks(message) do
        if NotChatLootBidder_Store.IgnoredItems[i] == nil then
          LoadBidFrame(i, me)
        end
      end
    end
  end
end

function NotChatLootBidder:GetAlt()
  return NotChatLootBidder_Store.Alt[me] == true
end

function NotChatLootBidder:SetAlt(isAlt)
  NotChatLootBidder_Store.Alt[me] = isAlt
  Message("Setting \"alt\" flag " .. (isAlt and "on" or "off"))
end

function NotChatLootBidder.ADDON_LOADED(loadedAddonName)
  if loadedAddonName == addonName then
    LoadVariables()
    InitSlashCommands()
    DEFAULT_CHAT_FRAME:AddMessage("Loaded " .. addonTitle .. " by " .. addonAuthor .. " v." .. addonVersion)
    this:UnregisterEvent("ADDON_LOADED")
  end
end

function NotChatLootBidder.PARTY_MEMBERS_CHANGED()
  VersionUtil:PARTY_MEMBERS_CHANGED(addonName)
end

function NotChatLootBidder.CHAT_MSG_ADDON(addonTag, stringMessage, channel, sender)
  if VersionUtil:CHAT_MSG_ADDON(addonName, function(ver)
    Message("New version " .. ver .. " of " .. addonTitle .. " is available! Upgrade now at " .. addonNotes)
  end) then return end

  if addonTag == addonName then
    local incomingMessage = VersionUtil:ParseMessage(stringMessage)
    if incomingMessage["items"] then
      local minimumBid = incomingMessage["minimumBid"] -- optional: defaults to 1
      local mode = incomingMessage["mode"] -- defaults to "DKP"
      for _, i in GetItemLinks(string.gsub(incomingMessage["items"], "~~~", ",")) do
        LoadBidFrame(i, sender, minimumBid, mode)
      end
    elseif incomingMessage["endSession"] then
      ClearFrames(2, sender)
    end
  end
end

function NotChatLootBidder.PLAYER_ENTERING_WORLD()
  VersionUtil:PLAYER_ENTERING_WORLD(addonName)
  if NotChatLootBidder_Store.Point and getn(NotChatLootBidder_Store.Point) == 4 then
    NotChatLootBidder:SetPoint(NotChatLootBidder_Store.Point[1], "UIParent", NotChatLootBidder_Store.Point[2], NotChatLootBidder_Store.Point[3], NotChatLootBidder_Store.Point[4])
  else
    TogglePlacementFrame()
  end
  this:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function NotChatLootBidder.PLAYER_LEAVING_WORLD()
  local point, _, relativePoint, xOfs, yOfs = NotChatLootBidder:GetPoint()
  NotChatLootBidder_Store.Point = {point, relativePoint, xOfs, yOfs}
end

function NotChatLootBidder.UI_SCALE_CHANGED()
  TogglePlacementFrame()
  TogglePlacementFrame()
  ResetFrameStack()
end
