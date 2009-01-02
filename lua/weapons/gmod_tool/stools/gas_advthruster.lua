
TOOL.Category		= "Gas Systems 2"
TOOL.Name			= "#Adv. Powered Thruster"
TOOL.ConfigName		= ""

if (CLIENT and GetConVarNumber("CAF_UseTab") == 1) then TOOL.Tab = "Custom Addon Framework" end

if ( CLIENT ) then
    language.Add( "Tool_gas_advthruster_name", "Gas Thruster Tool" )
    language.Add( "Tool_gas_advthruster_desc", "Spawns a resource consuming thruster." )
    language.Add( "Tool_gas_advthruster_0", "Primary: Create/Update Thruster" )
    language.Add( "AdvGasThrusterTool_Model", "Model:" )
    language.Add( "AdvGasThrusterTool_Effects", "Effects:" )
		language.Add( "AdvGasThrusterTool_Types", "Thruster Type:")
		language.Add( "AdvGasThrusterTool_Energy", "Energy Consumption:")
		language.Add( "AdvGasThrusterTool_Oxygen", "Oxygen Consumption:")
		language.Add( "AdvGasThrusterTool_Nitrogen", "Nitrogen Consumption:")
		language.Add( "AdvGasThrusterTool_Hydrogen", "Hydrogen Consumption:")
		language.Add( "AdvGasThrusterTool_Steam", "Steam Consumption:")
		language.Add( "AdvGasThrusterTool_Ngas", "Natural Gas Consumption:")
		language.Add( "AdvGasThrusterTool_Methane", "Methane Consumption:")
		language.Add( "AdvGasThrusterTool_Propane", "Propane Consumption:")
		language.Add( "AdvGasThrusterTool_Deuterium", "Deuterium Consumption:")
		language.Add( "AdvGasThrusterTool_Tritium", "Tritium Consumption:")
    language.Add( "AdvGasThrusterTool_bidir", "Bi-directional:" )
    language.Add( "AdvGasThrusterTool_collision", "Collision:" )
    language.Add( "AdvGasThrusterTool_sound", "Enable sound:" )
		language.Add( "AdvGasThrusterTool_massless", "Massless:" )
		language.Add( "AdvGasThrusterTool_key_fw", "Positive Thrust: " )
		language.Add( "AdvGasThrusterTool_key_bw", "Negative Thrust: " )
		language.Add( "AdvGasThrusterTool_toggle", "Toggle" )
	language.Add( "sboxlimit_gas_advthrusters", "You've hit the Powered thrusters limit!" )
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
TOOL.ClientConVar[ "energy" ] = "0"
TOOL.ClientConVar[ "oxygen" ] = "0"
TOOL.ClientConVar[ "nitrogen" ] = "0"
TOOL.ClientConVar[ "hydrogen" ] = "0"
TOOL.ClientConVar[ "steam" ] = "0"
TOOL.ClientConVar[ "ngas" ] = "0"
TOOL.ClientConVar[ "methane" ] = "0"
TOOL.ClientConVar[ "propane" ] = "0"
TOOL.ClientConVar[ "deuterium" ] = "0"
TOOL.ClientConVar[ "tritium" ] = "0"

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
	local key = self:GetClientNumber( "keygroup" )
	local key_bk = self:GetClientNumber( "keygroup_back" )
	local toggle = (self:GetClientNumber( "toggle" ) ~=0)
	local energy = self:GetClientNumber( "energy" )
	local oxygen = self:GetClientNumber( "oxygen" )
	local nitrogen = self:GetClientNumber( "nitrogen" )
	local hydrogen = self:GetClientNumber( "hydrogen" )
	local steam = self:GetClientNumber( "steam" )
	local ngas = self:GetClientNumber( "ngas" )
	local methane = self:GetClientNumber( "methane" )
	local propane = self:GetClientNumber( "propane" )
	local deuterium = self:GetClientNumber( "deuterium" )
	local tritium = self:GetClientNumber( "tritium" )
	
	if ( !trace.Entity:IsValid() ) then nocollide = false end
	
	// If we shot a gas_thruster change its force
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gas_advthruster" && trace.Entity.pl == ply ) then
		trace.Entity:SetEffect( effect )
		trace.Entity:Setup(effect, bidir, sound, massless, toggle, energy, oxygen, nitrogen, hydrogen, steam, ngas, methane, propane, deuterium, tritium)
		
		trace.Entity.bidir		= bidir
		trace.Entity.sound		= sound
		trace.Entity.effect	= effect
		trace.Entity.nocollide	= nocollide
		trace.Entity.resource = resource
		trace.Entity.multiplier = multiplier
		trace.Entity.toggle = toggle
		trace.Entity.energy = energy
		trace.Entity.oxygen = oxygen
		trace.Entity.nitrogen = nitrogen
		trace.Entity.hydrogen = hydrogen
		trace.Entity.steam = steam
		trace.Entity.ngas = ngas
		trace.Entity.methane = methane
		trace.Entity.propane = propane
		trace.Entity.deuterium = deuterium
		trace.Entity.tritium = tritium
		
		if ( nocollide == true ) then trace.Entity:GetPhysicsObject():EnableCollisions( false ) end
		
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "gas_thrusters" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	gas_thruster = MakeAdvGasThruster( ply, model, Ang, trace.HitPos, effect, bidir, sound, nocollide, nil, nil, nil, massless, key, key_bk, toggle, energy, oxygen, nitrogen, hydrogen, steam, ngas, methane, propane, deuterium, tritium )
	
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
	function MakeAdvGasThruster( pl, Model, Ang, Pos, effect, bidir, sound, nocollide, Vel, aVel, frozen, massless, key, key_bk, toggle, energy, oxygen, nitrogen, hydrogen, steam, ngas, methane, propane, deuterium, tritium )
		if ( !pl:CheckLimit( "gas_thrusters" ) ) then return false end
		
		local gas_thruster = ents.Create( "gas_advthruster" )
		if (!gas_thruster:IsValid()) then return false end
		gas_thruster:SetModel( Model )
		
		gas_thruster:SetAngles( Ang )
		gas_thruster:SetPos( Pos )
		gas_thruster:Spawn()
		
		gas_thruster:Setup(effect, bidir, sound, massless, toggle, energy, oxygen, nitrogen, hydrogen, steam, ngas, methane, propane, deuterium, tritium)
		gas_thruster:SetPlayer( pl )
		
		if ( nocollide == true ) then gas_thruster:GetPhysicsObject():EnableCollisions( false ) end
		
		local ttable = {
			bidir       = bidir,
			sound       = sound,
			pl			= pl,
			effect	= effect,
			nocollide	= nocollide,
			massless = massless,
			resource = resource,
			key = key,
			key_bk = key_bk,
			toggle = toggle
			}
		
		table.Merge(gas_thruster:GetTable(), ttable )
		
		pl:AddCount( "gas_thrusters", gas_thruster )
		
		numpad.OnDown(pl, key, "gas_advthruster_on", gas_thruster, 1)
		numpad.OnUp(pl, key, "gas_advthruster_off", gas_thruster, 1)

		numpad.OnDown(pl, key_bk, "gas_advthruster_on", gas_thruster, -1)
		numpad.OnUp(pl, key_bk, "gas_advthruster_off", gas_thruster, -1)
		
		return gas_thruster
	end
	duplicator.RegisterEntityClass("gas_advthruster", MakeAdvGasThruster,"Model","Ang","Pos","effect","bidir","sound","nocollide","Vel","aVel","frozen","massless","key","key_bk","toggle","energy","oxygen","nitrogen","hydrogen","steam","ngas","methane","propane","deuterium","tritium")
