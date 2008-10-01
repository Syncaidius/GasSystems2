TOOL.Category   = "Gas Systems 2"  
TOOL.Name     = "#Storages"  
TOOL.Command    = nil  
TOOL.ConfigName   = "" 
if (CLIENT and GetConVarNumber("CAF_UseTab") == 1) then TOOL.Tab = "Custom Addon Framework" end

TOOL.ClientConVar["type"] = "gas_lstore"
TOOL.ClientConVar["model"] = "models/syncaidius/gas_tank_large.mdl"

cleanup.Register('gassystem')

if ( CLIENT ) then
	language.Add( "Tool_gas_storage_name", "Gas Storages" )
	language.Add( "Tool_gas_storage_desc", "Spawns A Storage for use with Gas Systems." )
	language.Add( "Tool_gas_storage_0", "Left Click: Spawn A Storage. Right Click: Repair A Storage" )
	
	language.Add( "Undone_gas_storage", "Gas Storage Undone" )
	language.Add( "Cleanup_gas_storage", "Gas Storage" )
	language.Add( "Cleaned_gas_storage", "Cleaned up all Gas Storages" )
	language.Add( "SBoxLimit_gas_storage", "Maximum Gas Storages Reached" )
end

if not CAF or not CAF.GetAddon("Resource Distribution") then Error("Please Install Resource Distribution Addon.'" ) return end
if not CAF or not CAF.GetAddon("Life Support") then return end

if( SERVER ) then
	CreateConVar("sbox_maxgas_storage", 24)
	
	function Makegas_storage( ply, ang, pos, stortype, model, frozen )
		if ( !ply:CheckLimit( "gas_storage" ) ) then return nil end
		
		--Create gas storage
		local ent = ents.Create( stortype )
		
		-- Set position and angle
		ent:SetPos( pos )
		ent:SetAngles( ang )
		
		ent:Spawn()
		ent:Activate()
		
		ent:SetVar("Owner", ply)
		ent:SetPlayer(ply)
		
		ent.Class = stortype
		
		if (frozen) then
			local phys = ent:GetPhysicsObject()
			if (phys:IsValid()) then
				phys:EnableMotion( false ) 
				ply:AddFrozenPhysicsObject( ent, phys )
			end
		end
		
		ply:AddCount("gas_storage", ent)
		
		return ent
	end
	
	duplicator.RegisterEntityClass("gas_hstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_lstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_sstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_lproctank", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_mproctank", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_sproctank", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_hmethstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_lmethstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_smethstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_hpropstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_lpropstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_spropstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_hdetstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_ldetstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_sdetstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_htritstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_ltritstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_stritstore", Makegas_storage, "Ang", "Pos", "stortype", "model", "frozen")
end

if (GAMEMODE.Name == "SpaceBuild" || SpaceBuild) then MsgAll("You need the new Spacebuild (3) to use gas systems, you are using Spacebuild1!\n") end
if (GAMEMODE.Name == "SpaceBuild2" || SpaceBuild2) then MsgAll("You need the new Spacebuild(3) to use gas systems, you are using Spacebuild2!\n") end
local gas_stor_models = {
		{ "#Large Natural Gas Tank", "models/syncaidius/gas_tank_huge.mdl", "gas_hstore" },
		{ "#Medium Natural Gas Tank", "models/syncaidius/gas_tank_large.mdl", "gas_lstore" },
		{ "#Small Natural Gas Tank", "models/syncaidius/gas_tank_small.mdl", "gas_sstore" },
		{ "#Large Processed Gas Tank", "models/syncaidius/lprocstore.mdl", "gas_lproctank" },
    { "#Medium Processed Gas Tank", "models/syncaidius/mprocstore.mdl", "gas_mproctank" },
		{ "#Small Processed Gas Tank", "models/syncaidius/sprocstore.mdl", "gas_sproctank" },
		{ "#Large Methane Tank", "models/syncaidius/gas_tank_huge.mdl", "gas_hmethstore" },
		{ "#Medium Methane Tank", "models/syncaidius/gas_tank_large.mdl", "gas_lmethstore" },
		{ "#Small Methane Tank", "models/syncaidius/gas_tank_small.mdl", "gas_smethstore" },
		{ "#Large Propane Tank", "models/syncaidius/gas_tank_huge.mdl", "gas_hpropstore" },
		{ "#Medium Propane Tank", "models/syncaidius/gas_tank_large.mdl", "gas_lpropstore" },
		{ "#Small Propane Tank", "models/syncaidius/gas_tank_small.mdl", "gas_spropstore" },
		{ "#Large Deuterium Tank", "models/syncaidius/gas_tank_huge.mdl", "gas_hdetstore" },
		{ "#Medium Deuterium Tank", "models/syncaidius/gas_tank_large.mdl", "gas_ldetstore" },
		{ "#Small Deuterium Tank", "models/syncaidius/gas_tank_small.mdl", "gas_sdetstore" },
		{ "#Large Tritium Tank", "models/syncaidius/gas_tank_huge.mdl", "gas_htritstore" },
		{ "#Medium Tritium Tank", "models/syncaidius/gas_tank_large.mdl", "gas_ltritstore" },
		{ "#Small Tritium Tank", "models/syncaidius/gas_tank_small.mdl", "gas_stritstore" }
}
RD2_ToolRegister( TOOL, gas_stor_models, Makegas_storage,"gas_storage",24)
