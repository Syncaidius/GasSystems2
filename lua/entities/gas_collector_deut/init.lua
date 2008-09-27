AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
util.PrecacheSound( "Buttons.snd17" )

include('shared.lua')

if not (WireAddon == nil) then
    ENT.WireDebugName = "Deuterium Collector"
end

function ENT:Initialize()
	self.Entity:SetModel("models/syncaidius/gas_collector.mdl")
	self:SetSkin(2)
  self.BaseClass.Initialize(self)

   local phys = self.Entity:GetPhysicsObject()
	self.damaged = 0
	self.Active = 0
	
  self:SetMaxHealth(70)
  self:SetHealth(self:GetMaxHealth())
	self.disuse = 0 --use disabled via wire input
	
	self.energy = 0
	self.gas = 0
	
  -- resource attributes
  self.prod = 7 --collection rate.
  self.econ = 11 -- Energy consumption
    
	CAF.GetAddon("Resource Distribution").AddResource(self,"energy",0)
	if not (WireAddon == nil) then self.Inputs = Wire_CreateInputs(self.Entity, { "On"}) end
	if not (WireAddon == nil) then self.Outputs = Wire_CreateOutputs(self.Entity, { "On", "Output"}) end
	
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(18)
	end
end

function ENT:Setup()
	self:TriggerInput("On", 0)
end

function ENT:TriggerInput(iname, value)
	if (iname == "On") then
		if (value > 0) then
			if ( self.Active == 0 ) then
         self:TurnOn()
			end
		else
			if ( self.Active == 1 ) then
         self:TurnOff()
			end
		end
	end
end


function ENT:OnRemove()
    self.BaseClass.OnRemove(self)
    self.Entity:StopSound( "Buttons.snd17" )
end

function ENT:Damage()
	if (self.damaged == 0) then
		self.damaged = 1
	end
end

function ENT:Repair()
	self:SetHealth(self:GetMaxHealth())
	self.damaged = 0
end

function ENT:TurnOn()
  self.Active = 1
  self:SetOOO(1)
  if not (WireAddon == nil) then 
    Wire_TriggerOutput(self.Entity, "On", 1)
  end
  self.Entity:EmitSound( "Buttons.snd17" )
end

function ENT:TurnOff()
	self.Active = 0
	self:SetOOO(0)
	if not (WireAddon == nil) then
		Wire_TriggerOutput(self.Entity, "On", 0)
	end
	self.Entity:StopSound( "Buttons.snd17" )
end

function ENT:Destruct()
	local RD = CAF.GetAddon("Resource Distribution")
  CAF.GetAddon("Life Support").Destruct( self.Entity )
end

function ENT:Output()
	return 1
end

function ENT:CollectGas()
	local RD = CAF.GetAddon("Resource Distribution")
  self.gas = (self.prod + math.random(1,4))
  self.energy = self.econ
    
	if ( self:CanRun() ) then
		RD.ConsumeResource(self, "energy", self.energy)
			
		RD.SupplyResource(self.Entity,"Deuterium",self.gas)
	else
		self:TurnOff()
	end
	
	if not (WireAddon == nil) then
    Wire_TriggerOutput(self.Entity, "Output", self.gas)
		Wire_TriggerOutput(self.Entity, "On", self.active)
  end
		
	return
end

function ENT:CanRun()
	local RD = CAF.GetAddon("Resource Distribution")
	local energy = RD.GetResourceAmount(self, "energy")
	if (energy >= self.energy) then
			return true
	else
			return false
	end
end

function ENT:Think()
    self.BaseClass.Think(self)
    
	if ( self.Active == 1 ) then
		self:CollectGas()
	end
    
	self.Entity:NextThink( CurTime() + 1 )
	return true
end

function ENT:AcceptInput(name,activator,caller)
	if name == "Use" and caller:IsPlayer() and caller:KeyDownLast(IN_USE) == false then
		if ( self.Active == 0 ) then
			self:TurnOn()
		else
      self:TurnOff()
		end
	end
end

function ENT:PreEntityCopy()
    self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
    self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities )
end
