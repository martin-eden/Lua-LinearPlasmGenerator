-- Calculate midway pixel with noise

-- Last mod.: 2024-11-25

-- Imports:
local BaseColor = request('!.concepts.Image.Color.Interface')
local GetGap = request('Internals.GetGap')
local Clamp = request('!.number.constrain')

--[[
  Given left and right pixels calculate midway pixel,
  adding distance-dependent noise.

  Type TPixel

    { Index: int, Color: { 1=Red, 2=Green, 3=Blue: float_ui } }

  Input

    LeftPixel, RightPixel: TPixel

  Output

    TPixel
]]
local CalculateMidwayPixel =
  function(self, LeftPixel, RightPixel)
    local Gap = GetGap(LeftPixel.Index, RightPixel.Index)
    assert(Gap >= 1)

    -- Distance is normalized gap to make it fit in [0.0, 1.0]
    local Distance = Gap / self.MaxGap

    -- Index of middle pixel
    local Index = (LeftPixel.Index + RightPixel.Index) // 2

    -- Calculate color components
    local Color = new(BaseColor)
    for Index in ipairs(Color) do
      local Noise = self:MakeDistanceNoise(Distance)

      local Value
      Value = (LeftPixel.Color[Index] + RightPixel.Color[Index]) / 2
      Value = Value + Noise
      Value = Clamp(Value, 0.0, 1.0)

      Color[Index] = Value
    end

    return { Index = Index, Color = Color }
  end

-- Exports:
return CalculateMidwayPixel

--[[
  2024-09-30
  2024-11-06
  2024-11-18
  2024-11-24
]]
