AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

if not (WireAddon == nil) then
    ENT.WireDebugName = "H Natural Gas Tank"
end

function ENT:Initialize()
	self.Entity:SetModel( "models/props_wasteland/coolingtank02.mdl" )
    self.BaseClass.Initialize(self)
	self.Entity:SetColor(127,127,127, 255)

    local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(1700)
	end
	
	self.damaged = 0
    self.maxhealth = 1200
    self.health = self.maxhealth

	CAF.GetAddon("Resource Distribution").AddResource(self,"Natural Gas",25000)
	
	if not (WireAddon == nil) then
		self.Outputs = Wire_CreateOutputs(self.Entity, {"Natural Gas", "NGas Tank Capacity", "NGas Net Capacity"}) 
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
	self.Entity:SetColor(127,127,127, 255)
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
        Wire_TriggerOutput(self.Entity, "Natural Gas", RD.GetResourceAmount( self, "Natural Gas" ))
        Wire_TriggerOutput(self.Entity, "NGas Tank Capacity", RD.GetUnitCapacity( self, "Natural Gas" ))
		Wire_TriggerOutput(self.Entity, "NGas Net Capacity", RD.GetNetworkCapacity( self, "Natural Gas" ))
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
		local gascur = RD.GetResourceAmount( self, "Natural Gas" )
		caller:ChatPrint("There is "..tostring(gascur).." Natural Gas stored in this resource network.")
	end
end

function ENT:PreEntityCopy()
    self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
    self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities )
end
