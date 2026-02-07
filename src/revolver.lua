local Revolver = class({
    name = "RevolverDisplay",
})

local peachy = require("lib.peachy")
local assets = require("assets")
local display = require("display")
local flux = require("lib.flux")

local spritesize = 64

local bulletSprites = {
    damage = peachy.new("assets/animations/damage_bullet_revolver.json", assets.spritesheet, "Idle"),
    ricochet = peachy.new("assets/animations/ricochet_bullet_revolver.json", assets.spritesheet, "Idle"),
    empty = peachy.new("assets/animations/empty_bullet_revolver.json", assets.spritesheet, "Idle"),
}

function Revolver:new(player)
    self.player = player
    self.maxBullets = 6
    self.rotation = 0
    self.currentBulletIndex = 1

    self.sprite = peachy.new("assets/animations/revolver.json", assets.spritesheet, "Idle")
    self.bullets = {
        {
            type = "ricochet",
            enhanced = false
        },
        {
            type = "damage",
            enhanced = false
        },
        {
            type = "damage",
            enhanced = false
        },
        {
            type = "damage",
            enhanced = false
        },
        {
            type = "damage",
            enhanced = false
        },
        {
            type = "ricochet",
            enhanced = false
        }
    }
    
    pubsub:subscribe("PLAYER_SHOOT", function(bullet)
        local step = (math.pi * 2 / self.maxBullets)
        local targetRotation = self.rotation - step
        flux.to(self, 0.2, {rotation = targetRotation}):ease("quadout")
    end)
end

function Revolver:draw()
    local padding = 8
    local x, y = display.width - spritesize - padding, display.height - spritesize - padding
    self.sprite:draw(x, y)

    local bulletSpritesize = 16

    for i = 1, self.maxBullets do
        local v = self.bullets[i]

        local angle = (i - 1) * (math.pi * 2 / self.maxBullets) - (math.pi / 2) + self.rotation
        local radius = 22
        local startX = x + spritesize / 2
        local startY = y + spritesize / 2

        local bulletX = startX + math.cos(angle) * radius - (spritesize / 4) + (bulletSpritesize / 2)
        local bulletY = startY + math.sin(angle) * radius - (spritesize / 4) + (bulletSpritesize / 2)

        if v then
            bulletSprites[v.type]:draw(bulletX, bulletY)
        else
            bulletSprites.empty:draw(bulletX, bulletY)
        end
    end
end

function Revolver:update(dt)
    self.sprite:update(dt)

    for i, v in pairs(bulletSprites) do
        v:update(dt)
    end
end

function Revolver:getNextBullet()
    local bullet = self.bullets[self.currentBulletIndex]

    if bullet.type == "empty" then
        return nil
    end

    return bullet
end

function Revolver:removeFirstBullet()
    self.bullets[self.currentBulletIndex] = {
        type = "empty"
    }

    self.currentBulletIndex = self.currentBulletIndex % self.maxBullets + 1
end

return Revolver