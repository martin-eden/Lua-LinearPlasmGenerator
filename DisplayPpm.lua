-- Development test/demo for ANSI terminal codes image encoder

--[[
  Author: Martin Eden
  Last mod.: 2024-12-12
]]

--[[ Dev
package.path = package.path .. ';' .. '../../?.lua'
require('workshop.base')
--]]
require('workshop')

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

local PpmImageCodec = request('!.concepts.Ppm.Interface')
local InputFile = request('!.concepts.StreamIo.Input.File')
local DenormalizeColor = request('!.concepts.Image.Color.Denormalize')

InputFile:Open(Config.InputFileName)

PpmImageCodec.Input = InputFile

local Image = PpmImageCodec:Load()

local ImageWidth = #Image[1]
local ImageHeight = #Image

print(ImageWidth .. 'x' .. ImageHeight)

-- '─│╭╮╰╯'

io.write(GetCommand_Reset())

io.write('╭')
for _ = 1, ImageWidth + 2 do
  io.write('─')
end
io.write('╮')
io.write('\n')

for RowIndex, Row in ipairs(Image) do
  io.write(GetCommand_Reset())
  io.write('│ ')
  for ColIndex, Column in ipairs(Row) do
    local Color = Column

    DenormalizeColor(Color)

    local Red, Green, Blue = table.unpack(Color)

    io.write(GetCommand_SetRgbBackground(Red, Green, Blue))
    io.write(' ')
  end
  io.write(GetCommand_Reset())
  io.write(' │')
  io.write('\n')
end

io.write('╰')
for _ = 1, ImageWidth + 2 do
  io.write('─')
end
io.write('╯')
io.write('\n')

--[[
  2024-12-12
]]
