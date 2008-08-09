AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
util.PrecacheSound( "Airboat_engine_idle" )
util.PrecacheSound( "Airboat_engine_stop" )
util.PrecacheSound( "apc_engine_start" )

include('shared.lua')

if not (WireAddon == nil) then
    ENT.WireDebugName = "Gas Extractor"
end

function ENT:Initialize()
	self.Entity:SetModel( "models/props/cs_assault/firehydrant.mdl" )
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
	
    -- resource attributes
    self.ngasprod = 70 --N-Gas production
    self.econ = 18 -- Energy consumption
    
	CAF.GetAddon("Resource Distribution").AddResource(self,"energy",0)
	if not (WireAddon == nil) then self.Inputs = Wire_CreateInputs(self.Entity, { "On", "Overdrive", "Disable Use" }) end
	if not (WireAddon == nil) then self.Outputs = Wire_CreateOutputs(self.Entity, { "On", "Overdrive", "Energy Consumption", "NGas Production"}) end
	
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
    self.Entity:StopSound( "Airboat_engine_idle" )
    self.Entity:StopSound( "common/warning.wav" )
    self.Entity:StopSound( "apc_engine_start" )
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
    self.Entity:EmitSound( "Airboat_engine_idle" )
end

function ENT:TurnOff()
    self.Active = 0
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
    self.Entity:EmitSound( "apc_engine_start" )
end

function ENT:OverdriveOff()
    self.overdrive = 0
    self:SetOOO(1)
    
    self.Entity:StopSound( "Airboat_engine_idle" )
    self.Entity:EmitSound( "Airboat_engine_idle" )
    self.Entity:StopSound( "apc_engine_start" )
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
        self.energy = math.ceil((self.econ + math.random(5,15)) * self.overdrivefactor)
        self.ngas = math.ceil(self.ngasprod * self.overdrivefactor)
        
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
        self.ngas = (self.ngasprod + math.random(5,15))
        self.energy = self.econ
    end
    
	if ( self:CanRun() ) then
        RD.ConsumeResource(self, "energy", self.energy)
        
        RD.SupplyResource(self.Entity,"Natural Gas",self.ngas)
		if self.environment then
			self.environment:Convert(1,-1, self.energy)
		end
        if not (WireAddon == nil) then Wire_TriggerOutput(self.Entity, "On", 1) end
	else
		self:TurnOff()
	end
	
	if not (WireAddon == nil) then
        Wire_TriggerOutput(self.Entity, "NGas Production", self.ngas)
        Wire_TriggerOutput(self.Entity, "Energy Consumption", self.energy)
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
		self:ExtractGas()
	end
    
	self.Entity:NextThink( CurTime() + 1 )
	return true
end


function ENT:AcceptInput(name,activator,caller)
	if name == "Use" and caller:IsPlayer() and caller:KeyDownLast(IN_USE) == false and self.disuse == 0 then
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