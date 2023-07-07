if (exmeta.ReloadFile()) then return end

NAME = "PhotonLightingComponent"
BASE = "PhotonBaseEntity"

local print = Photon2.Debug.Print
local printf = Photon2.Debug.PrintF

---@class PhotonLightingComponent : PhotonBaseEntity
---@field Name string
---@field Ancestors table<string, boolean>
---@field Descendants table<string, boolean>
---@field Children table<string, boolean>
---@field Lights table<integer, PhotonLight>
---@field Segments table<string, PhotonLightingSegment>
---@field InputPriorities table<string, integer>
---@field CurrentModes table<string, string>
---@field ActiveSequences table<PhotonSequence, boolean>
---@field UseControllerTiming boolean (Default = `true`) When true, flash/sequence timing is managed by the Controller. Set to `false` if unsynchronized flashing is desired.
---@field ColorMap table<integer, string[]>
---@field Inputs table<string, string[]>
---@field LightGroups table<string, integer[]>
local Component = exmeta.New()

local Builder = Photon2.ComponentBuilder
local Util = Photon2.Util

Component.IsPhotonLightingComponent = true

--[[
		COMPILATION
--]]

local dumpLibraryData = false

-- [Internal] Compile a Library Component to store in the Index.
---@param name string
---@param data PhotonLibraryComponent
---@param base string Deprecated
---@return PhotonLightingComponent
function Component.New( name, data, base )

	data = table.Copy( data )

	local ancestors = { [name] = true }

	if ( data.Base ) then
		Util.Inherit( data, table.Copy(Photon2.BuildParentLibraryComponent( name, data.Base ) ))
		Photon2.Library.ComponentsGraph[data.Base] = Photon2.Library.ComponentsGraph[data.Base] or {}
		Photon2.Library.ComponentsGraph[data.Base][name] = true

		-- if ( Photon2.Library.Components[data.Base] ) then
		-- 	Photon2.Library.Components[data.Base].Children[name] = true
		-- end
	end

	if ( dumpLibraryData ) then
		print("_______________________________________")
		PrintTable(data)
		print("_______________________________________")
	end

	---@type PhotonLightingComponent
	local component = {
		Name = name,
		Ancestors = ancestors,
		Descendants = {},
		Children = {},
		Model = data.Model,
		Lights = {},
		Segments = {},
		Patterns = {},
		Inputs = {},
		LightGroups = data.LightGroups,
		SubMaterials = data.SubMaterials
	}

	-- --[[
	-- 		Build Ancestors Dictionary
	-- --]]

	-- local lastParent = data.Base

	-- while ( lastParent ) do
	-- 	ancestors[lastParent] = true
	-- 	if ( Photon2.Library.Components[lastParent] ) then
	-- 		Photon2.Library.Components[lastParent].Descendants[name] = true
	-- 		lastParent = Photon2.Library.Components[lastParent].Base
	-- 	end
	-- end


	--[[
			Compile COMPONENT-Wide Light States
	--]]

	local lightStates = {}
	for lightClassName, states in pairs( data.LightStates or {} ) do
		local lightClass = PhotonLight.FindClass( lightClassName )
		local lightStateClass = PhotonLightState.FindClass( lightClassName )
		-- Use actual COMPONENT.LightStates table to get around load/dependency order issues.

		-- Set __index to the base class's Light.States table.
		lightStates[lightClassName] = setmetatable( states, { __index = lightClass.States })

		-- Initialize each custom state from raw data
		for stateId, state in pairs( states ) do
			states[stateId] = lightStateClass:New( stateId, state, states )
		end
	end


	--[[
			Compile Color Map
	--]]

	if ( isstring( data.ColorMap ) ) then
		-- component.ColorMap = Builder.ColorMap( data.ColorMap --[[@as string]], data.LightGroups )
		component.ColorMap = Photon2.ComponentBuilder.ColorMap( data.ColorMap --[[@as string]], data.LightGroups )
	elseif ( istable( data.ColorMap ) ) then
		component.ColorMap = data.ColorMap --[[@as table<integer, string[]>]]
	end


	--[[
			Compile Light Templates
	--]]

	local lightTemplates = {}
	for lightClassName, templates in pairs( data.Lighting or {} ) do
		-- printf( "\t\tLight class %s templates...", lightClassName )

		local lightClass = _G["PhotonLight" .. lightClassName]

		-- Verify light class exists/is supported
		if ( not lightClass ) then
			error(string.format("Unrecognized light class [%s]. Global table [PhotonLight%s] is nil.", lightClassName, lightClassName))
		end

		-- Iterate through each template in the light class
		for templateName, templateData in pairs( templates ) do
			templateData.Class = lightClassName
			printf("\t\t\tTemplate name: %s", templateName)
			-- Throw error on duplicate light template name
			if ( lightTemplates[templateName] ) then
				error( string.format( "Light template name [%s] is declared more than once. Each template name must be unique, regardless of its class.", templateName ) )
			end

			-- Set the metatable __index of each template's States to the COMPONENT.LightStates

			--
			-- Process Template's Light States
			--

			local lightStateClass = PhotonLightState.FindClass( lightClassName )
			
			-- set the "parent" table to either COMPONENT.LightStates[class] or the default states
			local parentStatesTable = lightStates[lightClassName] or PhotonLight.FindClass( lightClassName ).States
			local templateStates = setmetatable( templateData.States or {}, { __index = parentStatesTable } )
			
			for stateId, state in pairs( templateStates ) do
				templateStates[stateId] = lightStateClass:New( stateId, state, templateStates )
			end

			templateData.States = templateStates

			--
			-- Generate Light Template Object
			--

			lightTemplates[templateName] = lightClass.NewTemplate( templateData )

			if ( not lightTemplates[templateName] ) then
				error( "Light template [" .. tostring(templateName) .. "] was not added. NewTemplate likely returned nil." )
			end
		end

	end
	

	--[[
			Compile Lights
	--]]

	-- print("Compiling lights...")
	for id, light in pairs( data.Lights or {} ) do
		-- printf( "\t\tLight ID: %s", id )
		-- TODO: Process { Set = "x" } scripting

		local inverse = nil

		-- Add light.Inverse value if the template starts with the - sign
		if ( string.StartsWith(light[1], "-") ) then
			inverse = true
			light[1] = string.sub( light[1], 2 )
		end

		-- Verify template
		local template = lightTemplates[light[1]]
		if ( not template ) then 
			error( string.format( "Light template [%s] is not defined.", light[1] ) )
		end

		-- Process light states
		local lightClass = PhotonLight.FindClass( template.Class )
		local lightStateClass = PhotonLightState.FindClass( template.Class )
		if ( istable( light.States ) ) then
			setmetatable( light.States, { __index = template.States } )
			for stateId, state in pairs( light.States ) do
				light.States[stateId] = lightStateClass:New( stateId, state, light.States )
			end
		else
			light.States = template.States
		end
		
		if ( light.Inverse == nil ) then light.Inverse = inverse end

		-- Additional data passed to light constructor for the light
		-- class to process.
		component.Lights[id] = lightClass.New( light, template ) --[[@as PhotonLight]]
	end


	--[[

			Compile Segments
	--]]

	for segmentName, segmentData in pairs( data.Segments or {} ) do
		component.Segments[segmentName] = PhotonLightingSegment.New( segmentName, segmentData, data.LightGroups )
	end


	--[[
			Compile Patterns
	--]]

	for channelName, channel in pairs( data.Patterns or {} ) do
		-- Build input interface channels
		component.Inputs[channelName] = {}
		
		local priorityScore = PhotonLightingComponent.DefaultInputPriorities[channelName]

		for modeName, sequences in pairs( channel ) do
			
			-- Build input interface modes
			if ( istable( sequences ) and ( next(sequences) ~= nil) ) then
				component.Inputs[channelName][#component.Inputs[channelName] + 1] = modeName
			end
			-- print("----------------------------")
			-- PrintTable( channel )
			-- print("----------------------------")
			local patternName = channelName .. ":" .. modeName

			-- sequence ranking...
			--[[
				for i=1, #sequences do
					{ Tail, "RIGHT" }
				end
			]]--\
			local rank = 1
			for segmentName, sequence in pairs ( sequences ) do
				-- if sequence == "<UNSET>" then continue end

				local sequenceName = patternName .. "/" .. sequence
				-- print("Sequence name: " .. sequenceName)
				local segment = component.Segments[segmentName]
				if (not segment) then
					error( string.format("Invalid segment: '%s'", segmentName) )
				end

				if (isstring(sequence)) then
					segment:AddPattern( patternName, sequence, priorityScore, rank )
				else
					-- TODO: advanced pattern assignment
					error( "Invalid pattern assignment." )
				end

				rank = rank + 1
				
				-- print("Segment Inputs =======================")
				-- PrintTable( segment.Inputs )
				-- print("========================================")
			end

			

		end
	end

	--[[
			Finalize and set meta-table
	--]]
	setmetatable( component, { __index = PhotonLightingComponent } )

	-- print("Component.Patterns ====================================")
	-- 	PrintTable( component.Patterns )
	-- print("=======================================================")

	return component
end


--[[
		INITIALIZATION
--]]

-- Return new INSTANCE of this component that connects
-- to a Photon Controller and component entity.
---@param ent photon_entity
---@param controller PhotonController
---@return PhotonLightingComponent
function Component:Initialize( ent, controller )
	-- Calls the base constructor but passes LightingComponent as "self"
	-- so LightingComponent is what's actually used for the metatable,
	-- not PhotonBaseEntity.
	local component = PhotonBaseEntity.Initialize( self, ent, controller ) --[[@as PhotonLightingComponent]]

	-- Set CurrentState to directly reference controller's table
	component.CurrentModes = controller.CurrentModes

	component.Lights = {}
	component.Segments = {}
	component.ActiveSequences = {}

	-- Process light table
	for key, light in pairs(self.Lights) do
		component.Lights[key] = light:Initialize( key, component.Entity )
	end

	-- Process segments
	for name, segment in pairs(self.Segments) do
		component.Segments[name] = segment:Initialize( component )
	end

	return component
end


function Component:OnScaleChange( newScale, oldScale )
	for key, light in pairs(self.Lights) do
		if (light.SetLightScale) then
			light:SetLightScale( newScale )
		end
	end
end

function Component:ApplyModeUpdate()
	for name, segment in pairs( self.Segments ) do
		segment:ApplyModeUpdate()
	end
	-- self:UpdateSegmentLightControl()
	self:FrameTick()
end

-- Functionally identical to what :ApplyModeUpdate() does but logs it
-- for debugging purposes.
function Component:SetChannelMode( channel, new, old )
	
	printf( "Component received mode change notification for [%s] => %s", channel, new )
	-- Notify segments
	for name, segment in pairs( self.Segments ) do
		segment:OnModeChange( channel, new )
	end
	self:FrameTick()
end


---@param segmentName string
---@param sequence PhotonSequence
function Component:RegisterActiveSequence( segmentName, sequence )
	-- local sequence = self.Segments[segmentName].Sequences[sequence]
	-- printf("Adding sequence [%s]", sequence)
	self.ActiveSequences[sequence] = true
end


---@param segmentName string
---@param sequence PhotonSequence
function Component:RemoveActiveSequence( segmentName, sequence)
	printf("Removing sequence [%s]", sequence)
	self.ActiveSequences[sequence] = nil
end

function Component:FrameTick()
	-- Relays notification to each segment
	-- TODO: consider sequence-based updates to reduce overhead
	for segmentName, segment in pairs( self.Segments ) do 
		segment:IncrementFrame( self.PhotonController.Frame )
	end

	for i=1, #self.Lights do
		self.Lights[i]:UpdateState()
	end
end

function Component:RemoveVirtual()
	if ( not self.IsVirtual ) then
		error("Cannot call Component:VirtualRemove() on non-virtual components.")
	end
	for i=1, #self.Lights do
		self.Lights[i]:DeactivateNow()
	end
end

function Component:SetColorMap( colorMap )
	if ( isstring( colorMap ) ) then
		-- error("Setting string ColorMap: " .. tostring(colorMap))
		colorMap = Photon2.ComponentBuilder.ColorMap( colorMap --[[@as string]], self.LightGroups )
	end
	self.ColorMap = colorMap
end

Component.Parameters = {}

Component.PropertyFunctionMap = {
	["ColorMap"] = "SetColorMap"
}

Component.PropertiesUpdatedOnSoftUpdate = {
	["ColorMap"] = true
}