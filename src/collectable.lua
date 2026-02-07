local Collectable = class({
    name = "Collectable",
})

local peachy = require("lib.peachy")
local assets = require("assets")

function Collectable:new(type, position)
    self.type = type
    self.position = position
    self.sprite = peachy.new("assets/animations/damage_bullet_collectable.json", assets.spritesheet, "Idle")
    self.radius = 16
end

function Collectable:draw()
    self.sprite:draw(self.position.x, self.position.y)
end

function Collectable:update(dt)
    self.sprite:update(dt)
end

return Collectable