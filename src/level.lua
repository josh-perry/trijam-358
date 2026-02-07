local assets = require("assets")
local display = require("display")

local Player = require("player")
local Revolver = require("revolver")
local Enemy = require("enemy")
local Collectable = require("collectable")

local Level = class({
    name = "level"
})

local enemySpawningCoroutine = coroutine.create(function()
    local function wait(t)
        local start = love.timer.getTime()

        while love.timer.getTime() - start < t do
            coroutine.yield()
        end
    end

    while true do
        wait(0.5)

        local columns = 3

        for i = 1, columns do
            for j = 1, 2 do
                local halfScreen = display.width / 2
                local slots = halfScreen / columns

                local x = i * slots

                if j % 2 == 0 then
                    x = display.width - x
                end

                coroutine.yield({
                    eventType = "spawn_enemy",
                    enemy = Enemy(vec2(x, -32))
                })
            end

            wait(2)
        end

        wait(5)
    end
end)

function Level:new()
    self.enemies = {
        -- Enemy(),
    }
    self.bullets = {}
    self.collectables = {}

    self.player = Player(self)
    self.revolver = Revolver(self.player)
    self.player.revolver = self.revolver

    pubsub:subscribe("ENEMY_DEATH", function(enemy)
        local bulletsOnGround = functional.count(self.collectables, function(c)
            return c.type == "damage_bullet"
        end)

        local bulletsInRevolver = #self.revolver.bullets

        local chancesToDrop = 0.5

        if love.math.random() < chancesToDrop then
            table.insert(self.collectables, Collectable("damage_bullet", vec2(enemy.position)))
        end
    end)
end

function Level:draw()
    self.player:draw()

    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end

    for _, bullet in ipairs(self.bullets) do
        bullet:draw()
    end

    for _, collectable in ipairs(self.collectables) do
        collectable:draw()
    end

    self.revolver:draw()
end

function Level:update(dt)
    self.player:update(dt)

    for _, enemy in ipairs(self.enemies) do
        enemy:update(dt)
    end

    for _, collectable in ipairs(self.collectables) do
        collectable:update(dt)
    end

    for _, bullet in ipairs(self.bullets) do
        if bullet.queueTargetNextEnemy then
            local closestEnemy = nil
            local closestDistance = math.huge

            for _, enemy in ipairs(self.enemies) do
                if enemy ~= bullet.lastHit then
                    local distance = bullet.position:distance(enemy.position)

                    if distance < closestDistance then
                        closestDistance = distance
                        closestEnemy = enemy
                    end
                end
            end

            if not closestEnemy then
                local direction = vec2(love.math.random(), love.math.random()):normalise_inplace()
                bullet.velocity = direction * bullet.ricochetSpeed
            else
                local direction = vec2(closestEnemy.position):vector_sub_inplace(bullet.position):normalise_inplace()
                bullet.velocity = direction * bullet.ricochetSpeed
            end

            bullet.queueTargetNextEnemy = nil
        end

        bullet:update(dt)

        for _, enemy in ipairs(self.enemies) do
            if enemy ~= bullet.lastHit then
                if bullet.position:distance(enemy.position) < bullet.radius + enemy.radius then
                    enemy:hurt(bullet.damage)
                    bullet:hitEnemy(enemy)
                    break
                end
            end
        end
    end

    for i, v in ripairs(self.collectables) do
        if self.player.position:distance(v.position) < self.player.radius + v.radius then
            if v.type == "damage_bullet" then
                if #self.revolver.bullets < self.revolver.maxBullets then
                    table.insert(self.revolver.bullets, {
                        type = "damage",
                        enhanced = false
                    })
                end
            end

            table.remove(self.collectables, i)
        end
    end

    for i, v in ripairs(self.bullets) do
        if v.toRemove then
            table.remove(self.bullets, i)
        end
    end

    for i, v in ripairs(self.enemies) do
        if v.health <= 0 then
            table.remove(self.enemies, i)
        end
    end

    local success, event = coroutine.resume(enemySpawningCoroutine)
    if success and event then
        if event.eventType == "spawn_enemy" then
            table.insert(self.enemies, event.enemy)
        end
    end

    self.revolver:update(dt)
end

function Level:addBullet(bullet)
    table.insert(self.bullets, bullet)
end

return Level