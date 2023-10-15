package terminus

import "core:math/linalg"
import "core:math"
import "core:fmt"
import rl "vendor:raylib"

// render a string of text - very rudimentary
render_text :: proc(text: string) {
    x, y : int
    for _, i in text {
        if text[i] == '\n' {
            y += 1
            x = 0
            continue
        }
        char_matrix[x][y] = text[i]
        color_matrix[x][y] = rl.RAYWHITE
        x += 1
    }
}

// test - draws diagonal pattern
pattern1 :: proc() {
    for x in u8(0)..<SCREEN_WIDTH/CHAR_WIDTH {
    for y in u8(0)..<SCREEN_HEIGHT/CHAR_HEIGHT {
        char_matrix[x][y] = x+y
        color_matrix[x][y] = rl.RAYWHITE
    }
    }
}

// test - draws circular pattern
pattern2 :: proc() {
    for x in u8(0)..<SCREEN_WIDTH/CHAR_WIDTH {
    for y in u8(0)..<SCREEN_HEIGHT/CHAR_HEIGHT {

        origin :: [2]f64{
            SCREEN_WIDTH/CHAR_WIDTH/2,
            SCREEN_HEIGHT/CHAR_HEIGHT/2*CHAR_HEIGHT/CHAR_WIDTH,
        }

        pos := [2]f64{
            f64(x),
            f64(y)*CHAR_HEIGHT/CHAR_WIDTH,
        }

        len := abs(math.round(linalg.vector_length(origin-pos)))

        char_matrix[x][y] = u8(len) % 20 + 0xB0
        //color_matrix[x][y] = {len - u8(rl.GetTime()*30), 0, len - u8(rl.GetTime()*30)-100, 255}
    
        //color_matrix[x][y] = lerp_hsv(rl.RED, rl.BLUE, cast(f32)abs(math.mod((len*3 - (rl.GetTime()*3)), 1)))
        color_matrix[x][y] = lerp_hsv(rl.RED, rl.BLUE, 0.02*f32(len))
    }
    }
}

// experiment
mouse_reactive_1 :: proc() {

    for x in i32(0)..<SCREEN_WIDTH/CHAR_WIDTH {
    for y in i32(0)..<SCREEN_HEIGHT/CHAR_HEIGHT {
        if char_matrix[x][y] > 0x20 {
            char_matrix[x][y] -= 1
        }
        color_matrix[x][y] = rl.RAYWHITE

    }
    }

    // mouse_delta := rl.GetMouseDelta()
    mouse_pos := rl.GetMousePosition()

    for x in i32(0)..<SCREEN_WIDTH/CHAR_WIDTH {
    for y in i32(0)..<SCREEN_HEIGHT/CHAR_HEIGHT {
        distance := math.sqrt(math.pow(f32(x*CHAR_WIDTH) - mouse_pos.x,2)+math.pow(f32(y*CHAR_HEIGHT) - mouse_pos.y,2))
    
        if distance <= 100 {
            char_matrix[x][y] = u8(map_range(distance, 0, 100, 0x21, 0x7a)) //u8(map_range(distance, 0, 500, 0xB0, 0xDF))
        }
    }
    }

}

// experiment
mouse_reactive_2 :: proc() {

    for x in i32(0)..<SCREEN_WIDTH/CHAR_WIDTH {
    for y in i32(0)..<SCREEN_HEIGHT/CHAR_HEIGHT {
        if char_matrix[x][y] > 0 {
            char_matrix[x][y] -= 1
        }
        color_matrix[x][y] = rl.RAYWHITE

    }
    }

    // mouse_delta := rl.GetMouseDelta()
    mouse_pos := rl.GetMousePosition()

    for x in i32(0)..<SCREEN_WIDTH/CHAR_WIDTH {
    for y in i32(0)..<SCREEN_HEIGHT/CHAR_HEIGHT {
        distance := math.sqrt(math.pow(f32(x*CHAR_WIDTH) - mouse_pos.x,2)+math.pow(f32(y*CHAR_HEIGHT) - mouse_pos.y,2))
    
        if distance <= 50 {
            char_matrix[x][y] = 0xdb //u8(map_range(distance, 0, 100, 0, 10))
        }
    }
    }

}