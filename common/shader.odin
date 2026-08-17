package common


import "core:fmt"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"


setBool :: proc(program: u32, name: string, value: bool) {
	nameC := strings.clone_to_cstring(name)
	defer delete(nameC)
	gl.Uniform1i(gl.GetUniformLocation(program, nameC), 1 if value else 0)
}
setInt :: proc(program: u32, name: string, value: i32) {
	nameC := strings.clone_to_cstring(name)
	defer delete(nameC)
	gl.Uniform1i(gl.GetUniformLocation(program, nameC), value)
}
setFloat :: proc(program: u32, name: string, value: f32) {
	nameC := strings.clone_to_cstring(name)
	defer delete(nameC)
	gl.Uniform1f(gl.GetUniformLocation(program, nameC), value)
}

compileProg :: proc(vertexPath, fragmentPath: string) -> (id: u32, err: os.Error) {
	vertexData := os.read_entire_file_from_path(vertexPath, context.allocator) or_return
	defer delete(vertexData)
	fragmentData := os.read_entire_file_from_path(fragmentPath, context.allocator) or_return
	defer delete(fragmentData)

	vertexId, okV := gl.compile_shader_from_source(string(vertexData), .VERTEX_SHADER)
	if (!okV) {
		error, _ := gl.get_last_error_message()
		fmt.printf("Error for vertex: %s", error)
		return 0, .Invalid_File
	}
	fragmentId, okF := gl.compile_shader_from_source(string(fragmentData), .FRAGMENT_SHADER)
	if (!okF) {
		error, _ := gl.get_last_error_message()
		fmt.printf("Error for fragment: %s", error)
		return 0, .Invalid_File
	}
	programId := gl.CreateProgram()
	gl.AttachShader(programId, vertexId)
	gl.AttachShader(programId, fragmentId)
	gl.LinkProgram(programId)
	gl.DeleteShader(vertexId)
	gl.DeleteShader(fragmentId)

	return programId, nil
}
