local display = require("display")
local colourCycle = require("colour_cycle")
local state = require("state")

local GameOver = class({
    name = "GameOver"
})

function GameOver:enter()
end

function GameOver:update(dt)
    if love.keyboard.isDown("r") then
        love.event.quit("restart")
    end
end

function GameOver:draw()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, display.width, display.height)

    love.graphics.setColor(1, 1, 1)

    colourCycle()
    love.graphics.printf("Game Over", 10, display.height / 2 - 20, display.width, "center")
    love.graphics.printf("Final Score: " .. math.floor(state.score), 10, display.height / 2 + 10, display.width, "center")

    love.graphics.printf("Press R to Restart", 10, display.height / 2 + 40, display.width, "center")
end

return GameOver