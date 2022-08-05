# Vogeljagd 2
Vogeljagd 2 is a game about shooting birds from the sky, made for the [TIC-80 fantasy console](https://tic80.com/).

![Gameplay Demonstration](media/gameplay.gif)

Inspired by [Moorhuhn](https://en.wikipedia.org/wiki/Moorhuhn) and [Duck Hunt](https://en.wikipedia.org/wiki/Duck_Hunt).

## Getting the game
You have the following options:

- Get it from [itch.io](https://nalquas.itch.io/vogeljagd2)
- Get it from [tic80.com](https://tic80.com/play?cart=1388)
- Get it from [GitHub](https://github.com/nalquas/vogeljagd2/releases)

## How to play
- Shoot as many birds as possible to beat your highscore.
- You get points for hitting birds. The further away the bird is, the bigger the reward.
- Try not to shoot any airplanes or you will loose points.

## Controls
Use your mouse to aim at the birds, then pull the trigger.

To move the camera, move your mouse towards the edge of the screen or use your directional keys.

## How to use development version
If you **don't** have TIC-80 Pro, please download the `.tic` cartridge in the GitHub release tab instead. The normal TIC-80 build can't open `.lua` formatted development cartridges. Alternatively, you should also be able to use a self-compiled version of TIC-80.

Assuming you have TIC-80 Pro installed, you can install the `.lua` dev cartridge like this:

- Run TIC-80 Pro
- Type `folder` to open your TIC-80 directory
- Copy `vogeljagd2.lua` into the folder
- Type `load vogeljagd2.lua`, then `run`
