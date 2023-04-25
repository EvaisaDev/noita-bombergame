local bomb = GetUpdatedEntityID()
local velocity_comp = EntityGetFirstComponentIncludingDisabled(bomb, "VelocityComponent")

local vel_x, vel_y = ComponentGetValue2(velocity_comp, "mVelocity")

local friction = 0.01

PhysicsApplyForce(bomb, -(vel_x * friction), -(vel_y * friction))

local phys_body = EntityGetFirstComponentIncludingDisabled(bomb, "PhysicsBodyComponent")

local ang_vel = PhysicsGetComponentAngularVelocity( bomb, phys_body )

PhysicsApplyTorque( bomb, -(ang_vel * friction) )