end

function TOOL:UpdateGhostGasThruster( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	if (trace.Entity && trace.Entity:GetClass() == "gas_advthruster" || trace.Entity:IsPlayer()) then
	
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
	panel:AddControl("Header", { Text = "#Tool_gas_advthruster_name", Description = "#Tool_gas_advthruster_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "gas_advthruster",

		Options = {
			Default = {
				gas_advthruster_force = "20",
				gas_advthruster_model = "models/props_junk/plasticbucket001a.mdl",
				gas_advthruster_effect = "fire",
			}
		},

		CVars = {
			[0] = "gas_advthruster_model",
			[1] = "gas_advthruster_force",
			[2] = "gas_advthruster_effect"
		}
	})

	/*panel:AddControl("ComboBox", {
		Label = "#AdvGasThrusterTool_Model",
		MenuButton = "0",

		Options = {
			["#Thruster"]				= { gas_advthruster_model = "models/dav0r/thruster.mdl" },
			["#Paint_Bucket"]			= { gas_advthruster_model = "models/props_junk/plasticbucket001a.mdl" },
			["#Small_Propane_Canister"]	= { gas_advthruster_model = "models/props_junk/PropaneCanister001a.mdl" },
			["#Medium_Propane_Tank"]	= { gas_advthruster_model = "models/props_junk/propane_tank001a.mdl" },
			["#Cola_Can"]				= { gas_advthruster_model = "models/props_junk/PopCan01a.mdl" },
			["#Bucket"]					= { gas_advthruster_model = "models/props_junk/MetalBucket01a.mdl" },
			["#Vitamin_Jar"]			= { gas_advthruster_model = "models/props_lab/jar01a.mdl" },
			["#Lamp_Shade"]				= { gas_advthruster_model = "models/props_c17/lampShade001a.mdl" },
			["#Fat_Can"]				= { gas_advthruster_model = "models/props_c17/canister_propane01a.mdl" },
			["#Black_Canister"]			= { gas_advthruster_model = "models/props_c17/canister01a.mdl" },
			["#Red_Canister"]			= { gas_advthruster_model = "models/props_c17/canister02a.mdl" }
		}
	})*/
	
	panel:AddControl( "PropSelect", {
		Label = "#AdvGasThrusterTool_Model",
		ConVar = "gas_advthruster_model",
		Category = "Thrusters",
		Models = list.Get( "ThrusterModels" )
	})
	
	panel:AddControl("Label", {
		Text = "#AdvGasThrusterTool_Effects", 
		Description = "Thruster Effect" 
	})
	
	panel:AddControl("ComboBox", {
		Label = "#AdvGasThrusterTool_Effects",
		MenuButton = "0",

		Options = {
			["#No_Effects"] = { gas_advthruster_effect = "none" },
			["#Flames"] = { gas_advthruster_effect = "fire" },
			["#Plasma"] = { gas_advthruster_effect = "plasma" },
			["#Smoke"] = { gas_advthruster_effect = "smoke" },
			["#Smoke Random"] = { gas_advthruster_effect = "smoke_random" },
			["#Smoke Do it Youself"] = { gas_advthruster_effect = "smoke_diy" },
			["#Rings"] = { gas_advthruster_effect = "rings" },
			["#Rings Growing"] = { gas_advthruster_effect = "rings_grow" },
			["#Rings Shrinking"] = { gas_advthruster_effect = "rings_shrink" },
			["#Bubbles"] = { gas_advthruster_effect = "bubble" },
			["#Magic"] = { gas_advthruster_effect = "magic" },
			["#Magic Random"] = { gas_advthruster_effect = "magic_color" },
			["#Magic Do It Yourself"] = { gas_advthruster_effect = "magic_diy" },
			["#Colors"] = { gas_advthruster_effect = "color" },
			["#Colors Random"] = { gas_advthruster_effect = "color_random" },
			["#Colors Do It Yourself"] = { gas_advthruster_effect = "color_diy" },
			["#Blood"] = { gas_advthruster_effect = "blood" },
			["#Money"] = { gas_advthruster_effect = "money" },
			["#Sperms"] = { gas_advthruster_effect = "sperm" },
			["#Feathers"] = { gas_advthruster_effect = "feather" },
			["#Candy Cane"] = { gas_advthruster_effect = "candy_cane" },
			["#Goldstar"] = { gas_advthruster_effect = "goldstar" },
			["#Water Small"] = { gas_advthruster_effect = "water_small" },
			["#Water Medium"] = { gas_advthruster_effect = "water_medium" },
			["#Water Big"] = { gas_advthruster_effect = "water_big" },
			["#Water Huge"] = { gas_advthruster_effect = "water_huge" },
			["#Striderblood Small"] = { gas_advthruster_effect = "striderblood_small" },
			["#Striderblood Medium"] = { gas_advthruster_effect = "striderblood_medium" },
			["#Striderblood Big"] = { gas_advthruster_effect = "striderblood_big" },
			["#Striderblood Huge"] = { gas_advthruster_effect = "striderblood_huge" },
			["#More Sparks"] = { gas_advthruster_effect = "more_sparks" },
			["#Spark Fountain"] = { gas_advthruster_effect = "spark_fountain" },
			["#Jetflame"] = { gas_advthruster_effect = "jetflame" },
			["#Jetflame Advanced"] = { gas_advthruster_effect = "jetflame_advanced" },
			["#Jetflame Blue"] = { gas_advthruster_effect = "jetflame_blue" },
			["#Jetflame Red"] = { gas_advthruster_effect = "jetflame_red" },
			["#Jetflame Purple"] = { gas_advthruster_effect = "jetflame_purple" },
			["#Comic Balls"] = { gas_advthruster_effect = "balls" },
			["#Comic Balls Random"] = { gas_advthruster_effect = "balls_random" },
			["#Comic Balls Fire Colors"] = { gas_advthruster_effect = "balls_firecolors" },
			["#Souls"] = { gas_advthruster_effect = "souls" },
			["#Debugger 10 Seconds"] = { gas_advthruster_effect = "debug_10" },
			["#Debugger 30 Seconds"] = { gas_advthruster_effect = "debug_30" },
			["#Debugger 60 Seconds"] = { gas_advthruster_effect = "debug_60" },
			["#Fire and Smoke"] = { gas_advthruster_effect = "fire_smoke" },
			["#Fire and Smoke Huge"] = { gas_advthruster_effect = "fire_smoke_big" },
			["#5 Growing Rings"] = { gas_advthruster_effect = "rings_grow_rings" },
			["#Color and Magic"] = { gas_advthruster_effect = "color_magic" },
		}
	})

	panel:AddControl("Slider", {
		Label = "#AdvGasThrusterTool_Energy",
		Type = "Float",
		Min = "0",
		Max = "2000",
		Command = "gas_advthruster_energy"
	})

	panel:AddControl("Slider", {
		Label = "#AdvGasThrusterTool_Oxygen",
		Type = "Float",
		Min = "0",
		Max = "2000",
		Command = "gas_advthruster_oxygen"
	})

	panel:AddControl("Slider", {
		Label = "#AdvGasThrusterTool_Nitrogen",
		Type = "Float",
		Min = "0",
		Max = "2000",
		Command = "gas_advthruster_nitrogen"
	})
	
	panel:AddControl("Slider", {
		Label = "#AdvGasThrusterTool_Hydrogen",
		Type = "Float",
		Min = "0",
		Max = "2000",
		Command = "gas_advthruster_hydrogen"
	})
	
	panel:AddControl("Slider", {
		Label = "#AdvGasThrusterTool_Steam",
		Type = "Float",
		Min = "0",
		Max = "2000",
		Command = "gas_advthruster_steam"
	})
	
	panel:AddControl("Slider", {
		Label = "#AdvGasThrusterTool_Ngas",
		Type = "Float",
		Min = "0",
		Max = "2000",
		Command = "gas_advthruster_ngas"
	})
	
	panel:AddControl("Slider", {
		Label = "#AdvGasThrusterTool_Methane",
		Type = "Float",
		Min = "0",
		Max = "2000",
		Command = "gas_advthruster_methane"
	})
	
	panel:AddControl("Slider", {
		Label = "#AdvGasThrusterTool_Propane",
		Type = "Float",
		Min = "0",
		Max = "2000",
		Command = "gas_advthruster_propane"
	})
	
	panel:AddControl("Slider", {
		Label = "#AdvGasThrusterTool_Deuterium",
		Type = "Float",
		Min = "0",
		Max = "2000",
		Command = "gas_advthruster_deuterium"
	})
	
	panel:AddControl("Slider", {
		Label = "#AdvGasThrusterTool_Tritium",
		Type = "Float",
		Min = "0",
		Max = "2000",
		Command = "gas_advthruster_tritium"
	})

	panel:AddControl("CheckBox", {
		Label = "#AdvGasThrusterTool_bidir",
		Command = "gas_advthruster_bidir"
	})

	panel:AddControl("CheckBox", {
		Label = "#AdvGasThrusterTool_collision",
		Command = "gas_advthruster_collision"
	})

	panel:AddControl("CheckBox", {
		Label = "#AdvGasThrusterTool_sound",
		Command = "gas_advthruster_sound"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#AdvGasThrusterTool_massless",
		Command = "gas_advthruster_massless"
	})
	
	panel:AddControl("Numpad", {
		Label = "#AdvGasThrusterTool_key_fw",
		Label2 = "#AdvGasThrusterTool_key_bw",
		Command = "gas_advthruster_keygroup", 
		Command2 = "gas_advthruster_keygroup_back", 
		ButtonSize = "22"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#AdvGasThrusterTool_toggle",
		Command = "gas_advthruster_toggle"
	})
end

list.Set( "ThrusterModels", "models/jaanus/thruster_flat.mdl", {} )
