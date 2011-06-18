AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
util.PrecacheSound( "apc_engine_start" )
util.PrecacheSound( "apc_engine_stop" )
util.PrecacheSound( "common/warning.wav" )

include('shared.lua')

function ENT:Initialize()
	self.Entity:SetModel( "models/syncaidius/gas_processor.mdl" )
	self.BaseClass.Initialize(self)
	
    local phys = self.Entity:GetPhysicsObject()
	self.damaged = 0
	self.overdrive = 0
	self.overdrivefactor = 0
	self.maxoverdrive = 4 -- maximum overdrive value allowed via wire input. Anything over this value may severely damage or destroy the device.
	self.Active = 0
	self.maxhealth = 250
	self.health = self.maxhealth
	
	self.energy = 0
	self.ngas = 0
	self.deuterium = 0
	self.tritium = 0
	self.methane = 0
	self.propane = 0
	
	self.mute = 0
	self.multiply = 1
	
    -- resource attributes
	self.ngascon = 80 --N-Gas production
	self.econ = 30 -- Energy consumption
	self.deutprod = 30 -- Deuterium Production
	self.tritprod = 25 -- Tritium Production
	self.methprod = 25 -- methane production
	self.propprod = 30 -- propane production
    
	local RD = CAF.GetAddon("Resource Distribution")
	RD.AddResource(self,"energy",0)
	RD.AddResource(self,"Natural Gas",0)
	
	if WireLib then
		self.WireDebugName = self.PrintName
		self.Inputs = WireLib.CreateInputs(self, { "On", "Overdrive", "Mute", "Multiplier" })
		self.Outputs = WireLib.CreateOutputs(self, { "On", "Overdrive", "Energy Consumption"}) 
	end
	
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(80)
	end
end

function ENT:Setup()
	self.Entity:SetColor(255, 255, 255, 255)
	self:TriggerInput("On", 0)
	self:TriggerInput("Overdrive", 0)
end

function ENT:TriggerInput(iname, value)
	if (iname == "On") then
		if (value > 0) then
			if ( self.Active == 0 ) then
				self:TurnOn()
				if (self.overdrive == 1) then
					self:OverdriveOn()
				end
			end
		else
			if ( self.Active == 1 ) then
                self:TurnOff()
				if self.overdrive>0 then
					self:OverdriveOff()
				end
			end
		end
	elseif (iname == "Overdrive") then
		if (self.Active == 1) then
			if (value > 0) then
				self:OverdriveOn()
				self.overdrivefactor = value
			else
				self:OverdriveOff()
			end
		end
	elseif (iname == "Mute") then
		if (value > 0) then
			self.mute = 1
		else
			self.mute = 0
		end
	elseif (iname == "Multiplier") then
		if (value > 0) then
			self.multiply = value
			if self.multiply > server_settings.Int("GASSYS_MaxMultiplier") then
				self.multiply = server_settings.Int("GASSYS_MaxMultiplier")
			end
		else
			self.multiply = 1
		end
	end
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)
	self.Entity:StopSound( "apc_engine_stop" )
	self.Entity:StopSound( "common/warning.wav" )
	self.Entity:StopSound( "apc_engine_start" )
end

function ENT:Damage()
	if (self.damaged == 0) then
		self.damaged = 1
	end
	if ((self.Active == 1) and self:Health() <= 20) then
		self:TurnOff()
	end
end

function ENT:Repair()
	self.health = self.maxhealth
	self.damaged = 0
end

function ENT:TurnOn()
	self.Active = 1
	self:SetOOO(1)
	
	if WireLib then
		WireLib.TriggerOutput(self, "On", 1)
	end
	
	if(self.mute == 0) then
		self.Entity:EmitSound( "apc_engine_start" )
	end
end

function ENT:TurnOff()
	self.Active = 0
	self.overdrive = 0
	self:SetOOO(0)
	
	if WireLib then
		WireLib.TriggerOutput(self, "On", 0)
	end
	
	self.Entity:StopSound( "apc_engine_start" )
	if(self.mute == 0) then
		self.Entity:EmitSound( "apc_engine_stop" )
	end
