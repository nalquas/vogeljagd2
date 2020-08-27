-- title:  Vogeljagd 2
-- author: Nalquas
-- desc:   Shoot birds. Inspired by Moorhuhn.
-- script: lua
-- saveid: TIC_Vogeljagd2_dev

-- MIT License
--
-- Copyright (c) 2020 nalquas
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- Constants
DEBUG = true
RELEASE_DATE = "2020-08-27"
RELEASE_TARGET = "TIC-80 0.80"
SCREEN_WIDTH = 240
SCREEN_WIDTH_HALF = SCREEN_WIDTH / 2
SCREEN_HEIGHT = 136
SCREEN_HEIGHT_HALF = SCREEN_HEIGHT / 2
GAME_WIDTH = 960 -- SCREEN_WIDTH * 4
GAME_TIME = 3600 --60sec
GAMEOVER_TIME = 240 --4sec
CAMERA_POS_MAX = GAME_WIDTH - SCREEN_WIDTH
CAMERA_SPEED = 5
AMMO_SIZE = 5
AMMO_RELOAD_TIME = 100--180 --3sec
CLOUD_COUNT = 128
INTRO_OFFSET = 60
INTRO_CUTOFF = -120
BIRD_MAX_CLOSENESS = 3

-- BEGIN HELPER FUNCTIONS
	function round(x)
		if x<0 then return math.ceil(x-0.5) end
		return math.floor(x+0.5)
	end
-- END HELPER FUNCTIONS

-- BEGIN GRAPHICS FUNCTIONS
	function background(color)
		poke(0x03FF8, color)
	end

	function print_shadowed(text, x, y, color, fixed, scale, smallfont)
		x = x or 0
		y = y or 0
		color = color or 15
		fixed = fixed or false
		scale = scale or 1
		smallfont = smallfont or false

		print(text, x+1, y+1, 0, fixed, scale, smallfont) -- Shadow
		print(text, x, y, color, fixed, scale, smallfont) -- Main
	end

	function print_centered(text, x, y, color, fixed, scale, smallfont, shadowed)
		x = x or 0
		y = y or 0
		color = color or 15
		fixed = fixed or false
		scale = scale or 1
		smallfont = smallfont or false
		shadowed = shadowed or false

		-- Print off-screen to get width
		local width = print(text, 0, -64, color, fixed, scale, smallfont)

		-- Print at proper position, but centered
		if shadowed then
			print_shadowed(text, x - (width / 2), y, color, fixed, scale, smallfont)
		else
			print(text, x - (width / 2), y, color, fixed, scale, smallfont)
		end

		return width
	end

	function spr_scaled(id, x, y, colorkey, scale, w, h)
		colorkey = colorkey or -1
		scale = scale or 1
		w = w or 1
		h = h or 1

		-- A B
		--
		-- D C
		-- ax ay bx by cx cy au av bu bv cu cv

		ax=x
		ay=y

		bx=x+(w*8*scale)
		by=y

		cx=x+(w*8*scale)
		cy=y+(h*8*scale)

		dx=x
		dy=y+(h*8*scale)

		uFactor=((id%16)*8)
		vFactor=math.floor(id/16)*8

		au=uFactor
		av=vFactor

		bu=uFactor+(w*8)
		bv=vFactor

		cu=uFactor+(w*8)
		cv=vFactor+(h*8)

		du=uFactor
		dv=vFactor+(h*8)

		textri(ax,ay,bx,by,cx,cy,au,av,bu,bv,cu,cv,false,colorkey)
		textri(ax,ay,dx,dy,cx,cy,au,av,du,dv,cu,cv,false,colorkey)
	end

	function powerline_cable(x1, y1, x2, y2, hang)
		hang = hang or 1.0 -- hang intensity factor

		-- Simple/debug implementation:
		--line(x1, y1, x2, y2, 6)

		-- Hanging cables:
		local dx = x2-x1
		local dy = y2-y1
		for i=1,4 do
			local y_offset1, y_offset2
			if i == 1 then
				y_offset1 = 0
				y_offset2 = dy * 0.33 * hang
			elseif i == 2 then
				y_offset1 = dy * 0.33 * hang
				y_offset2 = dy * 0.5 * hang
			elseif i == 3 then
				y_offset1 = dy * 0.5 * hang
				y_offset2 = dy * 0.33 * hang
			else
				y_offset1 = dy * 0.33 * hang
				y_offset2 = 0
			end
			line(x1 + dx / 4 * (i-1), y1 + dy / 4 * (i-1) - y_offset1, x1 + dx / 4 * i, y1 + dy / 4 * i - y_offset2, 15)
		end
	end
