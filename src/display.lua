local display = {}

display.width = 240
display.height = 320
display.canvas = love.graphics.newCanvas(display.width, display.height)

function display:calculateScale()
    local maxScaleX = love.graphics.getWidth() / self.canvas:getWidth()
    local maxScaleY = love.graphics.getHeight() / self.canvas:getHeight()
    local scale = math.min(maxScaleX, maxScaleY)

    return scale
end

function display:draw()
    local scale = self:calculateScale()

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.canvas, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 0, scale, scale, self.canvas:getWidth() / 2, self.canvas:getHeight() / 2)

    love.graphics.setColor(1, 1, 1)
end

function display:getMousePosition()
    local mouseX, mouseY = love.mouse.getPosition()
    local scale = self:calculateScale()
    local canvasX = (mouseX - love.graphics.getWidth() / 2) / scale + self.canvas:getWidth() / 2
    local canvasY = (mouseY - love.graphics.getHeight() / 2) / scale + self.canvas:getHeight() / 2

    return canvasX, canvasY
end

return display