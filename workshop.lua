local Modules = {
  ['workshop.base'] = [=[
--[[
  Lua base libraries extension. Used almost in any piece of my code.

  This module installs global function "request" which is based on
  "require" and makes possible relative module names.

  Also this function tracks module dependencies. This allows to
  get dependencies list for any module. Which is used to create
  deploys without unused code.

  Price for tracking dependencies is global table "dependencies"
  and function "get_require_name".

  Lastly, global functions are added for convenience. Such functions
  are "new" and families of "is_<type>" and "assert_<type>".
]]

-- Last mod.: 2024-03-02

-- Export request function:
local split_name =
  function(qualified_name)
    local prefix_name_pattern = '^(.+%.)([^%.]+)$'  -- a.b.c --> (a.b.) (c)
    local prefix, name = qualified_name:match(prefix_name_pattern)
    if not prefix then
      prefix = ''
      name = qualified_name
      if not name:find('^([^%.]+)$') then
        name = ''
      end
    end
    return prefix, name
  end

local unite_prefixes =
  function(base_prefix, rel_prefix)
    local init_base_prefix, init_rel_prefix = base_prefix, rel_prefix
    local list_without_tail_pattern = '(.+%.)[^%.]-%.$' -- a.b.c. --> (a.b.)
    local list_without_head_pattern = '[^%.]+%.(.+)$' -- a.b.c. --> (b.c.)
    while rel_prefix:find('^%^%.') do
      if (base_prefix == '') then
        error(
          ([[Link "%s" is outside caller's prefix "%s".]]):format(
            init_rel_prefix,
            init_base_prefix
          )
        )
      end
      base_prefix = base_prefix:match(list_without_tail_pattern) or ''
      rel_prefix = rel_prefix:match(list_without_head_pattern) or ''
    end
    return base_prefix .. rel_prefix
  end

local names = {}
local depth = 1

local get_caller_prefix =
  function()
    local result = ''
    if names[depth] then
      result = names[depth].prefix
    end
    return result
  end

local get_caller_name =
  function()
    local result = 'anonymous'
    if names[depth] then
      result = names[depth].prefix .. names[depth].name
    end
    return result
  end

local push =
  function(prefix, name)
    depth = depth + 1
    names[depth] = {prefix = prefix, name = name}
  end

local pop =
  function()
    depth = depth - 1
  end

local dependencies = {}
local add_dependency =
  function(src_name, dest_name)
    dependencies[src_name] = dependencies[src_name] or {}
    dependencies[src_name][dest_name] = true
  end

local base_prefix = split_name((...))

local get_require_name =
  function(qualified_name)
    local is_absolute_name = (qualified_name:sub(1, 2) == '!.')
    if is_absolute_name then
      qualified_name = qualified_name:sub(3)
    end
    local prefix, name = split_name(qualified_name)
    local caller_prefix =
      is_absolute_name and base_prefix or get_caller_prefix()
    prefix = unite_prefixes(caller_prefix, prefix)
    return prefix .. name, prefix, name
  end

local request =
  function(qualified_name)
    local src_name = get_caller_name()

    local require_name, prefix, name = get_require_name(qualified_name)

    push(prefix, name)
    local dest_name = get_caller_name()
    add_dependency(src_name, dest_name)
    local results = table.pack(require(require_name))
    pop()

    return table.unpack(results)
  end

local IsFirstRun = (_G.request == nil)

if IsFirstRun then
  _G.request = request
  _G.dependencies = dependencies
  _G.get_require_name = get_require_name

  --[[
    At this point we installed "request()", so it's usable from
    outer code.

    Below we call optional modules which install additional
    global functions.

    Functions made global because they are widely used in my code.

    They are inside other files. We use freshly added "request()"
    to load them and add them to dependencies of this module.

    We need add record to call stack with our name because these
    calls of "request()" are inside "if", so the call will not be
    done until actual execution.
  ]]

  -- First element is invocation module name, second - module file path
  local our_require_name = (...)

  push('', our_require_name)

  request('!.system.install_is_functions')()
  request('!.system.install_assert_functions')()
  _G.new = request('!.table.new')

  pop()
end

--[[
  2016-06
  2017-09
  2018-02
  2018-05
  2024-03
]]
]=],
  ['workshop.concepts.Counter.Interface'] = [=[
-- Counter class

return
  {
    -- Interface

    -- Initialization setup
    Init =
      function(self, StartValue)
        assert_integer(self.MinValue)
        assert_integer(self.MaxValue)
        assert(self.MinValue <= self.MaxValue)

        if is_nil(StartValue) then
          if is_nil(self.Value) then
            -- Fallback to min value
            self.Value = self.MinValue
          end
        else
          assert_integer(StartValue)
          if
            (StartValue < self.MinValue) or
            (StartValue > self.MaxValue)
          then
            local ErrorMsgFmt =
              '[Counter] Starting value out of range: (%d not in [%d, %d]).'
            local ErrorMsg =
              string.format(
                ErrorMsgFmt,
                StartValue,
                self.MinValue,
                self.MaxValue
              )
            error(ErrorMsg)
          end
          self.Value = StartValue
        end
      end,

    -- Return current value
    Get =
      function(self)
        return self.Value
      end,

    -- Move one unit forward
    Increase =
      function(self)
        if (self.Value >= self.MaxValue) then
          if (self.Value > self.MaxValue) then
            self.Value = self.MaxValue
          end
          return false
        end
        self.Value = self.Value + 1
        return true
      end,

    -- Move one unit backward
    Decrease =
      function(self)
        if (self.Value <= self.MinValue) then
          if (self.Value < self.MinValue) then
            self.Value = self.MinValue
          end
          return false
        end
        self.Value = self.Value - 1
        return true
      end,

    -- Intensities

    -- Current value
    Value = nil,

    -- Range min value
    MinValue = 0,

    -- Range max value
    MaxValue = 100,
  }

--[[
  2024-08-31
]]
]=],
  ['workshop.concepts.Image.Color.Denormalize'] = [=[
-- Map normalized color components to byte range

-- Last mod.: 2024-11-25

-- Imports:
local MapTo = request('MapTo')
local ToInt = math.floor
local ApplyFunc = request('!.concepts.List.ApplyFunc')

local Denormalize =
  function(Color)
    local DestRange = { 0, 255 }
    local SourceRange = { 0.0, 1.0 }

    MapTo(DestRange, Color, SourceRange)

    return ApplyFunc(ToInt, Color)
  end

-- Exports:
return Denormalize

--[[
  2024-11-24
]]
]=],
  ['workshop.concepts.Image.Color.Interface'] = [=[
-- Color structure for images

--[[
  Color is a list of color components.

  Color component is float in [0.0, 1.0].
]]

-- Last mod.: 2024-11-25

-- Imports:
local NameList = request('!.concepts.List.AddNames')

local Color = { 0.0, 0.0, 0.0 }

local Names = { 'Red', 'Green', 'Blue' }

NameList(Color, Names)

-- Exports:
return Color

--[[
  2024-11-24
  2024-11-25
]]
]=],
  ['workshop.concepts.Image.Color.MapTo'] = [=[
-- Map color components to given range

-- Last mod.: 2024-11-25

-- Imports:
local MapToRange = request('!.number.map_to_range')
local ApplyFunc = request('!.concepts.List.ApplyFunc')

local MapTo =
  function(DestRange, Color, SrcRange)
    local CurrentMapToRange =
      function(ColorComponent)
        return MapToRange(DestRange, ColorComponent, SrcRange)
      end

    return ApplyFunc(CurrentMapToRange, Color)
  end

-- Exports:
return MapTo

--[[
  2024-11-24
]]
]=],
  ['workshop.concepts.Image.Color.Normalize'] = [=[
-- Normalize image color components that are in byte range [0, 255]

-- Last mod.: 2024-11-25

-- Imports:
local MapTo = request('MapTo')

local Normalize =
  function(Color)
    local DestRange = { 0.0, 1.0 }
    local SourceRange = { 0, 255 }

    return MapTo(DestRange, Color, SourceRange)
  end

-- Exports:
return Normalize

--[[
  2024-11-24
]]
]=],
  ['workshop.concepts.Image.Matrix.CreateFromLine'] = [=[
-- Create 2-d image by duplicating line

-- Last mod.: 2024-11-25

--[[
  Stack line image N times
]]
local StackLineImage =
  function(NumTimes, LineImage)
    local Result = {}

    for Index = 1, NumTimes do
      Result[Index] = new(LineImage)
    end

    return Result
  end

-- Exports:
return StackLineImage

--[[
  2024-11-25
]]
]=],
  ['workshop.concepts.Indent.Interface'] = [=[
return
  {
    -- Interface

    -- Initialization setup
    Init =
      function(self, IndentValue, ChunkValue)
        -- Tune counter for our needs
        self.Counter.MinValue = 0
        self.Counter.MaxValue = 1000
        self.Counter:Init(IndentValue)

        -- Set chunk if passed
        if not is_nil(ChunkValue) then
          assert_string(ChunkValue)
          self.Chunk = ChunkValue
        end
      end,

    -- Increase indent
    Increase =
      function(self)
        return self.Counter:Increase()
      end,

    -- Decrease indent
    Decrease =
      function(self)
        return self.Counter:Decrease()
      end,

    -- Return current indent value (integer)
    GetDepth =
      function(self)
        return self.Counter:Get()
      end,

    -- Return current indent string
    GetString =
      function(self)
        return string.rep(self.Chunk, self:GetDepth())
      end,

    -- Intensities

    -- Indent counter
    Counter = request('!.concepts.Counter.Interface'),

    -- Indent chunk
    Chunk = '  ',
  }

--[[
  2024-08-31
]]
]=],
  ['workshop.concepts.List.AddNames'] = [=[
-- Add names to list entries

-- Last mod.: 2024-11-25

-- Imports:
local InvertTable = request('!.table.invert')

--[[
  Name list entries by attaching metatable to list

  Example:

    local Color = { 128, 0, 255 }
    local ColorNames = { 'Red', 'Green', 'Blue' }
    NameList(Color, ColorNames)
    assert(Color.Red == Color[1])
]]
local NameList =
  function(List, Names)
    local NamesKeys = InvertTable(Names)

    local Metatable = {}

    Metatable.__index =
      function(Table, Key)
        return rawget(Table, NamesKeys[Key])
      end

    Metatable.__newindex =
      function(Table, Key, Value)
        if NamesKeys[Key] then
          rawset(Table, NamesKeys[Key], Value)
          return
        end
        rawset(Table, Key, Value)
      end

    setmetatable(List, Metatable)
  end

-- Exports:
return NameList

--[[
  2024-11-23
  2024-11-24
]]
]=],
  ['workshop.concepts.List.ApplyFunc'] = [=[
-- Modify list by applying function to each element. Returns list

--[[
  Here we're breaking functional paradigm "result of function is new
  value". We're modifying argument. It's practical.
]]

-- Last mod.: 2024-11-25

-- Exports:
return
  function(Func, List)
    assert_function(Func)
    assert_table(List)

    for Index = 1, #List do
      List[Index] = Func(List[Index])
    end

    return List
  end

--[[
  2024-11-24
]]
]=],
  ['workshop.concepts.List.ToString'] = [=[
-- Concatenate list of string values to string

-- Last mod.: 2024-10-20

return
  function(List, Separator)
    Separator = Separator or ''

    -- Meh, in Lua it's simple
    return table.concat(List, Separator)
  end

--[[
  2024-10-20
  2024-10-24
]]
]=],
  ['workshop.concepts.Ppm.Compiler_IsToPpm.CompilePixel'] = [=[
-- Compile pixel to string

-- Last mod.: 2024-11-03

-- Exports:
return
  function(self, PixelIs)
    return
      string.format(
        self.PixelFmt,
        PixelIs[1],
        PixelIs[2],
        PixelIs[3]
      )
  end

--[[
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Compiler_IsToPpm.Interface'] = [=[
-- Serialize to pixmap format

-- Last mod.: 2024-11-25

-- Exports:
return
  {
    -- Setup: Output stream
    Output = request('!.concepts.StreamIo.Output'),

    -- Main: Serialize anonymous structure to pixmap
    Run = request('Run'),

    -- [Config]

    -- Format label format (lol)
    LabelFmt = '%s  # Plain portable pixmap',

    -- Header serialization format
    HeaderFmt = '%s %s %s  # Width, Height, Max color component value',

    -- Lines (rows) separator
    LinesDelimiter = '',

    -- Columns (pixels) separator
    ColumnsDelimiter = '  ',

    -- Number of serialized pixels per line of output
    NumColumns = 4,

    -- Pixel serialization format
    PixelFmt = '%3s %3s %3s',

    -- [Internal]

    -- .ppm format constants
    Constants = request('^.Constants.Interface'),

    -- Write label
    WriteLabel = request('WriteLabel'),

    -- Write header
    WriteHeader = request('WriteHeader'),

    -- Write data
    WriteData = request('WriteData'),

    -- Compile pixel to string
    CompilePixel = request('CompilePixel'),

    -- Write string as line to output
    WriteLine = request('WriteLine'),
  }

--[[
  2024-11-02
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Compiler_IsToPpm.Run'] = [=[
-- Convert from .is to .ppm

-- Last mod.: 2024-12-12

--[[
  Gets list of strings/lists structure. Writes in .ppm format.

  When failed returns false.
]]
local SerializePpm =
  function(self, PpmIs)
    self:WriteLabel()
    self:WriteHeader(PpmIs)
    self:WriteData(PpmIs)

    return true
  end

-- Exports:
return SerializePpm

--[[
  2024-11-02
  2024-11-03
  2024-11-25
  2024-12-12
]]
]=],
  ['workshop.concepts.Ppm.Compiler_IsToPpm.WriteData'] = [=[
-- Write pixels to output. We're doing some formatting

-- Last mod.: 2024-11-06

-- Imports:
local ListToString = request('!.concepts.List.ToString')

-- Exports:
return
  function(self, DataIs)
    local Height = #DataIs
    local Width = #DataIs[1]

    local ChunkSize = self.NumColumns
    local ColumnsDelim = self.ColumnsDelimiter
    local LinesDelim = self.LinesDelimiter

    self:WriteLine(LinesDelim)

    for Row = 1, Height do
      local Chunks = {}

      for Column = 1, Width do
        local PixelIs = DataIs[Row][Column]
        local PixelStr = self:CompilePixel(PixelIs)

        table.insert(Chunks, PixelStr)

        if (Column % ChunkSize == 0) then
          local ChunksStr = ListToString(Chunks, ColumnsDelim)
          Chunks = {}

          self:WriteLine(ChunksStr)
        end
      end

      -- Write remained chunk
      if (Width % ChunkSize ~= 0) then
        local ChunksStr = ListToString(Chunks, ColumnsDelim)
        self:WriteLine(ChunksStr)
      end

      self:WriteLine(LinesDelim)
    end
  end

--[[
  2024-11-02
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Compiler_IsToPpm.WriteHeader'] = [=[
-- Write header to output

-- Last mod.: 2024-12-12

-- Exports
return
  function(self, DataIs)
    local Height = #DataIs
    local Width = #DataIs[1]
    local MaxColorValue = self.Constants.MaxColorValue

    self:WriteLine(
      string.format(
        self.HeaderFmt,
        Width,
        Height,
        MaxColorValue
      )
    )
  end

--[[
  2024-11-03
  2024-12-12
]]
]=],
  ['workshop.concepts.Ppm.Compiler_IsToPpm.WriteLabel'] = [=[
-- Write label string to output

-- Last mod.: 2024-12-12

-- Exports:
return
  function(self)
    self:WriteLine(
      string.format(self.LabelFmt, self.Constants.FormatLabel)
    )
  end

--[[
  2024-11-02
  2024-12-12
]]
]=],
  ['workshop.concepts.Ppm.Compiler_IsToPpm.WriteLine'] = [=[
-- Write string as line to output

-- Last mod.: 2024-11-02

-- Exports:
return
  function(self, String)
    self.Output:Write(String)
    self.Output:Write('\n')
  end

--[[
  2024-11-02
]]
]=],
  ['workshop.concepts.Ppm.Compiler_LuaToIs.CompileColor'] = [=[
-- Anonymize color to list

-- Last mod.: 2024-12-12

-- Imports:
local DenormalizeColor = request('!.concepts.Image.Color.Denormalize')

-- Exports:
return
  function(self, Color)
    DenormalizeColor(Color)

    local RedIs = self:CompileColorComponent(Color[1])
    local GreenIs = self:CompileColorComponent(Color[2])
    local BlueIs = self:CompileColorComponent(Color[3])

    if not (RedIs and GreenIs and BlueIs) then
      return
    end

    return { RedIs, GreenIs, BlueIs }
  end

--[[
  2024-11-03
  2024-11-25
  2021-12-12
]]
]=],
  ['workshop.concepts.Ppm.Compiler_LuaToIs.CompileColorComponent'] = [=[
-- Serialize color component integer

-- Last mod.: 2024-11-04

-- Imports:
local NumberInRange = request('!.number.in_range')

-- Exports:
return
  function(self, ColorComponent)
    local MaxColorValue = self.Constants.MaxColorValue
    local FormatStr = self.ColorComponentFmt

    if not is_integer(ColorComponent) then
      return
    end

    if not NumberInRange(ColorComponent, 0, MaxColorValue) then
      return
    end

    return string.format(FormatStr, ColorComponent)
  end

--[[
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Compiler_LuaToIs.CompileImage'] = [=[
-- Compile pixels to anonymous structure

-- Last mod.: 2024-11-25

-- Exports:
return
  function(self, Image)
    local MatrixIs = {}

    for RowIndex, Row in ipairs(Image) do
      MatrixIs[RowIndex] = {}

      for ColumnIndex, Color in ipairs(Row) do
        if not Color then
          return
        end

        local ValueIs = self:CompileColor(Color)

        if not ValueIs then
          return
        end

        MatrixIs[RowIndex][ColumnIndex] = ValueIs
      end
    end

    return MatrixIs
  end

--[[
  2024-11-03
  2024-11-25
]]
]=],
  ['workshop.concepts.Ppm.Compiler_LuaToIs.Interface'] = [=[
-- Compile named Lua table to anonymous structure (list of strings/lists)

-- Last mod.: 2024-12-12

-- Exports:
return
  {
    -- Main: Convert table with .ppm to anonymous tree
    Run = request('Run'),

    -- [Config]

    -- Color component serialization format
    ColorComponentFmt = '%03d',

    -- [Internal]

    -- Format constants
    Constants = request('^.Constants.Interface'),

    -- Compile image data
    CompileImage = request('CompileImage'),

    -- Compile color
    CompileColor = request('CompileColor'),

    -- Serialize color component
    CompileColorComponent = request('CompileColorComponent'),
  }

--[[
  2024-11-03
  2024-11-04
  2024-11-06
  2024-11-25
  2024-12-12
]]
]=],
  ['workshop.concepts.Ppm.Compiler_LuaToIs.Run'] = [=[
-- Anonymize parsed .ppm

-- Last mod.: 2024-12-12

--[[
  Compile Lua table to anonymous structure
]]
local Compile =
  function(self, Image)
    return self:CompileImage(Image)
  end

-- Exports:
return Compile

--[[
  2024-11-03
  2024-11-06
  2024-12-12
]]
]=],
  ['workshop.concepts.Ppm.Constants.Interface'] = [=[
-- Format constants

-- Last mod.: 2024-11-02

-- Exports:
return
  {
    -- Format label
    FormatLabel = 'P3',

    --[[
       Max color component value

       Despite that format allows any integer in [1, 65535]
       we're fixing it to constant.

       Color component value should be between 0 and this number.
    ]]
    MaxColorValue = 255,

    -- Check that given string is our format label
    IsValidLabel = request('IsValidLabel'),
  }

--[[
  2024-11-02
]]
]=],
  ['workshop.concepts.Ppm.Constants.IsValidLabel'] = [=[
-- Check that given string is our format label

-- Last mod.: 2024-11-02

-- Exports:
return
  function(self, Label)
    return (Label == self.FormatLabel)
  end

--[[
  2024-11-02
]]
]=],
  ['workshop.concepts.Ppm.Interface'] = [=[
-- Encode/decode .ppm file to Lua table

-- Last mod.: 2024-11-06

-- Exports:
return
  {
    -- [Config]

    -- Input stream
    Input = request('!.concepts.StreamIo.Input'),

    -- Output stream
    Output = request('!.concepts.StreamIo.Output'),

    -- [Main]

    -- Load image from stream
    Load = request('Load'),

    -- Save image to stream
    Save = request('Save'),
  }

--[[
  2024-11-04
]]
]=],
  ['workshop.concepts.Ppm.Load'] = [=[
-- Load image from stream

-- Last mod.: 2024-11-23

-- Imports:
local Parser_PpmToIs = request('Parser_PpmToIs.Interface')
local Parser_IsToLua = request('Parser_IsToLua.Interface')

-- Exports:
return
  function(self)
    Parser_PpmToIs.Input = self.Input

    local ImageIs = Parser_PpmToIs:Run()

    if not ImageIs then
      return
    end

    local Image = Parser_IsToLua:Run(ImageIs)

    if not Image then
      return
    end

    return Image
  end

--[[
  2024-11-04
]]
]=],
  ['workshop.concepts.Ppm.Parser_IsToLua.Interface'] = [=[
-- Parse from anonymous structure to custom Lua format

-- Last mod.: 2024-11-25

-- Exports:
return
  {
    -- [Main] Parse pixmap structure to Lua table in custom format
    Run = request('Run'),

    -- [Internal]

    -- .ppm format constants
    Constants = request('^.Constants.Interface'),

    -- Parse raw pixels data
    ParsePixels = request('ParsePixels'),

    -- Parse pixel
    ParsePixel = request('ParsePixel'),

    -- Parse color component value
    ParseColorComponent = request('ParseColorComponent'),
  }

--[[
  2024-11-02
  2024-11-06
]]
]=],
  ['workshop.concepts.Ppm.Parser_IsToLua.ParseColorComponent'] = [=[
-- Parse color component value

-- Last mod.: 2024-11-06

-- Imports:
local NumberInRange = request('!.number.in_range')

--[[
  Parse color component value from string to integer.

  Checks that integer is within max color component range.

  In case of problems returns nil.
]]
local ParseColorComponent =
  function(self, Value)
    local MaxColorValue = self.Constants.MaxColorValue

    Value = tonumber(Value)

    if not is_integer(Value) then
      return
    end

    if not NumberInRange(Value, 0, MaxColorValue) then
      return
    end

    return Value
  end

-- Exports:
return ParseColorComponent

--[[
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Parser_IsToLua.ParsePixel'] = [==[
-- Parse raw pixel data

-- Last mod.: 2024-11-25

-- Imports:
local BaseColor = request('!.concepts.Image.Color.Interface')
local NormalizeColor = request('!.concepts.Image.Color.Normalize')

--[=[
  Parses raw pixel data to annotated list

  { '0', '128', '255' } -> { 0, 128, 255 --[[ aka .Red, .Green, .Blue ]] }

  In case of problems returns nil.
]=]
local ParsePixel =
  function(self, PixelIs)
    local Red = self:ParseColorComponent(PixelIs[1])
    local Green = self:ParseColorComponent(PixelIs[2])
    local Blue = self:ParseColorComponent(PixelIs[3])

    if not (Red and Green and Blue) then
      return
    end

    local Color = new(BaseColor, { Red, Green, Blue })

    NormalizeColor(Color)

    return Color
  end

-- Exports:
return ParsePixel

--[[
  2024-11-03
  2024-11-25
]]
]==],
  ['workshop.concepts.Ppm.Parser_IsToLua.ParsePixels'] = [==[
-- Parse raw pixels data

-- Last mod.: 2024-11-25

--[=[
  Parse raw pixels data.

  { { { '0', '128', '255' } } } ->

  { { { 0, 128, 255 --[[ aka .Red, .Green, .Blue ]] } } }
]=]
local ParsePixels =
  function(self, DataIs)
    local Matrix = {}

    for RowIndex, Row in ipairs(DataIs) do
      Matrix[RowIndex] = {}

      for ColumnIndex, PixelIs in ipairs(Row) do
        local Pixel = self:ParsePixel(PixelIs)

        if not Pixel then
          return
        end

        Matrix[RowIndex][ColumnIndex] = Pixel
      end
    end

    return Matrix
  end

-- Exports:
return ParsePixels

--[[
  2024-11-03
  2024-11-25
]]
]==],
  ['workshop.concepts.Ppm.Parser_IsToLua.Run'] = [=[
-- Gets structure as grouped strings. Returns table with nice names

-- Last mod.: 2024-11-25

--[[
  Custom Lua format

  Input

    1x2 bitmap

    {
      { '1', '2', '255' },
      {
        { { '0', '128', '255' } },
        { { '128', '255', '0' } },
      }
    }

  is converted to

    {
      { { 0, 128, 255 } },
      { { 128, 255, 0 } },
    }

  On fail it returns nil.

  Some fail conditions:

    * Holes at Input[2] data matrix.
    * If there is color component value that is not in range [0, 255]
]]

-- Exports:
return
  function(self, DataIs)
    local PixelsIs = DataIs[2]

    local Pixels = self:ParsePixels(PixelsIs)

    if not Pixels then
      return
    end

    return Pixels
  end

--[[
  2024-11-02
  2024-11-03
  2024-11-25
]]
]=],
  ['workshop.concepts.Ppm.Parser_PpmToIs.GetChunk'] = [=[
-- Load given amount of items

-- Last mod.: 2024-11-03

--[[
  Get specified amount of items from input stream.

  Return list of items. If failed, return nil.
]]
local GetChunk =
  function(self, NumItems)
    local Result = {}

    for i = 1, NumItems do
      local Item = self:GetNextItem()

      if not Item then
        return
      end

      table.insert(Result, Item)
    end

    return Result
  end

-- Exports:
return GetChunk

--[[
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Parser_PpmToIs.GetNextCharacter'] = [=[
-- Get next character

-- Last mod.: 2024-11-02

--[[
  Get next character from input stream.

  We store character in <.NextCharacter>.

  On end of stream:

    <.NextCharacter> = nil
    return false

  We can't move stream back. So parsers should call this method
  only when they are done with current <.NextCharacter>.
]]
local GetNextCharacter =
  function(self)
    local Char, IsOkay = self.Input:Read(1)

    if not IsOkay then
      self.NextCharacter = nil

      return false
    end

    self.NextCharacter = Char

    return true
  end

-- Exports:
return GetNextCharacter

--[[
  2024-11-02
]]
]=],
  ['workshop.concepts.Ppm.Parser_PpmToIs.GetNextItem'] = [=[
-- Get next item

-- Last mod.: 2024-11-04

local IsSpace =
  function(Char)
    return
      (Char == ' ') or
      (Char == '\t')
  end

local IsNewline =
  function(Char)
    return
      (Char == '\n') or
      (Char == '\r')
  end

local IsDelimiter =
  function(Char)
    return IsSpace(Char) or IsNewline(Char)
  end

-- Read until end of stream or until end of line
local SkipLine =
  function(self)
    while self:GetNextCharacter() do
      if IsNewline(self.NextCharacter) then
        break
      end
    end
  end

--[[
  Get next item

  Skips line comments.

    > P3
    > 1920 1080 # Width Height
    > 255

  Items are "P3", "1920", "1080", "255"
]]
local GetNextItem =
  function(self)
    local Char

    ::Redo::

    -- Space eating cycle
    while self:GetNextCharacter() do
      Char = self.NextCharacter

      if not IsDelimiter(Char) then
        break
      end

      PrevChar = Char
    end

    -- Check for line comment
    do
      local CommentChar = '#'

      if (Char == CommentChar) then
        -- Skip until end of line. Damned comment
        SkipLine(self)
        goto Redo
      end
    end

    -- Catenate characters to <Term>
    local Term = Char

    while self:GetNextCharacter() do
      Char = self.NextCharacter

      if IsDelimiter(Char) then
        break
      end

      Term = Term .. Char
    end

    return Term
  end

-- Exports:
return GetNextItem

--[[
  2024-11-02
]]
]=],
  ['workshop.concepts.Ppm.Parser_PpmToIs.GetPixels'] = [=[
-- Load raw pixels data from .ppm stream

-- Last mod.: 2024-11-03

--[[
  Load pixels data from .ppm stream

  Requires parsed header to know dimensions of data.
  Data values are not processed. But grouped.

  In case there are not enough data, return nil.
  Else return matrix of (height x width x 3).
]]
local GetPixels =
  function(self, Header)
    local Data = {}

    for Row = 1, Header.Height do
      local RowData = {}

      for Column = 1, Header.Width do
        local NumColorComponents = 3
        local Color = self:GetChunk(NumColorComponents)

        if not Color then
          return
        end

        RowData[Column] = Color
      end

      Data[Row] = RowData
    end

    return Data
  end

-- Exports:
return GetPixels

--[[
  2024-11-03
]]
]=],
  ['workshop.concepts.Ppm.Parser_PpmToIs.Interface'] = [=[
-- Load pixmap to itness format (list with strings and lists)

-- Last mod.: 2024-11-06

-- Exports:
return
  {
    -- [Config]

    -- Input stream
    Input = request('!.concepts.StreamIo.Input'),

    -- [Main] Load pixmap to itness format
    Run = request('Run'),

    -- [Internal]

    -- .ppm format constants
    Constants = request('^.Constants.Interface'),

    -- Next character. Used by GetNextCharacter()
    NextCharacter = nil,

    -- Get next character
    GetNextCharacter = request('GetNextCharacter'),

    -- Get next item
    GetNextItem = request('GetNextItem'),

    -- Get chunk of items
    GetChunk = request('GetChunk'),

    -- Parse header from raw data
    ParseHeader = request('ParseHeader'),

    -- Load raw pixels data from input stream
    GetPixels = request('GetPixels'),
  }

--[[
  2024-11-02
  2024-11-03
  2024-11-06
]]
]=],
  ['workshop.concepts.Ppm.Parser_PpmToIs.ParseHeader'] = [=[
-- Parse header from list to table

-- Last mod.: 2024-11-25

-- Imports:
local IsNaturalNumber = request('!.number.is_natural')

--[[
  Parse header in Itness format to Lua table

  Example:

    { '60', '30', '255' } -> { Width = 60, Height = 30 }
]]
local ParseHeader =
  function(self, HeaderIs)
    local WidthIs = HeaderIs[1]
    local HeightIs = HeaderIs[2]

    local Width = tonumber(WidthIs)
    assert(IsNaturalNumber(Width))

    local Height = tonumber(HeightIs)
    assert(IsNaturalNumber(Height))

    return { Width = Width, Height = Height }
  end

-- Exports:
return ParseHeader

--[[
  2024-11-03
  2024-11-25
]]
]=],
  ['workshop.concepts.Ppm.Parser_PpmToIs.Run'] = [=[
-- Read in .ppm format. Return structure in itness format (grouped strings)

-- Last mod.: 2024-11-06

--[[
  Normally it returns Lua list with strings and lists.

  On fail it returns nil.

  Fail conditions:

    * There are less values than required for (width x height x 3)
      matrix

  .ppm format allows line comments "# blah blah\n". They are lost.

  Example

    .ppm

      > P3 1 2 255 0 128 255 128 255 0

    is loaded as

      {
        { '1', '2', '255' },
        {
          { { '0', '128', '255' } },
          { { '128', '255', '0' } },
        }
      }
]]

--[[
  Convert from pixmap to itness

  Returns nil if problems.
]]
local Parse =
  function(self)
    local Label = self:GetNextItem()

    if not self.Constants:IsValidLabel(Label) then
      return
    end

    local NumItemsInHeader = 3
    local HeaderIs = self:GetChunk(NumItemsInHeader)

    if not HeaderIs then
      return
    end

    local Header = self:ParseHeader(HeaderIs)

    if not Header then
      return
    end

    local PixelsIs = self:GetPixels(Header)

    if not PixelsIs then
      return
    end

    return { HeaderIs, PixelsIs }
  end

-- Exports:
return Parse

--[[
  2024-11-02
  2024-11-03
  2024-11-05
]]
]=],
  ['workshop.concepts.Ppm.Save'] = [=[
-- Save image to stream

-- Last mod.: 2024-12-12

-- Imports:
local Compiler_LuaToIs = request('Compiler_LuaToIs.Interface')
local Compiler_IsToPpm = request('Compiler_IsToPpm.Interface')

-- Exports:
return
  function(self, Image)
    local ImageIs = Compiler_LuaToIs:Run(Image)

    if not ImageIs then
      return false
    end

    Compiler_IsToPpm.Output = self.Output

    local IsOkay = Compiler_IsToPpm:Run(ImageIs)

    if not IsOkay then
      return false
    end

    return true
  end

--[[
  2024-11-04
]]
]=],
  ['workshop.concepts.StreamIo.Input'] = [=[
-- Reader interface

--[[
  Exports

    {
      Read() - read function
    }
]]

--[[
  Read given amount of bytes to string

  Input:
    NumBytes (uint) >= 0

  Output:
    Data (string)
    IsComplete (bool)

  Details

    If we can't read <NumBytes> bytes we read what we can and set
    <IsComplete> to FALSE. Typical case is empty string for end-of-file
    state.

    Reading zero bytes is neutral operation which can be used to detect
    problems through <IsComplete> flag.
]]
local Read =
  function(self, NumBytes)
    assert_integer(NumBytes)
    assert(NumBytes >= 0)

    local ResultStr = ''
    local IsComplete = false

    return ResultStr, IsComplete
  end

-- Exports:
return
  {
    Read = Read,
  }

--[[
  2024-07-19
  2024-07-24
]]
]=],
  ['workshop.concepts.StreamIo.Input.File'] = [=[
-- Reads strings from file. Implements [Input]

-- Last mod.: 2024-11-11

local OpenForReading = request('!.file_system.file.OpenForReading')
local CloseFileFunc = request('!.file_system.file.Close')

-- Contract: Read string from file
local Read =
  function(self, NumBytes)
    assert_integer(NumBytes)
    assert(NumBytes >= 0)

    local Data = ''
    local IsComplete = false

    Data = self.FileHandle:read(NumBytes)

    local IsEof = is_nil(Data)

    -- No End-of-File state in [Input]
    if IsEof then
      Data = ''
    end

    IsComplete = (#Data == NumBytes)

    return Data, IsComplete
  end

-- Intestines: Open file for reading
local OpenFile =
  function(self, FileName)
    local FileHandle = OpenForReading(FileName)

    if is_nil(FileHandle) then
      return false
    end

    self.FileHandle = FileHandle

    return true
  end

-- Intestines: close file
local CloseFile =
  function(self)
    return (CloseFileFunc(self.FileHandle) == true)
  end

local Interface =
  {
    -- [New]

    -- Open file by name
    Open = OpenFile,

    -- Close file
    Close = CloseFile,

    -- [Main]: Read bytes
    Read = Read,

    -- Intestines
    FileHandle = 0,
  }

-- Close file at garbage collection
setmetatable(Interface, { __gc = function(self) self:Close() end } )

-- Exports:
return Interface

--[[
  2024-07-19
  2024-07-24
  2024-08-05
  2024-08-09
  2024-11-11
]]
]=],
  ['workshop.concepts.StreamIo.Output'] = [=[
-- Writer interface

--[[
  Exports:

    {
      Write() - write function
    }
]]

--[[
  Write string

  Input:
    Data (string)

  Output:
    NumBytesWritten (uint)
    IsCompleted (bool)

  Details

    Writing empty string is neutral operation which can be used to
    detect problems by examining <IsCompleted> flag.
]]
local Write =
  function(self, Data)
    assert_string(Data)

    local NumBytesWritten = 0
    local IsCompleted = false

    return NumBytesWritten, IsCompleted
  end

-- Exports:
return
  {
    Write = Write,
  }

--[[
  2024-07-19
  2024-07-24
]]
]=],
  ['workshop.concepts.StreamIo.Output.File'] = [=[
-- Writes strings to file. Implements [Output]

-- Last mod.: 2024-11-11

local OpenForWriting = request('!.file_system.file.OpenForWriting')
local CloseFileFunc = request('!.file_system.file.Close')

-- Contract: Write string to file
local Write =
  function(self, Data)
    assert_string(Data)

    local IsOk = self.FileHandle:write(Data)

    if is_nil(IsOk) then
      return 0, false
    end

    return #Data, true
  end

-- Intestines: Open file for writing
local OpenFile =
  function(self, FileName)
    local FileHandle = OpenForWriting(FileName)

    if is_nil(FileHandle) then
      return false
    end

    self.FileHandle = FileHandle

    return true
  end

-- Intestines: close file
local CloseFile =
  function(self)
    return (CloseFileFunc(self.FileHandle) == true)
  end

local Interface =
  {
    -- [Added]

    -- Open file by name
    Open = OpenFile,

    -- Close file
    Close = CloseFile,

    -- [Main]: Write string
    Write = Write,

    -- [Internals]
    FileHandle = 0,
  }

-- Close file at garbage collection
setmetatable(Interface, { __gc = function(self) self:Close() end } )

-- Exports:
return Interface

--[[
  2024-07-19
  2024-07-24
  2024-08-05
  2024-08-09
  2024-11-11
]]
]=],
  ['workshop.concepts.lua.is_identifier'] = [[
local keywords = request('keywords')

return
  function(s)
    return
      is_string(s) and
      s:match('^[%a_][%w_]*$') and
      not keywords[s]
  end
]],
  ['workshop.concepts.lua.keywords'] = [[
local map_values = request('!.table.map_values')

return
  map_values(
    {
      'nil',
      'true',
      'false',
      'not',
      'and',
      'or',
      'do',
      'end',
      'local',
      'function',
      'goto',
      'if',
      'then',
      'elseif',
      'else',
      'while',
      'repeat',
      'until',
      'for',
      'in',
      'break',
      'return',
    }
  )
]],
  ['workshop.concepts.lua.quote_string'] = [=[
local quote_escaped = request('quote_string.linear')
local quote_long = request('quote_string.intact')
local quote_dump = request('quote_string.dump')

local content_funcs = request('!.string.content_attributes')
local has_control_chars = content_funcs.has_control_chars
local has_backslashes = content_funcs.has_backslashes
local has_single_quotes = content_funcs.has_single_quotes
local has_double_quotes = content_funcs.has_double_quotes
local is_nonascii = content_funcs.is_nonascii
local has_newlines = content_funcs.has_newlines

local binary_entities_lengths =
  {
    [1] = true,
    [2] = true,
    [4] = true,
    [6] = true,
    [8] = true,
    [10] = true,
    [16] = true,
  }

return
  function(s)
    assert_string(s)

    local quote_func = quote_escaped

    if binary_entities_lengths[#s] and is_nonascii(s) then
      quote_func = quote_dump
    elseif
      has_backslashes(s) or
      has_newlines(s) or
      (
        has_single_quotes(s) and has_double_quotes(s)
      )
    then
      quote_func = quote_long
    end

    local result = quote_func(s)
    return result
  end

--[[
  2016-09
  2017-08
  2024-11
]]
]=],
  ['workshop.concepts.lua.quote_string.custom_quotes'] = [=[
return
  {
    ['\x07'] = [[\a]],
    ['\x08'] = [[\b]],
    ['\x09'] = [[\t]],
    ['\x0a'] = [[\n]],
    ['\x0b'] = [[\v]],
    ['\x0c'] = [[\f]],
    ['\x0d'] = [[\r]],
    ['"'] = [[\"]],
    ["'"] = [[\']],
    ['\\'] = [[\\]],
  }
]=],
  ['workshop.concepts.lua.quote_string.dump'] = [=[
--[[
  Quote given string as by substituting all characters to their
  hex values.

  Handy for representing binary numbers:
    '\xB2\x7F\x02\xEE' has more sense than '²\x7F\x02î'
]]

local quote_char = request('quote_char')

return
  function(s)
    assert_string(s)
    return "'" .. s:gsub('.', quote_char) .. "'"
  end
]=],
  ['workshop.concepts.lua.quote_string.intact'] = [====[
-- Quote string in long quotes

-- Last mod.: 2024-11-19

--[==[
  Long quotes

  Long quotes is multi-character quotes in Lua. String data inside them
  are not processed. So no need to worry about quoting some "special"
  characters.

  That's all the same:

    > s = [[
    Hello!]]
    > s = [[Hello!]]
    > s = [=[Hello!]=]
]==]

local has_newlines = request('!.string.content_attributes').has_newlines

return
  function(s)
    assert_string(s)

    -- (1)
    s = s .. ']'

    local eq_chunk = ''
    local postfix
    while true do
      postfix = ']' .. eq_chunk .. ']'
      if not s:find(postfix, 1, true) then
        break
      end
      eq_chunk = eq_chunk .. '='
    end

    local prefix = '[' .. eq_chunk .. '['

    -- (2)
    local first_char = s:sub(1, 1)
    if
      (first_char == '\x0D') or
      (first_char == '\x0A')
    then
      prefix = prefix .. first_char
    end

    -- (3)
    if has_newlines(s) then
      prefix = prefix .. '\x0A'
    end

    return prefix .. s .. eq_chunk .. ']'
  end

--[===[
  [1] Quoted result string will have following structure:

    "[" "="^N "[" ["\n"] s "]" "="^N "]"

    We may safely concatenate "]" to <s> before determining <N>.
    This is done to avoid following cases:

      s     | unpatched   |  patched
      ------+-------------+--------------
      "]"   | "[[]]]"     | "[=[]]=]"
      "]]=" | "[=[]]=]=]" | "[==[]]=]==]"

    Case pointed by Roberto Ierusalimschy 2018-12-14 in Lua Mail
    List.

  [2] Heading newline dropped from long string quote. So we need
    duplicate it to preserve second copy. Before it all variants
    of newlines are converted to 0x0A.

    Tricky case here is if we have 0x0D we cant add 0x0A or it still
    be interpreted as one newline.

    Nice workaround is duplicate first byte of newline:

      0D    | 0D 0D    | \
      0A    | 0A 0A    |   still two line
      0D 0A | 0D 0D 0A |   delimiters!
      0A 0D | 0A 0A 0D | /

    Case and solution pointed by Andrew Gierth 2018-12-15 in Lua
    Mail List.

  [3]
    If string is multiline like "Hey\n  buddy!\n" then we want to
    represent it as
      > [[
      > Hey
      >   buddy!
      > ]]

    Not as
      > [[Hey
      >   buddy!
      > ]]

    For the sake of readability.
  ]=]

]===]

--[[
  2017-03
  2018-12
  2024-11
]]
]====],
  ['workshop.concepts.lua.quote_string.linear'] = [=[
local quote_char = request('quote_char')
local custom_quotes = request('custom_quotes')

--[[
  [1]
    I do not want to remember <custom_quotes> mapping (to understand
    that "\f" in output means ASCII code 0x0C. Also I do not like when
    "\" maps to "\\", I prefer "\x5c". Without using <custom_quote>
    table you get longer but easier to understand data representation.
]]
return
  function(s)
    local result = s
    --(1)
    -- result = result:gsub([[\]], custom_quotes['\\'])
    result = result:gsub([[\]], quote_char)
    -- result = result:gsub('[%c]', custom_quotes)
    result = result:gsub('[%c]', quote_char)
    --/

    local cnt_q1 = 0
    for i in result:gmatch("'") do
      cnt_q1 = cnt_q1 + 1
    end
    local cnt_q2 = 0
    for i in result:gmatch('"') do
      cnt_q2 = cnt_q2 + 1
    end
    if (cnt_q1 <= cnt_q2) then
      result = "'" .. result:gsub("'", custom_quotes["'"]) .. "'"
    else
      result = '"' .. result:gsub('"', custom_quotes['"']) .. '"'
    end
    return result
  end
]=],
  ['workshop.concepts.lua.quote_string.quote_char'] = [=[
--[[
  Return string with escaped hex byte for given string with byte.

  So for ' ' it will return '\x20'.

  This function intended for use as gsub() match handler.
]]

return
  function(c)
    return ([[\x%02X]]):format(c:byte(1, 1))
  end
]=],
  ['workshop.concepts.lua_table.save'] = [[
-- Serialize lua table as string with lua table definition.

-- Not suitable for tables with cross-links in keys or values.

local c_table_serializer = request('save.interface')
local compile = request('!.struc.compile')

return
  function(t, options)
    assert_table(t)
    local table_serializer = new(c_table_serializer, options)
    table_serializer:init()
    local ast = table_serializer:get_ast(t)
    local result = table_serializer:serialize_ast(ast)
    return result
  end
]],
  ['workshop.concepts.lua_table.save.get_ast'] = [=[
-- Provide data tree for Lua table without cycles (for tree)

--[[
  /*
    That's a pseudocode. Implementation uses lowercase field names.
  */

  MakeTree(Data)
  ~~~~~~~~~~~~~~
    if not IsTable(Data)
      if
        @OnlyRestorableItems and
        (TypeOf(Data) not in @RestorableTypes)

        return

      Result.Type = TypeOf(Data)
      Result.Value = Data
      return

    if @NamedValues[Data]
      Result.Type = "name"
      Result.Value = Name of node. Used in cycled table serializer.
      return

    AssertTable(Data)

    Result.Type = "table"
    for (Key, Val) in Data
      Result[i] = { Key = MakeTree(Key), Value = MakeTree(Val) }
]]

local RestorableTypes =
  {
    ['boolean'] = true,
    ['number'] = true,
    ['string'] = true,
    ['table'] = true,
  }

return
  function(self, data)
    local result
    local data_type = type(data)
    if (data_type == 'table') then
      if self.value_names[data] then
        result =
          {
            type = 'name',
            value = self.value_names[data],
          }
      else
        result = {}
        result.type = 'table'
        for key, value in self.table_iterator(data) do
          if (
            self.OnlyRestorableItems and
              (
                not RestorableTypes[type(key)] or
                not RestorableTypes[type(value)]
              )
            )
          then
            goto next
          end
          local key_slot = self:get_ast(key)
          local value_slot = self:get_ast(value)
          result[#result + 1] =
            {
              key = key_slot,
              value = value_slot,
            }
        ::next::
        end
      end
    else
      result =
        {
          type = data_type,
          value = data,
        }
    end
    return result
  end

--[[
  2018-02
  2020-09
  2022-01
  2024-08
]]
]=],
  ['workshop.concepts.lua_table.save.init'] = [[
return
  function(self)
    self.text_block = new(self.c_text_block)
    self.text_block:init()
    self.install_node_handlers(self.node_handlers, self.text_block)
  end
]],
  ['workshop.concepts.lua_table.save.install_node_handlers.minimal'] = [=[
-- Minificating table serializer methods

-- Last mod.: 2024-11-11

local text_block

local add =
  function(s)
    text_block:add_curline(s)
  end

local node_handlers = {}

local raw_compile = request('!.struc.compile')

local compile =
  function(t)
    add(raw_compile(t, node_handlers))
  end

local is_identifier = request('!.concepts.lua.is_identifier')
local compact_sequences = true

node_handlers.table =
  function(node)
    if (#node == 0) then
      add('{}')
      return
    end
    local last_integer_key = 0
    add('{')
    for i = 1, #node do
      if (i > 1) then
        add(',')
      end
      local key, value = node[i].key, node[i].value
      -- skip key part?
      if
        compact_sequences and
        (key.type == 'number') and
        is_integer(key.value) and
        (key.value == last_integer_key + 1)
      then
        last_integer_key = key.value
      else
        -- may mention key without brackets?
        if
          (key.type == 'string') and
          is_identifier(key.value)
        then
          add(key.value)
        else
          add('[')
          compile(key)
          add(']')
        end
        add('=')
      end
      compile(value)
    end
    add('}')
  end

do
  local serialize_tostring =
    function(node)
      add(tostring(node.value))
    end

  node_handlers.boolean = serialize_tostring
  node_handlers['nil'] = serialize_tostring
end

--[[
  tostring() of 1/0, 2/0, ... yields unloadable "inf".
  (-1/0, -2/0, ...) -> "-inf". (0/0, -0/0, -0/-0.0, ...) -> "-nan".
  We can compare "inf" values (1/0 == 2/0 -> true) but
  can't compare "nan" values (0/0 == 0/0 -> false).
  For "inf" cases we emit loadable "1/0" or "-1/0".
]]
node_handlers.number =
  function(node)
    if (node.value == 1/0) then
      add('1/0')
    elseif (node.value == -1/0) then
      add('-1/0')
    else
      add(tostring(node.value))
    end
  end

do
  local quote = request('!.lua.string.quote')

  local serialize_quoted =
    function(node)
      local quoted_string = quote(tostring(node.value))
      -- Quite ugly handling indexing [[[s]]] case: convert to [ [[s]]]
      if not text_block:on_clean_line() then
        local text_line = text_block.line_with_text:get_line()
        if
          (text_line:sub(-1) == '[') and
          (quoted_string:sub(1, 1) == '[')
        then
          add(' ')
        end
      end
      add(quoted_string)
    end

  local quoted_datatypes = {'string', 'function', 'thread', 'userdata'}

  for i = 1, #quoted_datatypes do
    node_handlers[quoted_datatypes[i]] = serialize_quoted
  end
end

node_handlers.name =
  function(node)
    compile(node.value)
  end

local force_merge = request('!.table.merge_and_patch')

return
  function(a_node_handlers, a_text_block, options)
    node_handlers = force_merge(a_node_handlers, node_handlers)
    text_block = a_text_block
    if options and is_boolean(options.compact_sequences) then
      compact_sequences = options.compact_sequences
    end
  end

--[[
  2017-05
  2019-06
]]
]=],
  ['workshop.concepts.lua_table.save.install_node_handlers.readable'] = [=[
-- Implementation of "readable" Lua table serialization

-- Last mod.: 2024-11-11

local RawCompile = request('!.struc.compile')
local IsName = request('!.concepts.lua.is_identifier')

local Handlers = {}

-- State (
-- Virtual printer interface
local Printer
-- Do not emit integer indices when possible
local CompactSequences = true
-- )

-- Mostly aliasing printers methods (
local GoToEmptyLine =
  function()
    Printer:request_clean_line()
  end

local Indent =
  function()
    Printer:inc_indent()
  end

local Unindent =
  function()
    Printer:dec_indent()
  end

local Emit =
  function(s)
    Printer:add_curline(s)
  end
-- )

local Compile =
  function(Tree)
    Emit(RawCompile(Tree, Handlers))
  end

Handlers.table =
  function(Node)
    -- Shortcut: empty table
    if (#Node == 0) then
      Emit('{}')
      return
    end

    --[[
      One-element table

      We'll put it on one line and wont write trailing delimiter.
    ]]
    local TheOneAndOnly = (#Node == 1)

    -- Array part tracking for <CompactSequences>
    local LastIntKey = 0

    Emit('{')
    Indent()

    for Idx, El in ipairs(Node) do
      local Key, Value = El.key, El.value

      if not TheOneAndOnly then
        GoToEmptyLine()
      end

      --[[
        if CompactSequences
          Do not emit integer index while we are on array part
      ]]
      local IsOnArray =
        is_integer(Key.value) and (Key.value == LastIntKey + 1)

      if CompactSequences and IsOnArray then
        LastIntKey = Key.value
      else
        -- No brackets required for identifiers
        if IsName(Key.value) then
          Emit(Key.value)
        else
          Emit('[')
          Compile(Key)
          Emit(']')
        end
        Emit(' = ')
      end

      Compile(Value)

      if not TheOneAndOnly then
        Emit(',')
      end
    end

    if not TheOneAndOnly then
      GoToEmptyLine()
    end

    Unindent()
    Emit('}')
  end

local ForceMerge = request('!.table.merge_and_patch')
local InstallMinimalHandlers = request('minimal')

-- Exports:
return
  function(a_Handlers, a_Printer, Options)
    InstallMinimalHandlers(a_Handlers, a_Printer, Options)
    Handlers = ForceMerge(a_Handlers, Handlers)
    Printer = a_Printer
    if is_table(Options) and is_boolean(Options.compact_sequences) then
      CompactSequences = options.compact_sequences
    end
  end

--[[
  2018-02-05
  2024-08-09
]]
]=],
  ['workshop.concepts.lua_table.save.interface'] = [[
return
  {
    init = request('init'),

    get_ast = request('get_ast'),
    serialize_ast = request('serialize_ast'),

    OnlyRestorableItems = false,

    node_handlers = {},
    c_text_block = request('!.mechs.text_block.interface'),
    text_block = nil,
    value_names = {},
    table_iterator = request('!.table.ordered_pass'),
    install_node_handlers = request('install_node_handlers.readable'),
  }
]],
  ['workshop.concepts.lua_table.save.serialize_ast'] = [[
local compile = request('!.struc.compile')

return
  function(self, ast)
    compile(ast, self.node_handlers)
    return self.text_block:get_text() .. '\n'
  end
]],
  ['workshop.file_system.file.Close'] = [=[
-- Close file object

--[[
  Stock Lua explodes with exception on double close.
  I want idempotence.
]]

--[[
  Close file object

  Input
    file

  Output
    nil(if not applicable) or bool(file is closed)

  Notes
    Lua's "io" do not closes stdins etc. We reflect this in boolean
    result. For most practical cases is can be ignored.
]]
return
  function(File)
    local IsFile = is_string(io.type(File))

    if not IsFile then
      return
    end

    local IsClosed = (io.type(File) == 'closed file')
    if IsClosed then
      return true
    end

    local IsOk = io.close(File)

    return IsOk
  end

--[[
  2024-08-09
]]
]=],
  ['workshop.file_system.file.OpenForReading'] = [=[
-- Open file for reading

return
  function(FileName)
    assert_string(FileName)

    local File = io.open(FileName, 'rb')

    if is_nil(File) then
      return
    end

    return File
  end

--[[
  2024-08-09
]]
]=],
  ['workshop.file_system.file.OpenForWriting'] = [=[
-- Open file for writing

return
  function(FileName)
    assert_string(FileName)

    local File = io.open(FileName, 'w+b')

    if is_nil(File) then
      return
    end

    return File
  end

--[[
  2024-08-09
]]
]=],
  ['workshop.lua.data_mathtypes'] = [=[
-- Return list of numeric type names

--[[
  Output

    table

      List with number type names as they are returned
      by math.type() function.

  Note

    Used in code generation.
]]

-- Last mod.: 2024-08-06

return
  {
    'integer',
    'float',
  }

--[[
  2024-03-02
]]
]=],
  ['workshop.lua.data_types'] = [=[
-- Return list with names of all Lua data types

--[[
  Output

    table

      List of strings with type names as they are returned
      by type() function.

  Note

    Used in code generation.
]]

-- Last mod.: 2024-08-06

return
  {
    'nil',
    'boolean',
    'number',
    'string',
    'function',
    'thread',
    'userdata',
    'table',
  }

--[[
  2018-02
]]
]=],
  ['workshop.lua.string.quote'] = [[
return request('!.concepts.lua.quote_string')
]],
  ['workshop.mechs.text_block.dec_indent'] = [[
return
  function(self)
    self.Indent:Decrease()
  end
]],
  ['workshop.mechs.text_block.inc_indent'] = [[
return
  function(self)
    self.Indent:Increase()
  end
]],
  ['workshop.mechs.text_block.init'] = [[
return
  function(self)
    self.processed_text = {}

    self.Indent:Init(self.next_line_indent, self.indent_chunk)

    self.line_with_text:init(self.Indent:GetString())

    self.num_line_feeds = 0
  end
]],
  ['workshop.mechs.text_block.interface'] = [[
return
  {
    -- text:
    line_with_text = request('line.interface'),
    processed_text = {},
    num_line_feeds = 0,

    store_textline = request('text.store_textline'),
    add_textline = request('text.add_textline'),
    add_curline = request('text.add_curline'),

    new_line = request('text.new_line'),
    request_clean_line = request('text.request_clean_line'),
    request_empty_line = request('text.request_empty_line'),

    on_clean_line = request('text.on_clean_line'),

    include = request('text.include'),

    get_text = request('text.get_text'),

    -- indents:
    indent_chunk = '  ',
    next_line_indent = 0,
    inc_indent = request('inc_indent'),
    dec_indent = request('dec_indent'),

    -- text length:
    max_text_width = 0,
    max_block_width = 0,
    get_text_width = request('text.get_text_width'),
    get_block_width = request('text.get_block_width'),

    init = request('init'),

    -- Intestines
    Indent = request('!.concepts.Indent.Interface'),
  }
]],
  ['workshop.mechs.text_block.line.add'] = [[
-- Add string to text
return
  function(self, s)
    self.text = self.text .. s
  end
]],
  ['workshop.mechs.text_block.line.get_line'] = [[
-- Return string with indent and text
return
  function(self)
    if self:is_empty() then
      return ''
    end

    return self.indent .. self.text
  end
]],
  ['workshop.mechs.text_block.line.get_line_length'] = [[
-- Return length of indented text
return
  function(self)
    if self:is_empty() then
      return 0
    end

    return utf8.len(self.indent) + self:get_text_length()
  end
]],
  ['workshop.mechs.text_block.line.get_text_length'] = [[
-- Return length of text without indent
return
  function(self)
    return utf8.len(self.text) or #self.text
  end
]],
  ['workshop.mechs.text_block.line.init'] = [[
-- Set indent string and empty text
return
  function(self, IndentValue)
    assert_string(IndentValue)
    self.indent = IndentValue

    self.text = ''
  end
]],
  ['workshop.mechs.text_block.line.interface'] = [=[
-- Indented line interface

return
  {
    -- Contract:

    -- Set indent, empty text
    init = request('init'),

    -- Text is empty?
    is_empty = request('is_empty'),

    -- Get length of text
    get_text_length = request('get_text_length'),

    -- Get length of indented text
    get_line_length = request('get_line_length'),

    -- Get indented text
    get_line = request('get_line'),

    -- Add string to text
    add = request('add'),

    -- Intestines:

    -- Indent string
    indent = '',
    -- Text string
    text = '',
  }

--[[
  2017-09
  2024-09
]]
]=],
  ['workshop.mechs.text_block.line.is_empty'] = [[
-- Return true if text is empty

return
  function(self)
    return (self.text == '')
  end
]],
  ['workshop.mechs.text_block.text.add_curline'] = [=[
return
  function(self, s)
    if (self.num_line_feeds > 0) and (s ~= '') then
      --[[
        We're going to add some text to currently empty line.
        So <line_with_text> will point to this text. Save previous
        text from this object.
      ]]
      self:store_textline()
    end
    self.line_with_text:add(s)
  end
]=],
  ['workshop.mechs.text_block.text.add_textline'] = [[
return
  function(self, s)
    self.line_with_text:add(s)
  end
]],
  ['workshop.mechs.text_block.text.get_block_width'] = [[
return
  function(self)
    return
      math.max(self.max_block_width, self.line_with_text:get_line_length())
  end
]],
  ['workshop.mechs.text_block.text.get_text'] = [[
return
  function(self)
    self:store_textline()
    local result = table.concat(self.processed_text)
    return result
  end
]],
  ['workshop.mechs.text_block.text.get_text_width'] = [[
return
  function(self)
    return
      math.max(self.max_text_width, self.line_with_text:get_text_length())
  end
]],
  ['workshop.mechs.text_block.text.include'] = [[
return
  function(self, block, do_glue_border_lines)
    if not do_glue_border_lines then
      self:new_line()
    end
    self:store_textline()

    table.move(
      block.processed_text,
      1,
      #block.processed_text,
      #self.processed_text + 1,
      self.processed_text
    )

    self.line_with_text = block.line_with_text
  end
]],
  ['workshop.mechs.text_block.text.new_line'] = [[
return
  function(self)
    self.num_line_feeds = self.num_line_feeds + 1
  end
]],
  ['workshop.mechs.text_block.text.on_clean_line'] = [[
return
  function(self)
    return
      (self.num_line_feeds > 0) or
      (
        (self.num_line_feeds == 0) and
        (self.line_with_text.text == '')
      )
  end
]],
  ['workshop.mechs.text_block.text.request_clean_line'] = [[
return
  function(self)
    if not self:on_clean_line() then
      self:new_line()
    end
  end
]],
  ['workshop.mechs.text_block.text.request_empty_line'] = [[
return
  function(self)
    if not self:on_clean_line() then
      self:new_line()
    end
    if (self.num_line_feeds == 1) then
      self:new_line()
    end
  end
]],
  ['workshop.mechs.text_block.text.store_textline'] = [[
local trim = request('!.string.trim')

return
  function(self)
    local line_with_text = self.line_with_text

    line_with_text.text = trim(line_with_text.text)

    self.max_block_width = self:get_block_width()
    self.max_text_width = self:get_text_width()

    self.processed_text[#self.processed_text + 1] = line_with_text:get_line()
    for i = 1, self.num_line_feeds do
      self.processed_text[#self.processed_text + 1] = '\n'
    end
    self.num_line_feeds = 0

    line_with_text:init(self.Indent:GetString())
  end
]],
  ['workshop.number.assert_byte'] = [=[
--[[
  Assert that passed value is integer in byte range.
]]

local is_byte = request('is_byte')

return
  function(v)
    assert(is_byte(v))
  end
]=],
  ['workshop.number.constrain'] = [=[
-- Constrain given number between min and max values

-- Last mod.: 2024-11-24

return
  function(num, min, max)
    if (num < min) then
      return min
    end

    if (num > max) then
      return max
    end

    return num
  end

--[[
  2020-09
]]
]=],
  ['workshop.number.fit_to_range'] = [=[
-- Fit number into given range

-- Last mod.: 2024-11-24

--[[
  Basically it's classic constrain() (aka clamp()) but here
  we're passing range as list, not as two arguments.
]]

-- Imports:
local Clamp = request('!.number.constrain')

--[[
  Fit number to given range

  Input
    Number
    Range
      [1] - min
      [2] - max
  Output
    number
]]
local FitToRange =
  function(Number, Range)
    return Clamp(Number, Range[1], Range[2])
  end

-- Exports:
return FitToRange

--[[
  2024-11-24
]]
]=],
  ['workshop.number.float.get_middle'] = [=[
-- Return float between two floats

-- Exports:
return
  function(Left, Right)
    return (Left + Right) / 2
  end

--[[
  2024-11-30
]]
]=],
  ['workshop.number.float.symmetric_random'] = [=[
-- Return random value from flat distribution in interval [-1.0, +1.0]

return
  function()
    return (math.random() * 2.0 - 1.0)
  end

--[[
  2024-09
]]
]=],
  ['workshop.number.in_range'] = [=[
--[[
  Return true if given number in specified range.
]]

return
  function(num, min, max)
    return (num >= min) and (num <= max)
  end
]=],
  ['workshop.number.integer.get_gap'] = [=[
-- Return gap between two integers. (Gap between 4 and 5 is 0.)

--[[
  We can generalize this function as

  (Left, Right, UnitWidth)
    return ((Right - Left) - UnitWidth)

  and UnitWidth is 1 for integers and 0 for floats.

  But I just need it for integers.
]]

return
  function(Left, Right)
    return ((Right - Left) - 1)
  end

--[[
  2024-09
]]
]=],
  ['workshop.number.integer.get_middle'] = [=[
-- Return integer in the middle of given two

-- Last mod.: 2024-11-30

local GetMiddle =
  function(Left, Right)
    return (Left + Right) // 2
  end

-- Exports:
return GetMiddle

--[[
  2024-11-30
]]
]=],
  ['workshop.number.is_byte'] = [=[
-- Check that given argument is integer in byte range

--[[
  Input

    Value: any - any value

  Output

    Yes: bool - value is integer in byte range
]]

return
  function(Value)
    if not is_integer(Value) then
      return false
    end

    -- Masking integer with low byte changes nothing for byte range
    local Result = (Value == (Value & 0xFF))

    return Result
  end

--[[
  2020-08-09
  2024-09-30
]]
]=],
  ['workshop.number.is_natural'] = [=[
-- Return true if argument is natural number

--[[
  Natural numbers sequence starts as 1, 2, 3, ...
  Note that we do not include 0.
  This sequence is also called "counting numbers".

  Zero is neutral element to addition. It's great as
  initialization value. In multiplication using zero creates
  more problems than it solves.
]]

-- Last mod.: 2024-11-03

return
  function(Number)
    assert_number(Number)

    if not is_integer(Number) then
      return false
    end

    if (Number <= 0) then
      return false
    end

    return true
  end

--[[
  2024-11-03
]]
]=],
  ['workshop.number.map_to_range'] = [=[
-- Map number belonging to one range to number in another range

-- Last mod.: 2024-11-24

-- Imports:
local FitToRange = request('!.number.fit_to_range')

--[[
  Parameters order may look strange here. But consider
  calling it with infix notation: {0.0, 1.0}.MapNumber(64, {0, 255})
]]
local MapNumber =
  function(DestRange, Number, SrcRange)
    --[[
      Typical implementation is usually uses one formula.
      I can understand it and write it that way.
      But I value clarity more than smartassism and some performance.
    ]]

    local SrcRangeLen = SrcRange[2] - SrcRange[1]
    local DestRangeLen = DestRange[2] - DestRange[1]

    Number = FitToRange(Number, SrcRange)

    -- Offset in source range
    Number = Number - SrcRange[1]
    -- Part of source range
    Number = Number / SrcRangeLen
    -- Offset in dest range
    Number = Number * DestRangeLen
    -- Value in dest range
    Number = Number + DestRange[1]

    return Number
  end

-- Exports:
return MapNumber

--[[
  2024-11-24
]]
]=],
  ['workshop.string.content_attributes'] = [=[
local has_control_chars =
  function(s)
    return s:find('%c') and true
  end

local has_backslashes =
  function(s)
    return s:find([[%\]]) and true
  end

local has_single_quotes =
  function(s)
    return s:find([[%']]) and true
  end

local has_double_quotes =
  function(s)
    return s:find([[%"]]) and true
  end

local is_nonascii =
  function(s)
    return s:find('[^%w%s_%p]')
  end

local has_newlines =
  function(s)
    return s:find('[\n\r]')
  end

return
  {
    has_control_chars = has_control_chars,
    has_backslashes = has_backslashes,
    has_single_quotes = has_single_quotes,
    has_double_quotes = has_double_quotes,
    is_nonascii = is_nonascii,
    has_newlines = has_newlines,
  }

--[[
  2016-09
  2017-02
  2017-08
  2024-11
]]
]=],
  ['workshop.string.trim'] = [[
local trim_head = request('trim_head')
local trim_tail = request('trim_tail')

return
  function(s)
    return trim_head(trim_tail(s))
  end
]],
  ['workshop.string.trim_head'] = [[
return
  function(s)
    local result
    if (s:sub(1, 1) == ' ') then
      local start_pos = 2
      while (s:sub(start_pos, start_pos) == ' ') do
        start_pos = start_pos + 1
      end
      result = s:sub(start_pos)
    else
      result = s
    end
    return result
  end
]],
  ['workshop.string.trim_tail'] = [=[
-- Remove spaces at end of string

-- Last mod.: 2024-10-24

return
  function(s)
    assert_string(s)

    local result

    if (s:sub(-1, -1) == ' ') then
      local finish_pos = #s - 1
      while (s:sub(finish_pos, finish_pos) == ' ') do
        finish_pos = finish_pos - 1
      end
      result = s:sub(1, finish_pos)
    else
      result = s
    end

    return result
  end

--[[
  2017-01-20
]]
]=],
  ['workshop.struc.compile'] = [=[
-- Exotic table-to-string conversion

--[[
  Input

    Node: string or table
      if table then
        <Node.type> should be present

    NodeHandlers: table of functions
      key: <Node.type>

  Idea is to

    compile(
      { 'A', {type = 'Special', Value = 'X'}}, 'B' },
      { Special = function(Node) return ' -= ' .. Node.Value .. ' =- '}
    ) -> 'A -= X =- B'
]]

-- Last mod.: 2024-10-21

local compile_core = request('compile_core')
local ListToString = request('!.concepts.List.ToString')

return
  function(Node, NodeHandlers)
    if is_string(Node) then
      return Node
    else
      assert_table(Node)
    end

    NodeHandlers = NodeHandlers or {}
    assert_table(NodeHandlers)

    local Result = {}

    compile_core(Node, NodeHandlers, Result)
    Result = ListToString(Result)

    return Result
  end

--[[
  2017-02-13
  2017-05-09
  2017-08-27
  2018-08-08
  2024-10-21
]]
]=],
  ['workshop.struc.compile_core'] = [[
local compile
compile =
  function(node, node_handlers, result)
    if is_string(node) then
      result[#result + 1] = node
    elseif is_table(node) then
      local node_handler = node_handlers[node.type]

      if node.type and not node_handler then
        local msg =
          ('No node handler for type "%s".'):format(node.type)
        io.stderr:write(msg)
      end

      if node_handler then
        result[#result + 1] = node_handler(node)
      else
        for i = 1, #node do
          compile(node[i], node_handlers, result)
        end
      end
    end
  end

return compile
]],
  ['workshop.system.install_assert_functions'] = [=[
-- Function to spawn "assert_<type>" family of global functions

local data_types = request('!.lua.data_types')
local data_mathtypes = request('!.lua.data_mathtypes')

local generic_assert =
  function(type_name)
    -- assert_string(type_name)
    assert(type(type_name) == 'string')

    local checker_name = 'is_'.. type_name
    local checker = _G[checker_name]

    -- assert_function(checker)
    assert(type(checker) == 'function')

    return
      function(val)
        if not checker(val) then
          local err_msg =
            string.format('assert_%s(%s)', type_name, tostring(val))
          error(err_msg)
        end
      end
  end

return
  function()
    for _, type_name in ipairs(data_types) do
      local global_name = 'assert_' .. type_name
      _G[global_name] = generic_assert(type_name)
    end

    for _, number_type_name in ipairs(data_mathtypes) do
      local global_name = 'assert_' .. number_type_name
      _G[global_name] = generic_assert(number_type_name)
    end
  end

--[[
  2018-02
  2020-01
  2022-01
  2024-03
]]
]=],
  ['workshop.system.install_is_functions'] = [=[
-- Function to spawn "is_<type>" family of global functions.

--[[
  It spawns "is_nil", "is_boolean", ... for all Lua data types.
  Also it spawns "is_integer" and "is_float" for number type.
]]

--[[
  Design

    f(:any) -> bool

    Original design was

      f(:any) -> bool, (string or nil)

      Use case was "assert(is_number(x))" which will automatically
      provide error message when "x" is not a number.

      Today I prefer less fancy designs. Caller has enough information
      to build error message itself.
]]

-- Last mod.: 2024-03-02

local data_types = request('!.lua.data_types')
local data_mathtypes = request('!.lua.data_mathtypes')

local type_is =
  function(type_name)
    return
      function(val)
        return (type(val) == type_name)
      end
  end

local number_is =
  function(type_name)
    return
      function(val)
        --[[
          math.type() throws error for non-number types.
          This function returns "false" for non-number types.
        ]]
        if not is_number(val) then
          return false
        end
        return (math.type(val) == type_name)
      end
  end

return
  function()
    for _, type_name in ipairs(data_types) do
      _G['is_' .. type_name] = type_is(type_name)
    end
    for _, math_type_name in ipairs(data_mathtypes) do
      _G['is_' .. math_type_name] = number_is(math_type_name)
    end
  end

--[[
  2018-02
  2020-01
  2022-01
  2024-03 Changed design
]]
]=],
  ['workshop.table.as_string'] = [[
return request('!.concepts.lua_table.save')
]],
  ['workshop.table.clone'] = [=[
local cloned = {}

local clone
clone =
  function(node)
    if (type(node) == 'table') then
      if cloned[node] then
        return cloned[node]
      else
        local result = {}
        cloned[node] = result
        for k, v in pairs(node) do
          result[clone(k)] = clone(v)
        end
        setmetatable(result, getmetatable(node))
        return result
      end
    else
      return node
    end
  end

return
  function(node)
    cloned = {}
    return clone(node)
  end

--[[
* Metatables are shared, not cloned.

* This code optimized for performance.

  Main effect gave changing "is_table" to explicit type() check.
]]
]=],
  ['workshop.table.get_key_vals'] = [[
return
  function(t)
    assert_table(t)
    local result = {}
    for k, v in pairs(t) do
      result[#result + 1] = {key = k, value = v}
    end
    return result
  end
]],
  ['workshop.table.hard_patch'] = [=[
-- Shortcut to overwrite values in destination table according to patch

-- Last mod.: 2024-11-11

-- Imports:
local Patch = request('patch')

local HardPatch =
  function(Dest, PatchTable)
    return Patch(Dest, PatchTable, false)
  end

-- Exports:
return HardPatch

--[[
  2024-11-11
]]
]=],
  ['workshop.table.invert'] = [[
return
  function(t)
    assert_table(t)
    local result = {}
    for k, v in pairs(t) do
      result[v] = k
    end
    return result
  end
]],
  ['workshop.table.map_values'] = [=[
-- Map table values to keys

--[[
  Useful when you want to check presence and have list.

    { 'A', 'A', a = 'A', b = 'A'} ->
    { [1] = true, [2] = true, A = true }
]]

-- Last mod.: 2024-10-20

return
  function(t)
    assert_table(t)

    local Result = {}

    for k, v in pairs(t) do
      Result[v] = true
    end

    return Result
  end

--[[
  2016-09-06
  2024-10-20
]]
]=],
  ['workshop.table.merge'] = [=[
-- Merge one table onto another

--[[
  Union:
    ({ a = 'A'}, { b = 'B' }) -> { a = 'A', b = 'B' }

  Source values preserved:
    ({ a = 'A'}, { a = 'a' }) -> { a = 'A' }
]]

local MergeTable =
  function(Result, Additions)
    assert_table(Result)
    if (Additions == nil) then
      return Result
    end

    assert_table(Additions)
    for Addition_Key, Addition_Value in pairs(Additions) do
      if is_nil(Result[Addition_Key]) then
        Result[Addition_Key] = Addition_Value
      end
    end

    return Result
  end

-- Exports:
return MergeTable

--[[
  2016-06
  2016-09
  2017-09
  2019-12
  2024-08
]]
]=],
  ['workshop.table.merge_and_patch'] = [=[
-- Merge destination table. Override existing fields in source table

-- Last mod.: 2024-11-11

-- Imports:
local Merge = request('merge')
local HardPatch = request('hard_patch')

local MergeAndPatch =
  function(Dest, Source)
    Merge(Dest, Source)
    HardPatch(Dest, Source)
    return Dest
  end

-- Exports:
return MergeAndPatch

--[[
  2024-11-11
]]
]=],
  ['workshop.table.new'] = [=[
--[[
  Clone table <base_obj>. Optionally override fields in clone with
  fields from <overriden_params>.

  Returns cloned table.
]]

local clone = request('clone')
local patch = request('patch')

return
  function(base_obj, overriden_params)
    assert_table(base_obj)
    local result = clone(base_obj)
    if is_table(overriden_params) then
      patch(result, overriden_params)
    end
    return result
  end
]=],
  ['workshop.table.ordered_pass'] = [[
local default_comparator = request('ordered_pass.default_comparator')
local get_key_vals = request('get_key_vals')

-- Sort <t> and return iterator function to pass that sorted <t>
return
  function(t, comparator)
    assert_table(t)
    comparator = comparator or default_comparator
    assert_function(comparator)

    local key_vals = get_key_vals(t)
    table.sort(key_vals, comparator)

    local i = 0
    local sorted_next =
      function()
        i = i + 1
        if key_vals[i] then
          return key_vals[i].key, key_vals[i].value
        end
      end

    return sorted_next, t
  end
]],
  ['workshop.table.ordered_pass.default_comparator'] = [[
local val_rank =
  {
    string = 1,
    number = 2,
    other = 3,
  }

local comparable_types =
  {
    number = true,
    string = true,
  }

return
  function(a, b)
    local a_key = a.key
    local a_key_type = type(a_key)
    local rank_a = val_rank[a_key_type] or val_rank.other

    local b_key = b.key
    local b_key_type = type(b_key)
    local rank_b = val_rank[b_key_type] or val_rank.other

    if (rank_a ~= rank_b) then
      return (rank_a < rank_b)
    else
      if comparable_types[a_key_type] and comparable_types[b_key_type] then
        return (a_key < b_key)
      else
        return (tostring(a_key) < tostring(b_key))
      end
    end
  end
]],
  ['workshop.table.patch'] = [=[
-- Apply patch to table

-- Last mod.: 2024-11-11

--[[
  Basically it means that we're writing every entity from patch table to
  destination table.

  If no key in destination table, we'll explode.

  Additional third parameter means that we're not overwriting
  entity in destination table if it's value type is same as
  in patch's entity.

  That's useful when we want to force values to given types but
  keep values if they have correct type:

    ({ x = 42, y = '?' }, { x = 0, y = 0 }, false) -> { x = 0, y = 0 }
    ({ x = 42, y = '?' }, { x = 0, y = 0 }, true) -> { x = 42, y = 0 }

  Examples:

    Always overwriting values:

      ({ a = 'A' }, { a = '_A' }, false) -> { a = '_A' }

    Overwriting values if different types:

      ({ a = 'A' }, { a = '_A' }, true) -> { a = 'A' }
      ({ a = 0 }, { a = '_A' }, true) -> { a = '_A' }

    Nested values are supported:

      ({ b = { bb = 'BB' } }, { b = { bb = '_BB' } }, false) ->
      { b = { bb = '_BB' } }
]]

local Patch
Patch =
  function(MainTable, PatchTable, IfDifferentTypesOnly)
    assert_table(MainTable)
    assert_table(PatchTable)

    for PatchKey, PatchValue in pairs(PatchTable) do
      local MainValue = MainTable[PatchKey]

      -- Missing key in destination
      if is_nil(MainValue) then
        local ErrorMsg =
          string.format(
            [[Destination table doesn't have key "%s".]],
            tostring(PatchKey)
          )

        error(ErrorMsg, 2)
      end

      local DoPatch = true

      if IfDifferentTypesOnly then
        MainValueType = type(MainValue)
        PatchValueType = type(PatchValue)
        DoPatch = (MainValueType ~= PatchValueType)
      end

      if DoPatch then
        -- Recursive call when we're writing table to table
        if is_table(MainValue) and is_table(PatchValue) then
          Patch(MainValue, PatchValue)
        -- Else just overwrite value
        else
          MainTable[PatchKey] = PatchValue
        end
      end
    end
  end

-- Exports:
return Patch

--[[
  2016-09
  2024-02
  2024-11
]]
]=],
}

local AddModule =
  function(Name, Code)
    local CompiledCode = assert(load(Code, Name, 't'))

    _G.package.preload[Name] =
      function(...)
        return CompiledCode(...)
      end
  end

for ModuleName, ModuleCode in pairs(Modules) do
  AddModule(ModuleName, ModuleCode)
end

require('workshop.base')
