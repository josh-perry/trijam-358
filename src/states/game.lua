local display = require("display")
local Level = require("level")
local assets = require("assets")

local state = require("state")

local peachy = require("lib.peachy")
local flux = require("lib.flux")
local colourCycle = require("colour_cycle")

local font = love.graphics.newFont("assets/fonts/m5x7.ttf", 16)
love.graphics.setFont(font)

local Game = {}

function Game:enter()
    self.level = Level()
    self.crosshair = peachy.new("assets/animations/crosshair.json", assets.spritesheet, "Idle")

    self.hitstop = 0
    self.screenshake = 0
    self.displayedScore = 0

    pubsub:subscribe("BULLET_RICOCHET", function(bullet)
        self.hitstop = self.hitstop + bullet.chain * 0.05
        self.screenshake = self.screenshake + bullet.chain / 2
    end)

    pubsub:subscribe("BULLET_DESTROYED", function(bullet)
        if bullet.owner ~= self.level.player then
            return
        end

        self.hitstop = self.hitstop + (bullet.chain - 1) * 0.03
        self.screenshake = self.screenshake + (bullet.chain - 1) / 3
    end)

    pubsub:subscribe("PLAYER_SHOOT", function(bullet)
        if bullet.enhanced then
            self.hitstop = self.hitstop + 0.05
            self.screenshake = self.screenshake + 0.5
        else
            self.screenshake = self.screenshake + 0.2
        end
    end)

    pubsub:subscribe("PLAYER_DEATH", function()
        self.screenshake = 0
        self.hitstop = 0.3

        if self.level.player.lives <= 0 then
            self.queueGameOver = true
            state.score = self.level.player.score
        end
    end)
end

function Game:draw()
    local shakeAmount = self.screenshake * 3

    shakeAmount = math.min(shakeAmount, 15)

    local n = (love.math.simplexNoise(love.timer.getTime() * 10) - 1) * 2
    local offsetX = n * shakeAmount
    local offsetY = n * shakeAmount
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    self.level:draw()
    love.graphics.pop()

    local player = self.level.player
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Score", 20, 10, display.width - 40, "right")
    if math.abs(self.displayedScore - player.score) > 100 then
        colourCycle()
    end
    love.graphics.printf(tostring(math.ceil(self.displayedScore)), 20, 30, display.width - 40, "right")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Lives", 20, 10, display.width - 40, "left")
    love.graphics.printf(tostring(player.lives), 20, 30, display.width - 40, "left")

    local mouseX, mouseY = display:getMousePosition()
    self.crosshair:draw(mouseX, mouseY)
end

function Game:update(dt)
    if self.queueGameOver then
        return "GameOver"
    end

    if not assets.music:isPlaying() then
        assets.music:setLooping(true)
        assets.music:play()
    end

    if self.screenshake > 0 then
        self.screenshake = self.screenshake - dt * 5
        self.screenshake = math.max(self.screenshake, 0)
    end

    if self.hitstop > 0 then
        self.hitstop = self.hitstop - dt
        self.hitstop = math.max(self.hitstop, 0)
        return
    end

    self.level:update(dt)

    if self.level.player.score > self.displayedScore then
        flux.to(self, 0.4, {displayedScore = self.level.player.score}):ease("quadout")
    end
end

return Game