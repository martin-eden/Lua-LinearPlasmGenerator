-- Generate 1-d gradient filling and write it to pixmap

--[[
  Author: Martin Eden
  Last mod.: 2025-04-06
]]

-- Config:
local Config =
  {
    ImageWidth = tonumber(arg[1]) or 60,
    ImageHeight = tonumber(arg[2]) or 10,
    ColorFormat = arg[3] or 'Rgb',
    RandomSeed = tonumber(arg[4]) or math.randomseed(),
    OutputFileName = 'Plasm_1d.ppm',
  }

--[[ Dev
package.path = package.path .. ';../../?.lua'
require('workshop.base')
--]]
-- [[ Use
require('workshop')
--]]

-- Imports:
local t2s = request('!.table.as_string')
local PlasmGenerator = request('LinearPlasmGenerator.Interface')
local CreateImageFromLine = request('!.concepts.Image.Matrix.CreateFromLine')
local OutputFile = request('!.concepts.StreamIo.Output.File')
local PpmCodec = request('!.concepts.Netpbm.Interface')

io.write('Config = ', t2s(Config))

math.randomseed(Config.RandomSeed, Config.RandomSeed)

local Image
do
  PlasmGenerator.ImageLength = Config.ImageWidth
  PlasmGenerator.Scale = 2.4e-1*4

  PlasmGenerator.ColorFormat = Config.ColorFormat

  -- Custom [0.0, 1.0] -> [0.0, 1.0] mapping function
  PlasmGenerator.TransformDistance =
    function(self, Distance)
      local Result
      -- Result = Distance
      -- Result = Distance ^ 1.43
      -- [[
      local Angle_Deg = Distance * 180 - 90
      local Angle_Rad = math.rad(Angle_Deg)
      Result = (math.sin(Angle_Rad) + 1) / 2
      --]]

      assert(Result >= 0)

      return Result
    end

  PlasmGenerator:Run()

  local ImageLine = PlasmGenerator.Line

  Image = CreateImageFromLine(ImageLine, Config.ImageHeight)
end

do
  OutputFile:Open(Config.OutputFileName)

  PpmCodec.Output = OutputFile
  PpmCodec.Settings.ColorFormat = Config.ColorFormat
  PpmCodec:Save(Image)

  OutputFile:Close()
end

--[[
  2024-11 # # #
  2025-04-05
  2025-04-06
]]
