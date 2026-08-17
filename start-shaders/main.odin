package main

import cm "../common"
import gl "vendor:OpenGL"
import "vendor:glfw"


main :: proc() {
	// Initialize glfw, specify OpenGL version.
	glfw.Init()
	defer glfw.Terminate()
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	// Create render window.
	window := glfw.CreateWindow(1200, 800, "Learn Opengl", nil, nil)
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

	vertex_path, fragment_path := "./shaders/vertex.vs", "./shaders/fragment.fs"
	progId, progErr := cm.compile_prog(vertex_path, fragment_path)
	assert(progErr == nil)

	vertices := [?]f32 {
		0.5, // bottom right
		-0.5,
		0.0,
		1.0,
		0.0,
		0.0,
		-0.5, // bottom left
		-0.5,
		0.0,
		0.0,
		1.0,
		0.0,
		0.0, // top
		0.5,
		0.0,
		0.0,
		1.0,
		1.0,
	}
	vao, vbo: u32

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)

	gl.BindVertexArray(vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(f32),
		raw_data(&vertices),
		gl.STATIC_DRAW,
	)
	defer gl.DeleteVertexArrays(1, &vao)
	defer gl.DeleteBuffers(1, &vbo)


	// position
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)
	// color
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), uintptr(3 * size_of(f32)))
	gl.EnableVertexAttribArray(1)

	// Render loop
	off: f32 = 0.0
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(progId)
		gl.BindVertexArray(vao)
		off += 0.02
		if (off >= 1.5) {
			off = -1.5
		}
		cm.set_float(progId, "offset", off)
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		// Render screen with background color.
		glfw.SwapBuffers(window)
	}
}
