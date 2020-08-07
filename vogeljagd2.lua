-- title:  Vogeljagd 2
-- author: Nalquas
-- desc:   Shoot birds. Inspired by Moorhuhn.
-- script: lua
-- input:  mouse
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
RELEASE_DATE = "2020-08-07"
RELEASE_TARGET = "TIC-80 0.70.6"
SCREEN_WIDTH = 240
SCREEN_WIDTH_HALF = SCREEN_WIDTH / 2
SCREEN_HEIGHT = 136
SCREEN_HEIGHT_HALF = SCREEN_HEIGHT / 2
GAME_WIDTH = 1200 -- SCREEN_WIDTH * 5
CAMERA_POS_MAX = GAME_WIDTH - SCREEN_WIDTH
CAMERA_SPEED = 10
AMMO_SIZE = 5
CLOUD_COUNT = 128
INTRO_OFFSET = 60
INTRO_CUTOFF = -120
BIRD_MAX_CLOSENESS = 3

-- BEGIN GRAPHICS FUNCTIONS
	function background(color)
		poke(0x03FF8, color)
	end

	function print_centered(text, x, y, color, fixed, scale, smallfont)
		x = x or 0
		y = y or 0
		color = color or 15
		fixed = fixed or false
		scale = scale or 1
		smallfont = smallfont or false
		
		-- Print off-screen to get width
		local width = print(text, 0, -64, color, fixed, scale, smallfont)
		
		-- Print at proper position, but centered
		print(text, x - (width / 2), y, color, fixed, scale, smallfont)
		
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
		local mx = mx + camera_pos
		return (mx >= object.x and mx < object.x+object.size_x and my >= object.y and my < object.y+object.size_y)
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
		local cloud_width = scale * 8 * 8 -- the last 8 is w
		local cloud_x_max = GAME_WIDTH * scale + cloud_width
		
		-- Place at a random position
		local x = math.random(math.floor(-cloud_width), math.floor(cloud_x_max))
		local y = SCREEN_HEIGHT_HALF - scale*SCREEN_HEIGHT_HALF
		
		-- Set speed
		--local speed_x = 0.5 * scale * (math.random()*2.0 - 1.0)
		--if speed_x == 0 then speed_x = 0.1 end
		local speed_x = scale * 0.1
		
		-- Commit cloud
		add_cloud(id, x, y, scale, speed_x)
	end
	
	function render_cloud(cloud)
		spr_scaled(cloud.id, cloud.x-(camera_pos*cloud.scale), cloud.y, 0, cloud.scale, cloud.w, cloud.h)
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
		local y = math.random(0, math.floor(SCREEN_HEIGHT / distance) - size_y)
		
		-- Decide: left or right?
		local x
		if math.random() < 0.5 then
			-- Go right
			x = -size_x -- spawn left
		else
			-- Go left
			x = SCREEN_WIDTH -- spawn right
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
			
			spr(bird.base_sprite + sprite_offset, bird.x - camera_pos, bird.y, 15, bird.closeness, flip, rotation, 1, 1)
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
	for i = 1, 1024 do
		generate_bird()
	end
	clouds = {}
	for i = 1, CLOUD_COUNT do
		generate_cloud(0.25 + 0.75 * (i / CLOUD_COUNT))
	end
	camera_pos = CAMERA_POS_MAX / 2
end

