CreateConVar( "GASSYS_TankExplosions", "1" )

AddCSLuaFile("autorun/sh_gasadmin.lua")
AddCSLuaFile("GasAdmin/cl_Init.lua")

if (!SERVER) then
	include("GasAdmin/cl_Init.lua")
end

GasAdmin = {}

