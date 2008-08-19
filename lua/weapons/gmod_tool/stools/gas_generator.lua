TOOL.Category   = "Gas Systems 2"  
TOOL.Name     = "#Generators"  
TOOL.Command    = nil  
TOOL.ConfigName   = "" 
if (CLIENT and GetConVarNumber("CAF_UseTab") == 1) then TOOL.Tab = "Custom Addon Framework" end

TOOL.ClientConVar["type"] = "gas_extractor"
TOOL.ClientConVar["model"] = "models/props/cs_assault/firehydrant.mdl"

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
	CreateConVar("sbox_maxgas_generator", 20)
	
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
	
	duplicator.RegisterEntityClass("Natural Gas Extractor", Makegas_generator, "Ang", "Pos", "Class", "model", "frozen")
	duplicator.RegisterEntityClass("Natural Gas (Oil) Extractor", Makegas_generator, "Ang", "Pos", "Class", "model", "frozen")
	duplicator.RegisterEntityClass("Natural Gas Processor", Makegas_generator, "Ang", "Pos", "Class", "model", "frozen")
	duplicator.RegisterEntityClass("Nitrogen Oxidizer", Makegas_generator, "Ang", "Pos", "Class", "model", "frozen")
	duplicator.RegisterEntityClass("Nitrogen Liquidizer", Makegas_generator, "Ang", "Pos", "Class", "model", "frozen")
	duplicator.RegisterEntityClass("Nitrogen Inverter", Makegas_generator, "Ang", "Pos", "Class", "model", "frozen")
	duplicator.RegisterEntityClass("Large Gas Reactor", Makegas_generator, "Ang", "Pos", "Class", "model", "frozen")
	duplicator.RegisterEntityClass("Micro Gas Reactor", Makegas_generator, "Ang", "Pos", "Class", "model", "frozen")
	duplicator.RegisterEntityClass("Methane Collector", Makegas_generator, "Ang", "Pos", "Class", "model", "frozen")
	duplicator.RegisterEntityClass("Propane Collector", Makegas_generator, "Ang", "Pos", "Class", "model", "frozen")
	duplicator.RegisterEntityClass("Nitrogen Collector", Makegas_generator, "Ang", "Pos", "Class", "model", "frozen")
end
if (GAMEMODE.Name == "SpaceBuild" || SpaceBuild) then MsgAll("You need the new Spacebuild (3) to use gas systems, you are using Spacebuild1!\n") end
if (GAMEMODE.Name == "SpaceBuild2" || SpaceBuild2) then MsgAll("You need the new Spacebuild(3) to use gas systems, you are using Spacebuild2!\n") end
local gas_gen_models = {
		{'Natural Gas Extractor', 'models/props/cs_assault/firehydrant.mdl', 'gas_extractor'},
		{"Natural Gas Processor", "models/props_industrial/oil_storage.mdl", "gas_processor"},
		{"Large Tokomak Reactor", "models/syncaidius/tokomak.mdl", "gas_tokomak"},
		{"Large Methane Reactor", "models/props_citizen_tech/steamengine001a.mdl", "gas_methreactor"},
		{"Large Propane Reactor", "models/props_citizen_tech/steamengine001a.mdl", "gas_propreactor"},
		{"Small Methane Reactor", "models/syncaidius/microreactor.mdl", "gas_smethreactor"},
		{"Small Propane Reactor", "models//props_combine/headcrabcannister01a.mdl", "gas_spropreactor"},
		{"Small Tokomak Reactor", "models/syncaidius/stokomak.mdl", "gas_stokomak"},
		{"Methane Collector", "models/props_c17/light_decklight01_off.mdl", "methane_collector"},
		{"Propane Collector", "models/props_c17/light_decklight01_off.mdl", "propane_collector"},
		{"Nitrogen Collector", "models/props_c17/light_decklight01_off.mdl", "nitrogen_collector"},
		{"Hydrogen Splitter", "models/props_c17/light_decklight01_off.mdl", "gas_h2osplitter"},
		{"Oxygen Materializer", "models/props_c17/light_decklight01_off.mdl", "gas_o2materializer"},
}
RD2_ToolRegister( TOOL, gas_gen_models, Makegas_generator,"gas_generator",20)
