module main
import os
import math
import math.complex
import gfx


const (
    // do not adjust these constants
    size       = Size2i{ 512, 512 }             // size of images to generate
    all_steps  = [8, 16, 256]                   // gradient step sizes to generate
    blends     = [0.00, 0.25, 0.50, 0.75, 1.00] // blend values to generate

    // change these constants
    over_extra = true                          // set to true for extra credit (varies alpha across image)
    iterations = 10000                             // iterations for render algorithm, increase this before submitting!
)

// convenience type aliases
type Image   = gfx.Image
type Image4  = gfx.Image4
type Point2i = gfx.Point2i
type Size2i  = gfx.Size2i
type Color   = gfx.Color
type Color4  = gfx.Color4

type Compositor = fn(c_top Color4, c_bot Color4) Color4

// DONE
// renders checkerboard image, alternating between even and odd colors
/*fn render_checkerboard(even Color, odd Color) Image {
    mut image := gfx.Image.new(size)

    for row in 0 .. size.height {
        for col in 0 .. size.width {
            if (row + col) % 2 == 0 { 
                image.set_pixel(col, row, even)
            } else {
                image.set_pixel(col, row, odd)
            }
        }
    }
    return image
}
*/


// COMPLETE
// renders a stepped, vertical color gradient
fn render_gradient(top Color, bottom Color, num_steps int) Image {
    mut image := gfx.Image.new(size)

    step_height := size.height / num_steps
    
    for row in 0 .. size.height {
        step := row / step_height
         t := f64(step) / f64(num_steps - 1)  // Normalize row index
         color := Color{
            r: (1.0 - t) * top.r + t * bottom.r,
            g: (1.0 - t) * top.g + t * bottom.g,
            b: (1.0 - t) * top.b + t * bottom.b,
        }
        for col in 0 .. size.width {
            image.set_xy(col, row, color)

        }
    }

    return image
}




// color_over computes color of c_top over c_bottom
fn color_over(c_top Color4, c_bottom Color4) Color4 {
    mut c := Color4{ 0, 0, 0, 0 }
   
    // Compute the alha of the resulting color; a insues alpha
    c.a = c_top.a + c_bottom.a * (1.0 - c_top.a)
    
    // corresponds to RGB value colors
    c.r = (c_top.r * c_top.a + c_bottom.r * c_bottom.a * (1.0 - c_top.a)) / c.a
    c.g = (c_top.g * c_top.a + c_bottom.g * c_bottom.a * (1.0 - c_top.a)) / c.a
    c.b = (c_top.b * c_top.a + c_bottom.b * c_bottom.a * (1.0 - c_top.a)) / c.a

    return c
}


// color_blend computes color of blending c0 into c1 by factor.
// - when factor == 0.0, final color is c0
// - when factor == 0.5, final color is average of c0 and c1
// - when factor == 1.0, final color is c1
fn color_blend(c0 Color4, c1 Color4, factor f64) Color4 {
    mut c := Color4{ 0, 0, 0, 0 }
    // compute color of blending c0 and c1 by factor.
    c.a = ((1.0 - factor) * c0.a + factor * c1.a) 
if c.a != 0 {
    c.r = ((1 - factor) * c0.r * c0.a + (factor * c1.r * c1.a)) / c.a
    c.g = ((1 - factor) * c0.g * c0.a + (factor * c1.g * c1.a)) / c.a
    c.b = ((1 - factor) * c0.b * c0.a + (factor * c1.b * c1.a)) / c.a
} else {
    c.r = 0
    c.g = 0
    c.b = 0
}
    

    return c
}


// ALREADY COMPLETE
// render_composite will create an image based on passing corresponding pixels from img_top and img_bot into fn_composite
fn render_composite(img_top Image4, img_bot Image4, fn_composite Compositor) Image4 {
    // make sure two images are the same size
    assert img_top.size.width == img_bot.size.width && img_top.size.height == img_bot.size.height
    mut image := gfx.Image4.new(img_top.size)
    for y in 0 .. img_top.size.height {
        for x in 0 .. img_top.size.width {
            c_top := img_top.get_xy(x, y)
            c_bot := img_bot.get_xy(x, y)
            c_comp := fn_composite(c_top, c_bot)
            image.set_xy(x, y, c_comp)
        }
    }
    return image
}



