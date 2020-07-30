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
DEBUG = true
RELEASE_DATE = "2020-07-30"
SCREEN_WIDTH = 240
SCREEN_WIDTH_HALF = SCREEN_WIDTH / 2
SCREEN_HEIGHT = 136
SCREEN_HEIGHT_HALF = SCREEN_HEIGHT / 2
AMMO_SIZE = 5

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

function mdp()
	-- Has the mouse button been pressed?
	return (md and not md_last)
end
-- END INPUT FUNCTIONS

function init()
	t=0
	mode = "title" -- Modes: "title", "game", "gameover"
	highscore = pmem(0)
end
init()

function prepare_game()
	score = 0
	ammo = AMMO_SIZE
end
function TIC()
	update_mouse()
	
	-- Clear screen
	background(2)
	cls(2)
	
	-- Select mode
	if mode == "title" then
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
		
		if mdp() then
			ammo = ammo - 1
		end
		
		-- Show ammo
		for i = 1, ammo do
			spr(318, 237-(i*16), 118, 0, 2, 0, 0, 1, 1) -- Ammo
		end
		if ammo < AMMO_SIZE then
			for i = ammo, AMMO_SIZE do
				if i > 0 then
					spr(319, 237-(i*16), 118, 0, 2, 0, 0, 1, 1) -- Greyed out ammo
				end
			end
		end
		
		-- Show Targeting Cross
		circb(mx, my, 3, 6)
		circ(mx, my, 1, 6)
	elseif mode == "gameover" then
		
	else
		-- When in doubt, fall back to the title screen
		mode = "title"
	end
	
	if DEBUG then
		print("DEBUG:\nt=" .. t .. "\nammo=" .. ammo, SCREEN_WIDTH-32,1,15,true,1,true)
	end
	
	-- End tick
	t=t+1
end

function scanline(row)
	-- Sky gradient (palette index 2)
	poke(0x3fc6,64) --r
	poke(0x3fc7,64+row) --g
	poke(0x3fc8,200) --b
end
