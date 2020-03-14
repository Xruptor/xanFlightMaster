local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent)
end
addon = _G[ADDON_NAME]

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local Tourist = LibStub("LibTourist-3.0")

addon:SetScript("OnEvent", function(self, event, ...) 
	if self[event] then 
		return self[event](self, event, ...)
	end 
end)

local debugf = tekDebug and tekDebug:GetFrame(ADDON_NAME)
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

----------------------
--      Enable      --
----------------------

function addon:PLAYER_LOGIN()

	--do DB stuff
	if not XFM_DB then XFM_DB = {} end
	if not XFM_DB.color then XFM_DB.color = "FF58FF00" end  --a teal sort of color
	--FF4BFFC5 --a teal sort of color
	--FF58FF00  nice fel green
	--FFFF0030  deep red, works too
	
	addon:RegisterEvent("TAXIMAP_OPENED")
	addon:RegisterEvent("TAXIMAP_CLOSED")
	 
	local ver = GetAddOnMetadata(ADDON_NAME,"Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFF20ff20%s|r] loaded", ADDON_NAME, ver or "1.0"))
	
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

local function GetNodeID(mapID, slot)
	local taximapNodes = C_TaxiMap.GetAllTaxiNodes(mapID)
	for _, taxiNodeData in ipairs(taximapNodes) do
		if (slot == taxiNodeData.slotIndex) then
			return taxiNodeData.nodeID
		end
	end
end

local function GetFaction(mapID, nodeID)
	--GetTaxiNodesForMap has faction info, GetAllTaxiNodes does not
	local taxiNodes = C_TaxiMap.GetTaxiNodesForMap(mapID)
	for _, taxiNodeData in ipairs(taxiNodes) do
		if (nodeID == taxiNodeData.nodeID) then
			return taxiNodeData.faction
		end
	end
end

local function ShouldShowTaxiNode(factionGroup, faction)
	--sometimes faction returns nil, we need to check that
	if faction == nil then return false end
	
	if faction == Enum.FlightPathFaction.Horde then
		return factionGroup == "Horde"
	end

	if faction == Enum.FlightPathFaction.Alliance then
		return factionGroup == "Alliance"
	end
	
	return true
end

local function ToRGBA(hex)
	return tonumber('0x' .. string.sub(hex, 3, 4), 10) / 255,
		tonumber('0x' .. string.sub(hex, 5, 6), 10) / 255,
		tonumber('0x' .. string.sub(hex, 7, 8), 10) / 255,
		tonumber('0x' .. string.sub(hex, 1, 2), 10) / 255
end
local function ToHex(r, g, b, a)
	return string.format('%02X%02X%02X%02X', a * 255, r * 255, g * 255, b * 255)
end
	
