
TOOL.Category		= "Gas Systems 2"
TOOL.Name			= "Powered Thruster"
TOOL.ConfigName		= ""

if (CLIENT and GetConVarNumber("CAF_UseTab") == 1) then TOOL.Tab = "Custom Addon Framework" end

if ( CLIENT ) then
    language.Add( "Tool_gas_thruster_name", "Gas Thruster Tool" )
    language.Add( "Tool_gas_thruster_desc", "Spawns a gas consuming thruster." )
    language.Add( "Tool_gas_thruster_0", "Primary: Create/Update Gas Thruster" )
    language.Add( "GasThrusterTool_Model", "Model:" )
    language.Add( "GasThrusterTool_OWEffects", "Over water effects:" )
    language.Add( "GasThrusterTool_UWEffects", "Under water effects:" )
    language.Add( "GasThrusterTool_force", "Force multiplier:" )
    language.Add( "GasThrusterTool_force_min", "Force minimum:" )
    language.Add( "GasThrusterTool_force_max", "Force maximum:" )
    language.Add( "GasThrusterTool_bidir", "Bi-directional:" )
    language.Add( "GasThrusterTool_collision", "Collision:" )
    language.Add( "GasThrusterTool_sound", "Enable sound:" )
    language.Add( "GasThrusterTool_owater", "Works out of water:" )
    language.Add( "GasThrusterTool_uwater", "Works under water:" )
	language.Add( "sboxlimit_gas_thrusters", "You've hit Gas thrusters limit!" )
	language.Add( "undone_gasthruster", "Undone Gas Thruster" )
end

if (SERVER) then
	CreateConVar('sbox_maxgas_thrusters', 10)
end

TOOL.ClientConVar[ "force" ] = "1500"
TOOL.ClientConVar[ "force_min" ] = "0"
TOOL.ClientConVar[ "force_max" ] = "10000"
TOOL.ClientConVar[ "model" ] = "models/props_c17/lampShade001a.mdl"
TOOL.ClientConVar[ "bidir" ] = "1"
TOOL.ClientConVar[ "collision" ] = "0"
TOOL.ClientConVar[ "sound" ] = "0"
TOOL.ClientConVar[ "oweffect" ] = "fire"
TOOL.ClientConVar[ "uweffect" ] = "same"
TOOL.ClientConVar[ "owater" ] = "1"
TOOL.ClientConVar[ "uwater" ] = "1"

cleanup.Register( "gas_thrusters" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end
	
	local ply = self:GetOwner()
	
	local force			= self:GetClientNumber( "force" )
	local force_min		= self:GetClientNumber( "force_min" )
	local force_max		= self:GetClientNumber( "force_max" )
	local model			= self:GetClientInfo( "model" )
	local bidir			= (self:GetClientNumber( "bidir" ) ~= 0)
	local nocollide		= (self:GetClientNumber( "collision" ) == 0)
	local sound			= (self:GetClientNumber( "sound" ) ~= 0)
	local oweffect		= self:GetClientInfo( "oweffect" )
	local uweffect		= self:GetClientInfo( "uweffect" )
	local owater			= (self:GetClientNumber( "owater" ) ~= 0)
	local uwater			= (self:GetClientNumber( "uwater" ) ~= 0)
	
	if ( !trace.Entity:IsValid() ) then nocollide = false end
	
	// If we shot a gas_thruster change its force
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gas_thruster" && trace.Entity.pl == ply ) then
		trace.Entity:SetForce( force )
		trace.Entity:SetEffect( effect )
		trace.Entity:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound)
		
		trace.Entity.force		= force
		trace.Entity.force_min	= force_min
		trace.Entity.force_max	= force_max
		trace.Entity.bidir		= bidir
		trace.Entity.sound		= sound
		trace.Entity.oweffect	= oweffect
		trace.Entity.uweffect	= uweffect
		trace.Entity.owater		= owater
		trace.Entity.uwater		= uwater
		trace.Entity.nocollide	= nocollide
		
		if ( nocollide == true ) then trace.Entity:GetPhysicsObject():EnableCollisions( false ) end
		
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "gas_thrusters" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	gas_thruster = MakeGasThruster( ply, model, Ang, trace.HitPos, force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound, nocollide )
	
	local min = gas_thruster:OBBMins()
	gas_thruster:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	// Don't weld to world
	local const = WireLib.Weld(gas_thruster, trace.Entity, trace.PhysicsBone, true, nocollide)

	undo.Create("GasThruster")
		undo.AddEntity( gas_thruster )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
		
	ply:AddCleanup( "gas_thrusters", gas_thruster )
	ply:AddCleanup( "gas_thrusters", const )
	
	return true
