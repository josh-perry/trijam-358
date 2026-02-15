local assets = require("assets")
local display = require("display")
local peachy = require("lib.peachy")

local Enemy = class({
    name = "player"
})

local spritesize = 32

function Enemy:new(position)
    self.position = position or vec2((display.width / 2) - (spritesize / 2), 16)
    self.velocity = vec2(0, 0)
    self.speed = 30
    self.radius = spritesize / 2
    self.health = 2

    self.sprite = peachy.new("assets/animations/enemy.json", assets.spritesheet, "WalkDown")

    self.aiState = state_machine({
        walk = {
            enter = function(s)
                s.shootTimer = 1.5
            end,
            update = function(s, dt)
                self.sprite:setTag("WalkDown")
                self.speed = 30

                s.shootTimer = s.shootTimer - dt

                if s.shootTimer <= 0 then
                    return "shoot"
                end
            end
        },
        hurt = {
            enter = function(s)
                s.timer = 0.5
                self.sprite:setTag("Hurt")
                assets.playSfx("enemyHit")
                self.speed = 0
            end,
            update = function(s, dt)
                s.timer = s.timer - dt

                if s.timer <= 0 then
                    return "walk"
                end
            end
        },
        dead = {
            enter = function(s)
                self.sprite:setTag("Death")
                self.speed = 0
                s.timer = 0.6
            end,
            update = function(s, dt)
                s.timer = s.timer - dt

                if s.timer <= 0 then
                    pubsub:publish("ENEMY_DEATH", self)
                    self.dead = true
                end
            end
        },
        shoot = {
            enter = function(s)
                self.sprite:setTag("Shooting")
                s.timer = 0.5
            end,
            update = function(s, dt)
                s.timer = s.timer - dt

                if not s.hasShot and s.timer <= 0 then
                    pubsub:publish("ENEMY_SHOOT", self)
                    assets.playSfx("enemyShoot")
                    return "walk"
                end
            end
        }
    }, "walk")
end

function Enemy:draw()
    if self.dead then return end
    self.sprite:draw(math.round(self.position.x), math.round(self.position.y))
end

function Enemy:update(dt)
    self.sprite:update(dt)

    self.aiState:update(dt)

    self.position:vector_add_inplace(self.velocity * dt)

    self.velocity.x = 0
    self.velocity.y = self.speed
end

function Enemy:hurt(damage)
    self.health = self.health - damage
    self.aiState:set_state("hurt")

    if self.health <= 0 then
        self.aiState:set_state("dead")
    end
end

return Enemy