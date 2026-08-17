package common

import "core:fmt"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"


set_bool :: proc(program: u32, name: string, value: bool) {
	nameC := strings.clone_to_cstring(name)
	defer delete(nameC)
	gl.Uniform1i(gl.GetUniformLocation(program, nameC), 1 if value else 0)
}
set_int :: proc(program: u32, name: string, value: i32) {
	nameC := strings.clone_to_cstring(name)
	defer delete(nameC)
	gl.Uniform1i(gl.GetUniformLocation(program, nameC), value)
}
set_float :: proc(program: u32, name: string, value: f32) {
	nameC := strings.clone_to_cstring(name)
	defer delete(nameC)
	gl.Uniform1f(gl.GetUniformLocation(program, nameC), value)
}

compile_prog :: proc(vertex_path, fragment_path: string) -> (id: u32, err: os.Error) {
	vertex_data := os.read_entire_file_from_path(vertex_path, context.allocator) or_return
	defer delete(vertex_data)
	fragment_data := os.read_entire_file_from_path(fragment_path, context.allocator) or_return
	defer delete(fragment_data)

	vertx_id, ok_v := gl.compile_shader_from_source(string(vertex_data), .VERTEX_SHADER)
	if (!ok_v) {
		error, _ := gl.get_last_error_message()
		fmt.printf("Error for vertex: %s", error)
		return 0, .Invalid_File
	}
	fragment_id, ok_f := gl.compile_shader_from_source(string(fragment_data), .FRAGMENT_SHADER)
	if (!ok_f) {
		error, _ := gl.get_last_error_message()
		fmt.printf("Error for fragment: %s", error)
		return 0, .Invalid_File
	}
	program_id := gl.CreateProgram()
	gl.AttachShader(program_id, vertx_id)
	gl.AttachShader(program_id, fragment_id)
	gl.LinkProgram(program_id)
	gl.DeleteShader(vertx_id)
	gl.DeleteShader(fragment_id)

	return program_id, nil
}
