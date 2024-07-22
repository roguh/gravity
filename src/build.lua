return {
  -- basic settings:
  name = 'GRAVITY', -- name of the game for your executable
  developer = 'ROGUH', -- dev name used in metadata of the file
  output = 'build', -- output location for your game, defaults to $SAVE_DIRECTORY
  version = '0.1a', -- 'version' of your game, used to name the folder in output
  love = '11.5', -- version of LÖVE to use, must match github releases
  ignore = {'build'}, -- folders/files to ignore in your project
  icon = 'img/felina0.png', -- 256x256px PNG icon for game, will be converted for you

  -- optional settings:
  use32bit = false, -- set true to build windows 32-bit as well as 64-bit
  identifier = 'com.roguh.gravity', -- macos team identifier, defaults to game.developer.name
  libs = { -- files to place in output directly rather than fuse
    windows = {}, -- can specify per platform or "all"
    all = {'../README.md'}
  },
  hooks = { -- hooks to run commands via os.execute before or after building
    before_build = 'cd .. ; make lint',
  }
}