// ALREADY COMPLETE
// convenience struct that groups a Point2i with Color
struct PointColor {
    position Point2i
    color    Color
}


// render_algorithm renders an image following a simple algorithm
fn render_algorithm0() Image {
    mut image := gfx.Image.new(size)

    // pick three random locations and colors
    min := Point2i{0, 0}
    max := Point2i{size.width, size.height}
    corners := [
        PointColor{ gfx.point2i_rand(min, max), gfx.red },
        PointColor{ gfx.point2i_rand(min, max), gfx.green },
        PointColor{ gfx.point2i_rand(min, max), gfx.blue },
    ]
    mut position := gfx.point2i_rand(min, max)
    mut color    := gfx.white


    for _ in 0 .. iterations {
        image.set_xy(position.x, position.y, color) // write color into image at position

        chosen_corner := gfx.int_in_range(0, corners.len) // choose one of the corners at random

        // corners[chosen_corner].position
        // position = Point2i { // update position by moving it halfway to corner position
        
        position = Point2i {
            (corners[chosen_corner].position.x + position.x) / 2,
            (corners[chosen_corner].position.y + position.y) / 2
        }

        // position.x := (corners[chosen_corner].x + position.x) / 2,
        // position.y := (corners[chosen_corner].x + position.y) / 2
        
        //corners[chosen_corner].color
    
        color = Color {
            (color.r + corners[chosen_corner].color.r) / 2,
            (color.g + corners[chosen_corner].color.g) / 2,
            (color.b + corners[chosen_corner].color.b) / 2,
        }
        
        

    //}

    }
    return image
}



fn render_algorithm1() Image {
    mut image := gfx.Image.new(size)
    w, h := image.width(), image.height()
    max_iterations := gfx.ramp.len() * 10

        for y in 0 .. h {
        for x in 0 .. w {
            mut z := complex.Complex{re: 0.0, im: 0.0}
            c := complex.Complex{
                re: 2.0 * f64(x) / f64(w) - 1.5
                im: 2.0 * f64(y) / f64(h) - 1.0
            }
            for i in 0 .. max_iterations {
                z = z * z + c
                if z.abs() > 2.0 {
                    image.set_xy(x, y, gfx.ramp.color(i))
                    break
                }
            }
        }
    }

    return image
}



// CREATIVE ARTIFACT and ELECTIVE (Green Screen)

fn green_screen(foreground_path string, background_path string, output_path string) {
    // Load foreground and background images
    //mut foreground := gfx.load_png(foreground_path) 
    //background := gfx.load_png(background_path)

    foreground := gfx.load_png(foreground_path) 
    background := gfx.load_png(background_path) 


    width, height := foreground.width(), foreground.height()

    // Create a new image for the composited result
    mut result := gfx.Image.new(gfx.Size2i{width, height})

    // Iterate over each pixel in the foreground image
    for y in 0 .. height {
        for x in 0 .. width {
            fg_color := foreground.get_xy(x, y)
            bg_color := background.get_xy(x, y)

            // If the pixel is green, use the background pixel
            if fg_color.r < 0.2 && fg_color.b < 0.2 &&  fg_color.g > 0.3 {
                result.set_xy(x, y, bg_color.as_color())
            } else {
                result.set_xy(x, y, fg_color.as_color())
            }
        }
    }

    // Save the composited image
    result.save_png(output_path)
}



//  Extra Credit Blur Effect


