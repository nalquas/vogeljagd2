-- title:  Vogeljagd 2
-- author: Nalquas
-- desc:   Shoot birds. Inspired by Moorhuhn.
-- script: lua
-- input:  mouse
-- saveid: TIC_Vogeljagd2

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
DEBUG = false
RELEASE_DATE = "2020-07-31"
SCREEN_WIDTH = 240
SCREEN_WIDTH_HALF = SCREEN_WIDTH / 2
SCREEN_HEIGHT = 136
SCREEN_HEIGHT_HALF = SCREEN_HEIGHT / 2
AMMO_SIZE = 5
INTRO_OFFSET = 60
INTRO_CUTOFF = -120
BIRD_MAX_DISTANCE = 3

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
		return (mx >= object.x and mx < object.x+object.size_x and my >= object.y and my < object.y+object.size_y)
	end
-- END INPUT FUNCTIONS

-- BEGIN BIRD FUNCTIONS
	function add_bird(x, y, distance, size_x, size_y, speed_x, base_sprite)
		birds[#birds+1] = {
			alive = true,
			x = x or 0,
			y = y or 0,
			distance = distance or 1,
			size_x = size_x or 8,
			size_y = size_y or 8,
			speed_x = speed_x or 0,
			base_sprite = base_sprite or 304
			}
	end
	
	function generate_bird()
		local x, y
		
		-- Decide on distance (1=closest, 3=furthest)
		local distance = math.random(1, BIRD_MAX_DISTANCE)
		
		-- Set size based on distance
		local size_x = (BIRD_MAX_DISTANCE+1 - distance) * 8
		local size_y = size_x -- square
		
		-- Set speed based on distance
		--local speed_x = math.random()
		local speed_x = 0
		
		-- Decide: left or right?
		if math.random() < 0.5 then
			x = -size_x
		else
			x = SCREEN_WIDTH
		end
		
		-- Select a random base sprite
		local base_sprite = 304 + math.random(0,3)*3
		
		-- Commit bird
		add_bird(x, y, distance, size_x, size_y, speed_x, base_sprite)
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
	add_bird()
end

function TIC()
	update_mouse()
	
	-- Clear screen
	background(2)
	cls(2)
	
	-- Select mode
	if mode == "intro" then
		print_centered("Nalquas presents:", SCREEN_WIDTH_HALF-1, SCREEN_HEIGHT_HALF-8, 15, true, 2, false)
		
		intro_offset = intro_offset - 1
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
		print("Version as of " .. RELEASE_DATE, 1, 1, 15, true, 1, true)
		
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
		
		-- Process birds
		if #birds > 0 then
			for i=1,#birds do
				if birds[i].alive then
					birds[i].x = birds[i].x + birds[i].speed_x
				end
			end
		end
		
		-- Process shooting
		if mdp() and ammo > 0 then
			shake = 5 -- Shake screen for 5 ticks
			ammo = ammo - 1
		end
		
		-- Render birds
		if #birds > 0 then
			for i=1,#birds do
				spr(birds[i].base_sprite, birds[i].x, birds[i].y, 15, birds[i].size_x/8, 0, 0, 1, 1)
			end
		end
		
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
		print("DEBUG:\nt=" .. t .. "\nammo=" .. tostring(ammo), SCREEN_WIDTH-32,1,15,true,1,true)
	end
	
	-- End tick
	if shake > 0 then
		shake = shake - 1
	end
	t=t+1
end

function scanline(row)
	-- Intro effect
	if intro_offset > 0 then
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
