package main

import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"

init_lvl1 :: proc() -> Objects {
    idle_frames: i32 = 0
    idle_img := rl.LoadImageAnim("resources/character/Outline/120x80_gifs/__Idle.gif", &idle_frames)
    idle_texture := rl.LoadTextureFromImage(idle_img)

    run_frames: i32 = 0
    run_img := rl.LoadImageAnim("resources/character/Outline/120x80_gifs/__Run.gif", &run_frames)
    run_texture := rl.LoadTextureFromImage(run_img)

    animations := [2]AnimateInfo{
        AnimateInfo{idle_img, idle_texture, cast(int)idle_frames, 0, 8, 0},
        AnimateInfo{run_img, run_texture, cast(int)run_frames, 0, 8, 0},
    }

    player_lvl1 := Player {
        animations = animations,
        active_animation = 0,

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
