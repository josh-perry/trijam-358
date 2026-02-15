local assets = require("assets")
local display = require("display")
local peachy = require("lib.peachy")
local controls = require("controls")

local Bullet = require("bullet")

local Player = class({
    name = "player"
})

function Player:new(level)
    self.position = vec2(display.width / 2 - 16, display.height - 64)
    self.velocity = vec2(0, 0)
    self.speed = 100
    self.level = level
    self.health = 1
    self.lives = 3

    self.sprite = peachy.new("assets/animations/player.json", assets.spritesheet, "WalkUp")

    self.revolver = nil
    self.radius = 16
    self.scoreThreshold = 1000

    self.score = 0

    pubsub:subscribe("ENEMY_DEATH", function(item)
        self:addScore(100)
    end)

    pubsub:subscribe("COLLECTABLE_PICKED_UP", function(collectable)
        self:addScore(50)
    end)

    pubsub:subscribe("BULLET_DESTROYED", function(bullet)
        if bullet.chain > 1 then
            for _ = 1, bullet.chain do
                self:addScore(100)
            end
        end
    end)

    pubsub:subscribe("GAIN_SCORE", function(amount)
        --assets.playSfx("gainScore")

        if self.score >= self.scoreThreshold then
            self.lives = self.lives + 1
            self.scoreThreshold = self.scoreThreshold * 5
        end
    end)
end

function Player:draw()
    self.sprite:draw(math.round(self.position.x), math.round(self.position.y))
end

function Player:update(dt)
    self.sprite:update(dt)

    if controls:pressed("shoot") then
        self:shootBullet()
    end

    local x, y = controls:get("move")
    self.velocity = vec2(x, y) * self.speed

    self.position:vector_add_inplace(self.velocity * dt)
end

function Player:shootBullet()
    assert(self.revolver, "Player does not have a revolver!")

    local nextBullet = self.revolver:getNextBullet()

    if not nextBullet then
        pubsub:publish("PLAYER_SHOOT_EMPTY")
        assets.playSfx("shootEmpty")
        return
    end

    local mouseX, mouseY = display:getMousePosition()

    if nextBullet.type == "triple" then
        local direction = vec2(mouseX, mouseY):vector_sub_inplace(self.position):
            normalise_inplace()
        local shotSpeed = 150
        local spreadAngle = math.rad(15)
        local baseAngle = math.atan2(direction.y, direction.x)
        local angles = {baseAngle, baseAngle - spreadAngle, baseAngle + spreadAngle}

        if nextBullet.enhanced then
            spreadAngle = math.rad(30)
            angles = {baseAngle, baseAngle - spreadAngle, baseAngle + spreadAngle, baseAngle - spreadAngle / 2, baseAngle + spreadAngle / 2}
        end

        local firstBullet = nil

        for _, angle in ipairs(angles) do
            local bulletDirection = vec2(math.cos(angle), math.sin(angle))
            local bullet = Bullet(nextBullet.type, vec2(self.position):scalar_add_inplace(self.radius / 2, self.radius / 2), bulletDirection * shotSpeed, self, nextBullet.enhanced)
            self.level:addBullet(bullet)

            firstBullet = firstBullet or bullet
        end

        self.revolver:removeFirstBullet()
        pubsub:publish("PLAYER_SHOOT", firstBullet)
    else
        local direction = vec2(mouseX, mouseY):vector_sub_inplace(self.position):normalise_inplace()
        local shotSpeed = 150

        local bullet = Bullet(nextBullet.type, vec2(self.position):scalar_add_inplace(self.radius / 2, self.radius / 2), direction * shotSpeed, self, nextBullet.enhanced)
        pubsub:publish("PLAYER_SHOOT", bullet)

        self.revolver:removeFirstBullet()
        self.level:addBullet(bullet)
    end

    if nextBullet.enhanced then
        assets.playSfx("shootEnhanced")
    else
        assets.playSfx("shoot")
    end
end

function Player:addScore(score)
    self.score = self.score + score
    pubsub:publish("GAIN_SCORE", score)
end

function Player:hurt(damage)
    self.health = self.health - damage

    if self.health <= 0 then
        self.lives = self.lives - 1
        pubsub:publish("PLAYER_DEATH")

        if self.lives > 0 then
            self.health = 3
            self.position = vec2(display.width / 2 - 16, display.height - 64)
        else
            pubsub:publish("GAME_OVER")
        end
    end
end

return Player