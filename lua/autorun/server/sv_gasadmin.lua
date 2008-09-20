CreateConVar( "GASSYS_TankExplosions", "1" )
CreateConVar( "GASSYS_ForcePoweredThrusters", "1" )
CreateConVar( "GASSYS_ForcePoweredHoverballs", "1" )

local function gassys_thrusteroverride( userid, propid )
	if server_settings.Bool( "GASSYS_ForcePoweredThrusters" ) then
		local enttype = propid:GetClass()
		if (enttype == "gmod_thruster" or enttype == "gmod_wire_thruster") then
			propid:Remove()
			userid:ChatPrint("This Thruster Type Is Disabled. Use Powered Thrusters from Gas Systems Addon.")
			return false
		else
			return true
		end
	else
		return true
	end
end
hook.Add("PlayerSpawnedSENT","GASSYSthrusteroverride",gassys_thrusteroverride)  

local function gassys_hoverballoverride ( userid, classname )

end
hook.Add("PlayerSpawnedSENT","GASSYShoverballoverride",gassys_hoverballoverride)