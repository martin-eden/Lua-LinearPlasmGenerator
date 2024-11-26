-- 1-D "plasm" gradient generation core

-- Last mod.: 2024-11-25

-- Imports:
local GetGap = request('Internals.GetGap')

--[[
  Generate "1-D plasm": midway linear interpolation between pixels with
  some distance-dependent noise.

  Input

    LeftPixel, RightPixel: TPixel
      {
        Index: int
        Color: { 1=Red, 2=Green, 3=Blue: float_ui }
      }

  Output

    Calls <self:SetPixel()>
]]
local MakePlasm =
  function(self, LeftPixel, RightPixel)
    local Gap = GetGap(LeftPixel.Index, RightPixel.Index)

    if (Gap <= 0) then
      return
    end

    local MidwayPixel = self:CalculateMidwayPixel(LeftPixel, RightPixel)

    self:SetPixel(MidwayPixel)

    self:Plasm(LeftPixel, MidwayPixel)
    self:Plasm(MidwayPixel, RightPixel)
  end

-- Exports:
return MakePlasm

--[[
  2024-10-30
]]
