package main

import "core:fmt"
import rl "vendor:raylib"

Game :: struct {
    width: i32,
    height: i32,
    target_fps: i32,
    update: proc(self: ^Game),
    draw: proc(self: ^Game),
    time_rate: f32,
    character: rl.Rectangle,
    character_color: rl.Color,
    sample: rl.Rectangle,
    bullets: [dynamic]Bullet,
}

Bullet :: struct {
    shape: rl.Rectangle,
    color: rl.Color,
    target: rl.Vector2,
    is_enemy: bool,
}

shoot :: proc(self: ^Game) {
    bullet := Bullet {
        shape = {
            x = self.character.x + (self.character.width / 2) - 5,
            y = self.character.y + (self.character.height / 2) - 5,
            width = 10,
            height = 10,
        },
        color = rl.DARKGRAY,
        target = rl.GetMousePosition(),
        is_enemy = false,
    }

    append(&self.bullets, bullet)
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

handle_time_rate :: proc(self: ^Game, has_moved: ^bool) {
    if self.time_rate <= 1 {
        self.time_rate += 0.01
        has_moved^ = true
    }
}

handle_movement :: proc(self: ^Game) {
    has_moved := false

    if rl.IsKeyDown(.W) {
        self.character.y -= 1 * self.time_rate
        handle_time_rate(self, &has_moved)
    }
    if rl.IsKeyDown(.S) {
        self.character.y += 1 * self.time_rate
        handle_time_rate(self, &has_moved)
    }
    if rl.IsKeyDown(.A) {
        self.character.x -= 1 * self.time_rate
        handle_time_rate(self, &has_moved)
    }
    if rl.IsKeyDown(.D) {
        self.character.x += 1 * self.time_rate
        handle_time_rate(self, &has_moved)
    }

    if !has_moved && self.time_rate >= 0 {
        self.time_rate -= 0.01
    }
    if self.time_rate < 0 {
        self.time_rate = 0.01
    }
}

update :: proc(self: ^Game) {
    handle_movement(self)

    if rl.IsMouseButtonPressed(.LEFT) {
        shoot(self)
    }

    self.sample.x, self.sample.y = pathfind(self.time_rate, self.sample.x, self.sample.y, self.character.x, self.character.y)
    if len(self.bullets) > 0 {
        for i in 0..<len(self.bullets) {
            bullet := self.bullets[i].shape
            target := self.bullets[i].target
            if rl.CheckCollisionRecs(bullet, self.sample) {
                fmt.println("bullet hit sample, noice")
            }
            self.bullets[i].shape.x, self.bullets[i].shape.y = pathfind(self.time_rate, bullet.x, bullet.y, target[0], target[1])
        }
    }

    if rl.CheckCollisionRecs(self.character, self.sample) {
        fmt.println("boxes touched, game over")
    }
}

draw :: proc(self: ^Game) {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.RAYWHITE)
    rl.DrawRectangleRec(self.character, self.character_color)
    rl.DrawRectangleRec(self.sample, rl.RED)
    
    if len(self.bullets) > 0 {
        for i in 0..<len(self.bullets) {
            rl.DrawRectangleRec(self.bullets[i].shape, self.bullets[i].color)
        }
    }
}

main :: proc() {
    game := Game {
        width = 1200,
        height = 840,
        target_fps = 120,
        update = update,
        draw = draw,
        time_rate = 1,
        character = rl.Rectangle {
            530, 350, 70, 70,
        },
        character_color = rl.BLACK,
        sample = {
            1130, 770, 70, 70,
        },
        bullets = make([dynamic]Bullet, 0),
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
