local Collectable = class({
    name = "Collectable",
})

local peachy = require("lib.peachy")
local assets = require("assets")

function Collectable:new(type, position)
    self.type = type
    self.position = position

    self.sprite = peachy.new("assets/animations/" .. type .. "_collectable.json", assets.spritesheet, "Idle")
    self.radius = 16
    self.velocity = vec2(0, 50)
    self.fake = false
    self.despawnTimer = nil
    
    if self.fake then
        self.despawnTimer = 1
    end
end

function Collectable:draw()
    if self.despawnTimer then
        if self.despawnTimer <= 0 then
            return
        end
    end

    self.sprite:draw(math.round(self.position.x), math.round(self.position.y))
end

function Collectable:update(dt)
    self.sprite:update(dt)

    self.position:vector_add_inplace(self.velocity * dt)
end

return Collectable