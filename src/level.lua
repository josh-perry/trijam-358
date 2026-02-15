local assets = require("assets")
local display = require("display")
local peachy = require("lib.peachy")

local Player = require("player")
local Bullet = require("bullet")
local Revolver = require("revolver")
local Enemy = require("enemy")
local Collectable = require("collectable")

local bulletTypes = require("bullet_types")

local Level = class({
    name = "level"
})

local background = peachy.new("assets/animations/background.json", assets.spritesheet, nil)

local bulletTypes = require("bullet_types")

local enemySpawningCoroutine = coroutine.create(function()
    local function wait(t)
        local start = love.timer.getTime()

        while love.timer.getTime() - start < t do
            coroutine.yield()
        end
    end

    while true do
        wait(0.5)

        -- spawn a bullet
        local c = Collectable(table.pick_random(bulletTypes), vec2(display.width / 2 - 16, -32))
        coroutine.yield({
            eventType = "spawn_collectable",
            collectable = c
        })

        -- spawn some enemies
        local columns = 5
        local spacing = display.width / (columns + 1)
        local center = math.ceil(columns / 2)

        for i = 1, columns do
            local x = i * spacing
            local yOffset = math.abs(i - center) * 32

            coroutine.yield({
                eventType = "spawn_enemy",
                enemy = Enemy(vec2(x, -32 - (64 - yOffset)))
            })
        end

        wait(5)
    end
end)

function Level:new()
    self.enemies = {}
    self.bullets = {}
    self.badBullets = {} -- lol
    self.collectables = {}

    self.scroll = 0

    self.player = Player(self)
    self.revolver = Revolver(self.player)
    self.player.revolver = self.revolver

    pubsub:subscribe("ENEMY_DEATH", function(enemy)
        local bulletTypes = {
            "damage_bullet",
            "ricochet_bullet"
        }

        local bulletsOnGround = functional.count(self.collectables, function(c)
            return table.contains(bulletTypes, c.type)
        end)

        local bulletsInRevolver = #self.revolver.bullets
        local totalBullets = bulletsOnGround + bulletsInRevolver
        local maxBullets = self.revolver.maxBullets

        local chancesToDrop = math.max(0.3, 1.0 - (0.7 * totalBullets / maxBullets))

        if love.math.random() < chancesToDrop then
            for i = 1, love.math.random(1, 2) do
                local offset = vec2(love.math.random(-16, 16), love.math.random(-16, 16))
                table.insert(self.collectables, Collectable(table.pick_random(bulletTypes), vec2(enemy.position):vector_add_inplace(offset)))
            end
        end

        assets.playSfx("enemyDeath")
    end)

    pubsub:subscribe("ENEMY_SHOOT", function(enemy)
        local direction = vec2(self.player.position):vector_sub_inplace(enemy.position):normalise_inplace()
        local velocity = direction * 100
        self:addBadBullet(Bullet("enemy", vec2(enemy.position), velocity, enemy))
    end)

    pubsub:subscribe("PLAYER_DEATH", function()
        for i, v in ipairs(self.badBullets) do
            v.destroyed = true
        end

        for i, v in ipairs(self.enemies) do
            v:hurt(9999)
        end
    end)
end

local decor = {
    "cactus",
    "skull",
    "barrel"
}

function Level:draw()
    local tile = 16
    for i = 0, display.width / tile do
        for j = -1, display.height / tile do
            background:drawSlice("ground", i * tile, j * tile + self.scroll % tile)
        end
    end

    local currentDecorIndex = math.floor(self.scroll / 500) % #decor + 1
    local currentDecor = decor[currentDecorIndex]

    for y = -1, display.height / tile do
        background:drawSlice(currentDecor, 0, y * tile + self.scroll % tile)
        background:drawSlice(currentDecor, display.width - 16, y * tile + self.scroll % tile)
    end

    self.player:draw()

    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end

    for _, bullet in ipairs(self.bullets) do
        bullet:draw()
    end

    for _, bullet in ipairs(self.badBullets) do
        bullet:draw()
    end

    for _, collectable in ipairs(self.collectables) do
        collectable:draw()
    end

    self.revolver:draw()
