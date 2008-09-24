CreateConVar( "GASSYS_TankExplosions", "1" )

AddCSLuaFile("GasAdmin/cl_Init.lua")

GasAdmin = {}

if(SERVER) then
	include("GasAdmin/sv_Init.lua")
else
	include("GasAdmin/cl_Init.lua")
end
