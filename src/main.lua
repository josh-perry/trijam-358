local batteries = require("lib.batteries")
batteries:export()

love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setLineStyle("rough")

local display = require("display")
local states = require("states")

local gamestate = state_machine(states, "Menu")

function love.update(dt)
    gamestate:update(dt)
end

function love.draw()
    love.graphics.setCanvas(display.canvas)
    love.graphics.clear()

    gamestate:draw()

    love.graphics.setCanvas()
    display:draw()
end