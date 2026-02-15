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
    triple = peachy.new("assets/animations/triple_bullet_revolver.json", assets.spritesheet, "Idle"),
    homing = peachy.new("assets/animations/homing_bullet_revolver.json", assets.spritesheet, "Idle"),
}

function Revolver:new(player)
    self.player = player
    self.maxBullets = 6
    self.rotation = 0
    self.currentBulletIndex = 1

    self.sprite = peachy.new("assets/animations/revolver.json", assets.spritesheet, "Idle")
    self.bullets = {
        {
            type = "homing",
            enhanced = false
        },
        {
            type = "ricochet",
            enhanced = false
        },
        {
            type = "ricochet",
            enhanced = false
        },
        {
            type = "triple",
            enhanced = false
        },
        {
            type = "triple",
            enhanced = false
        },
        {
            type = "empty",
            enhanced = false
        }
    }

    pubsub:subscribe("PLAYER_SHOOT", function(bullet)
        local step = (math.pi * 2 / self.maxBullets)
        local targetRotation = self.rotation - step
        flux.to(self, 0.2, {rotation = targetRotation}):ease("quadout")
    end)

    pubsub:subscribe("PLAYER_SHOOT_EMPTY", function()
        -- local originalRotation = self.rotation
        -- local step = (math.pi * 2 / self.maxBullets)
        -- local targetRotation = self.rotation - step
        -- flux.to(self, 0.2, {rotation = targetRotation}):ease("elasticinout")
    end)

    self:updateEnhanced()
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

    for _, v in pairs(bulletSprites) do
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
        type = "empty",
        enhanced = false
    }

    self.currentBulletIndex = self.currentBulletIndex % self.maxBullets + 1
end

function Revolver:addBullet(bullet)
    for i = self.currentBulletIndex, self.currentBulletIndex + self.maxBullets do
        local index = ((i - 1) % self.maxBullets) + 1

        if self.bullets[index].type == "empty" then
            self.bullets[index] = {
                type = bullet.type,
                enhanced = bullet.enhanced
            }

            self:updateEnhanced()
            break
        end
    end
end

function Revolver:updateEnhanced()
    local enhanced = false
    -- if theres 3 of the same type, enhance all
    for i = 1, self.maxBullets do
        local v = self.bullets[i]

        if v.type ~= "empty" then
            local count = functional.count(self.bullets, function(b)
                return b.type == v.type
            end)

            if count >= 3 then
                for j = 1, self.maxBullets do
                    if self.bullets[j].type == v.type then
                        self.bullets[j].enhanced = true
                        bulletSprites[v.type]:setTag("Enhanced")
                    end
                end

                enhanced = true
            else
                bulletSprites[v.type]:setTag("Idle")
            end
        end
    end

    if enhanced then
        assets.playSfx("bulletsEnhanced")
    else
    end
end

return Revolver