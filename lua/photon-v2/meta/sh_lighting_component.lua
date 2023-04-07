if (exmeta.ReloadFile("photon-v2/meta/sh_lighting_component.lua")) then return end

NAME = "PhotonLightingComponent"
BASE = "PhotonBaseEntity"

local print = Photon2.Debug.Print
local printf = Photon2.Debug.PrintF

---@class PhotonLightingComponent : PhotonBaseEntity
---@field Lights table<integer, PhotonLight>
---@field Segments table<string, PhotonLightingSegment>
---@field InputPriorities table<string, integer>
---@field CurrentModes table<string, string>
local Component = META

Component.IsPhotonLightingComponent = true

-- [Internal] Compile a Library Component to store in the Index.
---@param data PhotonLibraryComponent
---@return PhotonLightingComponent
function Component.New( data )
	---@type PhotonLightingComponent
	local component = {
		Model = data.Model,
		Lights = {},
		Segments = {},
		Patterns = {}
	}

	--[[
			Setup Lights
	--]]

	-- Setup light templates
	local lightTemplates = {}
	--TODO: lighting providers system
	for name, data in pairs( data.Lighting["2D"] ) do
		lightTemplates[name] = exmeta.Inherit( data, PhotonLight2D )
	end

	-- Initialize individual lights
	for id, light in pairs( data.Lights ) do
		component.Lights[id] = exmeta.SetMetaTable(
			{
				LocalPosition = light[2],
				LocalAngles = light[3]
			},
			lightTemplates[light[1]]
		)
	end

	-- Process segments
	for segmentName, segmentData in pairs( data.Segments ) do
		component.Segments[segmentName] = PhotonLightingSegment.New( segmentData )
	end

	-- Process patterns
	print("Processing patterns...")
	for channelName, channel in pairs( data.Patterns ) do
		for modeName, mode in pairs( channel ) do
			local patternName = channelName .. ":" .. modeName
			for segmentName, sequence in pairs ( mode ) do
				local segment = component.Segments[segmentName]
				if (not segment) then
					error( string.format("Invalid segment: '%s'", segmentName) )
				end
				if (isstring(sequence)) then
					segment:AddPattern( patternName, sequence )
				else
					-- TODO: advanced pattern assignment
					error( "Invalid pattern assignment." )
				end
			end
		end
	end

	--[[
			Final metatable setup
	--]]
	setmetatable( component, { __index = PhotonLightingComponent } )

	return component
end

-- Return new INSTANCE of this component that connects
-- to a Photon Controller and component entity.
---@param ent photon_entity
---@param controller PhotonController
---@return PhotonLightingComponent
function Component:Initialize( ent, controller )
	local component = PhotonBaseEntity.Initialize( self, ent, controller ) --[[@as PhotonLightingComponent]]

	-- Set CurrentState to directly reference controller's table
	component.CurrentModes = controller.CurrentModes


	-- local entTable = component:GetTable() -- set via BaseEntity init?

	component.Lights = {}
	component.Segments = {}

	-- Process light table
	for key, light in pairs(self.Lights) do
		printf("\tInitializing light[%s]", key)
		component.Lights[key] = light:Initialize()
		print("\tLight table:")
		PrintTable(component.Lights[key])
	end

	-- Process segments
	for name, segment in pairs(self.Segments) do
		component.Segments[name] = segment:Initialize( component )
	end

	return component
end

function Component:SetChannelMode( channel, new, old )
	printf( "Component received mode change notification for [%s] => %s", channel, new )
	-- Notify segments
	for name, segment in pairs( self.Segments ) do
		segment:ApplyModeUpdate( channel, new )
	end
end

