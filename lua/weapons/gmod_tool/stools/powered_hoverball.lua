TOOL.Category		= "Gas Systems 2"
TOOL.Name			= "#Powered Hoverball"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if (CLIENT and GetConVarNumber("CAF_UseTab") == 1) then TOOL.Tab = "Custom Addon Framework" end

if ( CLIENT ) then
  language.Add( "Tool_powered_hoverball_name", "Powered Hoverball Tool" )
  language.Add( "Tool_powered_hoverball_desc", "Spawns a powered hoverball for use life support." )
  language.Add( "Tool_powered_hoverball_0", "Primary: Create/Update Hoverball" )
	language.Add( "PoweredHoverballTool_Types", "Hoverball Type: " )
  language.Add( "PoweredHoverballTool_starton", "Create with hover mode on:" )
	language.Add( "undone_poweredhoverball", "Undone Powered Hoverball" )
	language.Add( "sboxlimit_powered_hoverballs", "You've hit powered hover balls limit!" )
end

if (SERVER) then
  CreateConVar('sbox_maxgas_poweredhoverballs', 10)
end 

TOOL.ClientConVar[ "speed" ] = "1"
TOOL.ClientConVar[ "resistance" ] = "0"
TOOL.ClientConVar[ "strength" ] = "1"
TOOL.ClientConVar[ "starton" ] = "1"
TOOL.ClientConVar[ "resource" ] = "energy"
TOOL.ClientConVar[ "multiplier" ] = "1.0"

cleanup.Register( "powered_hoverballs" )

function TOOL:LeftClick( trace )

	if ( trace.Entity && trace.Entity:IsPlayer() ) then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	
	if (CLIENT) then return true end
	
	local ply = self:GetOwner()
	
	local speed 		= self:GetClientNumber( "speed" ) 
	local resistance 	= self:GetClientNumber( "resistance" ) 
	local strength	 	= self:GetClientNumber( "strength" ) 
	local starton	 	= self:GetClientNumber( "starton" ) == 1
	local resource = self:GetClientInfo( "resource" )
	local multiplier = self:GetClientNumber( "multiplier" )
	
	resistance 	= math.Clamp( resistance, 0, 20 )
	strength	= math.Clamp( strength, 0.1, 20 )
	
	// We shot an existing hoverball - just change its values
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gas_hoverball" && trace.Entity:GetTable().pl == ply ) then
	
		trace.Entity:GetTable():SetSpeed( speed )
		trace.Entity:GetTable():SetAirResistance( resistance )
		trace.Entity:GetTable():SetStrength( strength )
		
		trace.Entity:GetTable().speed		= speed
		trace.Entity:GetTable().strength	= strength
		trace.Entity:GetTable().resistance	= resistance
		
		if (!starton) then trace.Entity:GetTable():DisableHover() else trace.Entity:GetTable():EnableHover() end
	
		return true
	
	end
	
	if ( !self:GetSWEP():CheckLimit( "powered_hoverballs" ) ) then return false end
	
	// If we hit the world then offset the spawn position
	if ( trace.Entity:IsWorld() ) then
		trace.HitPos = trace.HitPos + trace.HitNormal * 8
	end

	local powered_ball = MakePoweredHoverBall( ply, trace.HitPos, speed, resistance, strength, resource, multiplier )
	
	local const = WireLib.Weld(powered_ball, trace.Entity, trace.PhysicsBone, true)
	
	local nocollide
	if ( !trace.Entity:IsWorld() ) then
		nocollide = constraint.NoCollide( trace.Entity, powered_ball, 0, trace.PhysicsBone )
	end
	
	if (!starton) then powered_ball:GetTable():DisableHover() end
	
	undo.Create("PoweredHoverBall")
		undo.AddEntity( powered_ball )
		undo.AddEntity( const )
		undo.AddEntity( nocollide )
		undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "powered_hoverballs", powered_ball )
	ply:AddCleanup( "powered_hoverballs", const )
	ply:AddCleanup( "powered_hoverballs", nocollide )
	
	return true

end