end

if (SERVER) then

	function MakeGasThruster( pl, Model, Ang, Pos, force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound, nocollide, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "gas_thrusters" ) ) then return false end
		
		local gas_thruster = ents.Create( "gas_thruster" )
		if (!gas_thruster:IsValid()) then return false end
		gas_thruster:SetModel( Model )
		
		gas_thruster:SetAngles( Ang )
		gas_thruster:SetPos( Pos )
		gas_thruster:Spawn()
		
		gas_thruster:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound)
		gas_thruster:SetPlayer( pl )
		
		if ( nocollide == true ) then gas_thruster:GetPhysicsObject():EnableCollisions( false ) end
		
		local ttable = {
			force		= force,
			force_min	= force_min,
			force_max	= force_max,
			bidir       = bidir,
			sound       = sound,
			pl			= pl,
			oweffect	= oweffect,
			uweffect	= uweffect,
			owater		= owater,
			uwater		= uwater,
			nocollide	= nocollide
			}
		
		table.Merge(gas_thruster:GetTable(), ttable )
		
		pl:AddCount( "gas_thrusters", gas_thruster )
		
		return gas_thruster
	end

	duplicator.RegisterEntityClass("gas_thruster", MakeGasThruster, "Model", "Ang", "Pos", "force", "force_min", "force_max", "oweffect", "uweffect", "owater", "uwater", "bidir", "sound", "nocollide", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostGasThruster( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	if (trace.Entity && trace.Entity:GetClass() == "gas_thruster" || trace.Entity:IsPlayer()) then
	
		ent:SetNoDraw( true )
		return
		
	end
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local min = ent:OBBMins()
	 ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )
	
	ent:SetNoDraw( false )
end


function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostGasThruster( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_gas_thruster_name", Description = "#Tool_gas_thruster_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "gas_thruster",

		Options = {
			Default = {
				gas_thruster_force = "20",
				gas_thruster_model = "models/props_junk/plasticbucket001a.mdl",
				gas_thruster_effect = "fire",
			}
		},

		CVars = {
			[0] = "gas_thruster_model",
			[1] = "gas_thruster_force",
			[2] = "gas_thruster_effect"
		}
	})

	/*panel:AddControl("ComboBox", {
		Label = "#GasThrusterTool_Model",
		MenuButton = "0",

		Options = {
			["#Thruster"]				= { gas_thruster_model = "models/dav0r/thruster.mdl" },
			["#Paint_Bucket"]			= { gas_thruster_model = "models/props_junk/plasticbucket001a.mdl" },
			["#Small_Propane_Canister"]	= { gas_thruster_model = "models/props_junk/PropaneCanister001a.mdl" },
			["#Medium_Propane_Tank"]	= { gas_thruster_model = "models/props_junk/propane_tank001a.mdl" },
			["#Cola_Can"]				= { gas_thruster_model = "models/props_junk/PopCan01a.mdl" },
			["#Bucket"]					= { gas_thruster_model = "models/props_junk/MetalBucket01a.mdl" },
			["#Vitamin_Jar"]			= { gas_thruster_model = "models/props_lab/jar01a.mdl" },
			["#Lamp_Shade"]				= { gas_thruster_model = "models/props_c17/lampShade001a.mdl" },
			["#Fat_Can"]				= { gas_thruster_model = "models/props_c17/canister_propane01a.mdl" },
			["#Black_Canister"]			= { gas_thruster_model = "models/props_c17/canister01a.mdl" },
			["#Red_Canister"]			= { gas_thruster_model = "models/props_c17/canister02a.mdl" }
		}
	})*/
	
	panel:AddControl( "PropSelect", {
		Label = "#GasThrusterTool_Model",
		ConVar = "gas_thruster_model",
		Category = "Thrusters",
		Models = list.Get( "ThrusterModels" )
	})
	

	panel:AddControl("ComboBox", {
		Label = "#GasThrusterTool_OWEffects",
		MenuButton = "0",

		Options = {
			["#No_Effects"] = { gas_thruster_oweffect = "none" },
			["#Flames"] = { gas_thruster_oweffect = "fire" },
			["#Plasma"] = { gas_thruster_oweffect = "plasma" },
			["#Smoke"] = { gas_thruster_oweffect = "smoke" },
			["#Smoke Random"] = { gas_thruster_oweffect = "smoke_random" },
			["#Smoke Do it Youself"] = { gas_thruster_oweffect = "smoke_diy" },
			["#Rings"] = { gas_thruster_oweffect = "rings" },
			["#Rings Growing"] = { gas_thruster_oweffect = "rings_grow" },
			["#Rings Shrinking"] = { gas_thruster_oweffect = "rings_shrink" },
			["#Bubbles"] = { gas_thruster_oweffect = "bubble" },
			["#Magic"] = { gas_thruster_oweffect = "magic" },
			["#Magic Random"] = { gas_thruster_oweffect = "magic_color" },
			["#Magic Do It Yourself"] = { gas_thruster_oweffect = "magic_diy" },
			["#Colors"] = { gas_thruster_oweffect = "color" },
			["#Colors Random"] = { gas_thruster_oweffect = "color_random" },
			["#Colors Do It Yourself"] = { gas_thruster_oweffect = "color_diy" },
			["#Blood"] = { gas_thruster_oweffect = "blood" },
			["#Money"] = { gas_thruster_oweffect = "money" },
			["#Sperms"] = { gas_thruster_oweffect = "sperm" },
			["#Feathers"] = { gas_thruster_oweffect = "feather" },
			["#Candy Cane"] = { gas_thruster_oweffect = "candy_cane" },
			["#Goldstar"] = { gas_thruster_oweffect = "goldstar" },
			["#Water Small"] = { gas_thruster_oweffect = "water_small" },
			["#Water Medium"] = { gas_thruster_oweffect = "water_medium" },
			["#Water Big"] = { gas_thruster_oweffect = "water_big" },
			["#Water Huge"] = { gas_thruster_oweffect = "water_huge" },
			["#Striderblood Small"] = { gas_thruster_oweffect = "striderblood_small" },
			["#Striderblood Medium"] = { gas_thruster_oweffect = "striderblood_medium" },
			["#Striderblood Big"] = { gas_thruster_oweffect = "striderblood_big" },
			["#Striderblood Huge"] = { gas_thruster_oweffect = "striderblood_huge" },
			["#More Sparks"] = { gas_thruster_oweffect = "more_sparks" },
			["#Spark Fountain"] = { gas_thruster_oweffect = "spark_fountain" },
			["#Jetflame"] = { gas_thruster_oweffect = "jetflame" },
			["#Jetflame Advanced"] = { gas_thruster_oweffect = "jetflame_advanced" },
			["#Jetflame Blue"] = { gas_thruster_oweffect = "jetflame_blue" },
			["#Jetflame Red"] = { gas_thruster_oweffect = "jetflame_red" },
			["#Jetflame Purple"] = { gas_thruster_oweffect = "jetflame_purple" },
			["#Comic Balls"] = { gas_thruster_oweffect = "balls" },
			["#Comic Balls Random"] = { gas_thruster_oweffect = "balls_random" },
			["#Comic Balls Fire Colors"] = { gas_thruster_oweffect = "balls_firecolors" },
			["#Souls"] = { gas_thruster_oweffect = "souls" },
			["#Debugger 10 Seconds"] = { gas_thruster_oweffect = "debug_10" },
			["#Debugger 30 Seconds"] = { gas_thruster_oweffect = "debug_30" },
			["#Debugger 60 Seconds"] = { gas_thruster_oweffect = "debug_60" },
			["#Fire and Smoke"] = { gas_thruster_oweffect = "fire_smoke" },
			["#Fire and Smoke Huge"] = { gas_thruster_oweffect = "fire_smoke_big" },
			["#5 Growing Rings"] = { gas_thruster_oweffect = "rings_grow_rings" },
			["#Color and Magic"] = { gas_thruster_oweffect = "color_magic" },
		}
	})

	panel:AddControl("ComboBox", {
		Label = "#GasThrusterTool_UWEffects",
		MenuButton = "0",

		Options = {
			["#No_Effects"] = { gas_thruster_uweffect = "none" },
			["#Same as over water"] = { gas_thruster_uweffect = "same" },
			["#Flames"] = { gas_thruster_uweffect = "fire" },
			["#Plasma"] = { gas_thruster_uweffect = "plasma" },
			["#Smoke"] = { gas_thruster_uweffect = "smoke" },
			["#Smoke Random"] = { gas_thruster_uweffect = "smoke_random" },
			["#Smoke Do it Youself"] = { gas_thruster_uweffect = "smoke_diy" },
			["#Rings"] = { gas_thruster_uweffect = "rings" },
			["#Rings Growing"] = { gas_thruster_uweffect = "rings_grow" },
			["#Rings Shrinking"] = { gas_thruster_uweffect = "rings_shrink" },
			["#Bubbles"] = { gas_thruster_uweffect = "bubble" },
			["#Magic"] = { gas_thruster_uweffect = "magic" },
			["#Magic Random"] = { gas_thruster_uweffect = "magic_color" },
			["#Magic Do It Yourself"] = { gas_thruster_uweffect = "magic_diy" },
			["#Colors"] = { gas_thruster_uweffect = "color" },
			["#Colors Random"] = { gas_thruster_uweffect = "color_random" },
			["#Colors Do It Yourself"] = { gas_thruster_uweffect = "color_diy" },
			["#Blood"] = { gas_thruster_uweffect = "blood" },
			["#Money"] = { gas_thruster_uweffect = "money" },
			["#Sperms"] = { gas_thruster_uweffect = "sperm" },
			["#Feathers"] = { gas_thruster_uweffect = "feather" },
			["#Candy Cane"] = { gas_thruster_uweffect = "candy_cane" },
			["#Goldstar"] = { gas_thruster_uweffect = "goldstar" },
			["#Water Small"] = { gas_thruster_uweffect = "water_small" },
			["#Water Medium"] = { gas_thruster_uweffect = "water_medium" },
			["#Water Big"] = { gas_thruster_uweffect = "water_big" },
			["#Water Huge"] = { gas_thruster_uweffect = "water_huge" },
			["#Striderblood Small"] = { gas_thruster_uweffect = "striderblood_small" },
			["#Striderblood Medium"] = { gas_thruster_uweffect = "striderblood_medium" },
			["#Striderblood Big"] = { gas_thruster_uweffect = "striderblood_big" },
			["#Striderblood Huge"] = { gas_thruster_uweffect = "striderblood_huge" },
			["#More Sparks"] = { gas_thruster_uweffect = "more_sparks" },
			["#Spark Fountain"] = { gas_thruster_uweffect = "spark_fountain" },
			["#Jetflame"] = { gas_thruster_uweffect = "jetflame" },
			["#Jetflame Advanced"] = { gas_thruster_uweffect = "jetflame_advanced" },
			["#Jetflame Blue"] = { gas_thruster_uweffect = "jetflame_blue" },
			["#Jetflame Red"] = { gas_thruster_uweffect = "jetflame_red" },
			["#Jetflame Purple"] = { gas_thruster_uweffect = "jetflame_purple" },
			["#Comic Balls"] = { gas_thruster_uweffect = "balls" },
			["#Comic Balls Random"] = { gas_thruster_uweffect = "balls_random" },
			["#Comic Balls Fire Colors"] = { gas_thruster_uweffect = "balls_firecolors" },
			["#Souls"] = { gas_thruster_uweffect = "souls" },
			["#Debugger 10 Seconds"] = { gas_thruster_uweffect = "debug_10" },
			["#Debugger 30 Seconds"] = { gas_thruster_uweffect = "debug_30" },
			["#Debugger 60 Seconds"] = { gas_thruster_uweffect = "debug_60" },
			["#Fire and Smoke"] = { gas_thruster_uweffect = "fire_smoke" },
			["#Fire and Smoke Huge"] = { gas_thruster_uweffect = "fire_smoke_big" },
			["#5 Growing Rings"] = { gas_thruster_uweffect = "rings_grow_rings" },
			["#Color and Magic"] = { gas_thruster_uweffect = "color_magic" },
		}
	})

	panel:AddControl("Slider", {
		Label = "#GasThrusterTool_force",
		Type = "Float",
		Min = "1",
		Max = "10000",
		Command = "gas_thruster_force"
	})

	panel:AddControl("Slider", {
		Label = "#GasThrusterTool_force_min",
		Type = "Float",
		Min = "0",
		Max = "10000",
		Command = "gas_thruster_force_min"
	})

	panel:AddControl("Slider", {
		Label = "#GasThrusterTool_force_max",
		Type = "Float",
		Min = "0",
		Max = "10000",
		Command = "gas_thruster_force_max"
	})

	panel:AddControl("CheckBox", {
		Label = "#GasThrusterTool_bidir",
		Command = "gas_thruster_bidir"
	})

	panel:AddControl("CheckBox", {
		Label = "#GasThrusterTool_collision",
		Command = "gas_thruster_collision"
	})

	panel:AddControl("CheckBox", {
		Label = "#GasThrusterTool_sound",
		Command = "gas_thruster_sound"
	})

	panel:AddControl("CheckBox", {
		Label = "#GasThrusterTool_owater",
		Command = "gas_thruster_owater"
	})

	panel:AddControl("CheckBox", {
		Label = "#GasThrusterTool_uwater",
		Command = "gas_thruster_uwater"
	})
end

//from model pack 1 --TODO: update model pack system to use list system
list.Set( "ThrusterModels", "models/jaanus/thruster_flat.mdl", {} )
