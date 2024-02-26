package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

Game :: struct {
    width: i32,
    height: i32,
    target_fps: i32,
    
    time_rate: f32,
    objects: Objects,

    update: proc(self: ^Game),
    draw: proc(self: ^Game),
}

Quadrant :: enum {
    Q1,
    Q2,
    Q3,
    Q4,
    Q5,
    Q6,
    Q7,
    Q8,
    Q9,
}

Player :: struct {
    shape: rl.Rectangle,
    color: rl.Color,
    pace: f32,
    quadrants: [dynamic]Quadrant,

    movement: proc(self: ^Player, time_rate: ^f32),
    shoot: proc(self: ^Player, arr: ^[dynamic]Bullet),
}

Enemy :: struct {
    shape: rl.Rectangle,
    color: rl.Color,
    direction: rl.Vector2,
    quadrants: [dynamic]Quadrant,

    pathfind: proc(self: ^Enemy, target: Player, time_rate: f32)
}

Bullet :: struct {
    shape: rl.Rectangle,
    color: rl.Color,
    direction: rl.Vector2,
    is_enemy: bool,
    quadrants: [dynamic]Quadrant,

    update: proc(self: ^Bullet, arr: ^[dynamic]Bullet, index: int, time_rate: f32),
}

Objects :: struct {
    player: ^Player,
    enemies: ^[dynamic]Enemy,
    bullets: ^[dynamic]Bullet,

    collision_detect: proc(self: ^Objects),
}

make_quadrant :: proc(shape: rl.Rectangle) -> [dynamic]Quadrant {
    quadrants: [dynamic]Quadrant

    center := rl.Vector2 {
        shape.x + shape.width / 2,
        shape.y + shape.height / 2,
    }

    row := math.floor(center.y / 280)
    column := math.floor(center.x / 400)

    index := column + row * 3
    append(&quadrants, (Quadrant)(index))

    return quadrants
}

collision_detect :: proc(self: ^Objects) {
    for i in 0..<len(self.enemies) {
        collision := false
        for player_quad in self.player.quadrants {
            if collision {
                break
            }

            for enemy_quad in self.enemies[i].quadrants {
                if player_quad == enemy_quad && rl.CheckCollisionRecs(self.player.shape, self.enemies[i].shape) {
                    fmt.println("enemy and player collide")
                    break
                }
            }
        }
    }

    for i in 0..<len(self.bullets) {
        for player_quad in self.player.quadrants {
            for bullet_quad in self.bullets[i].quadrants {
                if player_quad == bullet_quad && self.bullets[i].is_enemy && rl.CheckCollisionRecs(self.player.shape, self.bullets[i].shape) {
                    fmt.println("player and bullet collide")
                    break
                }
            }
        }

        for j in 0..<len(self.enemies) {
            for bullet_quad in self.bullets[i].quadrants {
                for enemy_quad in self.enemies[j].quadrants {
                    if enemy_quad == bullet_quad && rl.CheckCollisionRecs(self.enemies[j].shape, self.bullets[i].shape) {
                        ordered_remove(self.bullets, i)
                        ordered_remove(self.enemies, j)
                        fmt.println("enemy and bullet collide")
                        break
                    }
                }
            }
        }
    }
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
        quadrants = make_quadrant(rl.Rectangle{spawn_x, spawn_y, 10, 10}),

        update = bullet_update,
    }

    append(arr, bullet)
}

bullet_update :: proc(self: ^Bullet, arr: ^[dynamic]Bullet, index: int, time_rate: f32) {
    self.shape.x += self.direction.x * time_rate
    self.shape.y += self.direction.y * time_rate

    if self.shape.x < 0 || self.shape.x > 1200 || self.shape.y < 0 || self.shape.y > 840 {
        ordered_remove(arr, index)
    }
}

pathfind :: proc(self: ^Enemy, target: Player, time_rate: f32) {
    self.shape.x += self.direction.x * time_rate
    self.shape.y += self.direction.y * time_rate

    self.direction = linalg.vector_normalize(rl.Vector2{target.shape.x, target.shape.y} - rl.Vector2{self.shape.x, self.shape.y})
}

