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


	vertex_path, fragment_path := "./shaders/vertex.vert", "./shaders/object.frag"
	object_prog, prog_err := cm.compile_prog(vertex_path, fragment_path)
	assert(prog_err == nil)
	fragment_path = "./shaders/source.frag"
	light_prog, light_prog_err := cm.compile_prog(vertex_path, fragment_path)
	assert(light_prog_err == nil)

	vertices := [?]f32 {
	 -0.5, -0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5,  0.5, -0.5,
     0.5,  0.5, -0.5,
    -0.5,  0.5, -0.5,
    -0.5,  -0.5, -0.5,
    -0.5, -0.5,  0.5,
     0.5, -0.5,  0.5,
     0.5,  0.5,  0.5,
     0.5,  0.5,  0.5,
    -0.5,  0.5,  0.5,
    -0.5, -0.5,  0.5,
    -0.5,  0.5,  0.5,
    -0.5,  0.5, -0.5,
    -0.5, -0.5, -0.5,
    -0.5, -0.5, -0.5,
    -0.5, -0.5,  0.5,
    -0.5,  0.5,  0.5,
     0.5,  0.5,  0.5,
     0.5,  0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5, -0.5,  0.5,
     0.5,  0.5,  0.5,
    -0.5, -0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5, -0.5,  0.5,
     0.5, -0.5,  0.5,
    -0.5, -0.5,  0.5,
    -0.5, -0.5, -0.5,
    -0.5,  0.5, -0.5,
     0.5,  0.5, -0.5,
     0.5,  0.5,  0.5,
     0.5,  0.5,  0.5,
    -0.5,  0.5,  0.5,
    -0.5,  0.5, -0.5,	}
	indices := [?]u32 {
		0,1,3,
		1,2,3
	}
	object_vao, vbo, ebo: u32

	gl.GenVertexArrays(1, &object_vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)
	gl.BindVertexArray(object_vao)
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

	defer gl.DeleteVertexArrays(1, &object_vao)
	defer gl.DeleteBuffers(1, &vbo)
	defer gl.DeleteBuffers(1, &ebo)

	// position
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)

	// lightVao
	light_vao : u32
	gl.GenVertexArrays(1, &light_vao)
	gl.BindVertexArray(light_vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)
	defer gl.DeleteVertexArrays(1, &light_vao)

	// Render loop
	gl.Enable(gl.DEPTH_TEST)
	light_trafo := linalg.matrix4_translate_f32({1.2, 1, 2}) * linalg.matrix4_scale_f32({0.2, 0.2, 0.2})

	delta_time, last_frame :f32 = 0, 0
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()
		current_frame := cast(f32)glfw.GetTime();
        delta_time = current_frame - last_frame;
        last_frame = current_frame;
		process_input(window, input.camera, delta_time)

		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		look_at := cm.fly_cam_look_at(input.camera^)
		projection := linalg.matrix4_perspective_f32(math.to_radians_f32(input.camera.zoom), width / height, 0.1, 100 )


		gl.UseProgram(light_prog)
		gl.BindVertexArray(light_vao)

		cm.set_matrix4f32(light_prog, "model", &light_trafo)
		cm.set_matrix4f32(light_prog, "view", &look_at)
		cm.set_matrix4f32(light_prog, "projection", &projection)
		gl.DrawArrays(gl.TRIANGLES, 0,36)

		gl.UseProgram(object_prog)
		gl.BindVertexArray(object_vao)

		identity := linalg.MATRIX4F32_IDENTITY
		cm.set_matrix4f32(object_prog, "model", &identity)
		cm.set_matrix4f32(object_prog, "view", &look_at)
		cm.set_matrix4f32(object_prog, "projection", &projection)
		cm.set_vec3(object_prog, "objectColor", &{1, 0.5, 0.31})
		cm.set_vec3(object_prog, "lightColor", &{1, 1, 1})
		gl.DrawArrays(gl.TRIANGLES, 0,36)

		// Render screen with background color.
		glfw.SwapBuffers(window)
	}
}

process_input :: proc(window: glfw.WindowHandle, camera: ^cm.FlyCamera, deltaTime:f32) {
	processor := cm.fly_cam_process_keyboard
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
