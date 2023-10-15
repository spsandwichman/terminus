package terminus

import "core:fmt"
import rl "vendor:raylib"

// RENDER_TEXT :: 
//     "SIDE A\n\xC3" +   "\xC4 " +
//     "Evaluate\n\xC3" +    "\xC4 " +
//     "SysEx\n\xC3" +   "\xC4 " +
//     "Offset\n\xC3" +   "\xC4 " +
//     "Handshake\n\xC0" +   "\xC4 " +
//     "Carrier"

RENDER_TEXT :: "CGR-003"

IMAGE_PATH :: "ref/7.png"


// SCREEN_WIDTH  :: CHAR_WIDTH*len(RENDER_TEXT)
// SCREEN_HEIGHT :: CHAR_HEIGHT*1
SCREEN_WIDTH  :: CHAR_WIDTH*CHAR_HEIGHT*6
SCREEN_HEIGHT :: CHAR_WIDTH*CHAR_HEIGHT*6
CHAR_WIDTH  :: 8
CHAR_HEIGHT :: 14

font_texture : rl.Texture2D
font_image   : rl.Image

char_matrix  : [SCREEN_WIDTH/CHAR_WIDTH][SCREEN_HEIGHT/CHAR_HEIGHT]u8
color_matrix : [SCREEN_WIDTH/CHAR_WIDTH][SCREEN_HEIGHT/CHAR_HEIGHT]rl.Color

ref_texture : rl.Texture2D
ref_image   : rl.Image

main :: proc() {

    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "terminus")
    defer rl.CloseWindow()

    // rl.SetTargetFPS(100)

    ref_texture = rl.LoadTexture(IMAGE_PATH)
    defer rl.UnloadTexture(ref_texture)

    ref_image = rl.LoadImageFromTexture(ref_texture)
    defer rl.UnloadImage(ref_image)

    rl.ImageResize(&ref_image, SCREEN_WIDTH, SCREEN_HEIGHT)

    font_texture = rl.LoadTexture("font_alpha.png")
    defer rl.UnloadTexture(font_texture)

    font_image = rl.LoadImageFromTexture(font_texture)
    defer rl.UnloadImage(font_image)

    fmt.printf("\n\n%dx%d\n\n\n", SCREEN_WIDTH/CHAR_WIDTH, SCREEN_HEIGHT/CHAR_HEIGHT)

    for !rl.WindowShouldClose() {

        rl.BeginDrawing()
            rl.ClearBackground(rl.BLACK)
            rl.BeginBlendMode(.ALPHA)
            rl.EndBlendMode()
        rl.EndDrawing()

            pattern4() // warning - very slow

            // render_text(RENDER_TEXT)

            draw_matrix()

        //     rl.EndBlendMode()
        // rl.EndDrawing()
    
        // screen_image := rl.LoadImageFromScreen()
        // rl.ExportImage(screen_image,"text/"+RENDER_TEXT+".png")
        
    }
}

draw_matrix :: proc() {
    for x in i32(0)..<SCREEN_WIDTH/CHAR_WIDTH {
        for y in i32(0)..<SCREEN_HEIGHT/CHAR_HEIGHT {
            draw_font_char(char_matrix[x][y], x*CHAR_WIDTH, y*CHAR_HEIGHT, color_matrix[x][y])
        }
    }
}

draw_font_char :: proc(char: u8, x, y: i32, color : rl.Color) {
    fontx, fonty := char_pos(char)
    font_rect := rl.Rectangle{f32(fontx),f32(fonty), CHAR_WIDTH , CHAR_HEIGHT}
    rl.DrawTextureRec(font_texture, font_rect, rl.Vector2{f32(x),f32(y)}, color)
}

char_pos :: proc(char: u8) -> (w,h: i32) {
    return i32((char % 16)*9+1), i32((char / 16)*15)
}