handle_time_rate :: proc(time_rate: ^f32, has_moved: ^bool) {
    if time_rate^ <= 1 {
        time_rate^ += 0.01
        has_moved^ = true
    }
}

handle_movement :: proc(self: ^Player, time_rate: ^f32) {
    has_moved := false

    if rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT) {
        self.pace = 1.5
    } else {
        self.pace = 1
    }

    if rl.IsKeyDown(.W) {
        self.shape.y -= 1 * self.pace * time_rate^
        handle_time_rate(time_rate, &has_moved)
    }
    if rl.IsKeyDown(.S) {
        self.shape.y += 1 * self.pace * time_rate^
        handle_time_rate(time_rate, &has_moved)
    }
    if rl.IsKeyDown(.A) {
        self.shape.x -= 1 * self.pace * time_rate^
        handle_time_rate(time_rate, &has_moved)
    }
    if rl.IsKeyDown(.D) {
        self.shape.x += 1 * self.pace * time_rate^
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
    self.objects.collision_detect(&self.objects)

    player := self.objects.player
    enemies := self.objects.enemies
    bullets := self.objects.bullets

    player.movement(player, &self.time_rate)
    player.quadrants = make_quadrant(player.shape)

    if rl.IsMouseButtonPressed(.LEFT) {
        player.shoot(player, bullets)
    }

    for i in 0..<len(enemies^) {
        enemy := &enemies[i]
        enemy.pathfind(enemy, player^, self.time_rate)
        enemy.quadrants = make_quadrant(enemy.shape)
    }

    for i in 0..<len(bullets^) {
        bullet := &bullets[i]
        bullet.update(bullet, bullets, i, self.time_rate)
        bullet.quadrants = make_quadrant(bullet.shape)
    }
}

game_draw :: proc(self: ^Game) {
    player := self.objects.player
    enemies := self.objects.enemies
    bullets := self.objects.bullets

    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.RAYWHITE)
    rl.DrawRectangleRec(player.shape, player.color)

    rl.DrawLineEx({400, 0}, {400, 840}, 5, rl.GRAY)
    rl.DrawLineEx({800, 0}, {800, 840}, 5, rl.GRAY)

    rl.DrawLineEx({0, 280}, {1200, 280}, 5, rl.GRAY)
    rl.DrawLineEx({0, 560}, {1200, 560}, 5, rl.GRAY)
    
    for i in 0..<len(enemies^) {
        rl.DrawRectangleRec(enemies[i].shape, enemies[i].color)
    }

    for i in 0..<len(bullets^) {
        rl.DrawRectangleRec(bullets[i].shape, bullets[i].color)
    }
}

main :: proc() {

    player := Player {
        shape = rl.Rectangle {
            530, 350, 70, 70,
        },
        color = rl.BLACK,
        pace = 1,
        quadrants = make_quadrant(rl.Rectangle{530, 350, 70, 70}),

        movement = handle_movement,
        shoot = shoot,
    }
    fmt.println(player.quadrants)

    enemies := make([dynamic]Enemy, 0)
    bullets := make([dynamic]Bullet, 0)

    append(&enemies,
        Enemy {
            shape = {
                1130, 770, 70, 70,
            },
            color = rl.RED,
            direction = linalg.vector_normalize(rl.Vector2{player.shape.x, player.shape.y} - rl.Vector2{1130, 770}),
            quadrants = make_quadrant(rl.Rectangle{1130, 770, 70, 70}),

            pathfind = pathfind,
        },
        Enemy {
            shape = {
                0, 0, 70, 70,
            },
            color = rl.RED,
            direction = linalg.vector_normalize(rl.Vector2{player.shape.x, player.shape.y} - rl.Vector2{0, 0}),
            quadrants = make_quadrant(rl.Rectangle{0, 0, 70, 70}),

            pathfind = pathfind,
        },
    )

    objects := Objects {
        player = &player,
        enemies = &enemies,
        bullets = &bullets,

        collision_detect = collision_detect,
    }

    game := Game {
        width = 1200,
        height = 840,
        target_fps = 120,

        time_rate = 1,
        objects = objects,

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