-- END GRAPHICS FUNCTIONS

-- BEGIN INPUT FUNCTIONS
	function update_mouse()
		mx_last = mx or 0
		my_last = my or 0
		md_last = md or false
		mx,my,md = mouse()
	end

	-- Has the mouse button been pressed this tick?
	function mdp()
		return (md and not md_last)
	end

	-- Check if the mouse is colliding with a given object. Needs to contain the parameters x, y, size_x, size_y
	function mouse_collision(object)
		local mxl
		if object.closeness == nil then
			mxl = mx + camera_pos
		else
			mxl = mx + camera_pos/(BIRD_MAX_CLOSENESS+1-object.closeness)
		end
		return (mxl >= object.x and mxl < object.x+object.size_x and my >= object.y and my < object.y+object.size_y)
	end
-- END INPUT FUNCTIONS

-- BEGIN CLOUD FUNCTIONS
	function add_cloud(id, x, y, scale, speed_x)
		clouds[#clouds+1] = {
			id = id or 256,
			x = x or 0,
			y = y or 0,
			w = 8,
			h = 3,
			scale = scale or 1,
			speed_x = speed_x or 0
			}
	end

	function generate_cloud(scale)
		-- Select random sprite
		local id = 256
		if math.random() < 0.5 then
			id = 264
		end

		local cloud_width = scale * 8 * 8 -- the last 8 is w
		local cloud_x_max = (GAME_WIDTH + SCREEN_WIDTH) * (scale + 0.08) + cloud_width -- DON'T TOUCH X_MAX!

		-- Place at a random position
		local x = math.random(math.floor(-cloud_width), math.floor(cloud_x_max))
		local y = SCREEN_HEIGHT_HALF - scale*SCREEN_HEIGHT_HALF

		-- Set speed
		local speed_x = (scale^2) * 0.1

		-- Commit cloud
		add_cloud(id, x, y, scale, speed_x)
	end

	function render_cloud(cloud)
		spr_scaled(cloud.id, cloud.x-(camera_pos*cloud.scale*0.25), cloud.y, 0, cloud.scale, cloud.w, cloud.h)
	end
-- END CLOUD FUNCTIONS

-- BEGIN BIRD FUNCTIONS
	function add_bird(x, y, closeness, size_x, size_y, speed_x, base_sprite)
		birds[#birds+1] = {
			alive = true,
			hit_ground = false,
			x = x or 0,
			y = y or 0,
			closeness = closeness or 1,
			size_x = size_x or 8,
			size_y = size_y or 8,
			speed_x = speed_x or 0,
			base_sprite = base_sprite or 304
			}
	end

	function generate_bird()
		-- Decide on distance/closeness
		local closeness = math.random(1, BIRD_MAX_CLOSENESS) -- (1=furthest, 3=closest)
		local distance = BIRD_MAX_CLOSENESS + 1 - closeness -- ...the opposite

		-- Set size based on closeness
		local size_x = closeness * 8
		local size_y = size_x -- square

		-- Set speed based on distance
		local speed_x = (0.16666667 + math.random()/6.0) * closeness -- Anywhere from 1/6 to 1/3, multiplied by closeness

		-- Set y randomly, but also based on distance
		local y = math.random(0, math.floor((SCREEN_HEIGHT-32) / distance) - size_y)

		-- Decide: left or right?
		local x
		if math.random() < 0.5 then
			-- Go right
			x = -size_x -- spawn left
		else
			-- Go left
			x = SCREEN_WIDTH + CAMERA_POS_MAX/(BIRD_MAX_CLOSENESS+1-closeness) -- spawn right
			speed_x = -speed_x -- invert speed_x to go left
		end

		-- Select a random base sprite
		local base_sprite = 304 + math.random(0,3)*3

		-- Commit bird
		add_bird(x, y, closeness, size_x, size_y, speed_x, base_sprite)
	end

	function render_bird(bird)
		if bird.alive or not bird.hit_ground then
			-- Direction (left/right)
			local flip = 0
			if bird.speed_x < 0 then
				flip = 1
			end

			-- Dead or alive
			local rotation = 0
			if not bird.alive then
				rotation = 1 -- face downwards
			end

			-- Animation
			local sprite_offset = ((t/8)%3)
			if not bird.alive then
				sprite_offset = 0 -- dead birds don't move
			end

			spr(bird.base_sprite + sprite_offset, bird.x - camera_pos/(BIRD_MAX_CLOSENESS+1-bird.closeness), bird.y, 15, bird.closeness, flip, rotation, 1, 1)
		end
	end
