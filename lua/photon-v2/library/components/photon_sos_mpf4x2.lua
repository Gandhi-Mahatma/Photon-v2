if (Photon2.ReloadComponentFile()) then return end
local COMPONENT = Photon2.LibraryComponent()

COMPONENT.Author = "Photon"

COMPONENT.Credits = {
	Model = "SGM",
	Code = "Schmal"
}

-- photon_s[ound]o[ff]s[ignal]_mp[ower]f[ascia]4[inch]lic[ense plate]_h[orizontal]
COMPONENT.Title = [[SoundOff Signal mpower Fascia 4x2]]
COMPONENT.Category = "Perimeter"
COMPONENT.Model = "models/sentry/props/soundofffascia_thicc.mdl"

COMPONENT.Preview = {
	Position = Vector(),
	Angles = Angle( 0, 180, 0 ),
	Zoom = 3
}

COMPONENT.Templates = {}

COMPONENT.Elements = {}

COMPONENT.Segments = {}

COMPONENT.Inputs = {}