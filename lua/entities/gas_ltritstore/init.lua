AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

if not (WireAddon == nil) then
    ENT.WireDebugName = "L Tritium Tank"
end

function ENT:Initialize()
	self.Entity:SetModel( "models/props_borealis/bluebarrel001.mdl" )
    self.BaseClass.Initialize(self)
	self.Entity:SetColor(232,232,0,255)

    local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(500)
	end
	
	self.damaged = 0
	self:SetMaxHealth(500)
    self:SetHealth(self:GetMaxHealth())

	CAF.GetAddon("Resource Distribution").AddResource(self,"Tritium",12000)
	
	if not (WireAddon == nil) then
		self.Outputs = Wire_CreateOutputs(self.Entity, {"Tritium", "Tritium Tank Capacity", "Tritium Net Capacity"}) 
	end
end

function ENT:OnRemove()
    self.BaseClass.OnRemove(self)
end

function ENT:Damage()
	if (self.damaged == 0) then
		self.damaged = 1
	end
end

function ENT:TakeDamage(amount, attacker, inflictor)
	self:SetHealth(self:Health()-amount)
	if self:Health()<=0 then
		self:Destruct()
	end
end

function ENT:Repair()
	self.Entity:SetColor(232,232,0, 255)
	self:SetHealth(self:GetMaxHealth())
	self.damaged = 0
end

function ENT:Destruct()
	local RD = CAF.GetAddon("Resource Distribution")
    CAF.GetAddon("Life Support").Destruct( self.Entity )
end

function ENT:Output()
	return 1
end

function ENT:UpdateWireOutputs()
    if not (WireAddon == nil) then
		local RD = CAF.GetAddon("Resource Distribution")
        Wire_TriggerOutput(self.Entity, "Tritium Gas", RD.GetResourceAmount( self, "Tritium" ))
        Wire_TriggerOutput(self.Entity, "Tritium Tank Capacity", RD.GetUnitCapacity( self, "Tritium" ))
		Wire_TriggerOutput(self.Entity, "Tritium Net Capacity", RD.GetNetworkCapacity( self, "Tritium" ))
	end
end

function ENT:Think()
    self.BaseClass.Think(self)
    
    self:UpdateWireOutputs()
    
	self.Entity:NextThink( CurTime() + 1 )
	return true
end

function ENT:AcceptInput(name,activator,caller)
	if name == "Use" and caller:IsPlayer() and caller:KeyDownLast(IN_USE) == false then
		local RD = CAF.GetAddon("Resource Distribution")
		local gascur = RD.GetResourceAmount( self, "Tritium" )
		caller:ChatPrint("There is "..tostring(gascur).." Tritium stored in this resource network.")
	end
end

function ENT:PreEntityCopy()
    self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
    self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities )
end
