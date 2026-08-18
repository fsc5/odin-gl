package common

import "core:math"
import "core:math/linalg"

FlyCamera :: struct {
	position, world_up: linalg.Vector3f32,
	yaw, pitch, movement_speed, mouse_sensitivity,zoom:f32
}

INIT_CAM :: FlyCamera {
	position = {0,0,0},
	world_up = {0,1,0},
	yaw = -90,
	pitch = 0,
	movement_speed = 2.5,
	mouse_sensitivity = 0.1,
	zoom = 45
}

MovementDirections :: enum {
	FORWARD,
	BACKWARD,
	LEFT,
	RIGHT
}

fly_cam_vectors :: proc(cam:FlyCamera) -> (front:linalg.Vector3f32, right:linalg.Vector3f32, up: linalg.Vector3f32) {
	pitch := math.to_radians_f32(cam.pitch)
	yaw := math.to_radians_f32(cam.yaw)
	front = linalg.normalize(linalg.Vector3f32{
		math.cos_f32(yaw) * math.cos_f32(pitch),
		math.sin_f32(pitch),
		math.sin_f32(yaw) * math.cos_f32(pitch)
	})
	right = linalg.normalize(linalg.cross(front, cam.world_up))
	up = linalg.normalize(linalg.cross(right, front))
	return
}

fly_cam_process_keyboard :: proc(cam: ^FlyCamera, direction: MovementDirections, delta:f32 ) {
	vel := cam.movement_speed * delta
	front, right, _ := fly_cam_vectors(cam^)

	switch(direction) {
		case .FORWARD : cam.position += front * vel
		case .BACKWARD: cam.position -= front * vel
		case .LEFT: cam.position -= right * vel
		case .RIGHT: cam.position += right * vel
	}
}

fly_cam_process_mouse_move :: proc(cam: ^FlyCamera, x_off, y_off : f32, constrain_pitch : bool = true) {
	cam.yaw += x_off * cam.mouse_sensitivity
	cam.pitch += y_off * cam.mouse_sensitivity
	if(constrain_pitch){
		cam.pitch = math.clamp(cam.pitch, -89, 89)
	}
}

fly_cam_process_mouse_scroll :: proc(cam: ^FlyCamera, y_off:f32) {
	cam.zoom = math.clamp(cam.zoom - y_off, 1, 45)
}

fly_cam_look_at :: proc(cam: FlyCamera) -> linalg.Matrix4f32 {
	front, _, up := fly_cam_vectors(cam)
	return linalg.matrix4_look_at_f32(cam.position, cam.position + front, up)
}
