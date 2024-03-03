package main

import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"

init_lvl1 :: proc() -> Objects {
    player_frames: i32 = 0

    player_img := rl.LoadImageAnim("resources/character/Outline/120x80_gifs/__Idle.gif", &player_frames)
    player_texture := rl.LoadTextureFromImage(player_img)

    player_lvl1 := Player {
        anim_info = {
            player_img, player_texture, cast(int)player_frames, 0, 8, 0,
        },

        shape = {WIDTH / 2 - 55, HEIGHT / 2 - 60, 35, 60},
        color = rl.BLACK,
        pace = 1,
        game_state = .Playing,

        movement = handle_movement,
        shoot = shoot,
        animate = player_animate,
    }

    enemies_lvl1 := make([dynamic]Enemy, 0)
    append(&enemies_lvl1,
        Enemy {
            shape = {
                WIDTH - 70, HEIGHT - 70, 70, 70,
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
                0, 0, WIDTH, 5,
            },
            color = rl.DARKGRAY,
            text = "",
        },
        Obstacle {
            shape = {
                0, HEIGHT - 5, WIDTH, 5,
            },
            color = rl.DARKGRAY,
            text = "",
        },
        Obstacle {
            shape = {
                0, 0, 5, HEIGHT,
            },
            color = rl.DARKGRAY,
            text = "",
        },
        Obstacle {
            shape = {
                WIDTH - 5, 0, 5, HEIGHT,
            },
            color = rl.DARKGRAY,
            text = "",
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
