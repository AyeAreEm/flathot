package main

import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"

init_lvl1 :: proc() -> Objects {
    left_idle_frames: i32 = 0
    left_idle_img := rl.LoadImageAnim("resources/character/Outline/120x80_gifs/__Idle_l.gif", &left_idle_frames)
    left_idle_texture := rl.LoadTextureFromImage(left_idle_img)

    right_idle_frames: i32 = 0
    right_idle_img := rl.LoadImageAnim("resources/character/Outline/120x80_gifs/__Idle_r.gif", &right_idle_frames)
    right_idle_texture := rl.LoadTextureFromImage(right_idle_img)

    left_run_frames: i32 = 0
    left_run_img := rl.LoadImageAnim("resources/character/Outline/120x80_gifs/__Run_l.gif", &left_run_frames)
    left_run_texture := rl.LoadTextureFromImage(left_run_img)

    right_run_frames: i32 = 0
    right_run_img := rl.LoadImageAnim("resources/character/Outline/120x80_gifs/__Run_r.gif", &right_run_frames)
    right_run_texture := rl.LoadTextureFromImage(left_run_img)

    animations := [4]AnimateInfo{
        AnimateInfo{left_idle_img, left_idle_texture, cast(int)left_idle_frames, 0, 8, 0},
        AnimateInfo{right_idle_img, right_idle_texture, cast(int)right_idle_frames, 0, 8, 0},
        AnimateInfo{left_run_img, left_run_texture, cast(int)left_run_frames, 0, 8, 0},
        AnimateInfo{right_run_img, right_run_texture, cast(int)right_run_frames, 0, 8, 0},
    }

    player_lvl1 := Player {
        animations = animations,
        active_animation = 0,
        direction = 0,

        shape = {WIDTH / 2 - 55, HEIGHT / 2 - 60, 44, 79},
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
