AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
util.PrecacheSound( "Airboat_engine_idle" )
util.PrecacheSound( "Airboat_engine_stop" )

include('shared.lua')

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
	self.mute = 0
	
    -- resource attributes
    self.nitroprod = 140 --N production
    self.econ = 15 -- Energy consumption
	self.deutcon = 15 -- Deuterium Consumption
	
	self.multiply = 1
    
	local RD = CAF.GetAddon("Resource Distribution")
	RD.AddResource(self,"energy",0)
	RD.AddResource(self,"Deuterium",0)
	
	if WireLib then
		self.WireDebugName = self.PrintName
		self.Inputs = WireLib.CreateInputs(self, { "On", "Overdrive", "Mute", "Multiplier"})
		self.Outputs = WireLib.CreateOutputs(self, { "On", "Overdrive", "Nitrogen Output"})
	end
	
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(120)
	end
end

function ENT:Setup()
	WireLib.TriggerInputself(self, "On", 0)
	WireLib.TriggerInput(self, "Overdrive", 0)
	WireLib.TriggerInput(self, "Mute", 0)
	WireLib.TriggerInput(self, "Multiplier", 1)
end

function ENT:TriggerInput(iname, value)
	if (iname == "On") then
		if (value > 0) then
			if ( self.Active == 0 ) then
				self:TurnOn()
			end
			if (self.overdrive > 0) then
				self:OverdriveOn()
			end
		else
			if ( self.Active == 1 ) then
				self:TurnOff()
				if self.overdrive > 0 then
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
			if WireLib then
				WireLib.TriggerOutput(self, "Overdrive", self.overdrive) 
			end
		end
	elseif (iname == "Mute") then
		if (value >= 1) then
			if (self.mute == 0) then
				self.mute = 1
				self.Entity:StopSound( "Airboat_engine_idle" )
				self.Entity:StopSound( "Airboat_engine_stop" )
			end
		else
			if( self.mute == 1) then
				self.mute = 0
				if(self.Active == 1) then
					self.Entity:EmitSound( "Airboat_engine_idle" )
				end
			end
		end
	elseif (iname == "Multiplier") then
		if(value > 0) then
			self.multiply = value
		else
			self.multiply = 1
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
	if WireLib then 
		WireLib.TriggerOutput(self, "On", 1)
	end
	if(self.mute < 1) then
		self.Entity:EmitSound( "Airboat_engine_idle" )
	end
end

function ENT:TurnOff()
	self.Active = 0
	self.overdrive = 0
	self:SetOOO(0)
	if WireLib then
		WireLib.TriggerOutput(self, "On", 0)
	end
	
	self.Entity:StopSound( "Airboat_engine_idle" )
	if(self.mute == 0) then
		self.Entity:EmitSound( "Airboat_engine_stop" )
	end
end

function ENT:OverdriveOn()
	self.overdrive = 1
	self:SetOOO(2)
	
	if WireLib then
		WireLib.TriggerOutput(self, "Overdrive", 1)
	end
	
	self.Entity:StopSound( "Airboat_engine_idle" )
	if(self.mute < 1) then
		self.Entity:EmitSound( "Airboat_engine_idle" )
	end
end

function ENT:OverdriveOff()
	self.overdrive = 0
	self.overdrivefactor = 0
	self:SetOOO(1)
	
	if WireLib then
		WireLib.TriggerOutput(self, "Overdrive", 0)
	end
	
	self.Entity:StopSound( "Airboat_engine_idle" )
	if(self.mute < 1) then
		self.Entity:EmitSound( "Airboat_engine_idle" )
	end
end

function ENT:Destruct()
	CAF.GetAddon("Life Support").Destruct( self.Entity )
end

function ENT:Output()
	return 1
end

function ENT:ExtractGas()
	--base consumption for this cycle
	self.energy = (self.econ + math.random(1,2)) * self.multiply
    self.deuterium = (self.deutcon + math.random(1,2)) * self.multiply
	self.nitrogen = (self.nitroprod + math.random(2,4)) * self.multiply
		
	if ( self.overdrive == 1 ) then
        self.energy = (self.energy * self.overdrivefactor)
        self.deuterium = (self.deuterium * self.overdrivefactor)
		self.nitrogen = (self.nitrogen * self.overdrivefactor)
        
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
    end
	--+50 percent production if underwater
	local waterlevel = 0
	if CAF then
		waterlevel = self:WaterLevel2()
	else
		waterlevel = self:WaterLevel()
	end
	if (waterlevel==1) then
		self.nitrogen = self.nitrogen*1.5
	end
    
	if ( self:CanRun() ) then
		self:ConsumeResource("energy", self.energy)
		self:ConsumeResource("Deuterium",self.deuterium)
		
		if GAMEMODE.IsSpacebuildDerived then
			local left = self:SupplyResource("nitrogen", self.nitrogen)
		else
			self:SupplyResource("nitrogen",self.nitrogen)
		end
	else
		self:TurnOff()
	end
	
	if WireLib then
		WireLib.TriggerOutput(self,"Nitrogen Output", self.nitrogen)
		WireLib.TriggerOutput(self, "On", self.Active)
	end
end

function ENT:CanRun()
	local energy = self:GetResourceAmount("energy")
	local deuterium = self:GetResourceAmount("Deuterium")
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
