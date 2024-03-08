package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

WIDTH :: 1200
HEIGHT :: 840
TIME_RATE: f32 = 1
CLOSE_WINDOW := false
DEBUG_MODE := false

GameState :: enum {
    Menu,
    Playing,
    Over,
}

Game :: struct {
    width: i32,
    height: i32,
    target_fps: i32,
    
    objects: Objects,

    update: proc(self: ^Game),
    draw: proc(self: ^Game),
}

Timer :: struct {
    start: f64,
    lifetime: f64,
}

AnimateInfo :: struct {
    image: rl.Image,
    texture: rl.Texture,
    frames: int,
    current_frame: int,
    frame_delay: int,
    frame_counter: int,
}

Player :: struct {
    animations: [4]AnimateInfo,
    active_animation: int,
    direction: int,
    shape: rl.Rectangle,
    color: rl.Color,
    pace: f32,
    game_state: GameState,

    movement: proc(self: ^Player),
    shoot: proc(self: ^rl.Rectangle, target: rl.Vector2, is_enemy: bool, arr: ^[dynamic]Bullet),
    animate: proc(self: ^AnimateInfo, condition: int, constant: int)
}

Enemy :: struct {
    animations: AnimateInfo,
    shape: rl.Rectangle,
    color: rl.Color,
    direction: rl.Vector2,
    shoot_cooldown: Timer,

    pathfind: proc(self: ^Enemy, target: Player),
    shoot: proc(self: ^rl.Rectangle, target: rl.Vector2, is_enemy: bool, arr: ^[dynamic]Bullet),
    animate: proc(self: ^AnimateInfo, condition: int, constant: int)
}

Bullet :: struct {
    shape: rl.Rectangle,
    color: rl.Color,
    direction: rl.Vector2,
    is_enemy: bool,

    update: proc(self: ^Bullet, arr: ^[dynamic]Bullet, index: int),
}

Obstacle :: struct {
    shape: rl.Rectangle,
    color: rl.Color,
    text: cstring,
}

Objects :: struct {
    player: Player,
    enemies: [dynamic]Enemy,
    bullets: [dynamic]Bullet,
    obstacles: [dynamic]Obstacle,

    collision_detect: proc(self: ^Objects)
}

is_timer_done :: proc(timer: Timer, multiplier: f32) -> bool {
    return rl.GetTime() * cast(f64)multiplier - timer.start >= timer.lifetime;
}

collision_detect :: proc(self: ^Objects) {
    for i in 0..<len(self.obstacles) {
        if rl.CheckCollisionRecs(self.player.shape, self.obstacles[i].shape) {
            fmt.println("wall and player collide")
        }

        for j in 0..<len(self.enemies) {
            if rl.CheckCollisionRecs(self.enemies[j].shape, self.obstacles[i].shape) {
                fmt.println("wall and enemy collide")
            }
        }

        for j in 0..<len(self.bullets) {
            if rl.CheckCollisionRecs(self.bullets[j].shape, self.obstacles[i].shape) {
                fmt.println("wall, bullet delete")
                ordered_remove(&self.bullets, j)
            }
        }
    }

    for i in 0..<len(self.bullets) {
        if rl.CheckCollisionRecs(self.player.shape, self.bullets[i].shape) && self.bullets[i].is_enemy {
            fmt.println("bullet and player collide")
            self.player.game_state = .Over
        }

        for j in 0..<len(self.enemies) {
            if rl.CheckCollisionRecs(self.enemies[j].shape, self.bullets[i].shape) && !self.bullets[i].is_enemy {
                fmt.println("bullet, enemy delete")
                ordered_remove(&self.enemies, j)
            }
        }
    }

    for i in 0..<len(self.enemies) {
        if rl.CheckCollisionRecs(self.player.shape, self.enemies[i].shape) {
            fmt.println("enemy and player collide")
        }
    }
}

shoot :: proc(self: ^rl.Rectangle, target: rl.Vector2, is_enemy: bool, arr: ^[dynamic]Bullet) {
    spawn_x := self.x + (self.width / 2) - 5
    spawn_y := self.y + (self.height / 2) - 5
    bullet := Bullet {
        shape = {
            x = spawn_x,
            y = spawn_y,
            width = 10,
            height = 10,
        },
        color = rl.DARKGRAY,
        direction = linalg.vector_normalize(target - rl.Vector2{spawn_x, spawn_y}),
        is_enemy = is_enemy,

        update = bullet_update,
    }

    append(arr, bullet)
}

bullet_update :: proc(self: ^Bullet, arr: ^[dynamic]Bullet, index: int) {
    self.shape.x += self.direction.x * TIME_RATE* 3
    self.shape.y += self.direction.y * TIME_RATE * 3

    if self.shape.x < 0 || self.shape.x > WIDTH || self.shape.y < 0 || self.shape.y > HEIGHT {
        ordered_remove(arr, index)
    }
}

pathfind :: proc(self: ^Enemy, target: Player) {
    self.shape.x += self.direction.x * TIME_RATE
    self.shape.y += self.direction.y * TIME_RATE

    self.direction = linalg.vector_normalize(rl.Vector2{target.shape.x, target.shape.y} - rl.Vector2{self.shape.x, self.shape.y})
}

animate :: proc(self: ^AnimateInfo, condition: int, constant: int) {
    this_frame_delay := cast(int)(cast(f32)self.frame_delay * (1 - TIME_RATE))
    if this_frame_delay < condition {
        this_frame_delay += constant
    }
    fmt.println(this_frame_delay)

    self.frame_counter += 1
    if self.frame_counter >= this_frame_delay {
        self.current_frame += 1

        if self.current_frame >= self.frames do self.current_frame = 0
        next_frame_offset := cast(int)self.image.width * cast(int)self.image.height * cast(int)4 * self.current_frame

        rl.UpdateTexture(self.texture, cast(rawptr)(cast(uintptr)(cast(int)cast(uintptr)self.image.data + next_frame_offset)))
        self.frame_counter = 0
    }
}

