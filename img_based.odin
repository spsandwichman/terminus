package terminus

import "core:fmt"
import rl "vendor:raylib"
import "core:math/linalg"
import "core:math"

// generation - maps characters based on luminosity
pattern3 :: proc() {
    for x in i32(0)..<SCREEN_WIDTH/CHAR_WIDTH {
    for y in i32(0)..<SCREEN_HEIGHT/CHAR_HEIGHT {

        // terrible garbage

        img_x := i32(f32(x)/(SCREEN_WIDTH/CHAR_WIDTH)*f32(ref_image.width))
        img_y := i32(f32(y)/(SCREEN_HEIGHT/CHAR_HEIGHT)*f32(ref_image.height)*(CHAR_HEIGHT/CHAR_WIDTH))

        char_color := rl.GetImageColor(ref_image, img_x, img_y)
        char_color_hsv := rl.ColorToHSV(char_color)

        // / ░ ▒ ▓ █ 
        //index := []u8{0x00, '.' , '/', '*' , 0xB0, 0xB1, 0xB2, 0xDB}
        
        //  .,_*^=+///{}&#
        index := []u8{' ', '.', '_', '*', '/', '\\', '&'}

        color_matrix[x][y] = rl.ColorFromHSV(char_color_hsv[0], 
            1 if char_color_hsv[1] > 0.07 else 0, 
            1,
        )
        
        char_matrix[x][y] = chunk_luma_map(ref_image, img_x, img_y, index)

    }
    }

}

// generation - maps characters based on MSE (mean squared error) similarity to the underyling image
// WARNING: SLOW AND JANK
pattern4 :: proc() {

    char_count : i32 = 0
    for x in i32(0)..<SCREEN_WIDTH/CHAR_WIDTH {
    for y in i32(0)..<SCREEN_HEIGHT/CHAR_HEIGHT {

        rl.BeginDrawing()
        rl.BeginBlendMode(.ALPHA)
        // terrible garbage

        img_x := i32(f32(x)/(SCREEN_WIDTH/CHAR_WIDTH)*f32(ref_image.width))
        img_y := i32(f32(y)/(SCREEN_HEIGHT/CHAR_HEIGHT)*f32(ref_image.height)*(CHAR_HEIGHT/CHAR_WIDTH))

        chunk_width  := i32(f32(x+1)/(SCREEN_WIDTH/CHAR_WIDTH)*f32(ref_image.width)) - img_x
        chunk_height := i32(f32(y+1)/(SCREEN_HEIGHT/CHAR_HEIGHT)*f32(ref_image.height)*(CHAR_HEIGHT/CHAR_WIDTH)) - img_y


        char_color := rl.GetImageColor(ref_image, img_x, img_y)
        char_color_hsv := rl.ColorToHSV(char_color)

        // / ░ ▒ ▓ █ 
        //index := []u8{0x00, '.', '_', '*', '/', '\\', 0xB0, 0xB1, 0xB2, 0xDB}

        //index := []u8{0x00, 0xDC, 0xDF, 0xDD, 0xDE, 0xDB}
        
        //  .,_*^=+///{}&#
        //index := []u8{' ', '[', ']', '*', '/', '\\'}

        index := []u8{' ', ' ', '.', '_', '*', '^', '=', '/', '\\'}


        chunk_avg_color := average_color_rgb(ref_image, img_x, img_y, chunk_width, chunk_height)
        chunk_avg_color_hsv := rl.ColorToHSV(chunk_avg_color)

        color_matrix[x][y] = chunk_avg_color
        // color_matrix[x][y] = rl.RAYWHITE
        
        // color_matrix[x][y] = rl.ColorFromHSV(chunk_avg_color_hsv[0], 
        //     1 if chunk_avg_color_hsv[1] > 0.3 else 0, 
        //     1 if chunk_avg_color_hsv[2] > 0.1 else 0, 
        // )

        // chunk_avg_color_hsl := color_to_hsl(chunk_avg_color)
        // color_matrix[x][y] = hsl_to_color(chunk_avg_color_hsl[0], 
        //     chunk_avg_color_hsl[1],
        //     chunk_avg_color_hsl[2],
        // )


        // char_matrix[x][y] = chunk_luma_map(ref_image, img_x, img_y, index)
        // char_matrix[x][y] = chunk_mse_map_full(ref_image, img_x, img_y, color_matrix[x][y])
        char_matrix[x][y] = chunk_mse_map(ref_image, img_x, img_y, index, color_matrix[x][y])
        //char_matrix[x][y] = 0xDB

        char_count += 1
        if math.mod(f32(char_count*100)/f32((SCREEN_WIDTH/CHAR_WIDTH)*(SCREEN_HEIGHT/CHAR_HEIGHT)),1) < 0.001 {
            fmt.printf("%.2f%%\n",f32(char_count*100)/f32((SCREEN_WIDTH/CHAR_WIDTH)*(SCREEN_HEIGHT/CHAR_HEIGHT)))
        }

        draw_matrix()

        rl.EndBlendMode()
        rl.EndDrawing()

    }
    }

}

