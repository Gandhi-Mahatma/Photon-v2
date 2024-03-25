-- Helper functions for compiling components
Photon2.ComponentBuilder = {}

local string = string

---@param colorMap string
---@param lightGroups table<string, integer[]>
function Photon2.ComponentBuilder.StateMap( colorMap, lightGroups, stateSlots )
	colorMap = string.Replace( colorMap, "\n", " " )
	colorMap = string.Replace( colorMap, "\t", " " )
	colorMap = string.Trim( colorMap )
	while string.find( colorMap, "  " ) do
		colorMap = string.Replace( colorMap, "  ", " " )
	end

	local blocks = string.Split( colorMap, " " )
	
	-- micro optimization
	local validatedStateSlot = false

	local result = {}

	local current
	for i=1, #blocks do
		local block = blocks[i]
		if ( block == "" ) then continue end
		if ( string.StartsWith( block, "[" ) ) then
			block = string.sub( block, 2, string.len(block) - 1 )
			block = string.Replace( block, " ", "" )
			current = string.Split( block, "/" )
			
			for i=1, #current do
				-- If the provided state is a number, it is assumed that it's a slot.
				-- (numeric state names aren't supported)
				local asNumber = tonumber( current[i] )
				if ( asNumber ) then
					if ( not validatedStateSlot ) then
						if ( not istable( stateSlots ) ) then
							error( "Failed to setup StateMap because StateSlots is invalid. Ensure you have COMPONENT.States = {} configured.")
						end
						if ( not stateSlots[asNumber] ) then
							error( "Failed to setup StateMap because slot [" .. tostring(current[i]) .. "] is not defined in COMPONENT.States.")
						end
						validatedStateSlot = true
					end
					current[i] = stateSlots[asNumber]
				end
			end
		else
			local asNumber = tonumber( block )
			if ( not isnumber( asNumber ) ) then
				local group = lightGroups[block]
				if ( not group ) then
					error( string.format( "Invalid light group [%s]", block ) )
				end
				for _i=1, #group do
					result[group[_i]] = current
				end
			elseif ( asNumber ) then
				result[asNumber] = current
			else
				error( "StateMap parsing failed. Received: [" .. tostring(colorMap) .. "]" )
			end
		end
	end

	return result
end

-- Discards inherited sequences for each channel:mode the child explicitly declares. This is a
-- special case where normal deep inheritance is rarely desired (for easier pattern overrding).
---@param childInputs table Original input table from child.
---@param mergedInputs table The merged input table created from inheritance.
function Photon2.ComponentBuilder.InheritInputs( childInputs, mergedInputs )
	if ( childInputs ) then
		for channel, modes in pairs( childInputs ) do
			if ( not istable( modes ) ) then continue end
			for mode, sequences in pairs( modes ) do
				mergedInputs[channel][mode] = sequences
			end
		end
	end
end

function Photon2.ComponentBuilder.SetupAutomaticVehicleLighting( component )
	local mixin = {
		VirtualOutputs = {
			["Vehicle.AutomaticLighting"] = {
				{
					Mode = "HEADLIGHTS",
					Conditions = {
						["Vehicle.Transmission"] = { "DRIVE", "REVERSE" },
						["Vehicle.Ambient"] = { "DARK" },
						["Vehicle.Lights"] = { "AUTO" }
					}
				},
				{
					Mode = "PARKING",
					Conditions = {
						["Vehicle.Ambient"] = { "DARK" },
						["Vehicle.Lights"] = { "AUTO" },
						["Vehicle.Engine"] = { "ON" },
						["Vehicle.Transmission"] = { "PARK" }
					}
				},
				{
					Mode = "DRL",
					Conditions = {
						["Vehicle.Transmission"] = { "DRIVE", "REVERSE" },
						["Vehicle.Lights"] = { "AUTO" },
					}
				}
			}
		},
		InputPriorities = {
			["Vehicle.AutomaticLighting"] = 21
		},
		Inputs = {
			["Vehicle.AutomaticLighting"] = {
				["HEADLIGHTS"] = table.Copy( component.Inputs["Vehicle.Lights"]["HEADLIGHTS"] or {} ),
				["PARKING"] = table.Copy( component.Inputs["Vehicle.Lights"]["PARKING"] or {} ),
				["DRL"] = table.Copy( component.Inputs["Vehicle.Lights"]["DRL"] or {} )
			}
		}
	}

	table.Merge( component, mixin )
end

function Photon2.ComponentBuilder.SetupParkMode( component, params )
	if ( not istable( params ) ) then params = { "Emergency.Warning", "MODE2" } end
	local sequences = component.Inputs[params[1]][params[2]]

	-- Ignore automatic copying if the input is manually defined
	if ( component.Inputs and component.Inputs["Emergency.ParkedWarning"] and component.Inputs["Emergency.ParkedWarning"]["MODE3"] ) then
		sequences = component.Inputs["Emergency.ParkedWarning"]["MODE3"]
	end

	local mixin = {
		VirtualOutputs = {
			["Emergency.ParkedWarning"] = {
				{
					Mode = "MODE3",
					Conditions = {
						["Vehicle.Transmission"] = { "PARK" },
						["Emergency.Warning"] = { "MODE3" }
					}
				}
			},
		},
		InputPriorities = {
			["Emergency.ParkedWarning"] = 45
		},
		Inputs = {
			["Emergency.ParkedWarning"] = {
				["MODE3"] = table.Copy( sequences )
			}
		}
	}
	table.Merge( component, mixin )
end

function Photon2.ComponentBuilder.SetupNightParkMode( component, params )
	if ( not istable( params ) ) then params = { "Emergency.Warning", "MODE3" } end
	local sequences = component.Inputs[params[1]][params[2]]
	
	-- Ignore automatic copying if the input is manually defined
	if ( component.Inputs and component.Inputs["Emergency.NightParkedWarning"] and component.Inputs["Emergency.NightParkedWarning"]["MODE3"] ) then
		sequences = component.Inputs["Emergency.NightParkedWarning"]["MODE3"]
	end
	
	local mixin = {
		VirtualOutputs = {
			["Emergency.NightParkedWarning"] = {
				{
					Mode = "MODE3",
					Conditions = {
						["Vehicle.Transmission"] = { "PARK" },
						["Emergency.Warning"] = { "MODE3" },
						["Vehicle.Ambient"] = { "DARK" }
					}
				}
			},
		},
		InputPriorities = {
			["Emergency.NightParkedWarning"] = 46
		},
		Inputs = {
			["Emergency.NightParkedWarning"] = {
				["MODE3"] = table.Copy( sequences )
			}
		}
	}
	table.Merge( component, mixin )
end

-- Modifies a component to add a special debug channel and _quietly_ recompiles. It's somewhat hacky-
-- but it plays nicely with the component registration and compilation process. This might be somewhat
-- laggy on very complex components but it probably doesn't matter.
function Photon2.ComponentBuilder.ApplyDebugSequences( entryName, inputAction )
	local component = Photon2.Library.Components:Get( entryName )
	component.Segments = component.Segments or {}
	-- This will probably be necessary for the sequence creation UI
	-- component.Segments["#DEBUG"] = {

	-- }
	component.Inputs = component.Inputs or {}
	component.Inputs["#DEBUG"] = {
		["ON"] = inputAction
	}

	Photon2.Library.Components:Compile( component )
end

function Photon2.ComponentBuilder.ApplyDebugElementGroup( entryName, elementGroup )
	local component = Photon2.Library.Components:Get( entryName )
	component.Segments = component.Segments or {}
	component.Segments["#DEBUG"] = {
		Frames = {
			[1] = elementGroup
		},
		Sequences = {
			["ON"] = { 1 }
		}
	}

	return Photon2.ComponentBuilder.ApplyDebugSequences( entryName, { ["#DEBUG"] = "ON" } )
end