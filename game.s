	AREA lib, CODE, READWRITE

	EXPORT keystroke
	EXPORT board
	
bomb_placed		DCD 0x00000000
bomb_detonated	DCD 0x00000000
bomb_timer		DCD 0x00000000
bomb_radius		DCD 0x00000001
bomb_x_pos		DCD 0x00000000
bomb_y_pos		DCD 0x00000000

bomberman_x_pos	DCD 0x00000000
bomberman_y_pos DCD 0x00000000

enemy1_x_pos	DCD 0x00000000
enemy1_y_pos	DCD 0x00000000
enemy1_killed	DCD 0x00000000

enemy2_x_pos	DCD 0x00000000
enemy2_y_pos	DCD 0x00000000
enemy2_killed	DCD 0x00000000

enemy3_x_pos	DCD 0x00000000
enemy3_y_pos	DCD 0x00000000
enemy3_killed	DCD 0x00000000

num_enemies		DCD 0x00000000

num_lives		DCD 0x00000000

level			DCD 0x00000000

time			DCD 0x00000000

score			DCD 0x00000000

game_over		DCD 0x00000000

keystroke		DCD 0x00000000

board = "ZZZZZZZZZZZZZZZZZZZZZZZZZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZZZZZZZZZZZZZZZZZZZZZZZZZ"

	ALIGN

	END