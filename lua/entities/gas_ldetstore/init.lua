AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

if not (WireAddon == nil) then
    ENT.WireDebugName = "L Deuterium Tank"
end

function ENT:Initialize()
	self.Entity:SetModel( "models/props_borealis/bluebarrel001.mdl" )
    self.BaseClass.Initialize(self)
	self.Entity:SetColor(0, 123, 38, 255)

    local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(650)
	end
	
	self.damaged = 0
    self.maxhealth = 700
    self.health = self.maxhealth

	CAF.GetAddon("Resource Distribution").AddResource(self,"Deuterium",10000)
	
	if not (WireAddon == nil) then
		self.Outputs = Wire_CreateOutputs(self.Entity, {"Deuterium", "Deuterium Tank Capacity", "Deuterium Net Capacity"}) 
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

function ENT:Repair()
	self.Entity:SetColor(0, 123, 38, 255)
	self.health = self.maxhealth
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
        Wire_TriggerOutput(self.Entity, "Deuterium Gas", RD.GetResourceAmount( self, "Deuterium" ))
        Wire_TriggerOutput(self.Entity, "Deuterium Tank Capacity", RD.GetUnitCapacity( self, "Deuterium" ))
		Wire_TriggerOutput(self.Entity, "Deuterium Net Capacity", RD.GetNetworkCapacity( self, "Deuterium" ))
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
		local gascur = RD.GetResourceAmount( self, "Deuterium" )
		caller:ChatPrint("There is "..tostring(gascur).." Deuterium stored in this resource network.")
	end
end

function ENT:PreEntityCopy()
    self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
    self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities )
end
