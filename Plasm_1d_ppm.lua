-- Generate 1-d gradient filling and write it to pixmap

--[[
  Author: Martin Eden
  License: LGPL v3
  Last mod.: 2024-11-26
]]

-- Config:
local Config =
  {
    ImageWidth = tonumber(arg[1]) or 60,
    ImageHeight = tonumber(arg[2]) or 30,
    RandomSeed = (math.randomseed()),
    OutputFileName = 'Plasm_1d.ppm',
  }

if arg[3] then
  Config.RandomSeed = tonumber(arg[3])
end

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
local DuplicateImageLine = request('!.concepts.Image.Matrix.CreateFromLine')
local OutputFile = request('!.concepts.StreamIo.Output.File')
local PpmCodec = request('!.concepts.Ppm.Interface')

io.write('Config = ', t2s(Config))

math.randomseed(Config.RandomSeed, Config.RandomSeed)

PlasmGenerator.ImageLength = Config.ImageWidth
PlasmGenerator.OnRing = true
PlasmGenerator.Scale = 2.5

-- Custom [0.0, 1.0] -> [0.0, 1.0] mapping function
PlasmGenerator.TransformDistance =
  function(self, Distance)
    return Distance ^ 1.26
    --[[
    local Angle_Deg = Distance * 180 - 90
    local Angle_Rad = math.rad(Angle_Deg)
    return (math.sin(Angle_Rad) + 1) / 2
    --]]
  end

PlasmGenerator:Run()

local PlasmImage = new(PlasmGenerator.Image)

local ResultImage = DuplicateImageLine(Config.ImageHeight, PlasmImage)

OutputFile:Open(Config.OutputFileName)

PpmCodec.Output = OutputFile
PpmCodec:Save(ResultImage)

OutputFile:Close()

--[[
  2024-11-06
  2024-11-24
  2024-11-25
]]
