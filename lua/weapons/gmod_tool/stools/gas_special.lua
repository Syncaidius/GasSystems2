TOOL.Category   = "Gas Systems 2"  
TOOL.Name     = "#Specials"  
TOOL.Command    = nil  
TOOL.ConfigName   = "" 
if (CLIENT and GetConVarNumber("CAF_UseTab") == 1) then TOOL.Tab = "Custom Addon Framework" end

TOOL.ClientConVar["type"] = "gas_gravmodule"
TOOL.ClientConVar["model"] = "models/syncaidius/gas_extractor.mdl"

cleanup.Register('gassystem')

if ( CLIENT ) then
	language.Add( "Tool_gas_special_name", "Special Gas Devices" )
	language.Add( "Tool_gas_special_desc", "Spawns A Device for use with Gas Systems." )
	language.Add( "Tool_gas_special_0", "Left Click: Spawn A Device. Right Click: Repair A Device" )
	
	language.Add( "Undone_gas_special", "Gas Device Undone" )
	language.Add( "Cleanup_gas_special", "Gas Device" )
	language.Add( "Cleaned_gas_special", "Cleaned up all Special Gas Devices" )
	language.Add( "SBoxLimit_gas_special", "Maximum Special Gas Devices Reached" )
end

if not CAF or not CAF.GetAddon("Resource Distribution") then Error("Please Install Resource Distribution Addon.'" ) return end
if not CAF or not CAF.GetAddon("Life Support") then return end

if( SERVER ) then
	CreateConVar("sbox_maxgas_special", 15)
	
	function Makegas_special( ply, ang, pos, spctype, model, frozen )
		if ( !ply:CheckLimit( "gas_special" ) ) then return nil end
		
		--Create special
		local ent = ents.Create( spctype )
		
		-- Set
		ent:SetPos( pos )
		ent:SetAngles( ang )
		
		ent:Spawn()
		ent:Activate()
		
		ent:SetVar("Owner", ply)
		ent:SetPlayer(ply)
		
		ent.Class = gentype
		
		if (frozen) then
			local phys = ent:GetPhysicsObject()
			if (phys:IsValid()) then
				phys:EnableMotion( false ) 
				ply:AddFrozenPhysicsObject( ent, phys )
			end
		end
		
		ply:AddCount("gas_special", ent)
		
		return ent
	end
	
	duplicator.RegisterEntityClass("Natural Gas Extractor", Makegas_special, "Ang", "Pos", "Class", "model", "frozen")
	duplicator.RegisterEntityClass("Natural Gas (Oil) Extractor", Makegas_special, "Ang", "Pos", "Class", "model", "frozen")
	duplicator.RegisterEntityClass("Natural Gas Processor", Makegas_special, "Ang", "Pos", "Class", "model", "frozen")
end
if (GAMEMODE.Name == "SpaceBuild" || SpaceBuild) then MsgAll("You need the new Spacebuild (3) to use gas systems, you are using Spacebuild1!\n") end
if (GAMEMODE.Name == "SpaceBuild2" || SpaceBuild2) then MsgAll("You need the new Spacebuild(3) to use gas systems, you are using Spacebuild2!\n") end
local gas_spc_models = {
		{'Tokomak Gravity Module', 'models/syncaidius/gas_extractor.mdl', 'gas_gravmodule'},
		{'Tokomak Repair Module', "models/props_industrial/oil_storage.mdl", "gas_repmodule"},
		{'Gas Powered Terraformer', "models/syncaidius/tokomak.mdl", "gas_pterraformer"},
}
RD2_ToolRegister( TOOL, gas_spc_models, Makegas_special,"gas_special",15)
