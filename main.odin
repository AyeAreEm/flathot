package main

import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"

Game :: struct {
    width: i32,
    height: i32,
    target_fps: i32,
    
    time_rate: f32,
    player: Player,
    sample: rl.Rectangle,
    enemies: [dynamic]Enemy,
    bullets: [dynamic]Bullet,
    quad_arr: [9][dynamic]QuadNode,

    update: proc(self: ^Game),
    draw: proc(self: ^Game),
}

Player :: struct {
    shape: rl.Rectangle,
    color: rl.Color,

    movement: proc(self: ^Player, time_rate: ^f32),
    shoot: proc(self: ^Player, arr: ^[dynamic]Bullet),
}

Enemy :: struct {
    shape: rl.Rectangle,
    color: rl.Color,
    direction: rl.Vector2,
}

Bullet :: struct {
    shape: rl.Rectangle,
    color: rl.Color,
    direction: rl.Vector2,
    is_enemy: bool,

    update: proc(self: ^Bullet, time_rate: f32),
}

QuadNodeType :: enum {
    Player,
    Enemy,
    Bullet,
}

QuadNode :: struct {
    type: QuadNodeType,
    pos: rl.Vector2,
    quadrant: u8,
    index: i32,
}

update_quadrant :: proc(self: ^QuadNode, arr: ^[9][dynamic]QuadNode, x, y: f32) {
    // finish this, test it, fix it

    if x == self.pos.x && y == self.pos.y {
        return
    }

    x_pos: int
    y_pos: int

    if x <= 400 {
        x_pos = 0
    } else if x > 400 && x <= 800 {
        x_pos = 1
    } else if x > 800 {
        x_pos = 2
    }

    if y <= 280 {
        y_pos = 0
    } else if y > 280 && y < 560 {
        y_pos = 3
    } else if y > 560 {
        y_pos = 6
    }

    cur_quad := x_pos + y_pos
    self.pos.x = x
    self.pos.y = y

    append(arr[cur_quad], self^)
    ordered_remove(arr[self.quadrant], self.index)
}

shoot :: proc(self: ^Player, arr: ^[dynamic]Bullet) {
    spawn_x := self.shape.x + (self.shape.width / 2) - 5
    spawn_y := self.shape.y + (self.shape.width / 2) - 5
    bullet := Bullet {
        shape = {
            x = spawn_x,
            y = spawn_y,
            width = 10,
            height = 10,
        },
        color = rl.DARKGRAY,
        direction = linalg.vector_normalize(rl.GetMousePosition() - rl.Vector2{spawn_x, spawn_y}),
        is_enemy = false,
        update = bullet_update,
    }

    append(arr, bullet)
}

bullet_update :: proc(self: ^Bullet, time_rate: f32) {
    self.shape.x += self.direction.x * time_rate
    self.shape.y += self.direction.y * time_rate
}

pathfind :: proc(
    time_rate: f32,
    mover_x: f32,
    mover_y: f32,
    target_x: f32,
    target_y: f32,
) -> (f32, f32) {
    x: f32
    y: f32

    if mover_x < target_x {
        x = mover_x + 1 * time_rate
    } else if mover_x > target_x {
        x = mover_x - 1 * time_rate
    }

    if mover_y < target_y {
        y = mover_y + 1 * time_rate
    } else if mover_y > target_y {
        y = mover_y - 1 * time_rate
    }

    return x, y
}

handle_time_rate :: proc(time_rate: ^f32, has_moved: ^bool) {
    if time_rate^ <= 1 {
        time_rate^ += 0.01
        has_moved^ = true
    }
}

handle_movement :: proc(self: ^Player, time_rate: ^f32) {
    has_moved := false

    if rl.IsKeyDown(.W) {
        self.shape.y -= 1 * time_rate^
        handle_time_rate(time_rate, &has_moved)
    }
    if rl.IsKeyDown(.S) {
        self.shape.y += 1 * time_rate^
        handle_time_rate(time_rate, &has_moved)
    }
    if rl.IsKeyDown(.A) {
        self.shape.x -= 1 * time_rate^
        handle_time_rate(time_rate, &has_moved)
    }
    if rl.IsKeyDown(.D) {
        self.shape.x += 1 * time_rate^
        handle_time_rate(time_rate, &has_moved)
    }

    if !has_moved && time_rate^ >= 0 {
        time_rate^ -= 0.01
    }
    if time_rate^ < 0 {
        time_rate^ = 0.01
    }
}

game_update :: proc(self: ^Game) {
    update_quadrant(&self.player.quadrant, self.player.shape.x, self.player.shape.y)

    self.player.movement(&self.player, &self.time_rate)

    if rl.IsMouseButtonPressed(.LEFT) {
        self.player.shoot(&self.player, &self.bullets)
    }

    self.sample.x, self.sample.y = pathfind(self.time_rate, self.sample.x, self.sample.y, self.player.shape.x, self.player.shape.y)
    if len(self.bullets) > 0 {
        for i in 0..<len(self.bullets) {
            bullet := &self.bullets[i]
            if rl.CheckCollisionRecs(bullet.shape, self.sample) {
                fmt.println("bullet hit sample, noice")
            }
            bullet.update(bullet, self.time_rate)
        }
    }

    // if rl.CheckCollisionRecs(self.player.shape, self.sample) {
    //     fmt.println("boxes touched, game over")
    // }
}

game_draw :: proc(self: ^Game) {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.RAYWHITE)
    rl.DrawRectangleRec(self.player.shape, self.player.color)
    rl.DrawRectangleRec(self.sample, rl.RED)

    rl.DrawLineEx({400, 0}, {400, 840}, 5, rl.GRAY)
    rl.DrawLineEx({800, 0}, {800, 840}, 5, rl.GRAY)

    rl.DrawLineEx({0, 280}, {1200, 280}, 5, rl.GRAY)
    rl.DrawLineEx({0, 560}, {1200, 560}, 5, rl.GRAY)
    
    if len(self.bullets) > 0 {
        for i in 0..<len(self.bullets) {
            rl.DrawRectangleRec(self.bullets[i].shape, self.bullets[i].color)
        }
    }
}

main :: proc() {

    player := Player {
        shape = rl.Rectangle {
            530, 350, 70, 70,
        },
        color = rl.BLACK,
        movement = handle_movement,
        shoot = shoot,
    }

    game := Game {
        width = 1200,
        height = 840,
        target_fps = 120,

        time_rate = 1,
        player = player,
        sample = {
            1130, 770, 70, 70,
        },
        enemies = make([dynamic]Enemy, 0),
        bullets = make([dynamic]Bullet, 0),
        quad_arr = make([9][dynamic]QuadNode),

        update = game_update,
        draw = game_draw,
    }

    rl.InitWindow(game.width, game.height, "flathot")
    rl.SetTargetFPS(game.target_fps)
    rl.SetConfigFlags({.MSAA_4X_HINT})

    for (!rl.WindowShouldClose()) {
        game.update(&game)
        game.draw(&game)
    }

    rl.CloseWindow()
}
