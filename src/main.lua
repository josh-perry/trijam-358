local batteries = require("lib.batteries")
batteries:export()
pubsub:new()

love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setLineStyle("rough")

local display = require("display")
local gamestate = state_machine(require("states"), "Game")

local flux = require("lib.flux")
local baton = require("lib.baton")

local controls = require("controls")

function love.update(dt)
    flux.update(dt)
    controls:update()
    gamestate:update(dt)
end

function love.draw()
    love.graphics.setCanvas(display.canvas)
    love.graphics.clear()

    gamestate:draw()

    love.graphics.setCanvas()
    display:draw()
end