local Level = require("level")

local Game = {}

function Game:enter()
    self.level = Level()
end

function Game:draw()
    self.level:draw()
end

function Game:update(dt)
    self.level:update(dt)
end

return Game