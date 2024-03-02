package main

import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"

init_lvl1 :: proc() -> Objects {
    player_lvl1 := Player {
        shape = {530, 350, 70, 70},
        color = rl.BLACK,
        pace = 1,
        game_state = .Playing,

        movement = handle_movement,
        shoot = shoot,
    }

    enemies_lvl1 := make([dynamic]Enemy, 0)
    append(&enemies_lvl1,
        Enemy {
            shape = {
                1130, 770, 70, 70,
            },
            color = rl.RED,
            direction = linalg.vector_normalize(rl.Vector2{player_lvl1.shape.x, player_lvl1.shape.y} - rl.Vector2{1130, 770}),
            shoot_cooldown = {
                rl.GetTime(),
                5,
            },

            pathfind = pathfind,
            shoot = shoot,
        },
        Enemy {
            shape = {
                0, 0, 70, 70,
            },
            color = rl.RED,
            direction = linalg.vector_normalize(rl.Vector2{player_lvl1.shape.x, player_lvl1.shape.y} - rl.Vector2{0, 0}),
            shoot_cooldown = {
                rl.GetTime(),
                5,
            },

            pathfind = pathfind,
            shoot = shoot,
        },
    )

    obstacles_lvl1 := make([dynamic]Obstacle, 0)
    append(&obstacles_lvl1,
        Obstacle {
            shape = {
                0, 0, 1200, 5,
            },
            color = rl.DARKGRAY,
        },
        Obstacle {
            shape = {
                0, 835, 1200, 5,
            },
            color = rl.DARKGRAY,
        },
        Obstacle {
            shape = {
                0, 0, 5, 840,
            },
            color = rl.DARKGRAY,
        },
        Obstacle {
            shape = {
                1195, 0, 5, 840,
            },
            color = rl.DARKGRAY,
        },
    )

    bullets_lvl1 := make([dynamic]Bullet, 0)

    objects_lvl1 := Objects {
        player = player_lvl1,
        enemies = enemies_lvl1,
        bullets = bullets_lvl1,
        obstacles = obstacles_lvl1,

        collision_detect = collision_detect,
    }

    return objects_lvl1
}
