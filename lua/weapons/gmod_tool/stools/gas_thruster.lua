
TOOL.Category		= "Gas Systems 2"
TOOL.Name			= "#Powered Thruster"
TOOL.ConfigName		= ""

if (CLIENT and GetConVarNumber("CAF_UseTab") == 1) then TOOL.Tab = "Custom Addon Framework" end

if ( CLIENT ) then
    language.Add( "Tool_gas_thruster_name", "Gas Thruster Tool" )
    language.Add( "Tool_gas_thruster_desc", "Spawns a resource consuming thruster." )
    language.Add( "Tool_gas_thruster_0", "Primary: Create/Update Thruster" )
    language.Add( "GasThrusterTool_Model", "Model:" )
    language.Add( "GasThrusterTool_Effects", "Effects:" )
		language.Add( "GasThrusterTool_Types", "Thruster Type:")
    language.Add( "GasThrusterTool_force", "Force multiplier:" )
    language.Add( "GasThrusterTool_force_min", "Force minimum:" )
    language.Add( "GasThrusterTool_force_max", "Force maximum:" )
    language.Add( "GasThrusterTool_bidir", "Bi-directional:" )
    language.Add( "GasThrusterTool_collision", "Collision:" )
    language.Add( "GasThrusterTool_sound", "Enable sound:" )
		language.Add( "GasThrusterTool_massless", "Massless:" )
		language.Add( "GasThrusterTool_key_fw", "Positive Thrust: " )
		language.Add( "GasThrusterTool_key_bw", "Negative Thrust: " )
		language.Add( "GasThrusterTool_toggle", "Toggle" )
	language.Add( "sboxlimit_gas_thrusters", "You've hit the Powered thrusters limit!" )
	language.Add( "undone_gasthruster", "Undone Powered Thruster" )
end

if (SERVER) then
	CreateConVar('sbox_maxgas_thrusters', 20)
end

TOOL.ClientConVar[ "force" ] = "1500"
TOOL.ClientConVar[ "force_min" ] = "0"
TOOL.ClientConVar[ "force_max" ] = "10000"
TOOL.ClientConVar[ "model" ] = "models/props_c17/lampShade001a.mdl"
TOOL.ClientConVar[ "bidir" ] = "1"
TOOL.ClientConVar[ "collision" ] = "0"
TOOL.ClientConVar[ "sound" ] = "0"
TOOL.ClientConVar[ "effect" ] = "fire"
TOOL.ClientConVar[ "massless" ] = "0"
TOOL.ClientConVar[ "resource" ] = "energy"
TOOL.ClientConVar[ "multiplier" ] = "0.6"
TOOL.ClientConVar[ "keygroup" ] = "8"
TOOL.ClientConVar[ "keygroup_back" ] = "2"
TOOL.ClientConVar[ "toggle" ] = "0"

