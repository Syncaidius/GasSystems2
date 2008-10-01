TOOL.Category   = "Gas Systems 2"  
TOOL.Name     = "#Generators"  
TOOL.Command    = nil  
TOOL.ConfigName   = "" 
if (CLIENT and GetConVarNumber("CAF_UseTab") == 1) then TOOL.Tab = "Custom Addon Framework" end

TOOL.ClientConVar["type"] = "gas_extractor"
TOOL.ClientConVar["model"] = "models/syncaidius/gas_extractor.mdl"

cleanup.Register('gassystem')

if ( CLIENT ) then
	language.Add( "Tool_gas_generator_name", "Gas Devices" )
	language.Add( "Tool_gas_generator_desc", "Spawns A Device for use with Gas Systems." )
	language.Add( "Tool_gas_generator_0", "Left Click: Spawn A Device. Right Click: Repair A Device" )
	
	language.Add( "Undone_gas_generator", "Gas Device Undone" )
	language.Add( "Cleanup_gas_generator", "Gas Device" )
	language.Add( "Cleaned_gas_generator", "Cleaned up all Gas Devices" )
	language.Add( "SBoxLimit_gas_generator", "Maximum Gas Devices Reached" )
end

if not CAF or not CAF.GetAddon("Resource Distribution") then Error("Please Install Resource Distribution Addon.'" ) return end
if not CAF or not CAF.GetAddon("Life Support") then return end

if( SERVER ) then
	CreateConVar("sbox_maxgas_generator", 24)
	
	function Makegas_generator( ply, ang, pos, gentype, model, frozen )
		if ( !ply:CheckLimit( "gas_generator" ) ) then return nil end
		
		--Create generator
		local ent = ents.Create( gentype )
		
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
		
		ply:AddCount("gas_generator", ent)
		
		return ent
	end
	
	duplicator.RegisterEntityClass("gas_extractor", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_processor", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_tokomak", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_stokomak", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_tritinverter", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_lpropreactor", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_spropreactor", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_collector_meth", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_collector_prop", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_collector_trit", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_collector_deut", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_lmethreactor", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_smethreactor", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_rehydrator", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")
	duplicator.RegisterEntityClass("gas_deutinverter", Makegas_generator, "Ang", "Pos", "gentype", "model", "frozen")

end
if (GAMEMODE.Name == "SpaceBuild" || SpaceBuild) then MsgAll("You need the new Spacebuild (3) to use gas systems, you are using Spacebuild1!\n") end
if (GAMEMODE.Name == "SpaceBuild2" || SpaceBuild2) then MsgAll("You need the new Spacebuild(3) to use gas systems, you are using Spacebuild2!\n") end
local gas_gen_models = {
	{'Natural Gas Extractor', 'models/syncaidius/gas_extractor.mdl', 'gas_extractor'},
	{"Natural Gas Processor", "models/syncaidius/gas_processor.mdl", "gas_processor"},
	{"Large Tokomak Reactor", "models/syncaidius/tokomak.mdl", "gas_tokomak"},
	{"Large Methane Reactor", "models/syncaidius/gas_lreactor.mdl", "gas_lmethreactor"},
	{"Large Propane Reactor", "models/syncaidius/gas_lreactor.mdl", "gas_lpropreactor"},
	{"Small Methane Reactor", "models/syncaidius/gas_sreactor.mdl", "gas_smethreactor"},
	{"Small Propane Reactor", "models/syncaidius/gas_sreactor.mdl", "gas_spropreactor"},
	{"Small Tokomak Reactor", "models/syncaidius/stokomak.mdl", "gas_stokomak"},
	{"Methane Collector", "models/syncaidius/gas_collector.mdl", "gas_collector_meth"},
	{"Propane Collector", "models/syncaidius/gas_collector.mdl", "gas_collector_prop"},
	{"Deuterium Collector", "models/syncaidius/gas_collector.mdl", "gas_collector_deut"},
	{"Tritium Collector", "models/syncaidius/gas_collector.mdl", "gas_collector_trit"},
	{"Tritium Inverter", "models/syncaidius/gas_inverter.mdl", "gas_tritinverter"},
	{"Deuterium Inverter", "models/syncaidius/gas_inverter.mdl", "gas_deutinverter"},
	{"Methane Rehydrator", "models/syncaidius/gas_inverter.mdl", "gas_rehydrator"},
}
RD2_ToolRegister( TOOL, gas_gen_models, Makegas_generator,"gas_generator",24)
