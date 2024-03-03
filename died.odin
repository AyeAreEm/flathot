package main

import "core:fmt"
import rl "vendor:raylib"

died_update :: proc(self: ^Game) {
    player := &self.objects.player

    if rl.IsMouseButtonPressed(.LEFT) {
        rl.UnloadTexture(self.objects.player.anim_info.texture)
        rl.UnloadImage(self.objects.player.anim_info.image)

        level := init_lvl1()
        player.game_state = .Playing
    
        self.objects = level
    } else if rl.IsKeyPressed(.ESCAPE) {
        player.game_state = .Menu
    }
}

died_draw :: proc(self: ^Game) {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.Color{89, 19, 27, 0})
    rl.DrawText("game over", (WIDTH / 2 - 40), (HEIGHT / 2 - 40), 20, rl.WHITE)
}
