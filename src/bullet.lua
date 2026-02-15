local Bullet = class({
    name = "Bullet",
})

local peachy = require("lib.peachy")
local assets = require("assets")

local baseDamage = 1

function Bullet:new(type, position, velocity, owner, enhanced)

    if type == "damage" then
        self.damage = baseDamage * 3
        self.colour = {1, 0, 0}

        if enhanced then
            self.damage = self.damage * 2
            self.colour = {1, 0.5, 0.5}
        end
    elseif type == "ricochet" then
        self.damage = baseDamage
        self.ricochetCount = 4
        self.ricochetSpeed = 200
        self.colour = {0, 0, 1}

        if enhanced then
            self.damage = self.damage * 2
            self.ricochetCount = self.ricochetCount + 2
        end
    elseif type == "enemy" then
        self.damage = baseDamage
        self.colour = {1, 0, 1}
    elseif type == "triple" then
        self.damage = baseDamage
        self.colour = {1, 1, 0}
    elseif type == "homing" then
        self.damage = baseDamage
        self.colour = {0, 1, 1}
        self.queueTargetNextEnemy = true
        self.homing = true
        self.ricochetSpeed = 150
    else
        error("Unknown bullet type: " .. tostring(type))
    end

    self.owner = owner
    self.position = position
    self.velocity = velocity
    self.sprite = peachy.new("assets/animations/bullet.json", assets.spritesheet, "Idle")
    self.radius = 6
    self.chain = 0
    self.enhanced = enhanced

    self.destroyed = false
    self.destroyTimer = 1
end

function Bullet:draw()
    love.graphics.setColor(self.colour)
    self.sprite:draw(self.position.x - self.radius / 2, self.position.y - self.radius / 2)
    love.graphics.setColor(1, 1, 1)
end

function Bullet:update(dt)
    if self.destroyed then
        self.sprite:setTag("Destroy")

        self.destroyTimer = self.destroyTimer - dt

        if self.destroyTimer <= 0 then
            self.toRemove = true
        end
    end

    if self.targetEnemy then
        local direction = vec2(self.targetEnemy.position):vector_sub_inplace(self.position):normalise_inplace()
        self.velocity = direction * self.ricochetSpeed
    end

    self.sprite:update(dt)
    self.position:vector_add_inplace(self.velocity * dt)
end

function Bullet:hitEnemy(enemy)
    self.lastHit = enemy
    self.chain = self.chain + 1

    if self.ricochetCount then
        self.ricochetCount = self.ricochetCount - 1

        assets.playSfx("hit")

        if self.ricochetCount <= 0 then
            self.destroyed = true
            pubsub:publish("BULLET_DESTROYED", self)
        else
            self.queueTargetNextEnemy = true
            pubsub:publish("BULLET_RICOCHET", self)
        end
    else
        self.destroyed = true
        pubsub:publish("BULLET_DESTROYED", self)
    end
end

return Bullet