end

function Level:update(dt)
    self.scroll = self.scroll + (30 * dt)
    self.player:update(dt)

    for _, enemy in ipairs(self.enemies) do
        enemy:update(dt)

        if enemy.position:distance(self.player.position) < enemy.radius + self.player.radius then
            self.player:hurt(9999)
            enemy:hurt(9999)
            break
        end
    end

    for _, collectable in ipairs(self.collectables) do
        collectable:update(dt)
    end

    for _, bullet in ipairs(self.bullets) do
        if bullet.queueTargetNextEnemy then
            local closestEnemy = nil
            local closestDistance = math.huge

            for _, enemy in ipairs(self.enemies) do
                if enemy ~= bullet.lastHit and enemy.health > 0 then
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

            if bullet.homing then
                bullet.queueTargetNextEnemy = true
            end
        end

        bullet:update(dt)

        for _, enemy in ipairs(self.enemies) do
            if enemy ~= bullet.lastHit and enemy.health > 0 then
                if bullet.position:distance(enemy.position) < bullet.radius + enemy.radius then
                    enemy:hurt(bullet.damage)
                    bullet:hitEnemy(enemy)
                    break
                end
            end
        end
    end

    for _, bullet in ipairs(self.badBullets) do
        bullet:update(dt)

        if bullet.position:distance(self.player.position) < bullet.radius + self.player.radius then
            self.player:hurt(bullet.damage)
            bullet.destroyed = true
            pubsub:publish("BULLET_DESTROYED", bullet)
        end
    end

    for i, v in ripairs(self.collectables) do
        if not v.fake then
            local distanceToPlayer = v.position:distance(self.player.position)

            if distanceToPlayer < v.radius + self.player.radius then
                if v.type == "damage_bullet" then
                    self.revolver:addBullet({
                        type = "damage",
                        enhanced = false
                    })
                elseif v.type == "ricochet_bullet" then
                    self.revolver:addBullet({
                        type = "ricochet",
                        enhanced = false,
                    })
                elseif v.type == "triple_bullet" then
                    self.revolver:addBullet({
                        type = "triple",
                        enhanced = false,
                    })
                elseif v.type == "homing_bullet" then
                    self.revolver:addBullet({
                        type = "homing",
                        enhanced = false,
                    })
                end

                pubsub:publish("COLLECTABLE_PICKED_UP", v)
                table.remove(self.collectables, i)

                local empty = Collectable("empty", vec2(v.position))
                empty.fake = true

                table.insert(self.collectables, empty)
            elseif distanceToPlayer < 50 then
                local direction = vec2(self.player.position):vector_sub_inplace(v.position):normalise_inplace()
                v.velocity = direction * 100
            end
        else
            if v.despawnTimer and v.despawnTimer <= 0 then
                table.remove(self.collectables, i)
            end
        end
    end

    for i, v in ripairs(self.bullets) do
        if v.toRemove then
            table.remove(self.bullets, i)
        end
    end

    for i, v in ripairs(self.badBullets) do
        if v.toRemove then
            table.remove(self.badBullets, i)
        end
    end

    for i, v in ripairs(self.enemies) do
        if v.dead then
            table.remove(self.enemies, i)
        end
    end

    local success, event = coroutine.resume(enemySpawningCoroutine)
    if success and event then
        if event.eventType == "spawn_enemy" then
            table.insert(self.enemies, event.enemy)
        elseif event.eventType == "spawn_collectable" then
            table.insert(self.collectables, event.collectable)
        end
    end

    self.revolver:update(dt)
end

function Level:addBullet(bullet)
    table.insert(self.bullets, bullet)
end

function Level:addBadBullet(bullet)
    table.insert(self.badBullets, bullet)
end

return Level