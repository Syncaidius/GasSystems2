AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
util.PrecacheSound( "k_lab.ambient_powergenerators" )
util.PrecacheSound( "ambient/machines/thumper_startup1.wav" )

include('shared.lua')

function ENT:Initialize()
	self.Entity:SetModel( "models/syncaidius/tokomak.mdl" )
	self:SetSkin(0)
	self.BaseClass.Initialize(self)

	local phys = self.Entity:GetPhysicsObject()
	self.damaged = 0
	self.overdrive = 0
	self.overdrivefactor = 0
	self.maxoverdrive = 4 -- maximum overdrive value allowed via wire input. Anything over this value may severely damage or destroy the device.
	self.Active = 0
	self.disuse = 0 --use disabled via wire input
	
	self.energy = 0
	self.Deuterium = 0
	self.Tritium = 0
	
	self.mute = 0
	self.multiply = 1
	
	self:SetMaxHealth(550)
	self:SetHealth(self:GetMaxHealth())
	-- resource attributes
	self.energyprod = 2500 --Energy production
	self.deutcon = 49 -- Deuterium consumption
	self.tritcon = 46 -- tritium consumt
    
	local RD = CAF.GetAddon("Resource Distribution")
	RD.AddResource(self,"Deuterium",0)
	RD.AddResource(self,"Tritium",0)
	
	if WireLib then
		self.WireDebugName = self.PrintName
		self.Inputs = WireLib.CreateInputs(self, { "On", "Overdrive", "Mute", "Multiplier" })
		self.Outputs = WireLib.CreateOutputs(self, { "On", "Overdrive","Energy Production"}) 
	end
	
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(500)
	end
end

function ENT:Setup()
	self:TriggerInput("On", 0)
	self:TriggerInput("Overdrive", 0)
end

function ENT:TriggerInput(iname, value)
	if (iname == "On") then
		if (value >0) then
			if ( self.Active == 0 ) then
				self:TurnOn()
				if (self.overdrive == 1) then
					self:OverdriveOn()
				end
			end
		else
			if ( self.Active == 1 ) then
				self:TurnOff()
				if(self.overdrive > 0) then
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
		else
			self.multiply = 1
		end
	end
end


function ENT:OnRemove()
	self.BaseClass.OnRemove(self)
	self.Entity:StopSound( "k_lab.ambient_powergenerators" )
	self.Entity:StopSound( "ambient/machines/thumper_startup1.wav" )
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
	
	if(self.mute == 0) then
		self.Entity:EmitSound( "ambient/machines/thumper_startup1.wav" )
		self.Entity:EmitSound( "k_lab.ambient_powergenerators" )
	end
end

function ENT:TurnOff()
	self.Active = 0
	self.overdrive = 0
	self:SetOOO(0)
	
	if WireLib then
		WireLib.TriggerOutput(self, "On", 0)
	end
	
	self.Entity:StopSound( "ambient/machines/thumper_startup1.wav" )
	self.Entity:StopSound( "k_lab.ambient_powergenerators" )
end

function ENT:OverdriveOn()
	self.overdrive = 1
	self:SetOOO(2)
	
	if WireLib then
		WireLib.TriggerOutput(self, "Overdrive", 1)
	end

	self.Entity:StopSound( "ambient/machines/thumper_startup1.wav" )
	self.Entity:StopSound( "k_lab.ambient_powergenerators" )
	if(self.mute == 0) then
		self.Entity:EmitSound( "ambient/machines/thumper_startup1.wav" )
		self.Entity:EmitSound( "k_lab.ambient_powergenerators" )
	end
end

function ENT:OverdriveOff()
	self.overdrive = 0
	self:SetOOO(1)
	
	if WireLib then
		WireLib.TriggerOutput(self, "Overdrive", 0)
	end

	self.Entity:StopSound( "ambient/machines/thumper_startup1.wav" )
	self.Entity:StopSound( "k_lab.ambient_powergenerators" )
	if(self.mute == 0) then
		self.Entity:EmitSound( "ambient/machines/thumper_startup1.wav" )
		self.Entity:EmitSound( "k_lab.ambient_powergenerators" )
	end
end

function ENT:Destruct()
	if CAF and CAF.GetAddon("Life Support") then
		CAF.GetAddon("Life Support").Destruct( self.Entity, true )
	end
end

function ENT:Output()
	return 1
end

function ENT:GenerateEnergy()
	self.energy = (self.energyprod + math.random(5,15)) * self.multiply
	self.Deuterium = (self.deutcon + math.random(1,3)) * self.multiply
	self.Tritium = (self.tritcon + math.random(1,3)) * self.multiply
		 
	if ( self.overdrive == 1 ) then
		 self.energy = self.energy * self.overdrivefactor
		 self.Deuterium = self.Deuterium * self.overdrivefactor
		 self.Tritium = self.Tritium * self.overdrivefactor
	
		 if self.overdrivefactor > 1 then
				if CAF and CAF.GetAddon("Life Support") then
				CAF.GetAddon("Life Support").DamageLS(self, math.random(10,20)*self.overdrivefactor)
			else
				self:SetHealth( self:Health() - math.random(10,20)*self.overdrivefactor)
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
		self:ConsumeResource("Deuterium", self.Deuterium)
		self:ConsumeResource("Tritium", self.Tritium)
		
		self:SupplyResource("energy",self.energy)
		if self.environment then
			self.environment:Convert(1,-1, self.energy)
		end
	else
		self.energy = math.random(15,20)
		self:SupplyResource("energy",self.energy)
		if(self.mute == 0) then
			self.Entity:EmitSound( "common/warning.wav" )
		end
		CAF.GetAddon("Life Support").DamageLS(self, math.random(10,20))
	end
	
	if WireLib then 
		WireLib.TriggerOutput(self, "Energy Production", self.energy)
	end
end

function ENT:CanRun()
	local Deuterium = self:GetResourceAmount("Deuterium")
	local Tritium = self:GetResourceAmount("Tritium")
	
	if Deuterium >= self.Deuterium and Tritium >= self.Tritium then
		return true
	else
		return false
	end
end

function ENT:Think()
  self.BaseClass.Think(self)
	if ( self.Active == 1 ) then
		self:GenerateEnergy()
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
