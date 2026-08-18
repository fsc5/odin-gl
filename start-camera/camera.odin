package main

import cm "../common"
import gl "vendor:OpenGL"
import "vendor:glfw"
import img "core:image"
import "core:image/jpeg"
import "core:bytes"
import "core:math"
import "core:math/linalg"
import "base:runtime"

width :: 1200
height :: 800

InputState :: struct {
	camera: ^cm.FlyCamera,

	first_mouse: bool,
	last_x:      f64,
	last_y:      f64,
}

main :: proc() {
	// Initialize glfw, specify OpenGL version.
	glfw.Init()
	defer glfw.Terminate()
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	// Create render window.
	window := glfw.CreateWindow(width, height, "Learn Opengl", nil, nil)
	assert(window != nil)
	defer glfw.DestroyWindow(window)
	glfw.MakeContextCurrent(window)

	// Enable Vsync.
	glfw.SwapInterval(1)

	// Load OpenGL function pointers.
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	// Set normalized device coords to window coords transformation.
	w, h := glfw.GetFramebufferSize(window)
	gl.Viewport(0, 0, w, h)


	// glfw camera controls
	camera := cm.INIT_CAM
	camera.position = {0,0,3}

	input := InputState{
		camera      = &camera,
		first_mouse = true,
	}

	glfw.SetWindowUserPointer(window, &input)

	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)

	glfw.SetCursorPosCallback(window, mouse_callback)
	glfw.SetScrollCallback(window, scroll_callback)


	vertex_path, fragment_path := "./shaders/vertex.vert", "./shaders/fragment.frag"
	progId, progErr := cm.compile_prog(vertex_path, fragment_path)
	assert(progErr == nil)

	vertices := [?]f32 {
	 -0.5, -0.5, -0.5,  0.0, 0.0,
     0.5, -0.5, -0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,
    -0.5,  -0.5, -0.5,  0.0, 0.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
    -0.5,  0.5,  0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5,  0.5,  0.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  1.0, 1.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5, -0.5,  0.0, 1.0
	}
	indices := [?]u32 {
		0,1,3,
		1,2,3
	}
	vao, vbo, ebo: u32

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)

	gl.BindVertexArray(vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(f32),
		raw_data(&vertices),
		gl.STATIC_DRAW,
	)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(u32),
		raw_data(&indices),
		gl.STATIC_DRAW,
	)

	defer gl.DeleteVertexArrays(1, &vao)
	defer gl.DeleteBuffers(1, &vbo)
	defer gl.DeleteBuffers(1, &ebo)


	// position
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)
	// textures
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), uintptr(3 * size_of(f32)))
	gl.EnableVertexAttribArray(1)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST) // nearest pixel for downscaling
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR) // lin pixel for upscaling

	rei_path, shinji_path := "textures/rei.jpg", "textures/shinji.jpg"
	rei_img, err := img.load_from_file(rei_path, {.alpha_drop_if_present})
	assert(err == nil)
	assert(rei_img.channels == 3)
	rei_texture : u32
	gl.GenTextures(1, &rei_texture)
	gl.BindTexture(gl.TEXTURE_2D, rei_texture)

	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, cast(i32)rei_img.width, cast(i32)rei_img.height, 0, gl.RGB, gl.UNSIGNED_BYTE, raw_data(bytes.buffer_to_bytes(&rei_img.pixels)) )
	gl.GenerateMipmap(gl.TEXTURE_2D)
	img.destroy(rei_img)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE) // x axis = s
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT) // y axis = t (z = r)

	shinji_img, err_shinji := img.load_from_file(shinji_path, {.alpha_drop_if_present})
	assert(err_shinji == nil)
	assert(shinji_img.channels == 3)
	shinji_texture : u32
	gl.GenTextures(1, &shinji_texture)
	gl.BindTexture(gl.TEXTURE_2D, shinji_texture)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, cast(i32)shinji_img.width, cast(i32)shinji_img.height, 0, gl.RGB, gl.UNSIGNED_BYTE, raw_data(bytes.buffer_to_bytes(&shinji_img.pixels)) )
	gl.GenerateMipmap(gl.TEXTURE_2D)
	img.destroy(shinji_img)

	// Render loop
	gl.UseProgram(progId)
	gl.Enable(gl.DEPTH_TEST)
	cm.set_int(progId,"reiTexture", 0)
	cm.set_int(progId,"shinjiTexture", 1)

	//cam_pos := linalg.Vector3f32{0,0,3}
	//cam_target := linalg.Vector3f32{0,0,0}
	//cam_direction_rev := linalg.vector_normalize(cam_pos - cam_target)
	//up := linalg.Vector3f32{0,1,0}
	//cam_right := linalg.vector_normalize(linalg.vector_cross3(up, cam_direction_rev))
	//cam_up := linalg.vector_normalize(linalg.vector_cross3(cam_direction_rev, cam_right))
	//look_at := linalg.matrix3_look_at_f32(cam_pos, cam_target, {0,1,0})

	//view := linalg.matrix4_translate_f32(linalg.Vector3f32{1,0,-4})


	cube_positions := []linalg.Vector3f32 {
	{ 0.0,  0.0,  0.0},
    { 2.0,  5.0, -15.0},
    {-1.5, -2.2, -2.5},
    {-3.8, -2.0, -12.3},
    { 2.4, -0.4, -3.5},
    {-1.7,  3.0, -7.5},
    { 1.3, -2.0, -2.5},
    { 1.5,  2.0, -2.5},
    { 1.5,  0.2, -1.5},
    {-1.3,  1.0, -1.5}
	}

	delta_time, last_frame :f32 = 0, 0

	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()
		current_frame := cast(f32)glfw.GetTime();
        delta_time = current_frame - last_frame;
        last_frame = current_frame;
		process_input(window, input.camera, delta_time)

		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, rei_texture)
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, shinji_texture)

		radius:f32 = 10.0
		time := cast(f32)glfw.GetTime()
		/*cam_pos := linalg.Vector3f32{math.sin_f32(time) * radius, 0, math.cos_f32(time) * radius}
		cam_target := linalg.Vector3f32{0,0,0}
		look_at := linalg.matrix4_look_at_f32(cam_pos, cam_target, {0,1,0})*/
		look_at := cm.fly_cam_look_at(input.camera^)

		cm.set_matrix4f32(progId, "view", &look_at)
		projection := linalg.matrix4_perspective_f32(math.to_radians_f32(input.camera.zoom), width / height, 0.1, 100 )
		cm.set_matrix4f32(progId, "projection", &projection)

		gl.BindVertexArray(vao)
		for position, i in cube_positions {
			model := linalg.matrix4_translate_f32(position)
			if(i % 3 == 0){
				model *= linalg.matrix4_rotate_f32(cast(f32)glfw.GetTime() * math.to_radians_f32(50), {0.5,1,0})
			}
			model *= linalg.matrix4_rotate_f32(math.to_radians_f32(cast(f32)(20 * i)), {1,0.3,0.5}) // additional unique rotation for all
			cm.set_float(progId, "mixArg", cast(f32)i * 0.1)
			cm.set_matrix4f32(progId, "model", &model)
			gl.DrawArrays(gl.TRIANGLES, 0,36)

		}

		// Render screen with background color.
		glfw.SwapBuffers(window)
	}
}

