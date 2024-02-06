local NotChatLootBidder = NotChatLootBidder_Frame
local placementFrame = getglobal("NotChatLootBidder_FramePlacement")
local gfind = string.gmatch or string.gfind
local addonName = "NotChatLootBidder"
local addonTitle = GetAddOnMetadata(addonName, "Title")
local addonNotes = GetAddOnMetadata(addonName, "Notes")
local addonVersion = GetAddOnMetadata(addonName, "Version")
local addonAuthor = GetAddOnMetadata(addonName, "Author")
local me = UnitName("player")
local chatPrefix = "<BID> "
local frameId = 0
local maxFrames = 6
local needFrames = {}
local itemRegex = "|c.-|H.-|h|r"

local function LoadVariables()
  NotChatLootBidder_Store = NotChatLootBidder_Store or {}
  NotChatLootBidder_Store.Version = addonVersion
end

local function Message(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff".. chatPrefix .."|r "..message)
end

local function ShowHelp()
  Message("/bid  - Open the placement frame")
  Message("/bid [item-link] [item-link2] - Open test bid frames")
	Message("/bid info  - Show information about the add-on")
end

local function ShowInfo()
	if NotChatLootBidder_Store.DebugLevel > 0 then Message("Debug Level set to " .. NotChatLootBidder_Store.DebugLevel) end
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
      if tier == "ROLL" then
        amt = ""
      else
        amt = tonumber(amt)
        if amt == nil then return end
        if amt < 1 then return end -- TODO: replace with min bid from ML addon
      end
      local note = string.gsub(getglobal(f:GetName() .. "Note"):GetText(), "^%s*(.-)%s*$", "%1")
      if string.len(note) > 0 then note = " " .. note end
      ChatThrottleLib:SendChatMessage("ALERT", addonName, f.itemLink .. " " .. tier .. " " .. amt .. " " .. note, "WHISPER", nil, f.masterLooter)
      frame:Hide()
    end)
  end
  frame:SetScript("OnHide", function()
    needFrames[bidFrameId] = nil
    frame:ClearAllPoints()
    ResetFrameStack()
  end)
  return frame
end

local function LoadBidFrame(item, masterLooter)
  local _, _ , itemKey = string.find(item, "(item:%d+:%d+:%d+:%d+)")
  local itemName, itemLinkInfo, itemRarity, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemKey)
  local bidFrameId = NextFrameId()
  local frame = getglobal("BidFrame" .. bidFrameId) or CreateBidFrame(bidFrameId)
  frame.itemLink = item
  frame.itemLinkInfo = itemLinkInfo
  frame.masterLooter = masterLooter
  needFrames[bidFrameId] = frame
  getglobal(frame:GetName() .. "ItemIconItemName"):SetText(item)
  getglobal(frame:GetName() .. "ItemIcon"):SetNormalTexture(itemTexture)
  getglobal(frame:GetName() .. "ItemIcon"):SetPushedTexture(itemTexture)
  getglobal(frame:GetName() .. "Note"):SetText("")
  getglobal(frame:GetName() .. "Bid"):SetText("")
  ResetFrameStack()
  frame:Show()
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

local function InitSlashCommands()
	SLASH_NotChatLootBidder1 = "/bid"
	SlashCmdList[addonName] = function(message)
		local commandlist = { }
		local command
		for command in gfind(message, "[^ ]+") do
			table.insert(commandlist, command)
		end
    if commandlist[1] == nil then
      if placementFrame:IsVisible() then placementFrame:Hide() else placementFrame:Show() end
    elseif commandlist[1] == "help" then
			ShowHelp()
    elseif commandlist[1] == "debug" then
      if commandlist[2] then
        local value = tonumber(commandlist[2])
        if value then NotChatLootBidder_Store.DebugLevel = value end
      end
      Message("Debug level set to " .. NotChatLootBidder_Store.DebugLevel)
    else
      for _, i in GetItemLinks(message) do
        LoadBidFrame(i, me)
      end
    end
  end
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

function NotChatLootBidder.CHAT_MSG_ADDON(addonTag, stringMessage)
  if VersionUtil:CHAT_MSG_ADDON(addonName, function(ver)
    Message("New version " .. ver .. " of " .. addonTitle .. " is available! Upgrade now at " .. addonNotes)
  end) then return end

  if addonTag == addonName then
    local incomingMessage = VersionUtil:ParseMessage(stringMessage)
    if incomingMessage["items"] and incomingMessage["sender"] then
      for _, i in GetItemLinks(incomingMessage["items"]) do
        LoadBidFrame(i, incomingMessage["sender"])
      end
    end
  end
end

function NotChatLootBidder.PLAYER_ENTERING_WORLD()
  VersionUtil:PLAYER_ENTERING_WORLD(addonName)
  if NotChatLootBidder_Store.Point and getn(NotChatLootBidder_Store.Point) == 4 then
    NotChatLootBidder:SetPoint(NotChatLootBidder_Store.Point[1], "UIParent", NotChatLootBidder_Store.Point[2], NotChatLootBidder_Store.Point[3], NotChatLootBidder_Store.Point[4])
  else
    placementFrame:Show()
  end
  this:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function NotChatLootBidder.PLAYER_LEAVING_WORLD()
  local point, _, relativePoint, xOfs, yOfs = NotChatLootBidder:GetPoint()
  NotChatLootBidder_Store.Point = {point, relativePoint, xOfs, yOfs}
end
