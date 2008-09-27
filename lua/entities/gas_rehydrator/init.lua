AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
util.PrecacheSound( "Airboat_engine_idle" )
util.PrecacheSound( "Airboat_engine_stop" )

include('shared.lua')

if not (WireAddon == nil) then
  ENT.WireDebugName = "Methane Inverter"
end

function ENT:Initialize()
	self.Entity:SetModel("models/syncaidius/gas_inverter.mdl")
	self:SetSkin(2)
  self.BaseClass.Initialize(self)

  local phys = self.Entity:GetPhysicsObject()
	self.damaged = 0
	self.overdrive = 0
	self.overdrivefactor = 0
	self.maxoverdrive = 4 -- maximum overdrive value allowed via wire input. Anything over this value may severely damage or destroy the device.
	self.Active = 0
	
  self:SetMaxHealth(230)
  self:SetHealth(self:GetMaxHealth())
	
	self.energy = 0
	self.methane = 0
	self.water = 0
	
    -- resource attributes
    self.waterprod = 270 --O2 production
    self.econ = 15 -- Energy consumption
		self.methcon = 15 -- Methane Consumption
    
	CAF.GetAddon("Resource Distribution").AddResource(self,"energy",0)
	CAF.GetAddon("Resource Distribution").AddResource(self,"Methane",0)
	if not (WireAddon == nil) then self.Inputs = Wire_CreateInputs(self.Entity, { "On", "Overdrive"}) end
	if not (WireAddon == nil) then self.Outputs = Wire_CreateOutputs(self.Entity, { "On", "Overdrive", "O2 Output"}) end
	
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(130)
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
	if not (WireAddon == nil) then 
		Wire_TriggerOutput(self.Entity, "On", 1)
	end
	self.Entity:EmitSound( "Airboat_engine_idle" )
end

function ENT:TurnOff()
	self.Active = 0
	self.overdrive = 0
	self:SetOOO(0)
	if not (WireAddon == nil) then
		Wire_TriggerOutput(self.Entity, "On", 0)
	end
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
        self.methane = math.ceil(self.methcon + math.random(1,2) * self.overdrivefactor)
				self.water = math.ceil(self.waterprod + math.random(2,4) * self.overdrivefactor)
        
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
        self.methane = self.methcon + math.random(1,2)
        self.energy = self.econ + math.random(1,2)
				self.water = self.waterprod + math.random(2,4)
    end
		local waterlevel = 0
		if CAF then
			waterlevel = self:WaterLevel2()
		else
			waterlevel = self:WaterLevel()
		end
		if (waterlevel==1) then --x2 production if underwater
			self.water = self.water*1.5
		end
    
	if ( self:CanRun() ) then
		RD.ConsumeResource(self,"energy", self.energy)
		RD.ConsumeResource(self,"Methane",self.methane)
		
		if GAMEMODE.IsSpacebuildDerived then
			RD.SupplyResource(self, "water", self.water)
		else
			RD.SupplyResource(self.Entity,"water",self.water)
		end
	else
		self:TurnOff()
	end
	
	if not (WireAddon == nil) then
			Wire_TriggerOutput(self.Entity,"O2 Output", self.water)
			Wire_TriggerOutput(self.Entity, "On", self.active)
  end
end

function ENT:CanRun()
	local RD = CAF.GetAddon("Resource Distribution")
    local energy = RD.GetResourceAmount(self,"energy")
		local methane = RD.GetResourceAmount(self,"Methane")
    if (energy >= self.energy) and (methane >= self.methane) then
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