-- END BIRD FUNCTIONS

function init()
	t=0
	shake = 0
	mode = "intro" -- Modes: "intro", "title", "game", "gameover"
	highscore = pmem(0)
	intro_offset = INTRO_OFFSET
end
init()

function prepare_game()
	score = 0
	ammo = AMMO_SIZE
	birds = {}
	clouds = {}
	for i = 1, CLOUD_COUNT do
		generate_cloud(0.25 + 0.75 * (i / CLOUD_COUNT))
	end
	camera_pos = CAMERA_POS_MAX / 2
	t_game = GAME_TIME
	t_gameover = GAMEOVER_TIME
	t_reload = AMMO_RELOAD_TIME
end

function TIC()
	if DEBUG then
		-- Store frame start time
		frame_start = time()
	end

	update_mouse()

	-- Clear screen
	background(2)
	cls(2)

	-- Select mode
	if mode == "intro" then
		-- Rendering
		print_centered("Nalquas presents:", SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT_HALF-8, 15, true, 2, false, true)

		-- Events
		intro_offset = intro_offset - 1 -- Timer and, simultaneously, offset used in scanline()
		if intro_offset > 0 then
			-- Fade-in of sound
			sfx(2, math.floor((1.0-(intro_offset / INTRO_OFFSET)) * 60), -1, 0, 15, 0)
		elseif intro_offset == 0 then
			-- Bell sound
			sfx(0, "B-5", -1, 0, 15, 0)
			sfx(0, "G#5", -1, 1, 15, -1)
			sfx(0, "E-5", -1, 2, 15, -1)
		elseif intro_offset < INTRO_CUTOFF then
			mode = "title"
			-- Stop all sound channels, should they still be running
			for i=0,3 do
				sfx(-1, 0, -1, i)
			end
		end
	elseif mode == "title" then
		-- Version
		print_shadowed("Version as of " .. RELEASE_DATE .. "\nfor " .. RELEASE_TARGET, 1, 1, 15, true, 1, true)

		-- Title
		print_centered("Vogeljagd 2", SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT/3, 15, true, 2, false, true)

		-- Instructions
		print_centered("Click to begin", SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT_HALF, 15, true, 1, true, true)

		-- Highscore
		print_centered("Current Highscore: " .. highscore, SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT_HALF+8, 15, true, 1, true, true)

		-- Credits / Copyright notice
		print_centered("(C) Nalquas, 2020", SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT-16, 15, true, 1, true, true)
		print_centered("Licensed under the MIT license", SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT-8, 15, true, 1, true, true)

		-- Handle input
		if mdp() then
			prepare_game()
			mode = "game"
		end
	elseif mode == "game" then

		-- Handle game time
		if t_game <= 0 then
			mode = "gameover"
			music() -- Stop music
		else
			t_game = t_game - 1
			if t_game%60==0 then -- Sfx: Timer ticking down
				local note = "B-2"
				if t_game == 0 then note = "B-4"
				elseif t_game%600==0 then note = "D-3"
				elseif t_game <= 180 then note = "D-4"
				elseif t_game <= 600 then note = "F-3" end
				sfx(0, note, -1, 0, 7, 0)
			end
		end

		-- Camera movement
		local cam_moved = 0
		if mx < 5 or btn(2) then
			camera_pos = camera_pos - CAMERA_SPEED
			if camera_pos < 0 then
				camera_pos = 0
			else
				cam_moved = -1
			end
		elseif mx > SCREEN_WIDTH - 5 or btn(3) then
			camera_pos = camera_pos + CAMERA_SPEED
			if camera_pos > CAMERA_POS_MAX then
				camera_pos = CAMERA_POS_MAX
			else
				cam_moved = 1
			end
		end

		-- Spawn birds
		if math.random() < 0.015 then
			generate_bird()
		end

		-- Process birds
		if #birds > 0 then
			for i=1,#birds do
				if birds[i].alive then
					-- Movement
					birds[i].x = birds[i].x + birds[i].speed_x

					-- Out of bounds? Kill.
					if birds[i].x < -birds[i].size_x or birds[i].x > SCREEN_WIDTH + CAMERA_POS_MAX/(BIRD_MAX_CLOSENESS+1-birds[i].closeness) then
						birds[i].alive = false
					end
				elseif not birds[i].hit_ground then
					birds[i].y = birds[i].y + birds[i].closeness
					if birds[i].y > SCREEN_HEIGHT then
						birds[i].hit_ground = true
					end
				end
			end
		end

		-- Process shooting
		if ammo > 0 then
			if mdp() then
				shake = 5 -- Shake screen for 5 ticks
				ammo = ammo - 1
				sfx(1, "B-3", 31, 1, 15, 0)

				-- Check for hits
				for i=1,#birds do
					if birds[i].alive and mouse_collision(birds[i]) then
						-- Kill the bird on hit
						birds[i].alive = false
						score = score + (BIRD_MAX_CLOSENESS+1 - birds[i].closeness)
					end
				end
			end
		else
			-- Reload ammo
			if t_reload == AMMO_RELOAD_TIME then
				music(0, -1, -1, false) -- Play reload track
			end
			t_reload = t_reload - 1
			if t_reload < 0 then
				ammo = AMMO_SIZE
				t_reload = AMMO_RELOAD_TIME -- Reset reload time
			end
		end

		-- Render sun
		local sun_x = 100 - (camera_pos * 0.05)
		spr(316, sun_x, 15, 0, 1, 0, 0, 1, 1)

		-- Render (and process) clouds
		if #clouds > 0 then
			for i=1,#clouds do
				clouds[i].x = clouds[i].x + clouds[i].speed_x
				local cloud_width = clouds[i].scale * 8 * clouds[i].w
				local cloud_x_max = (GAME_WIDTH + SCREEN_WIDTH) * (clouds[i].scale + 0.08) + cloud_width -- DON'T TOUCH X_MAX!
				if clouds[i].x > cloud_x_max then
					clouds[i].x = -cloud_width
				elseif clouds[i].x < -cloud_width then
					clouds[i].x = cloud_x_max
				end
				render_cloud(clouds[i])
			end
		end

		-- Render game content, layer by layer (from back to front)
		for distance=8,1,-1 do
			-- Layer-specific props
			if distance==1 then
				-- Power line (front)
				local x_pl = 300 - 0.5*(camera_pos/distance)
				spr(384, x_pl, SCREEN_HEIGHT-128, 0, 2, 0, 0, 4, 8)
				powerline_cable(x_pl+6, SCREEN_HEIGHT-126, 520+12 - 0.5*(camera_pos*2), SCREEN_HEIGHT-182, 0.75)
				powerline_cable(x_pl+56, SCREEN_HEIGHT-126, 520+112 - 0.5*(camera_pos*2), SCREEN_HEIGHT-182, 0.75)
			elseif distance==3 then
				-- Power line (mid)
				local x_pl = 150 - 0.5*(camera_pos/distance)
				spr(384, x_pl, SCREEN_HEIGHT-96, 0, 1, 0, 0, 4, 8)
				powerline_cable(x_pl+3, SCREEN_HEIGHT-95, 306 - 0.5*(camera_pos/1), SCREEN_HEIGHT-126, 1.0)
				powerline_cable(x_pl+28, SCREEN_HEIGHT-95, 356 - 0.5*(camera_pos/1), SCREEN_HEIGHT-126, 1.0)
			elseif distance==5 then
				-- Power line (back)
				local x_pl = 125 - 0.5*(camera_pos/distance)
				spr(320, x_pl, SCREEN_HEIGHT-64, 0, 1, 0, 0, 2, 4)
				powerline_cable(x_pl+1, SCREEN_HEIGHT-64, 153 - 0.5*(camera_pos/3), SCREEN_HEIGHT-95, 0.5)
				powerline_cable(x_pl+14, SCREEN_HEIGHT-64, 178 - 0.5*(camera_pos/3), SCREEN_HEIGHT-95, 0.5)
			elseif distance==7 then
				local x_pl = 117 - 0.5*(camera_pos/distance)
				spr_scaled(320, x_pl, SCREEN_HEIGHT-48, 0, 0.5, 2, 4)
				powerline_cable(x_pl+0.5, SCREEN_HEIGHT-48, 126 - 0.5*(camera_pos/5), SCREEN_HEIGHT-64, 0.25)
				powerline_cable(x_pl+7, SCREEN_HEIGHT-48, 139 - 0.5*(camera_pos/5), SCREEN_HEIGHT-64, 0.25)
			end

			-- Terrain
			map(0, 136-(distance*17), 240, 17, -0.5*(camera_pos/distance), 0, 2, 1)

			-- Birds
			local closeness = BIRD_MAX_CLOSENESS+1-distance
			if #birds > 0 and closeness > 0 then
				for i=1,#birds do -- iterate over all birds
					if birds[i].closeness == closeness then -- only render birds from this layer
						render_bird(birds[i])
					end
				end
			end
		end

		-- Indicate camera movement on edge of screen
		if not (cam_moved == 0) then
			local cam_indicator_x, cam_indicator_flip
			if cam_moved == -1 then
				-- moving left
				cam_indicator_x = 0
				cam_indicator_flip = 1
			else
				-- moving right
				cam_indicator_x = SCREEN_WIDTH - 16
				cam_indicator_flip = 0
			end
			for i=1,2 do
				spr(322, cam_indicator_x, SCREEN_HEIGHT_HALF - 32 + 16*i, 0, 1, cam_indicator_flip + (i-1)*2, 0, 2, 2)
			end
		end

		-- Show position of screen on map (as a rectangle on a line)
		local rect_width = (SCREEN_WIDTH / GAME_WIDTH) * SCREEN_WIDTH
		local rect_pos = (camera_pos / CAMERA_POS_MAX) * (SCREEN_WIDTH-rect_width)
		line(0, SCREEN_HEIGHT-7, rect_pos, SCREEN_HEIGHT-7, 15) -- map (left)
		line(rect_pos + rect_width, SCREEN_HEIGHT-7, SCREEN_WIDTH-1, SCREEN_HEIGHT-7, 15) -- map (right)
		rectb(rect_pos, SCREEN_HEIGHT-13, rect_width, 13, 15) -- screen

		-- Show ammo
		for i = 1, AMMO_SIZE do
			spr(317, 238-(i*16), 119, 15, 2, 0, 0, 1, 1) -- Shadow
		end
		for i = 1, ammo do
			spr(318, 237-(i*16), 118, 0, 2, 0, 0, 1, 1) -- Ammo
		end
		if ammo < AMMO_SIZE then
			for i = ammo+1, AMMO_SIZE do
				if i > 0 then
					spr(319, 237-(i*16), 118, 0, 2, 0, 0, 1, 1) -- Greyed out ammo
				end
			end
		end

		-- Show UI
		print_shadowed("Highscore: " .. highscore .. "\nScore: " .. score, 1, 1, 15, true, 1, true) -- score
		print_centered(tostring(1 + t_game // 60), SCREEN_WIDTH_HALF-1, 1, 15, true, 2, true, true) -- timer

		-- Show Targeting Cross
		local crosscolor = 6
		if ammo <= 0 then crosscolor = 10 end
		circb(mx, my, 3, crosscolor)
		circ(mx, my, 1, crosscolor)

	elseif mode == "gameover" then
		-- Show UI
		print_centered("Game Over", SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT/3, 15, true, 2, false, true) -- game over
		print_centered("Score: " .. score, SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT_HALF, 15, true, 1, true, true) -- score
		print_centered("Current Highscore: " .. highscore, SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT_HALF+8, 15, true, 1, true, true) -- highscore

		-- Show time bar
		line(0, SCREEN_HEIGHT-1, (t_gameover / GAMEOVER_TIME) * SCREEN_WIDTH, SCREEN_HEIGHT-1, 15)

		-- Process time
		t_gameover = t_gameover - 1
		if t_gameover < 0 then
			mode = "title"
		end
	else
		-- When in doubt, fall back to the title screen
		trace("Unknown mode \"" .. tostring(mode) .. "\", falling back to \"title\".")
		mode = "title"
	end

	if DEBUG then
		print_shadowed("DEBUG:\nt=" .. t .. "\nframe=" .. round(time() - frame_start) .. "ms\nmx=" .. mx .. "\nmy=" .. my .. "\nammo=" .. tostring(ammo) .. "\ncam=" .. tostring(camera_pos), SCREEN_WIDTH-40,1,15,true,1,true)
	end

	-- End tick
	if shake > 0 and t%2==0 then
		shake = shake - 1
	end
	t=t+1
end

function scanline(row)
	-- Intro effect
	if intro_offset > 0 and row > 59 and row < 76 then
		local factor = 1
		if row % 2 == 0 then
			factor = -1
		end
		poke(0x3FF9, factor * intro_offset) -- horizontal
	-- Screen shake
	elseif shake > 0 then
		poke(0x3FF9, math.random(-shake,shake)) -- horizontal
		poke(0x3FFA, math.random(-shake,shake)) -- vertical
	else
		poke(0x3FF9, 0)
		poke(0x3FFA, 0)
	end

	-- Sky gradient (palette index 2)
	local brightness = 1.0
	if intro_offset > 0 then
		brightness = 1.0 - (intro_offset / INTRO_OFFSET) -- Intro fade-in
	end
	poke(0x3fc6, brightness * (64))     --r
	poke(0x3fc7, brightness * (64+row)) --g
	poke(0x3fc8, brightness * (200))    --b
end
