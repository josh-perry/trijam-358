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
            update = function(s, dt)
                self.sprite:setTag("WalkDown")
                self.speed = 30
            end
        },
        hurt = {
            enter = function(s)
                s.timer = 0.5
                self.sprite:setTag("Hurt")
                self.speed = 0
            end,
            update = function(s, dt)
                s.timer = s.timer - dt

                if s.timer <= 0 then
                    return "walk"
                end
            end
        }
    }, "walk")
end

function Enemy:draw()
    self.sprite:draw(self.position.x, self.position.y)
end

function Enemy:update(dt)
    self.aiState:update(dt)

    self.sprite:update(dt)

    self.position:vector_add_inplace(self.velocity * dt)

    self.velocity.x = 0
    self.velocity.y = self.speed
end

function Enemy:hurt(damage)
    self.health = self.health - damage
    self.aiState:set_state("hurt")

    if self.health <= 0 then
        pubsub:publish("ENEMY_DEATH", self)
    end
end

return Enemy