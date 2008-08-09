AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
util.PrecacheSound( "k_lab.ambient_powergenerators" )
util.PrecacheSound( "ambient/machines/thumper_startup1.wav" )

include('shared.lua')

if not (WireAddon == nil) then
    ENT.WireDebugName = "Micro Methane Reactor"
end

function ENT:Initialize()
	self.Entity:SetModel( "models//props_combine/headcrabcannister01a.mdl" )
    self.BaseClass.Initialize(self)
    self.Entity:SetColor(89, 45, 0, 255)

    local phys = self.Entity:GetPhysicsObject()
	self.damaged = 0
	self.overdrive = 0
	self.overdrivefactor = 0
	self.maxoverdrive = 4 -- maximum overdrive value allowed via wire input. Anything over this value may severely damage or destroy the device.
	self.Active = 0
    self:SetMaxHealth(250)
    self:SetHealth(self:GetMaxHealth())
	self.disuse = 0 --use disabled via wire input
	self.energy = 0
	self.nitrous = 0
    self.methane = 0
	
    -- resource attributes
    self.energyprod = 180 --Energy production
    self.methanecon = 30 -- methane consumption
    
	CAF.GetAddon("Resource Distribution").AddResource(self,"methane",0)
	if not (WireAddon == nil) then self.Inputs = Wire_CreateInputs(self.Entity, { "On", "Overdrive", "Disable Use" }) end
	if not (WireAddon == nil) then self.Outputs = Wire_CreateOutputs(self.Entity, { "On", "Overdrive", "Methane Consumption", "Energy Production"}) end
	
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(300)
	end
end

function ENT:Setup()
	self:TriggerInput("On", 0)
	self:TriggerInput("Overdrive", 0)
end

function ENT:TriggerInput(iname, value)
	if (iname == "On") then
		if (value ~= 0) then
			if ( self.Active == 0 ) then
                self:TurnOn()
                if (self.overdrive == 1) then
                    self:OverdriveOn()
                end
			end
		else
			if ( self.Active == 1 ) then
                self:TurnOff()
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
	self.Entity:SetColor(89, 45, 0, 255)
	self:SetHealth(self:GetMaxHealth())
	self.damaged = 0
end

function ENT:TurnOn()
    self.Active = 1
    self:SetOOO(1)
    if not (WireAddon == nil) then 
        Wire_TriggerOutput(self.Entity, "On", 1)
    end
    self.Entity:EmitSound( "ambient/machines/thumper_startup1.wav" )
    self.Entity:EmitSound( "k_lab.ambient_powergenerators" )
end

function ENT:TakeDamage(amount, attacker, inflictor)
	self:SetHealth(self:Health()-amount)
	if self:Health()<=0 then
		self:Destruct()
	end
end

function ENT:TurnOff()
    self.Active = 0
    self:SetOOO(0)
    if not (WireAddon == nil) then
        Wire_TriggerOutput(self.Entity, "On", 0)
    end
    self.Entity:StopSound( "ambient/machines/thumper_startup1.wav" )
	self.Entity:StopSound( "k_lab.ambient_powergenerators" )
end

function ENT:OverdriveOn()
    self.overdrive = 1
    self:SetOOO(2)
    
    self.Entity:StopSound( "ambient/machines/thumper_startup1.wav" )
	self.Entity:StopSound( "k_lab.ambient_powergenerators" )
    self.Entity:EmitSound( "ambient/machines/thumper_startup1.wav" )
    self.Entity:EmitSound( "k_lab.ambient_powergenerators" )
end

function ENT:OverdriveOff()
    self.overdrive = 0
    self:SetOOO(1)
    
    self.Entity:StopSound( "ambient/machines/thumper_startup1.wav" )
	self.Entity:StopSound( "k_lab.ambient_powergenerators" )
    self.Entity:EmitSound( "ambient/machines/thumper_startup1.wav" )
    self.Entity:EmitSound( "k_lab.ambient_powergenerators" )
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
	local RD = CAF.GetAddon("Resource Distribution")
	if ( self.overdrive == 1 ) then
        self.energy = math.ceil((self.energyprod + math.random(5,15)) * self.overdrivefactor)
        self.nitrous = math.ceil(self.nitrouscon * self.overdrivefactor)
        self.methane = math.ceil(self.methanecon * self.overdrivefactor)
        
        if self.overdrivefactor > 1 then
            if CAF and CAF.GetAddon("Life Support") then
				CAF.GetAddon("Life Support").DamageLS(self, math.random(10,10)*self.overdrivefactor)
			else
				self:SetHealth( self:Health() - math.random(10,10)*self.overdrivefactor)
				if self:Health() <= 0 then
					self:Remove()
				end
			end
			if self.overdrivefactor > self.maxoverdrive then
				self:Destruct()
			end
        end
        
    else
        self.energy = (self.energyprod + math.random(5,15))
        self.methane = self.methanecon
    end
    
	if ( self:CanRun() ) then
        RD.ConsumeResource(self, "methane", self.methane)
        
        RD.SupplyResource(self.Entity, "energy",self.energy)

        if not (WireAddon == nil) then Wire_TriggerOutput(self.Entity, "On", 1) end
	else
		self.energy = 10
		RD.SupplyResource(self.Entity, "energy",self.energy)
		self.Entity:EmitSound( "common/warning.wav" )
		CAF.GetAddon("Life Support").DamageLS(self, math.random(10,20))
		if not (WireAddon == nil) then Wire_TriggerOutput(self.Entity, "On", 0) end
	end
	if self.environment then
		self.environment:Convert(1,-1, self.energy)
	end
	
	if not (WireAddon == nil) then
        Wire_TriggerOutput(self.Entity, "Energy Production", self.energy)
        Wire_TriggerOutput(self.Entity, "Methane Consumption", self.methane)
    end
		
	return
end

function ENT:CanRun()
	local RD = CAF.GetAddon("Resource Distribution")
    local methane = RD.GetResourceAmount(self, "methane")
    if (methane >= self.methane) then
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
