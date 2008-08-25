AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
util.PrecacheSound( "apc_engine_start" )
util.PrecacheSound( "apc_engine_stop" )
util.PrecacheSound( "common/warning.wav" )

include('shared.lua')

if not (WireAddon == nil) then
    ENT.WireDebugName = "Natural Gas Processor"
end

function ENT:Initialize()
	self.Entity:SetModel( "models/props_industrial/oil_storage.mdl" )
    self.BaseClass.Initialize(self)
	self.Entity:SetColor(127,127,127, 255)

    local phys = self.Entity:GetPhysicsObject()
	self.damaged = 0
	self.overdrive = 0
	self.overdrivefactor = 0
	self.maxoverdrive = 4 -- maximum overdrive value allowed via wire input. Anything over this value may severely damage or destroy the device.
	self.Active = 0
    self.maxhealth = 250
    self.health = self.maxhealth
	self.disuse = 0 --use disabled via wire input
	
	self.energy = 0
	self.ngas = 0
	self.deuterium = 0
	self.tritium = 0
	self.methane = 0
	self.propane = 0
	
    -- resource attributes
    self.ngascon = 80 --N-Gas production
    self.econ = 30 -- Energy consumption
	self.deutprod = 30 -- Deuterium Production
	self.tritprod = 25 -- Tritium Production
	self.methprod = 25 -- methane production
	self.propprod = 20 -- propane production
    
	CAF.GetAddon("Resource Distribution").AddResource(self,"energy",0)
	CAF.GetAddon("Resource Distribution").AddResource(self,"Natural Gas",0)
	if not (WireAddon == nil) then self.Inputs = Wire_CreateInputs(self.Entity, { "On", "Overdrive", "Disable Use" }) end
	if not (WireAddon == nil) then self.Outputs = Wire_CreateOutputs(self.Entity, { "On", "Overdrive", "Energy Consumption"}) end
	
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(80)
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
	elseif (iname == "Disable Use") then
		if (value >= 1) then
			self.disuse = 1
		else
			self.disuse = 0
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
	self.Entity:SetColor(127,127,127, 255)
	self.health = self.maxhealth
	self.damaged = 0
end

function ENT:TurnOn()
    self.Active = 1
    self:SetOOO(1)
    if not (WireAddon == nil) then 
        Wire_TriggerOutput(self.Entity, "On", 1)
    end
    self.Entity:EmitSound( "apc_engine_start" )
end

function ENT:TurnOff()
    self.Active = 0
	self.overdrive = 0
    self:SetOOO(0)
    if not (WireAddon == nil) then
        Wire_TriggerOutput(self.Entity, "On", 0)
    end
    self.Entity:EmitSound( "apc_engine_stop" )
    self.Entity:StopSound( "apc_engine_start" )
end

function ENT:OverdriveOn()
    self.overdrive = 1
    self:SetOOO(2)
    
    self.Entity:StopSound( "apc_engine_start" )
    self.Entity:EmitSound( "apc_engine_stop" )
    self.Entity:EmitSound( "apc_engine_start" )
end

function ENT:OverdriveOff()
    self.overdrive = 0
    self:SetOOO(1)
    
    self.Entity:StopSound( "apc_engine_start" )
    self.Entity:EmitSound( "apc_engine_stop" )
    self.Entity:EmitSound( "apc_engine_start" )
end

function ENT:Destruct()
	local RD = CAF.GetAddon("Resource Distribution")
    CAF.GetAddon("Life Support").Destruct( self.Entity )
end

function ENT:Output()
	return 1
end

function ENT:ConvertGas()
	local RD = CAF.GetAddon("Resource Distribution")
	if ( self.overdrive == 1 ) then
        self.energy = math.ceil(self.econ + math.random(1,3) * self.overdrivefactor)
        self.ngas = math.ceil(self.ngascon + math.random(1,3)* self.overdrivefactor)
		self.deuterium = math.ceil(self.deutprod + math.random(1,4) * self.overdrivefactor)
		self.tritium = math.ceil(self.tritprod + math.random(1,4) * self.overdrivefactor)
		self.methane = math.ceil(self.methprod + math.random(1,5) * self.overdrivefactor)
		self.propane = math.ceil(self.propprod + math.random(1,6) * self.overdrivefactor)
        
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
    else
        self.energy = self.econ + math.random(1,3)
        self.ngas = self.ngascon + math.random(1,3)
		self.deuterium = self.deutprod + math.random(1,4)
		self.tritium = self.tritprod + math.random(1,4)
		self.methane = self.methprod + math.random(1,5)
		self.propane = self.propprod + math.random(1,6)
    end
    
	if ( self:CanRun() ) then
        RD.ConsumeResource(self,"energy", self.energy)
        RD.ConsumeResource(self,"Natural Gas",self.ngas)
		
        RD.SupplyResource(self.Entity,"Deuterium",self.deuterium)
		RD.SupplyResource(self.Entity,"Tritium",self.tritium)
		RD.SupplyResource(self.Entity,"Methane",self.methane)
		RD.SupplyResource(self.Entity,"Propane",self.propane)
		
		if self.environment then
			self.environment:Convert(0,1, self.energy) -- O2 to CO2
			self.environment:Convert(1,-1, self.ngas) --CO2 to E-air
		end
        if not (WireAddon == nil) then Wire_TriggerOutput(self.Entity, "On", 1) end
	else
		self.Entity:EmitSound( "common/warning.wav" )
	end
	
	if not (WireAddon == nil) then
        Wire_TriggerOutput(self.Entity, "Energy Consumption", self.energy)
    end
		
	return
end

function ENT:CanRun()
	local RD = CAF.GetAddon("Resource Distribution")
    local energy = RD.GetResourceAmount(self, "energy")
	local ngas = RD.GetResourceAmount(self,"Natural Gas")
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