// luminosity of a color
luma :: proc(color: rl.Color) -> f32 {
    return math.sqrt( // luminance formula
        0.299*math.pow(f32(color.r)/255,2) +
        0.587*math.pow(f32(color.g)/255,2) +
        0.114*math.pow(f32(color.b)/255,2),
    )
}

// map luminosity of a sampled point to a character range (lowest to highest)
point_luma_map :: proc(im: rl.Image, x,y: i32, index: []u8) -> u8 {
    
    color := rl.GetImageColor(im, 
        x,
        y,
    )

    char_brightness := luma(color)
    
    return index[min(int(map_range(char_brightness,0,1,0,f32(len(index)))),len(index))]
}

// get rgb-averaged color of an image chunk
average_color_rgb :: proc(im: rl.Image, x, y, width, height: i32) -> rl.Color {

    avg_col : [4]u32

    for i in 0..<width {
    for j in 0..<height {

        color := rl.GetImageColor(im, x+i, y+j)

        avg_col += {u32(color.r),u32(color.g),u32(color.b),u32(color.a)}
    }
    }

    avg_col /= transmute([4]u32) [4]i32{width*height,width*height,width*height,width*height}

    return {u8(avg_col.r),u8(avg_col.g),u8(avg_col.b),u8(avg_col.a)}
}

// get hsv-averaged color of an image chunk
average_color_hsv :: proc(im: rl.Image, x, y, width, height: i32) -> rl.Color {

    avg_col : [3]f32

    for i in 0..<width {
    for j in 0..<height {

        color := rl.ColorToHSV(rl.GetImageColor(im, x+i, y+j))

        avg_col += transmute([3]f32) color
    }
    }

    avg_col /= [3]f32{f32(width*height),f32(width*height),f32(width*height)}

    return rl.ColorFromHSV(avg_col[0],avg_col[1],avg_col[2])
}

// map luminosity of a sampled chunk to a character range (lowest to highest)
chunk_luma_map :: proc(im: rl.Image, x, y: i32, index: []u8) -> u8 {
    
    color := average_color_rgb(im, x, y, CHAR_WIDTH, CHAR_HEIGHT)

    char_brightness := math.sqrt( // luminance formula
        0.299*math.pow(f32(color.r)/255,2) +
        0.587*math.pow(f32(color.g)/255,2) +
        0.114*math.pow(f32(color.b)/255,2),
    )
    
    return index[int(map_range(char_brightness,0,1,0,f32(len(index))-1))]
}

// choose the most visually similar character to an image chunk within a list of characters
chunk_mse_map :: proc(im: rl.Image, x, y: i32, index: []u8, foreground: rl.Color) -> u8 {
    
    error_index := make([]f32, len(index))
    defer delete(error_index)
    
    for char in 0..<len(index) {

        char_x, char_y := char_pos(index[char])

        //fmt.println(rl.GetImageColor(font_image, char_x, char_y))

        for i in i32(0)..<CHAR_WIDTH {
        for j in i32(0)..<CHAR_HEIGHT {

            img_color  := rl.GetImageColor(im, x+i, y+j)
            char_color := rl.GetImageColor(font_image, char_x+i, char_y+j)
            char_color = {char_color.a * foreground.r,char_color.a * foreground.g,char_color.a * foreground.b,char_color.a * foreground.a}
            pixel_diff_luma := luma(img_color) - luma(char_color)
            //fmt.println("DIFF",diff_rgba)

            error_index[char] += pixel_diff_luma * pixel_diff_luma
        }
        }

        //error_index[char] = error_index[char] / (CHAR_WIDTH*CHAR_HEIGHT)

    }
    
    min_index := 3

    for char in 0..<len(index) {
        if error_index[min_index] > error_index[char] {
            min_index = char
        }
    }

    //fmt.println(error_index)
    //fmt.println(min_index)

    return index[min_index]
}