process_input :: proc(window: glfw.WindowHandle, camera: ^cm.FlyCamera, deltaTime:f32) {
	processor := cm.fly_cam_process_keyboard_as_fps
	if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS){
		 glfw.SetWindowShouldClose(window, true);
	}
   if (glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS){
   		processor(camera, .FORWARD, deltaTime)
   }
   if (glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS){
   		processor(camera, .LEFT, deltaTime)
   }
   if (glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS){
   		processor(camera, .BACKWARD, deltaTime)
   }
   if (glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS){
   		processor(camera, .RIGHT, deltaTime)
   }
}


mouse_callback :: proc "c"  (
	window: glfw.WindowHandle,
	x_pos: f64,
	y_pos: f64,
) {
	context = runtime.default_context()
	input := cast(^InputState)glfw.GetWindowUserPointer(window)

	if input.first_mouse {
		input.last_x = x_pos
		input.last_y = y_pos
		input.first_mouse = false
		return
	}

	x_offset := f32(x_pos - input.last_x)
	y_offset := f32(input.last_y - y_pos)

	input.last_x = x_pos
	input.last_y = y_pos

	cm.fly_cam_process_mouse_move(
		input.camera,
		x_offset,
		y_offset,
	)
}

scroll_callback :: proc "c" (
	window: glfw.WindowHandle,
	x_offset: f64,
	y_offset: f64,
) {
	context = runtime.default_context()
	input := cast(^InputState)glfw.GetWindowUserPointer(window)

	cm.fly_cam_process_mouse_scroll(
		input.camera,
		f32(y_offset),
	)
}
