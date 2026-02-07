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
    self.health = 3
    self.lives = 3

    self.sprite = peachy.new("assets/animations/player.json", assets.spritesheet, "WalkUp")
    self.revolver = nil
    self.radius = 16
end

function Player:draw()
    self.sprite:draw(self.position.x, self.position.y)
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
        return
    end

    local mouseX, mouseY = display:getMousePosition()

    local direction = vec2(mouseX, mouseY):vector_sub_inplace(self.position):normalise_inplace()
    local shotSpeed = 150

    local bullet = Bullet(nextBullet.type, vec2(self.position), direction * shotSpeed, self)
    pubsub:publish("PLAYER_SHOOT", bullet)

    self.revolver:removeFirstBullet()
    self.level:addBullet(bullet)
end

return Player