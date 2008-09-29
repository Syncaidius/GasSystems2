AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
util.PrecacheSound( "Airboat_engine_idle" )
util.PrecacheSound( "Airboat_engine_stop" )

include('shared.lua')

if not (WireAddon == nil) then
  ENT.WireDebugName = "Deuterium Inverter"
end

function ENT:Initialize()
	self.Entity:SetModel("models/syncaidius/gas_inverter.mdl")
	self:SetSkin(1)
  self.BaseClass.Initialize(self)

  local phys = self.Entity:GetPhysicsObject()
	self.damaged = 0
	self.overdrive = 0
	self.overdrivefactor = 0
	self.maxoverdrive = 4 -- maximum overdrive value allowed via wire input. Anything over this value may severely damage or destroy the device.
	self.Active = 0
	
  self:SetMaxHealth(220)
  self:SetHealth(self:GetMaxHealth())
	
	self.energy = 0
	self.deuterium = 0
	self.nitrogen = 0
	
    -- resource attributes
    self.nitroprod = 140 --N production
    self.econ = 15 -- Energy consumption
		self.deutcon = 15 -- Deuterium Consumption
    
	CAF.GetAddon("Resource Distribution").AddResource(self,"energy",0)
	CAF.GetAddon("Resource Distribution").AddResource(self,"Deuterium",0)
	if not (WireAddon == nil) then self.Inputs = Wire_CreateInputs(self.Entity, { "On", "Overdrive"}) end
	if not (WireAddon == nil) then self.Outputs = Wire_CreateOutputs(self.Entity, { "On", "Overdrive", "Nitrogen Output"}) end
	
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(120)
	end
end

function ENT:Setup()
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
				if self.overdrive==1 then
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
      if not (WireAddon == nil) then Wire_TriggerOutput(self.Entity, "Overdrive", self.overdrive) end
    end
	end
end


function ENT:OnRemove()
  self.BaseClass.OnRemove(self)
  self.Entity:StopSound( "Airboat_engine_idle" )
  self.Entity:StopSound( "common/warning.wav" )
  self.Entity:StopSound( "Airboat_engine_stop" )
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
	self:SetHealth(self:GetMaxHealth())
	self.damaged = 0
end

function ENT:TurnOn()
	self.Active = 1
	self:SetOOO(1)
	self.Entity:EmitSound( "Airboat_engine_idle" )
end

function ENT:TurnOff()
	self.Active = 0
	self.overdrive = 0
	self:SetOOO(0)
	self.Entity:StopSound( "Airboat_engine_idle" )
	self.Entity:EmitSound( "Airboat_engine_stop" )
end

function ENT:OverdriveOn()
	self.overdrive = 1
	self:SetOOO(2)
	self.Entity:StopSound( "Airboat_engine_idle" )
	self.Entity:EmitSound( "Airboat_engine_idle" )
end

function ENT:OverdriveOff()
	self.overdrive = 0
	self.overdrivefactor = 0
	self:SetOOO(1)
	self.Entity:StopSound( "Airboat_engine_idle" )
	self.Entity:EmitSound( "Airboat_engine_idle" )
end

function ENT:Destruct()
	local RD = CAF.GetAddon("Resource Distribution")
	CAF.GetAddon("Life Support").Destruct( self.Entity )
end

function ENT:Output()
	return 1
end

function ENT:ExtractGas()
	local RD = CAF.GetAddon("Resource Distribution")
	if ( self.overdrive == 1 ) then
        self.energy = math.ceil((self.econ + math.random(1,2)) * self.overdrivefactor)
        self.deuterium = math.ceil(self.deutcon + math.random(1,2) * self.overdrivefactor)
				self.nitrogen = math.ceil(self.nitroprod + math.random(2,4) * self.overdrivefactor)
        
        if self.overdrivefactor > 1 then
            if CAF and CAF.GetAddon("Life Support") then
				CAF.GetAddon("Life Support").DamageLS(self, math.random(5,5)*self.overdrivefactor)
			else
				self:SetHealth( self:Health( ) - math.random(5,5)*self.overdrivefactor)
				if self:Health() <= 0 then
					self:Remove()
				end
			end
			if self.overdrivefactor > self.maxoverdrive then
				self:Destruct()
			end
        end
        
    else
        self.deuterium = self.deutcon + math.random(1,2)
        self.energy = self.econ + math.random(1,2)
				self.nitrogen = self.nitroprod + math.random(2,4)
    end
		local waterlevel = 0
		if CAF then
			waterlevel = self:WaterLevel2()
		else
			waterlevel = self:WaterLevel()
		end
		if (waterlevel==1) then --x2 production if underwater
			self.nitrogen = self.nitrogen*1.5
		end
    
	if ( self:CanRun() ) then
		RD.ConsumeResource(self,"energy", self.energy)
		RD.ConsumeResource(self,"Deuterium",self.deuterium)
		
		if GAMEMODE.IsSpacebuildDerived then
			local left = RD.SupplyResource(self, "nitrogen", self.environment:Convert(2, -1, self.nitrogen))
			self.environment:Convert(-1, 2, left)
		else
			RD.SupplyResource(self.Entity,"nitrogen",self.nitrogen)
		end
		if self.environment then
			self.environment:Convert(2,-1, self.energy)
		end
	else
		self:TurnOff()
	end
	
	if not (WireAddon == nil) then
			Wire_TriggerOutput(self.Entity,"Nitrogen Output", self.nitrogen)
			Wire_TriggerOutput(self.Entity, "On", self.Active)
  end
end

function ENT:CanRun()
	local RD = CAF.GetAddon("Resource Distribution")
	local energy = RD.GetResourceAmount(self,"energy")
	local deuterium = RD.GetResourceAmount(self,"Deuterium")
	if (energy >= self.energy) and (deuterium >= self.deuterium) then
		return true
	else
		return false
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	if ( self.Active == 1 ) then
		self:ExtractGas()
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
