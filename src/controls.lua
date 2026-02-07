local baton = require("lib.baton")

return baton.new({
    controls = {
        left = {"key:a"},
        right = {"key:d"},
        up = {"key:w"},
        down = {"key:s"},
        shoot = {"mouse:1"}
    },
    pairs = {
        move = {"left", "right", "up", "down"}
    }
})