if (SERVER) then

	function MakePoweredHoverBall( ply, Pos, speed, resistance, strength, Vel, aVel, frozen, nocollide, resource, multiplier )
	
		if ( !ply:CheckLimit( "powered_hoverballs" ) ) then return nil end
	
		local powered_ball = ents.Create( "gas_hoverball" )
		if (!powered_ball:IsValid()) then return false end

		powered_ball:SetPos( Pos )
		powered_ball:Spawn()
		powered_ball:SetSpeed( speed )
		powered_ball:SetPlayer( ply )
		powered_ball:SetAirResistance( resistance )
		powered_ball:SetStrength( strength )

		local ttable = 
		{
			pl	= ply,
			nocollide = nocollide,
			speed = speed,
			strength = strength,
			resistance = resistance,
			resource  = resource,
			multiplier = multiplier
		}
		table.Merge( powered_ball:GetTable(), ttable )
		
		ply:AddCount( "powered_hoverballs", powered_ball )
		
		return powered_ball
		
	end
	
	duplicator.RegisterEntityClass("gas_hoverball", MakePoweredHoverBall, "Pos", "speed", "resistance", "strength", "Vel", "aVel", "frozen", "nocollide", "resource", "multiplier")

end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_powered_hoverball_name", Description = "#Tool_powered_hoverball_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "powered_hoverball",

		Options = {
			Default = {
				powered_hoverball_speed = "1",
				powered_hoverball_resistance = "0",
				powered_hoverball_strength = "1",
				powered_hoverball_starton = "1"
			}
		},

		CVars = {
			[0] = "powered_hoverball_speed",
			[1] = "powered_hoverball_strength",
			[2] = "powered_hoverball_resistance",
			[3] = "powered_hoverball_starton"
		}
	})
	
		panel:AddControl("Label", {
		Text = "#PoweredHoverballTool_Types", 
		Description = "Hoverball Type" 
	})
	
		panel:AddControl("ComboBox", {
		Label = "#PoweredHoverballTool_Types",
		MenuButton = "0",

		Options = {
			["Energy Hoverball"] = { powered_hoverball_resource = "energy", powered_hoverball_multiplier = 1.0 },
			["Oxygen Hoverball"] = { powered_hoverball_resource = "oxygen", powered_hoverball_multiplier = 0.7 },
			["Nitrogen Hoverball"] = { powered_hoverball_resource = "nitrogen", powered_hoverball_multiplier = 0.7 },
			["Hydrogen Hoverball"] = { powered_hoverball_resource = "hydrogen", powered_hoverball_multiplier = 1.2},
			["Steam Hoverball"] = { powered_hoverball_resource = "steam", powered_hoverball_multiplier = 0.5 },
			["Natural Gas Hoverball"] = { powered_hoverball_resource = "Natural Gas", powered_hoverball_multiplier = 0.6 },
			["Methane Hoverball"] = { powered_hoverball_resource = "Methane", powered_hoverball_multiplier = 1.1 },
			["Propane Hoverball"] = { powered_hoverball_resource = "Propane", powered_hoverball_multiplier = 1.2 },
			["Deuterium Hoverball"] = { powered_hoverball_resource = "Deuterium", powered_hoverball_multiplier = 1.5 },
			["Tritium Hoverball"] = { powered_hoverball_resource = "Tritium", powered_hoverball_multiplier = 1.4 },
		}
	})

	panel:AddControl("Slider", {
		Label = "#Movement Speed",
		Type = "Float",
		Min = "1",
		Max = "10",
		Command = "powered_hoverball_speed"
	})
	
	panel:AddControl("Slider", {
		Label = "#Air Resistance",
		Type = "Float",
		Min = "1",
		Max = "10",
		Command = "powered_hoverball_resistance"
	})
	
	panel:AddControl("Slider", {
		Label = "#Strength",
		Type = "Float",
		Min = "0.1",
		Max = "10",
		Command = "powered_hoverball_strength"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#PoweredHoverballTool_starton",
		Command = "powered_hoverball_starton"
	})

end
