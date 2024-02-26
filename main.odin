package main

import "core:fmt"
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
    None,
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
    quadrant: Quadrant,

    movement: proc(self: ^Player, time_rate: ^f32),
    shoot: proc(self: ^Player, arr: ^[dynamic]Bullet),
}

Enemy :: struct {
    shape: rl.Rectangle,
    color: rl.Color,
    direction: rl.Vector2,
    quadrant: Quadrant,

    pathfind: proc(self: ^Enemy, target: Player, time_rate: f32)
}

Bullet :: struct {
    shape: rl.Rectangle,
    color: rl.Color,
    direction: rl.Vector2,
    is_enemy: bool,
    quadrant: Quadrant,

    update: proc(self: ^Bullet, arr: ^[dynamic]Bullet, index: int, time_rate: f32),
}

Objects :: struct {
    player: ^Player,
    enemies: ^[dynamic]Enemy,
    bullets: ^[dynamic]Bullet,

    collision_detect: proc(self: ^Objects),
}

make_quadrant :: proc(x, y: f32) -> Quadrant {
    quadrant: u8

    if x < 400 {
        quadrant += 1
    } else if x >= 400 && x < 800 {
        quadrant += 2
    } else if x >= 800 && x < 1200 {
        quadrant += 3
    }

    if y < 280 {
        quadrant += 0
    } else if y >= 280 && y < 560 {
        quadrant += 3
    } else  if y >= 560 && y < 840 {
        quadrant += 6
    }

    return (Quadrant)(quadrant)
}

collision_detect :: proc(self: ^Objects) {
    for i in 0..<len(self.enemies) {
        if self.player.quadrant == self.enemies[i].quadrant {
            if rl.CheckCollisionRecs(self.player.shape, self.enemies[i].shape) {
                fmt.println("enemy and player collide")
            }
        }

        for j in 0..<len(self.bullets) {
            p_b := false
            e_b := false

            if self.player.quadrant == self.bullets[j].quadrant {
                p_b = true
            }
            if self.enemies[i].quadrant == self.bullets[j].quadrant {
                e_b = true
            }

            if p_b == false && e_b == false {
                continue
            }
            if p_b && self.bullets[i].is_enemy {
                if rl.CheckCollisionRecs(self.player.shape, self.bullets[j].shape) {
                    fmt.println("player and bullet collide")
                }
            }
            if e_b {
                if rl.CheckCollisionRecs(self.enemies[i].shape, self.bullets[j].shape) {
                    ordered_remove(self.enemies, i)
                    ordered_remove(self.bullets, j)
                    fmt.println("enemy and bullet collide")
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
        quadrant = make_quadrant(spawn_x, spawn_y),

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
    self.objects.collision_detect(&self.objects)

    player := self.objects.player
    enemies := self.objects.enemies
    bullets := self.objects.bullets

    player.movement(player, &self.time_rate)
    player.quadrant = make_quadrant(player.shape.x, player.shape.y)

    if rl.IsMouseButtonPressed(.LEFT) {
        player.shoot(player, bullets)
    }

    for i in 0..<len(enemies^) {
        enemy := &enemies[i]
        enemy.pathfind(enemy, player^, self.time_rate)
        enemy.quadrant = make_quadrant(enemy.shape.x, enemy.shape.y)
    }

    for i in 0..<len(bullets^) {
        bullet := &bullets[i]
        bullet.update(bullet, bullets, i, self.time_rate)
        bullet.quadrant = make_quadrant(bullet.shape.x, bullet.shape.y)
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

    // rl.DrawLineEx({400, 0}, {400, 840}, 5, rl.GRAY)
    // rl.DrawLineEx({800, 0}, {800, 840}, 5, rl.GRAY)
    //
    // rl.DrawLineEx({0, 280}, {1200, 280}, 5, rl.GRAY)
    // rl.DrawLineEx({0, 560}, {1200, 560}, 5, rl.GRAY)
    
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
        quadrant = make_quadrant(530, 350),

        movement = handle_movement,
        shoot = shoot,
    }

    enemies := make([dynamic]Enemy, 0)
    bullets := make([dynamic]Bullet, 0)

    append(&enemies,
        Enemy {
            shape = {
                1130, 770, 70, 70,
            },
            color = rl.RED,
            direction = linalg.vector_normalize(rl.Vector2{player.shape.x, player.shape.y} - rl.Vector2{1130, 770}),
            quadrant = make_quadrant(1130, 770),

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
