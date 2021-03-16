local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent)
end
addon = _G[ADDON_NAME]

addon.configFrame = CreateFrame("frame", ADDON_NAME.."_config_eventFrame",UIParent)
local configFrame = addon.configFrame

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

local lastObject
local function addConfigEntry(objEntry, adjustX, adjustY)
	
	objEntry:ClearAllPoints()
	
	if not lastObject then
		objEntry:SetPoint("TOPLEFT", 20, -150)
	else
		objEntry:SetPoint("LEFT", lastObject, "BOTTOMLEFT", adjustX or 0, adjustY or -30)
	end
	
	lastObject = objEntry
end

local chkBoxIndex = 0
local function createCheckbutton(parentFrame, displayText)
	chkBoxIndex = chkBoxIndex + 1
	
	local checkbutton = CreateFrame("CheckButton", ADDON_NAME.."_config_chkbtn_" .. chkBoxIndex, parentFrame, "ChatConfigCheckButtonTemplate")
	getglobal(checkbutton:GetName() .. 'Text'):SetText(" "..displayText)
	
	return checkbutton
end

local buttonIndex = 0
local function createButton(parentFrame, displayText)
	buttonIndex = buttonIndex + 1
	
	local button = CreateFrame("Button", ADDON_NAME.."_config_button_" .. buttonIndex, parentFrame, "UIPanelButtonTemplate")
	button:SetText(displayText)
	button:SetHeight(30)
	button:SetWidth(button:GetTextWidth() + 30)

	return button
end

local sliderIndex = 0
local function createSlider(parentFrame, displayText, minVal, maxVal)
	sliderIndex = sliderIndex + 1
	
	local SliderBackdrop  = {
		bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
		edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
		tile = true, tileSize = 8, edgeSize = 8,
		insets = { left = 3, right = 3, top = 6, bottom = 6 }
	}
	
	local slider = CreateFrame("Slider", ADDON_NAME.."_config_slider_" .. sliderIndex, parentFrame)
	slider:SetOrientation("HORIZONTAL")
	slider:SetHeight(15)
	slider:SetWidth(300)
	slider:SetHitRectInsets(0, 0, -10, 0)
	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	slider:SetMinMaxValues(minVal or 0, maxVal or 100)
	slider:SetValue(0)
	slider:SetBackdrop(SliderBackdrop)

	local label = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("CENTER", slider, "CENTER", 0, 16)
	label:SetJustifyH("CENTER")
	label:SetHeight(15)
	label:SetText(displayText)

	local lowtext = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	lowtext:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 2, 3)
	lowtext:SetText(minVal)

	local hightext = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	hightext:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", -2, 3)
	hightext:SetText(maxVal)
	
	local currVal = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	currVal:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 45, 12)
	currVal:SetText('(?)')
	slider.currVal = currVal
	
	return slider
end

local colorPickerIndex = 0
local function createColorPicker(parentFrame, dbObj, objName, displayText)
	colorPickerIndex = colorPickerIndex + 1
	
	local function ToRGBA(hex)
		return tonumber('0x' .. string.sub(hex, 3, 4), 10) / 255,
			tonumber('0x' .. string.sub(hex, 5, 6), 10) / 255,
			tonumber('0x' .. string.sub(hex, 7, 8), 10) / 255,
			tonumber('0x' .. string.sub(hex, 1, 2), 10) / 255
	end
	local function ToHex(r, g, b, a)
		return string.format('%02X%02X%02X%02X', a * 255, r * 255, g * 255, b * 255)
	end

	local function Update(self, value)
		local r, g, b, a
		if(type(value) == 'table' and r.GetRGB) then
			r, g, b, a = value:GetRGBA()
		else
			r, g, b, a = ToRGBA(value)
		end

		self.Swatch:SetVertexColor(r, g, b, a)
	
		--save values
		--r, g, b, a, value
		--value is hex
		dbObj[objName] = value
	end
	
	local Button = CreateFrame('Button', ADDON_NAME.."_config_colorpicker_" .. colorPickerIndex, parentFrame)
	Button:SetSize(25, 25)
	Button:SetScript('OnClick', function(self)
		local r, g, b, a = ToRGBA(dbObj[objName])
		ColorPickerFrame:SetColorRGB(r or 1, g or 1, b or 1)
		ColorPickerFrame.opacity = 1
		ColorPickerFrame.hasOpacity = false
		ColorPickerFrame.func = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			local a = 1
			Update(self, ToHex(r, g, b, a))
		end

		ColorPickerFrame.opacityFunc = ColorPickerFrame.func
		ColorPickerFrame.cancelFunc = function()
			Update(self, ToHex(r, g, b, a))
		end
		ShowUIPanel(ColorPickerFrame)
	end)

	local Swatch = Button:CreateTexture(nil, 'OVERLAY')
	Swatch:SetPoint('CENTER')
	Swatch:SetSize(24, 24)
	Swatch:SetTexture([[Interface\ChatFrame\ChatFrameColorSwatch]])
	Button.Swatch = Swatch

	local text = parentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	text:SetPoint("LEFT", Swatch, "RIGHT", 5, 0)
	text:SetText(displayText)
	
	--update to initial color stored
	Update(Button, dbObj[objName])

	return Button
end

local function LoadAboutFrame()

	--Code inspired from tekKonfigAboutPanel
	local about = CreateFrame("Frame", ADDON_NAME.."AboutPanel", InterfaceOptionsFramePanelContainer)
	about.name = ADDON_NAME
	about:Hide()
	
    local fields = {"Version", "Author"}
	local notes = GetAddOnMetadata(ADDON_NAME, "Notes")

    local title = about:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")

	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(ADDON_NAME)

	local subtitle = about:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(32)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", about, -32, 0)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(notes)

	local anchor
	for _,field in pairs(fields) do
		local val = GetAddOnMetadata(ADDON_NAME, field)
		if val then
			local title = about:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			title:SetWidth(75)
			if not anchor then title:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", -2, -8)
			else title:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6) end
			title:SetJustifyH("RIGHT")
			title:SetText(field:gsub("X%-", ""))

			local detail = about:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			detail:SetPoint("LEFT", title, "RIGHT", 4, 0)
			detail:SetPoint("RIGHT", -16, 0)
			detail:SetJustifyH("LEFT")
			detail:SetText(val)

			anchor = title
		end
	end
	
	InterfaceOptions_AddCategory(about)

	return about
end

function configFrame:EnableConfig()
	
	addon.aboutPanel = LoadAboutFrame()

	--color swatch
	local btnColorPicker = createColorPicker(addon.aboutPanel, XFM_DB, "color", "Change undiscovered flight path icon color.")
	addConfigEntry(btnColorPicker, 0, -20)
	addon.aboutPanel.btnColorPicker = btnColorPicker
end