handle_time_rate :: proc() -> bool {
    if TIME_RATE <= 1 {
        TIME_RATE += 0.01
    }

    return true
}

handle_movement :: proc(self: ^Player) {
    has_moved := false
    direction := self.direction

    if rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT) {
        self.pace = 1.5
    } else {
        self.pace = 1
    }

    if rl.IsKeyDown(.W) || rl.IsKeyPressedRepeat(.W) {
        self.shape.y -= 1 * self.pace * TIME_RATE
        has_moved = handle_time_rate()
    }
    if rl.IsKeyDown(.S) || rl.IsKeyPressedRepeat(.S) {
        self.shape.y += 1 * self.pace * TIME_RATE
        has_moved = handle_time_rate()
    }
    if rl.IsKeyDown(.A) || rl.IsKeyPressedRepeat(.A) {
        self.shape.x -= 1 * self.pace * TIME_RATE
        direction = 0
        has_moved = handle_time_rate()
    }
    if rl.IsKeyDown(.D) || rl.IsKeyPressedRepeat(.D) {
        self.shape.x += 1 * self.pace * TIME_RATE
        direction = 1
        has_moved = handle_time_rate()
    }

    if !has_moved && TIME_RATE >= 0 {
        TIME_RATE -= 0.01
    }
    if TIME_RATE < 0 {
        TIME_RATE = 0.01
    }

    switch direction {
        case 0:
            if has_moved {
                self.active_animation = 2
                self.animate(&self.animations[2], 12, 10)
            } else {
                self.active_animation = 0
                self.animate(&self.animations[0], 12, 10)
            }
        case 1:
            if has_moved {
                self.active_animation = 3
                self.animate(&self.animations[3], 12, 10)
            } else {
                self.active_animation = 1
                self.animate(&self.animations[1], 12, 10)
            }
    }

    self.direction = direction
}

game_update :: proc(self: ^Game) {
    player := &self.objects.player
    enemies := self.objects.enemies
    bullets := &self.objects.bullets
    obstacles := &self.objects.obstacles

    player.movement(player)

    if rl.IsMouseButtonPressed(.LEFT) {
        player.shoot(&player.shape, rl.GetMousePosition(), false, bullets)
    }

    if rl.IsMouseButtonPressed(.MIDDLE) {
        DEBUG_MODE = !DEBUG_MODE
    }

    for i in 0..<len(enemies) {
        enemy := &enemies[i]
        enemy.pathfind(enemy, player^)
        enemy.animate(&enemy.animations, 12, 25)
        
        if is_timer_done(enemy.shoot_cooldown, TIME_RATE) {
            // bug, in slowmo, first bullet spawns correct but the next ones spawn immediately next frame
            enemy.shoot(&enemy.shape, rl.Vector2{player.shape.x, player.shape.y}, true, bullets)
            lifetime := enemy.shoot_cooldown.lifetime
            enemy.shoot_cooldown = {
                rl.GetTime(),
                lifetime,
            }
        }
    }

    for i in 0..<len(bullets) {
        bullet := &bullets[i]
        bullet.update(bullet, bullets, i)
    }

    self.objects.collision_detect(&self.objects)
}

game_draw :: proc(self: ^Game) {
    player := self.objects.player
    enemies := self.objects.enemies
    bullets := self.objects.bullets
    obstacles := self.objects.obstacles

    rl.BeginDrawing()
    defer rl.EndDrawing()
    rl.ClearBackground(rl.RAYWHITE)
    
    rl.DrawTexturePro(player.animations[player.active_animation].texture, rl.Rectangle{44, 42, 65, 79}, rl.Rectangle{player.shape.x, player.shape.y, 65*2, 79*2}, rl.Vector2{0, 0}, 0, rl.WHITE)

    if DEBUG_MODE {
        rl.DrawRectangleRec(player.shape, rl.Color{10, 10, 10, 60})
    }
    
    for i in 0..<len(enemies) {
        rl.DrawTexturePro(enemies[i].animations.texture, rl.Rectangle{0, 0, enemies[i].shape.width/4, enemies[i].shape.height/4}, rl.Rectangle{enemies[i].shape.x, enemies[i].shape.y, enemies[i].shape.width, enemies[i].shape.height}, rl.Vector2{0, 0}, 0, rl.WHITE)

        if DEBUG_MODE {
            rl.DrawRectangleRec(enemies[i].shape, rl.Color{10, 10, 10, 60})
        }
    }

    for i in 0..<len(bullets) {
        rl.DrawRectangleRec(bullets[i].shape, bullets[i].color)
    }

    for i in 0..<len(obstacles) {
        rl.DrawRectangleRec(obstacles[i].shape, obstacles[i].color)
    }
}

main :: proc() {
    game := Game {
        width = WIDTH,
        height = HEIGHT,
        target_fps = 120,

        objects = init_menu(),

        update = game_update,
        draw = game_draw,
    }
    
    rl.InitWindow(game.width, game.height, "flathot")
    rl.SetTargetFPS(game.target_fps)
    rl.SetConfigFlags({.MSAA_4X_HINT})
    rl.SetExitKey(.Q)

    for (!rl.WindowShouldClose() && !CLOSE_WINDOW) {
        if game.objects.player.game_state == .Playing {
            game.update(&game)
            game.draw(&game)
        } else if game.objects.player.game_state == .Menu {
            menu_update(&game)
            menu_draw(&game)
        } else {
            died_update(&game)
            died_draw(&game)
        }
    }

    rl.CloseWindow()
}
