-- Development test/demo for ANSI terminal codes image encoder

--[[
  Author: Martin Eden
  Last mod.: 2025-03-31
]]

--[[ Dev
package.path = package.path .. ';' .. '../../?.lua'
require('workshop.base')
--]]
-- [[ Use
require('workshop')
--]]

local Config =
  {
    InputFileName = arg[1] or 'Plasm_1d.ppm',
  }

local AssertByte = request('!.number.assert_byte')

local FukenEsc = '\027['

local GetCommand_SetRgbBackground =
  function(RedByte, GreenByte, BlueByte)
    AssertByte(RedByte)
    AssertByte(GreenByte)
    AssertByte(BlueByte)

    local CommandFmt = FukenEsc .. '48;2;%d;%d;%dm'
    local Command = string.format(CommandFmt, RedByte, GreenByte, BlueByte)

    return Command
  end

local GetCommand_Reset =
  function()
    local Command = FukenEsc .. '0m'

    return Command
  end

local PpmImageCodec = request('!.concepts.Netpbm.Interface')
local InputFile = request('!.concepts.StreamIo.Input.File')
local DenormalizeColor = request('!.concepts.Image.Color.Denormalize')

InputFile:Open(Config.InputFileName)

PpmImageCodec.Input = InputFile

local Image = PpmImageCodec:Load()

if not Image then
  print('Failed to load image.')
  return
end

print(Image.Width .. 'x' .. Image.Height)

-- '─│╭╮╰╯'

io.write(GetCommand_Reset())

io.write('╭')
for _ = 1, Image.Width + 2 do
  io.write('─')
end
io.write('╮')
io.write('\n')

for Row = 1, Image.Height do
  io.write(GetCommand_Reset())
  io.write('│ ')
  for Column = 1, Image.Width do
    local Color = new(Image[Row][Column])

    DenormalizeColor(Color)

    local Red, Green, Blue
    do
      if (#Color == 1) then
        Red = Color[1]
        Green = Color[1]
        Blue = 0-- Color[1]
      elseif (#Color == 3) then
        Red = Color[1]
        Green = Color[2]
        Blue = Color[3]
      end
    end

    io.write(GetCommand_SetRgbBackground(Red, Green, Blue))
    io.write(' ')
  end
  io.write(GetCommand_Reset())
  io.write(' │')
  io.write('\n')
end

io.write('╰')
for _ = 1, Image.Width + 2 do
  io.write('─')
end
io.write('╯')
io.write('\n')

--[[
  2024-12-12
  2025-03-29
  2025-03-31
]]