function addon:TAXIMAP_OPENED(event, taxiFrameID)
	
	local isTaxiMap = taxiFrameID == Enum.UIMapSystem.Taxi
	local numNodes = NumTaxiNodes()
	local mapID = GetTaxiMapID()
	
	--Debug("NumTaxiNodes", numNodes)
	--Debug("GetTaxiMapID", mapID)
	
	for i = 1, numNodes do
		local taxiType = TaxiNodeGetType(i)
		local taxiName = TaxiNodeName(i)
			
		--local x,y = TaxiNodePosition(1);
		
		--should return number of your current flightmaster slotindex
		--local srcSlot = TaxiGetNodeSlot(i, 1, true)
		--local dstSlot = TaxiGetNodeSlot(index, i, false)
		
		local nodeID = GetNodeID(mapID, i)
		
		--Debug("-   Node:".. i, taxiType, taxiName, nodeID)
		
		--local index = button:GetID();
		
		--https://github.com/Gethe/wow-ui-source/blob/2ca215b373e6107bdc7f1e2715fc0c2ec4720a14/FrameXML/TaxiFrame.lua
		--sX = taxiNodePositions[srcSlot].x;
		--sY = taxiNodePositions[srcSlot].y;
		--local dstSlot = TaxiGetNodeSlot(i, 1, false);
		
	end
	
	--Debug("   +++++++", isTaxiMap)
	--TEST_NodeList = {}
	
	if isTaxiMap then
		if not TaxiFrame.unknownFPList then TaxiFrame.unknownFPList = {} end
		for i = 1, #TaxiFrame.unknownFPList do
			--hide all our markers first
			TaxiFrame.unknownFPList[i]:Hide()
		end
		
		for i = 1, numNodes do
			local pin = _G["TaxiButton"..i]
			
			if pin and pin:IsVisible() then
				local x, y = TaxiNodePosition(pin:GetID())
				--Debug("-   TF_Button:".. i, pin:GetID(), x, y)
			end
		end
		
	elseif FlightMapFrame then
		if not FlightMapFrame.unknownFPList then FlightMapFrame.unknownFPList = {} end
		for i = 1, #FlightMapFrame.unknownFPList do
			--hide all our markers first
			if FlightMapFrame.unknownFPList[i] then
				FlightMapFrame.unknownFPList[i]:Hide()
			end
		end
		

		-- function MapCanvasMixin:SetGlobalPinScale(scale)
			-- if self.globalPinScale ~= scale then
				-- self.globalPinScale = scale;
				-- for pin in self:EnumerateAllPins() do
					-- pin:ApplyCurrentScale();
				-- end
			-- end
		-- end

		--OnCanvasScaleChanged()
		
		local pinPool = FlightMapFrame.pinPools.FlightMap_FlightPointPinTemplate
		for flightnode in pinPool:EnumerateActive() do
		
			--table.insert(TEST_NodeList, flightnode)
			local fnSlotIndex = flightnode.taxiNodeData.slotIndex
			local fnNodeID = flightnode.taxiNodeData.nodeID
			local fnName = flightnode.taxiNodeData.name
			local fnFaction = GetFaction(mapID, fnNodeID)
			local fnFlightType = TaxiNodeGetType(fnSlotIndex)
			
			--POOPCRAP = Enum.FlightPathState

			--Debug(fnSlotIndex, fnNodeID,  fnName, flightnode:GetTaxiNodeState(), fnFaction, fnFlightType)
			--local fnX, fnY = flightnode.taxiNodeData.position:GetXY()
			--local effScale = flightnode:GetEffectiveScale()
			
			--Debug("-   FN_Button:".. fnSlotIndex, fnNodeID, fnName, fnX, fnY, flightnode:IsShown())
			
			--if flightnode:IsShown() then
				--local point, relativeTo, relativePoint, xOffset, yOffset = flightnode:GetPoint()

				--Debug(point, relativeTo, relativePoint, fnSlotIndex, xOffset, yOffset)
				--Debug(flightnode:GetParent())
				--Debug(flightnode:GetHeight(), flightnode:GetWidth(), flightnode.Icon:GetHeight(), flightnode.Icon:GetWidth())
				--Debug(flightnode:GetSize())
				--Debug(fnSlotIndex, fnX, fnY, xOffset, yOffset)
				--Debug(flightnode:GetParent():GetHeight(), flightnode:GetParent():GetWidth())
				
				--Debug(flightnode:GetScale(), flightnode:GetEffectiveScale())
				
				
				--local canvas = self:GetCanvas()
				-- local canvas = flightnode:GetParent()
				-- local scale = flightnode:GetScale()
				
				-- local testX = (canvas:GetWidth() * fnX) / scale
				-- local testY = -(canvas:GetHeight() * fnY) / scale
				
				-- Debug(testX, testY)
				--pin:SetPoint("CENTER", canvas, "TOPLEFT", (canvas:GetWidth() * x) / scale, -(canvas:GetHeight() * y) / scale)
			
			--end
			
			

			
			--we aren't showing the flightpath
			if not flightnode:IsShown() then
			
				--if we don't have our pin node to work with then create it
				local parent = flightnode:GetParent()
				local scale = flightnode:GetScale()
				local fnX, fnY = flightnode.taxiNodeData.position:GetXY()
				
				if not FlightMapFrame.unknownFPList[fnSlotIndex] then
					FlightMapFrame.unknownFPList[fnSlotIndex] = CreateFrame('frame', nil, parent)
				end
				
				local iconSize = 20
				
				--to make it easier to reference
				local unknownPin = FlightMapFrame.unknownFPList[fnSlotIndex]
				unknownPin:Hide()
				unknownPin:SetHeight(iconSize + 5)
				unknownPin:SetWidth(iconSize + 5)
				unknownPin:SetScale(scale)
				unknownPin.fnNodeID = fnNodeID
				unknownPin.fnName = fnName
				unknownPin.fnSlotIndex = fnSlotIndex
				unknownPin.fnFaction = fnFaction
				
				local testX = (parent:GetWidth() * fnX) / scale
				local testY = -(parent:GetHeight() * fnY) / scale
				unknownPin:SetPoint("CENTER", parent, "TOPLEFT", testX, testY)
				
				local pinIcon = unknownPin:CreateTexture(nil, "OVERLAY")
				pinIcon:SetTexture("Interface\\AddOns\\xanFlightMaster\\media\\taxi-icon")
				pinIcon:SetSize(iconSize, iconSize)
				pinIcon:SetPoint("TOPLEFT", unknownPin, "TOPLEFT")
				
				local r, g, b, a = ToRGBA(XFM_DB.color)
				
				pinIcon:SetVertexColor(r, g, b, 0.9) --give it a fel green color for optional
				
				unknownPin:SetScript("OnEnter", function()
					GameTooltip:SetOwner(unknownPin, "ANCHOR_PRESERVE")
					GameTooltip:ClearAllPoints()
					GameTooltip:SetPoint("BOTTOMLEFT", unknownPin, "TOPRIGHT", 0, 0)
					GameTooltip:AddLine(fnName, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				unknownPin:SetScript("OnLeave", function() GameTooltip_Hide() end)
				
				
				-- local exclamation = unknownPin:CreateTexture(nil, "OVERLAY")
				-- exclamation:SetTexture("Interface\\AddOns\\xanFlightMaster\\media\\green-exclamation")
				-- exclamation:SetSize(16, 16)
				-- exclamation:SetPoint("CENTER", pinIcon, "CENTER", 0, 17)
				
				
				local factionGroup = UnitFactionGroup("player")
				local showSwitch = ShouldShowTaxiNode(factionGroup, fnFaction)
				
				if showSwitch then
					unknownPin:Show()
				else
					unknownPin:Hide()
				end

			end
			
		end
		
	end


	-- local iconAlert = frame:CreateTexture(nil, "OVERLAY")
	-- iconAlert:SetTexture("Interface\\AddOns\\XanUI\\media\\questicon_1")
	-- iconAlert:SetSize(16, 32)
	-- iconAlert:SetPoint("BOTTOM", f, "TOP")
	-- frame.iconAlert = iconAlert
	
	
	--Debug("@@@@@@@@@@@@@@@@@@@@@@@@")
	
	
	--for slotIndex, pin in pairs(self.slotIndexToPin) do
	
	--TaxiNodeName(index)
	--C_Taximap.MapTaxiNodeInfo
	-- UnitOnTaxi("player")
	
end

if IsLoggedIn() then addon:PLAYER_LOGIN() else addon:RegisterEvent("PLAYER_LOGIN") end
