if (Photon2.ReloadComponentFile()) then return end
local COMPONENT = Photon2.LibraryComponent()

COMPONENT.Author = "Photon"

COMPONENT.Credits = {
	Model = "SGM",
	Code = "Schmal"
}

COMPONENT.PrintName = [[SoundOff Signal nForce (54")]]

COMPONENT.Model = "models/sentry/props/nforce_suv.mdl"

COMPONENT.DefaultSubMaterials = {
	-- [1] = "photon/common/blank",
	-- [2] = "photon/common/blank",
	-- [6] = "photon/common/blank"
}

COMPONENT.Lighting = {
	["2D"] = {
		Main = {
			Material = PhotonDynamicMaterial.GenerateLightQuad("photon/lights/sos_nforce_main_shape.png").MaterialName,
			MaterialOverlay = PhotonDynamicMaterial.GenerateLightQuad("photon/lights/sos_nforce_main_detail.png").MaterialName,
			MaterialBloom = PhotonDynamicMaterial.GenerateBloomQuad("photon/lights/sos_nforce_main_bloom.png").MaterialName,
			Width = 9.9,
			Height = 9.9,
			Ratio = 2.4,
			Scale = 1.2,
			ForwardVisibilityOffset = -0.1,
			ForwardBloomOffset = 0.5
		},
		Corner3 = {
			Material = PhotonDynamicMaterial.GenerateLightQuad("photon/lights/sos_nforce_corner3_shape.png").MaterialName,
			MaterialOverlay = PhotonDynamicMaterial.GenerateLightQuad("photon/lights/sos_nforce_corner3_detail.png").MaterialName,
			MaterialBloom = PhotonDynamicMaterial.GenerateBloomQuad("photon/lights/sos_nforce_main_bloom.png").MaterialName,
			Width = 9.9,
			Height = 9.9,
			Ratio = 1,
			Scale = 1,
			ForwardVisibilityOffset = -0.1,
			ForwardBloomOffset = 0.5
		}
	}
}

COMPONENT.ColorMap = "[W] 1 [R] 2 4 6 8 10 12 14 16 18 20 [B] 3 5 7 9 11 13 15 17 19 21 [A] 22 23 24 25 26"

COMPONENT.Lights = {
	[1] = { "Main", Vector( 0, 6.6, -0.2 ), Angle( 0, 0, 0 ) },
	-- [1] = { "Main", Vector( 0, 6.6, -0.2 ), Angle( 0, 0, 0 ) },
	[2] = { "Main", Vector( -7.7, 6.6, -0.2 ), Angle( 0, 0, 0 ) },
	[3] = { "Main", Vector( 7.7, 6.6, -0.2 ), Angle( 0, 0, 0 ) },

	[4] = { "Main", Vector( -15.4, 6.6, -0.2 ), Angle( 0, 0, 0 ) },
	[5] = { "Main", Vector( 15.4, 6.6, -0.2 ), Angle( 0, 0, 0 ) },

	[6] = { "Main", Vector( -22.5, 6.6, -0.2 ), Angle( 0, 0, 0 ) },
	[7] = { "Main", Vector( 22.5, 6.6, -0.2 ), Angle( 0, 0, 0 ) },

	[8] = { "Corner3", Vector( -27.75, 6.1, -0.2 ), Angle( 0, 16, 0 ) },
	[9] = { "Corner3", Vector( 27.75, 6.1, -0.2 ), Angle( 0, -16, 0 ) },

	[10] = { "Corner3", Vector( -30.13, 4.75, -0.2 ), Angle( 0, 43, 0 ) },
	[11] = { "Corner3", Vector( 30.13, 4.75, -0.2 ), Angle( 0, -43, 0 ) },

	[12] = { "Corner3", Vector( -31.49, 2.43, -0.2 ), Angle( 0, 77, 0 ) },
	[13] = { "Corner3", Vector( 31.49, 2.43, -0.2 ), Angle( 0, -77, 0 ) },

	[14] = { "Corner3", Vector( -31.49, -2.43, -0.2 ), Angle( 0, 180-77, 0 ) },
	[15] = { "Corner3", Vector( 31.49, -2.43, -0.2 ), Angle( 0, 180+77, 0 ) },

	[16] = { "Corner3", Vector( -30.13, -4.75, -0.2 ), Angle( 0, 180-43, 0 ) },
	[17] = { "Corner3", Vector( 30.13, -4.75, -0.2 ), Angle( 0, 180+43, 0 ) },

	[18] = { "Corner3", Vector( -27.75, -6.1, -0.2 ), Angle( 0, 180-16, 0 ) },
	[19] = { "Corner3", Vector( 27.75, -6.1, -0.2 ), Angle( 0, 180+16, 0 ) },

	[20] = { "Main", Vector( -22.5, -6.6, -0.2 ), Angle( 0, 180, 0 ) },
	[21] = { "Main", Vector( 22.5, -6.6, -0.2 ), Angle( 0, 180, 0 ) },

	[22] = { "Main", Vector( -15.4, -6.6, -0.2 ), Angle( 0, 180, 0 ) },
	[23] = { "Main", Vector( 15.4, -6.6, -0.2 ), Angle( 0, 180, 0 ) },

	[24] = { "Main", Vector( -7.7, -6.6, -0.2 ), Angle( 0, 180, 0 ) },
	[25] = { "Main", Vector( 7.7, -6.6, -0.2 ), Angle( 0, 180, 0 ) },

	[26] = { "Main", Vector( 0, -6.6, -0.2 ), Angle( 0, 180, 0 ) },
}

local sequence = Photon2.SequenceBuilder.New

COMPONENT.Segments = {
	All = {
		Frames = {
			[1] = "2 3 6 7",
			[2] = "1 4 5",
			[3] = "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26",
			[4]  = "2 4 6 8 10 12 14 16 18 20 22 24 1:R",
			[5]  = "3 5 7 9 11 13 15 17 19 21 23 25 1:B",
		},
		Sequences = {
			["STEADY"] = { 3 },
			["FLASH"] = sequence():Flash( 4, 5, 4 ),
			["FLASH_2"] = sequence():Flash(1, 2, 3):Do(3):Add( 1, 1, 3, 2, 2, 3 ):Do(5)
		}
	}
}

COMPONENT.Patterns = {
	["Vehicle.Lights"] = {
		["HEADLIGHTS"] = {
			All = "FLASH_2"
		}
	}
}