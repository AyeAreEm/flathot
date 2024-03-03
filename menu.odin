package main

import "core:fmt"
import rl "vendor:raylib"

menu_procs := map[cstring]proc(self: ^Objects) {
    "start" = menu_start,
    "quit" = menu_quit,
}

menu_update :: proc(self: ^Game) {
   self.objects.collision_detect(&self.objects)
}

menu_draw :: proc(self: ^Game) {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.BLACK)
    for i in 0..<len(self.objects.obstacles) {
        ob := self.objects.obstacles[i]
        
        rl.DrawRectangleRec(ob.shape, ob.color)
        rl.DrawText(ob.text, cast(i32)ob.shape.x + cast(i32)(ob.shape.width / 2 - 20), cast(i32)ob.shape.y + cast(i32)(ob.shape.height / 2 - 10), 20, rl.WHITE)
    }
}

collision_menu :: proc(self: ^Objects) {
    for i in 0..<len(self.obstacles) {
        if rl.CheckCollisionPointRec(rl.GetMousePosition(), self.obstacles[i].shape) {
            if rl.IsMouseButtonPressed(.LEFT) {
                menu_procs[self.obstacles[i].text](self)
            }
        }
    }
}

init_menu :: proc() -> Objects {
    player_menu := Player {
        shape = {
            0, 0, 0, 0,
        },
        color = rl.BLACK,
        pace = 0,
        game_state = .Menu,

        movement = nil,
        shoot = nil,
    }

    obstacles_menu := make([dynamic]Obstacle, 0)
    append(&obstacles_menu,
        Obstacle {
            shape = {
                WIDTH / 2 - 100, HEIGHT / 2 - 25, 200, 50,
            },
            color = rl.DARKGRAY,
            text = "start",
        },
        Obstacle {
            shape = {
                WIDTH / 2 - 100, HEIGHT / 2 + 50, 200, 50,
            },
            color = rl.DARKGRAY,
            text = "quit",
        },
    )

    objects_menu := Objects {
        player = player_menu,
        enemies = nil,
        bullets = nil,
        obstacles = obstacles_menu,

        collision_detect = collision_menu,
    }

    return objects_menu
}

menu_start :: proc(self: ^Objects) {
    self^ = init_lvl1()
}

menu_quit :: proc(self: ^Objects) {
    CLOSE_WINDOW = true
}