end

function ENT:OverdriveOn()
    self.overdrive = 1
    self:SetOOO(2)
	
	if WireLib then
		WireLib.TriggerOutput(self, "Overdrive", 1) 
	end
    
    self.Entity:StopSound( "apc_engine_start" )
    if(self.mute == 0) then
		self.Entity:EmitSound( "apc_engine_stop" )
		self.Entity:EmitSound( "apc_engine_start" )
	end
end

function ENT:OverdriveOff()
    self.overdrive = 0
    self:SetOOO(1)
	
	if WireLib then
		WireLib.TriggerOutput(self, "Overdrive", 0) 
	end
    
    self.Entity:StopSound( "apc_engine_start" )
    if(self.mute == 0) then
		self.Entity:EmitSound( "apc_engine_stop" )
		self.Entity:EmitSound( "apc_engine_start" )
	end
end

function ENT:Destruct()
    CAF.GetAddon("Life Support").Destruct( self.Entity )
end

function ENT:Output()
	return 1
end

function ENT:ConvertGas()
	self.energy = (self.econ + math.random(1,3)) * self.multiply
	self.ngas = (self.ngascon + math.random(1,3))* self.multiply
	self.deuterium = (self.deutprod + math.random(1,4)) * self.multiply
	self.tritium = (self.tritprod + math.random(1,4)) * self.multiply
	self.methane = (self.methprod + math.random(1,5)) * self.multiply
	self.propane = (self.propprod + math.random(1,6)) * self.multiply
		
	if ( self.overdrive == 1 ) then
        self.energy = self.energy * self.overdrivefactor
        self.ngas = self.ngas * self.overdrivefactor
		self.deuterium = self.deuterium * self.overdrivefactor
		self.tritium = self.tritium * self.overdrivefactor
		self.methane = self.methane * self.overdrivefactor
		self.propane = self.propane * self.overdrivefactor
        
        if self.overdrivefactor > 1 then
            if CAF and CAF.GetAddon("Life Support") then
				CAF.GetAddon("Life Support").DamageLS(self, math.random(5,8)*self.overdrivefactor)
			else
				self:SetHealth( self:Health( ) - math.random(5,8)*self.overdrivefactor)
				if self:Health() <= 0 then
					self:Remove()
				end
			end
			if self.overdrivefactor > self.maxoverdrive then
				self:Destruct()
			end
        end
    end
    
	if ( self:CanRun() ) then
		self:ConsumeResource("energy", self.energy)
		self:ConsumeResource("Natural Gas",self.ngas)

		self:SupplyResource("Deuterium",self.deuterium)
		self:SupplyResource("Tritium",self.tritium)
		self:SupplyResource("Methane",self.methane)
		self:SupplyResource("Propane",self.propane)
	else
		if(self.mute == 0) then
			self.Entity:EmitSound( "common/warning.wav" )
		end
	end
	
	if WireLib then
		WireLib.TriggerOutput(self, "Energy Consumption", self.energy)
	end
		
	return
end

function ENT:CanRun()
	local energy = self:GetResourceAmount("energy")
	local ngas = self:GetResourceAmount("Natural Gas")
	if (energy >= self.energy) and (ngas >= self.ngas) then
		return true
	else
		return false
	end
end

function ENT:Think()
  self.BaseClass.Think(self)
    
	if ( self.Active == 1 ) then
		self:ConvertGas()
	end
    
	self.Entity:NextThink( CurTime() + 1 )
	return true
end

function ENT:AcceptInput(name,activator,caller)
	if name == "Use" and caller:IsPlayer() and caller:KeyDownLast(IN_USE) == false then
		if ( self.Active == 0 ) then
			self:TurnOn()
		elseif (self.Active == 1 && self.overdrive==0) then
			self:OverdriveOn()
			self.overdrivefactor = 2
		elseif (self.overdrive > 0) then
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
