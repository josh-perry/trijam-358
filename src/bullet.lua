local Bullet = class({
    name = "Bullet",
})

local peachy = require("lib.peachy")
local assets = require("assets")

local baseDamage = 1

function Bullet:new(type, position, velocity, owner)
    if type == "damage" then
        self.damage = baseDamage * 3
        self.colour = {1, 0, 0}
    elseif type == "ricochet" then
        self.damage = baseDamage
        self.ricochetCount = 4
        self.ricochetSpeed = 200
        self.colour = {0, 0, 1}
    else
        error("Unknown bullet type: " .. tostring(type))
    end

    self.owner = owner
    self.position = position
    self.velocity = velocity
    self.sprite = peachy.new("assets/animations/bullet.json", assets.spritesheet, "Idle")
    self.radius = 16
end

function Bullet:draw()
    love.graphics.setColor(self.colour)
    self.sprite:draw(self.position.x, self.position.y)
    love.graphics.setColor(1, 1, 1)
end

function Bullet:update(dt)
    self.sprite:update(dt)
    self.position:vector_add_inplace(self.velocity * dt)
end

function Bullet:hitEnemy(enemy)
    self.lastHit = enemy

    if self.ricochetCount then
        self.ricochetCount = self.ricochetCount - 1

        if self.ricochetCount <= 0 then
            self.toRemove = true
            pubsub:publish("BULLET_DESTROYED", self)
        else
            self.queueTargetNextEnemy = true
        end
    else
        self.toRemove = true
        pubsub:publish("BULLET_DESTROYED", self)
    end
end

return Bullet