// choose the most visually similar character to an image chunk within the entire character set
chunk_mse_map_full :: proc(im: rl.Image, x, y: i32, foreground: rl.Color) -> u8 {
    
    error_index := make([]f32, 256)
    defer delete(error_index)
    
    chunk_avg_color := average_color_hsv(im, x, y, CHAR_WIDTH, CHAR_HEIGHT)

    for char in u8(0)..=255 {

        char_x, char_y := char_pos(char)

        //fmt.println(rl.GetImageColor(font_image, char_x, char_y))


        for i in i32(0)..<CHAR_WIDTH {
        for j in i32(0)..<CHAR_HEIGHT {

            img_color  := rl.GetImageColor(im, x+i, y+j)
            char_color := rl.GetImageColor(font_image, char_x+i, char_y+j)
            
            char_color = {char_color.a * foreground.r,char_color.a * foreground.g,char_color.a * foreground.b,char_color.a * foreground.a}

            pixel_diff_luma := luma(img_color) - luma(char_color)
            
            error_index[char] += pixel_diff_luma * pixel_diff_luma
        }
        }

        //error_index[char] = error_index[char] / (CHAR_WIDTH*CHAR_HEIGHT)

    }
    
    min_index := 3

    for char in 0..<255 {
        if error_index[min_index] > error_index[char] {
            min_index = char
        }
    }

    //fmt.println(error_index)
    //fmt.println(min_index)

    return u8(min_index)
}

map_range :: proc(value, from_low, from_high, to_low, to_high: f32) -> (new_value: f32) {
    
    scale := (to_high-to_low)/(from_high-from_low)
    offset := -from_low*(to_high-to_low)/(from_high-from_low) + to_low

    new_value = value * scale + offset
    
    return
}

// rgb linear interpolation
lerp :: proc(col1, col2 : rl.Color, factor: f32) -> rl.Color {

    factor := abs(math.mod(factor, 1))

    col1_rgb := [4]f32{f32(col1.r),f32(col1.g),f32(col1.b),f32(col1.a)}
    col2_rgb := [4]f32{f32(col2.r),f32(col2.g),f32(col2.b),f32(col2.a)}

    col3_rgb := col1_rgb * {(1-factor),(1-factor),(1-factor),(1-factor)} + 
                col2_rgb * {factor,factor,factor,factor}

    return rl.Color{cast(u8) col3_rgb.r,cast(u8) col3_rgb.g,cast(u8) col3_rgb.b,cast(u8) col3_rgb.a}

}

// hsv linear interpolation
lerp_hsv :: proc(col1, col2 : rl.Color, factor: f32) -> rl.Color {

    factor := abs(math.mod(factor, 1))

    col1_hsv := rl.ColorToHSV(col1)
    col2_hsv := rl.ColorToHSV(col2)

    col3_hsv := col1_hsv * {(1-factor),(1-factor),(1-factor)} + 
                col2_hsv * {factor,factor,factor}

    return rl.ColorFromHSV(col3_hsv[0],col3_hsv[1],col3_hsv[2])

}

// rgb -> hsv
color_to_hsl :: proc(color: rl.Color) -> (result: [3]f32) {
    
    r := f32(color.r)/255
    g := f32(color.g)/255
    b := f32(color.b)/255
    
    max := max(r,g,b)
    min := min(r,g,b)

    result[0] = (max+min)/2
    result[1] = result[0]
    result[2] = result[0]

    if max == min {
        result[0] = 0
        result[1] = 0
    } else {
        d := max - min
        result[1] = (result[2] > 0.5) ? d / (2 - max - min) : d / (max+min)
    
        if max == r {
            result[0] = (g - b) / d + (g < b ? 6 : 0)
        } else if max == g {
            result[0] = (b - r) / d + 2
        } else if max == b {
            result[0] = (r - g) / d + 4
        }
        result[0] /= 6
    }

    return
}

hsl_to_color :: proc(h, s, l: f32) -> (result: rl.Color) {

    hue2rgb :: proc(p, q, t : f32) -> f32 {
        p := p
        q := q
        t := t

        if (t < 0) {
            t += 1
        }
        if (t > 1) {
            t -= 1
        }
        if (t < 1/6) {
            return (p + (q - p) * 6 * t)
        }
        if (t < 1/2) {
            return q
        }
        if (t < 2/3) {
            return (p + (q - p) * (2./3 - t) * 6)
        }
        return p

    }

  
    if s == 0 {
        result.r = u8(l*255)
        result.g = u8(l*255)
        result.b = u8(l*255) // achromatic
    } else {
        q := l < 0.5 ? l * (1 + s) : l + s - l * s;
        p := 2 * l - q;

        fmt.println(hue2rgb(p, q, h + 1./3) * 255, hue2rgb(p, q, h + 1./3) * 255)

        result.r = u8(hue2rgb(p, q, h + 1./3) * 255)
        result.g = u8(hue2rgb(p, q, h) * 255)
        result.b = u8(hue2rgb(p, q, h - 1./3) * 255)
    }

    result.a = 255

    return result;

}