function TIC()
	update_mouse()
	
	-- Clear screen
	background(2)
	cls(2)
	
	-- Select mode
	if mode == "intro" then
		-- Rendering
		print_centered("Nalquas presents:", SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT_HALF-8, 15, true, 2, false)
		
		-- Events
		intro_offset = intro_offset - 1 -- Timer and, simultaneously, offset used in scanline()
		if intro_offset > 0 then
			-- Fade-in of sound
			sfx(1, math.floor((1.0-(intro_offset / INTRO_OFFSET)) * 60), -1, 0, 15, 0)
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
		print("Version as of " .. RELEASE_DATE .. "\nfor " .. RELEASE_TARGET, 1, 1, 15, true, 1, true)
		
		-- Title
		print_centered("Vogeljagd 2", SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT/3, 15, true, 2, false)
		
		-- Instructions
		print_centered("Click to begin", SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT_HALF, 15, true, 1, true)
		
		-- Credits / Copyright notice
		print_centered("(C) Nalquas, 2020", SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT-16, 15, true, 1, true)
		print_centered("Licensed under the MIT license", SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT-8, 15, true, 1, true)
		
		-- Handle input
		if mdp() then
			prepare_game()
			mode = "game"
		end
	elseif mode == "game" then
		
		-- Camera movement
		if mx < 5 or btn(2) then
			camera_pos = camera_pos - CAMERA_SPEED
			if camera_pos < 0 then
				camera_pos = 0
			end
		elseif mx > SCREEN_WIDTH - 5 or btn(3) then
			camera_pos = camera_pos + CAMERA_SPEED
			if camera_pos > CAMERA_POS_MAX then
				camera_pos = CAMERA_POS_MAX
			end
		end
		
		-- Process birds
		if #birds > 0 then
			for i=1,#birds do
				if birds[i].alive then
					-- Movement
					birds[i].x = birds[i].x + birds[i].speed_x
					
					-- Out of bounds? Kill.
					if birds[i].x < -birds[i].size_x or birds[i].x > GAME_WIDTH then
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
		if mdp() and ammo > 0 then
			shake = 5 -- Shake screen for 5 ticks
			ammo = ammo - 1
			
			-- Check for hits
			for i=1,#birds do
				if birds[i].alive and mouse_collision(birds[i]) then
					-- Kill the bird on hit
					birds[i].alive = false
					score = score + (BIRD_MAX_CLOSENESS+1 - birds[i].closeness)
				end
			end
		end
		
		-- Render (and process) clouds
		if #clouds > 0 then
			for i=1,#clouds do
				clouds[i].x = clouds[i].x + clouds[i].speed_x
				local cloud_width = clouds[i].scale * 8 * clouds[i].w
				local cloud_x_max = GAME_WIDTH * clouds[i].scale + cloud_width
				if clouds[i].x > cloud_x_max then
					clouds[i].x = -cloud_width
				elseif clouds[i].x < -cloud_width then
					clouds[i].x = cloud_x_max
				end
				render_cloud(clouds[i])
			end
		end
		
		-- Render birds, one closeness layer after the other
		if #birds > 0 then
			for closeness=1,BIRD_MAX_CLOSENESS do -- iterate through the layers
				for i=1,#birds do -- iterate over all birds
					if birds[i].closeness == closeness then -- only render birds from this layer
						render_bird(birds[i])
					end
				end
			end
		end
		
		-- Show position of screen on map (as a rectangle on a line)
		local rect_width = (SCREEN_WIDTH / GAME_WIDTH) * SCREEN_WIDTH
		local rect_pos = (camera_pos / CAMERA_POS_MAX) * (SCREEN_WIDTH-rect_width)
		line(0, SCREEN_HEIGHT-7, rect_pos, SCREEN_HEIGHT-7, 15) -- map (left)
		line(rect_pos + rect_width, SCREEN_HEIGHT-7, SCREEN_WIDTH-1, SCREEN_HEIGHT-7, 15) -- map (right)
		rectb(rect_pos, SCREEN_HEIGHT-13, rect_width, 13, 15) -- screen
		
		-- Show ammo
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
		
		-- Show score
		print("Score: " .. score, 1, 1, 15, true, 1, true)
		print_centered("Highscore: " .. highscore, SCREEN_WIDTH_HALF-1, 1, 15, true, 1, true)
		
		-- Show Targeting Cross
		circb(mx, my, 3, 6)
		circ(mx, my, 1, 6)
		
	elseif mode == "gameover" then
		
	else
		-- When in doubt, fall back to the title screen
		mode = "title"
	end
	
	if DEBUG then
		print("DEBUG:\nt=" .. t .. "\nmx=" .. mx .. "\nmy=" .. my .. "\nammo=" .. tostring(ammo) .. "\ncam=" .. tostring(camera_pos), SCREEN_WIDTH-32,1,15,true,1,true)
	end
	
	-- End tick
	if shake > 0 then
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
