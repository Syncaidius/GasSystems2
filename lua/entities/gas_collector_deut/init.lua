AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
util.PrecacheSound( "Buttons.snd17" )

include('shared.lua')

function ENT:Initialize()
	self.Entity:SetModel("models/syncaidius/gas_collector.mdl")
	self:SetSkin(2)
	self.BaseClass.Initialize(self)

	local phys = self.Entity:GetPhysicsObject()
	self.damaged = 0
	self.Active = 0
	
	self:SetMaxHealth(150)
	self:SetHealth(self:GetMaxHealth())
	
	self.energy = 0
	self.gas = 0
	self.mute = 0
	
	--device multiplier (multiplys all consumption and production by this)
	self.multiply = 1 
	
	-- resource attributes
	self.prod = 7 --collection rate.
	self.econ = 11 -- Energy consumption
    
	CAF.GetAddon("Resource Distribution").AddResource(self,"energy",0)
	if WireLib then
		self.WireDebugName = self.PrintName
		self.Inputs = WireLib.CreateInputs(self, { "On", "Multiplier" })
		self.Outputs = WireLib.CreateOutputs(self, { "On", "Output"})
	else
		self.Inputs = {{Name="On"}}
	end
	
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(18)
	end
end

function ENT:Setup()
	self:TriggerInput("On", 0)
	self:TriggerInput("Multiplier",1)
end

function ENT:TriggerInput(iname, value)
	if (iname == "On") then
		if (value != 0) then
			if ( self.Active == 0 ) then
				self:TurnOn()
			end
		else
			if ( self.Active == 1 ) then
				self:TurnOff()
			end
		end
	end
	
	if (iname == "Multiplier") then
		if (value > 1) then
			self.multiply = value
			if (self.multiply > 5) then
				self.multiply = 5
			end
		else
			self.multiply = 1
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
	self.Entity:SetColor(255, 255, 255, 255)
	self:SetHealth(self:GetMaxHealth())
	self.damaged = 0
end

function ENT:TurnOn()
	self.Active = 1
	self:SetOOO(1)
	if WireLib then
		WireLib.TriggerOutput(self, "On", 1)
	end
	self.Entity:EmitSound( "Buttons.snd17" )
end

function ENT:TurnOff()
	self.Active = 0
	self:SetOOO(0)
	if WireLib then
		WireLib.TriggerOutput(self, "On", 0)
	end
	self.Entity:StopSound( "Buttons.snd17" )
end

function ENT:Destruct()
	CAF.GetAddon("Life Support").Destruct( self.Entity )
end

function ENT:Output()
	return 1
end

function ENT:CollectGas()
	self.gas = (self.prod + math.random(1,4)) * self.multiply
	self.energy = self.econ * self.multiply
    
	if ( self:CanRun() ) then
		self:ConsumeResource("energy", self.energy)
		self:SupplyResource("Deuterium",self.gas)
	else
		self:TurnOff()
	end
	
	if WireLib then
		WireLib.TriggerOutput(self, "Output", self.gas)
		WireLib.TriggerOutput(self, "On", self.Active)
	end
		
	return
end

function ENT:CanRun()
	local energy = self:GetResourceAmount("energy")
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
