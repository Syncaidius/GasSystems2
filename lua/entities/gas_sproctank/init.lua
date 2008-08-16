AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

if not (WireAddon == nil) then
    ENT.WireDebugName = "S Processed Gas Tank"
end

function ENT:Initialize()
	self.Entity:SetModel( "models/pegasus/protank_small.mdl" )
    self.BaseClass.Initialize(self)

    local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(310)
	end
	
	self.damaged = 0
    self:SetMaxHealth(350)
    self:SetHealth(self:GetMaxHealth())

	CAF.GetAddon("Resource Distribution").AddResource(self,"Methane",5000)
	CAF.GetAddon("Resource Distribution").AddResource(self,"Propane",5000)
	CAF.GetAddon("Resource Distribution").AddResource(self,"Deuterium",5500)
	CAF.GetAddon("Resource Distribution").AddResource(self,"Tritium",5500)
	
	if not (WireAddon == nil) then
		self.Outputs = Wire_CreateOutputs(self.Entity, {"Methane","Propane","Deuterium","Tritium"}) 
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
	self.Entity:SetColor(255,255,255, 255)
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
        Wire_TriggerOutput(self.Entity, "Methane", RD.GetResourceAmount( self, "Methane" ))
        Wire_TriggerOutput(self.Entity, "Propane", RD.GetResourceAmount( self, "Propane" ))
		Wire_TriggerOutput(self.Entity, "Deuterium",RD.GetResourceAmount(self,"Deuterium"))
		Wire_TriggerOutput(self.Entity, "Tritium",RD.GetResourceAmount(self,"Tritium"))
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
		local propane = RD.GetResourceAmount( self, "Propane" )
		local methane = RD.GetResourceAmount(self,"Methane")
		local deut = RD.GetResourceAmount(self,"Deuterium")
		local trit = RD.GetResourceAmount(self,"Tritium")
		caller:ChatPrint("There is "..tostring(propane).." Propane stored in this resource network.")
		caller:ChatPrint("There is "..tostring(methane).." Propane stored in this resource network.")
		caller:ChatPrint("There is "..tostring(deut).." Deuterium stored in this resource network.")
		caller:ChatPrint("There is "..tostring(trit).." Tritium stored in this resource network.")
	end
end

function ENT:PreEntityCopy()
    self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
    self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities )
end