fn blur_screen(foreground_path2 string, background_path2 string, output_path2 string) {
    // Load foreground and background images
    //mut foreground := gfx.load_png(foreground_path) 
    //background := gfx.load_png(background_path)

    foreground2 := gfx.load_png(foreground_path2) 
    background2 := gfx.load_png(background_path2) 


    // Ensure both images are the same size
    //if foreground.height() != background.height() {
        //return
    //}

    //if foreground.width() != background.width() {
        //return
    //}

    width, height := foreground2.width(), foreground2.height()

    // Create a new image for the composited result
    mut result := gfx.Image.new(gfx.Size2i{width, height})

    // Iterate over each pixel in the foreground image
    for y in 0 .. height {
        for x in 0 .. width {
            fg_color := foreground2.get_xy(x, y)
            bg_color := background2.get_xy(x, y)

            // If the pixel is green, use the background pixel
            if fg_color.r < 0.2 && fg_color.b < 0.2 &&  fg_color.g > 0.3 {
                result.set_xy(x, y, bg_color.as_color())
            } else {
                result.set_xy(x, y, fg_color.as_color())
            }
        }
    }



// Apply a simple blur effect
    blur_radius := 8 // Adjust the blur radius as needed
    mut blurred_result := gfx.Image.new(gfx.Size2i{width, height})
    for y in 0 .. height {
        for x in 0 .. width {
            mut r_sum := 0.0
            mut g_sum := 0.0
            mut b_sum := 0.0
            mut count := 0
            for ky in -blur_radius .. blur_radius + 1 {
                for kx in -blur_radius .. blur_radius + 1 {
                    nx := x + kx
                    ny := y + ky
                    if nx >= 0 && nx < width && ny >= 0 && ny < height {
                        color := result.get_xy(nx, ny)
                        r_sum += color.r
                        g_sum += color.g
                        b_sum += color.b
                        count++
                    }
                }

            }

            //blurred_color := gfx.Color4(r_sum / count, g_sum / count, b_sum / count)

            //blurred_color := gfx.color(r_sum / count, g_sum / count, b_sum / count)
            //blurred_result.set_xy(x, y, blurred_color.as_color())

            blurred_color := gfx.Color{
                r: r_sum / count
                g: g_sum / count
                b: b_sum / count
                //a: 1.0 // Assuming full opacity
            }
            blurred_result.set_xy(x, y, blurred_color)
        }
    }

    // Save the blurred composited image
    blurred_result.save_png(output_path2) 

}



fn main() {
    // Make sure images folder exists, because this is where all
    // generated images will be saved
    if !os.exists('finalimages') {
        os.mkdir('finalimages') or { panic(err) }
    }

    // Creative Artifact and Elective function
    foreground_path := 'finalimages/gorilla3.png'
    background_path := 'finalimages/skyscraper.png'
    output_path := 'finalimages/composited.png'

    println('Compositing Green Screen Image...')
    green_screen(foreground_path, background_path, output_path)


    println('Blur Image..')
    foreground_path2 := 'finalimages/gorilla3.png'
    background_path2 := 'finalimages/skyscraper.png'
    output_path2 := 'finalimages/blurimage.png'
    blur_screen(foreground_path2, background_path2, output_path2)


    println('Rendering images A and B...')
    img_a := gfx.render_image0(size)
    img_b := gfx.render_image1(size, over_extra)  // set to true for extra credit (varies alpha across image)

    println('Writing images A and B...')  // write images out just to see them
    img_a.save_png('finalimages/P00_image_A.png')
    img_b.save_png('finalimages/P00_image_B.png')

    println('Testing image loading...')
    test := gfx.load_png('finalimages/P00_image_A.png')
    test.save_png('finalimages/P00_image_A_test.png')

    /*println('Rendering checkerboard image...')
    render_checkerboard(gfx.red, gfx.cyan).save_png('finalimages/P00_checkerboard.png')
*/
    println('Rendering gradient images...')
    for num_steps in all_steps {
        render_gradient(Color{0,0,0}, Color{1,1,1}, num_steps).save_png('finalimages/P00_00_gradient_${num_steps:03}.png')
    }

    println('Rendering composite color_over images...')
    render_composite(img_a, img_b, color_over).save_png('finalimages/P00_01_A_over_B.png')
    render_composite(img_b, img_a, color_over).save_png('finalimages/P00_01_B_over_A.png')

    println('Rendering composite color_blend images...')
    for blend in blends {
        render_composite( img_a, img_b, fn [blend] (c0 Color4, c1 Color4) Color4 {
            return color_blend(c0, c1, blend)
        }).save_png('finalimages/P00_02_A_blend${int(100*blend):03}_B.png')
    }

    println('Rendering algorithm 0 image...')
    render_algorithm0().save_png('finalimages/P00_03_algorithm0.png')

    println('Rendering algorithm 1 image...')
    render_algorithm1().save_png('finalimages/P00_04_algorithm1.png')

    println('Done!')
}