cleanup.Register( "gas_thrusters" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end
	
	local ply = self:GetOwner()
	
	local force			= self:GetClientNumber( "force" )
	local force_min	= self:GetClientNumber( "force_min" )
	local force_max	= self:GetClientNumber( "force_max" )
	local model			= self:GetClientInfo( "model" )
	local bidir			= (self:GetClientNumber( "bidir" ) ~= 0)
	local nocollide	= (self:GetClientNumber( "collision" ) ~= 0)
	local sound			= (self:GetClientNumber( "sound" ) ~= 0)
	local effect		= self:GetClientInfo( "effect" )
	local massless	= (self:GetClientNumber( "massless" ) ~= 0)
	local resource	= self:GetClientInfo( "resource" )
	local multiplier = self:GetClientNumber( "multiplier" )
	local key = self:GetClientNumber( "keygroup" )
	local key_bk = self:GetClientNumber( "keygroup_back" )
	local toggle = (self:GetClientNumber( "toggle" ) ~=0)
	
	if ( !trace.Entity:IsValid() ) then nocollide = false end
	
	// If we shot a gas_thruster change its force
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gas_thruster" && trace.Entity.pl == ply ) then
		trace.Entity:SetEffect( effect )
		trace.Entity:Setup(force, multiplier, force_min, force_max, effect, bidir, sound, massless, resource, key, key_bk, trace.Entity.pl, toggle)
		
		trace.Entity.force		= force
		trace.Entity.force_min	= force_min
		trace.Entity.force_max	= force_max
		trace.Entity.bidir		= bidir
		trace.Entity.sound		= sound
		trace.Entity.effect	= effect
		trace.Entity.nocollide	= nocollide
		trace.Entity.resource = resource
		trace.Entity.multiplier = multiplier
		trace.Entity.toggle = toggle
		
		if ( nocollide == true ) then trace.Entity:GetPhysicsObject():EnableCollisions( false ) end
		
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "gas_thrusters" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	gas_thruster = MakeGasThruster( ply, model, Ang, trace.HitPos, force, force_min, force_max, effect, bidir, sound, nocollide, nil, nil, nil, massless, resource, multiplier, key, key_bk, toggle )
	
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
	function MakeGasThruster( pl, Model, Ang, Pos, force, force_min, force_max, effect, bidir, sound, nocollide, Vel, aVel, frozen, massless, resource, multiplier, key, key_bk, toggle )
		if ( !pl:CheckLimit( "gas_thrusters" ) ) then return false end
		
		local gas_thruster = ents.Create( "gas_thruster" )
		if (!gas_thruster:IsValid()) then return false end
		gas_thruster:SetModel( Model )
		
		gas_thruster:SetAngles( Ang )
		gas_thruster:SetPos( Pos )
		gas_thruster:Spawn()
		
		gas_thruster:Setup(force, multiplier, force_min, force_max, effect, bidir, sound, massless, resource, key, key_bk, pl, toggle)
		gas_thruster:SetPlayer( pl )
		
		if ( nocollide == true ) then gas_thruster:GetPhysicsObject():EnableCollisions( false ) end
		
		local ttable = {
			force		= force,
			force_min	= force_min,
			force_max	= force_max,
			bidir       = bidir,
			sound       = sound,
			pl			= pl,
			effect	= effect,
			nocollide	= nocollide,
			massless = massless,
			resource = resource,
			multiplier = multiplier,
			key = key,
			key_bk = key_bk,
			toggle = toggle
			}
		
		table.Merge(gas_thruster:GetTable(), ttable )
		
		pl:AddCount( "gas_thrusters", gas_thruster )
		
		return gas_thruster
	end

	duplicator.RegisterEntityClass("gas_thruster", MakeGasThruster, "Model", "Ang", "Pos", "force", "force_min", "force_max", "effect", "bidir", "sound", "nocollide", "Vel", "aVel", "frozen", "massless", "resource", "multiplier", "key", "key_bk", "toggle" )
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
	
	panel:AddControl("Label", {
		Text = "#GasThrusterTool_Effects", 
		Description = "Thruster Effect" 
	})
	
	panel:AddControl("ComboBox", {
		Label = "#GasThrusterTool_Effects",
		MenuButton = "0",

		Options = {
			["#No_Effects"] = { gas_thruster_effect = "none" },
			["#Flames"] = { gas_thruster_effect = "fire" },
			["#Plasma"] = { gas_thruster_effect = "plasma" },
			["#Smoke"] = { gas_thruster_effect = "smoke" },
			["#Smoke Random"] = { gas_thruster_effect = "smoke_random" },
			["#Smoke Do it Youself"] = { gas_thruster_effect = "smoke_diy" },
			["#Rings"] = { gas_thruster_effect = "rings" },
			["#Rings Growing"] = { gas_thruster_effect = "rings_grow" },
			["#Rings Shrinking"] = { gas_thruster_effect = "rings_shrink" },
			["#Bubbles"] = { gas_thruster_effect = "bubble" },
			["#Magic"] = { gas_thruster_effect = "magic" },
			["#Magic Random"] = { gas_thruster_effect = "magic_color" },
			["#Magic Do It Yourself"] = { gas_thruster_effect = "magic_diy" },
			["#Colors"] = { gas_thruster_effect = "color" },
			["#Colors Random"] = { gas_thruster_effect = "color_random" },
			["#Colors Do It Yourself"] = { gas_thruster_effect = "color_diy" },
			["#Blood"] = { gas_thruster_effect = "blood" },
			["#Money"] = { gas_thruster_effect = "money" },
			["#Sperms"] = { gas_thruster_effect = "sperm" },
			["#Feathers"] = { gas_thruster_effect = "feather" },
			["#Candy Cane"] = { gas_thruster_effect = "candy_cane" },
			["#Goldstar"] = { gas_thruster_effect = "goldstar" },
			["#Water Small"] = { gas_thruster_effect = "water_small" },
			["#Water Medium"] = { gas_thruster_effect = "water_medium" },
			["#Water Big"] = { gas_thruster_effect = "water_big" },
			["#Water Huge"] = { gas_thruster_effect = "water_huge" },
			["#Striderblood Small"] = { gas_thruster_effect = "striderblood_small" },
			["#Striderblood Medium"] = { gas_thruster_effect = "striderblood_medium" },
			["#Striderblood Big"] = { gas_thruster_effect = "striderblood_big" },
			["#Striderblood Huge"] = { gas_thruster_effect = "striderblood_huge" },
			["#More Sparks"] = { gas_thruster_effect = "more_sparks" },
			["#Spark Fountain"] = { gas_thruster_effect = "spark_fountain" },
			["#Jetflame"] = { gas_thruster_effect = "jetflame" },
			["#Jetflame Advanced"] = { gas_thruster_effect = "jetflame_advanced" },
			["#Jetflame Blue"] = { gas_thruster_effect = "jetflame_blue" },
			["#Jetflame Red"] = { gas_thruster_effect = "jetflame_red" },
			["#Jetflame Purple"] = { gas_thruster_effect = "jetflame_purple" },
			["#Comic Balls"] = { gas_thruster_effect = "balls" },
			["#Comic Balls Random"] = { gas_thruster_effect = "balls_random" },
			["#Comic Balls Fire Colors"] = { gas_thruster_effect = "balls_firecolors" },
			["#Souls"] = { gas_thruster_effect = "souls" },
			["#Debugger 10 Seconds"] = { gas_thruster_effect = "debug_10" },
			["#Debugger 30 Seconds"] = { gas_thruster_effect = "debug_30" },
			["#Debugger 60 Seconds"] = { gas_thruster_effect = "debug_60" },
			["#Fire and Smoke"] = { gas_thruster_effect = "fire_smoke" },
			["#Fire and Smoke Huge"] = { gas_thruster_effect = "fire_smoke_big" },
			["#5 Growing Rings"] = { gas_thruster_effect = "rings_grow_rings" },
			["#Color and Magic"] = { gas_thruster_effect = "color_magic" },
		}
	})
	
	panel:AddControl("Label", {
		Text = "#GasThrusterTool_Types", 
		Description = "Thruster Type" 
	})
	
		panel:AddControl("ComboBox", {
		Label = "#GasThrusterTool_Types",
		MenuButton = "0",

		Options = {
			["Energy Thruster"] = { gas_thruster_resource = "energy", gas_thruster_multiplier = 1.0 },
			["Oxygen Thruster"] = { gas_thruster_resource = "oxygen", gas_thruster_multiplier = 0.7 },
			["Hydrogen Thruster"] = { gas_thruster_resource = "hydrogen", gas_thruster_multiplier = 1.2},
			["Steam Thruster"] = { gas_thruster_resource = "steam", gas_thruster_multiplier = 0.5 },
			["Nitrogen Thruster"] = { gas_thruster_resource = "nitrogen", gas_thruster_multiplier = 0.7 },
			["Natural Gas Thruster"] = { gas_thruster_resource = "Natural Gas", gas_thruster_multiplier = 0.6 },
			["Methane Thruster"] = { gas_thruster_resource = "Methane", gas_thruster_multiplier = 1.1 },
			["Propane Thruster"] = { gas_thruster_resource = "Propane", gas_thruster_multiplier = 1.2 },
			["Deuterium Thruster"] = { gas_thruster_resource = "Deuterium", gas_thruster_multiplier = 1.5 },
			["Tritium Thruster"] = { gas_thruster_resource = "Tritium", gas_thruster_multiplier = 1.4 },
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
		Label = "#GasThrusterTool_massless",
		Command = "gas_thruster_massless"
	})
	
	panel:AddControl("Numpad", {
		Label = "#GasThrusterTool_key_fw",
		Label2 = "#GasThrusterTool_key_bw",
		Command = "gas_thruster_keygroup", 
		Command2 = "gas_thruster_keygroup_back", 
		ButtonSize = "22"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#GasThrusterTool_toggle",
		Command = "gas_thruster_toggle"
	})
end

list.Set( "ThrusterModels", "models/jaanus/thruster_flat.mdl", {} )
