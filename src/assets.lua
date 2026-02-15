local spritesheet = love.graphics.newImage("assets/img/spritesheet.png")

local assets = {
    spritesheet = spritesheet,
    sfx = {
        shoot = love.audio.newSource("assets/sfx/shoot_ricochet.wav", "static"),
        shootEmpty = love.audio.newSource("assets/sfx/shoot_empty.wav", "static"),
        shootEnhanced = love.audio.newSource("assets/sfx/shoot_damage_enhanced.wav", "static"),
        gainScore = love.audio.newSource("assets/sfx/gain_score.wav", "static"),
        collect = love.audio.newSource("assets/sfx/collect.wav", "static"),
        enemyDeath = love.audio.newSource("assets/sfx/enemy_death.wav", "static"),
        enemyHit = love.audio.newSource("assets/sfx/enemy_hit.wav", "static"),
        gainLife = love.audio.newSource("assets/sfx/gain_life.wav", "static"),
        bulletsEnhanced = love.audio.newSource("assets/sfx/bullets_enhanced.wav", "static"),
        playerHit = love.audio.newSource("assets/sfx/player_hit.wav", "static"),
        enemyShoot = love.audio.newSource("assets/sfx/enemy_shoot.wav", "static"),
        hit = love.audio.newSource("assets/sfx/hit.wav", "static"),
    },
    music = love.audio.newSource("assets/music/josh_ricochets 2026-02-07 1739.mp3", "stream"),
}

assets.playSfx = function(name)
    local sfx = assets.sfx[name]
    print("Playing SFX:", name)

    if not sfx then
        error("SFX not found: " .. tostring(name))
    end

    if sfx:isPlaying() then
        sfx:stop()
    end

    sfx:play()
end

return assets