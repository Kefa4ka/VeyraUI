local HttpService = game:GetService('HttpService')
local Signal = require(script.Parent.Signal)
local Store = {}
Store.__index = Store
local function copy(value)
    if typeof(value) ~= 'table' then return value end
    local result = {}
    for k,v in pairs(value) do result[k] = copy(v) end
    return result
end
local function normalize(def,value)
    local kind = def.Kind
    if kind == 'Toggle' then assert(type(value) == 'boolean','expected boolean')
    elseif kind == 'Slider' then
        assert(type(value) == 'number' and value == value and math.abs(value) < math.huge,'expected finite number')
        local step = def.Step or 1
        value = math.clamp(def.Min + math.floor((value-def.Min)/step+0.5)*step,def.Min,def.Max)
    elseif kind == 'Dropdown' then assert(type(value) == 'string' and table.find(def.Items,value),'unknown option')
    elseif kind == 'MultiDropdown' then
        assert(type(value) == 'table','expected option array')
        local result = {}
        for _,item in ipairs(def.Items) do if table.find(value,item) then table.insert(result,item) end end
        for _,item in ipairs(value) do assert(table.find(def.Items,item),'unknown option') end
        value = result
    elseif kind == 'ColorPicker' then
        assert(type(value) == 'table' and typeof(value.Color) == 'Color3','expected {Color = Color3, Alpha = number}')
        assert(type(value.Alpha) == 'number' and value.Alpha == value.Alpha,'expected alpha')
        value = {Color = value.Color,Alpha = math.clamp(value.Alpha,0,1)}
    elseif kind == 'Keybind' then
        assert(type(value) == 'string' and (value == 'none' or value == 'MouseButton1' or value == 'MouseButton2' or value == 'MouseButton3' or pcall(function() assert(Enum.KeyCode[value]) end)),'unknown key')
    end
    return copy(value)
end
function Store.new() return setmetatable({values = {},definitions = {},Changed = Signal.new()},Store) end
function Store:Define(id,def)
    assert(type(id) == 'string' and #id > 0,'Control needs a unique Id')
    if self.definitions[id] then
        assert(self.definitions[id].Kind == def.Kind,'Setting kind mismatch: '..id)
        return
    end
    self.definitions[id] = def
    self.values[id] = normalize(def,def.Default)
end
function Store:Get(id) return copy(self.values[id]) end
function Store:Set(id,value)
    local def = assert(self.definitions[id],'Unknown setting: '..tostring(id))
    value = normalize(def,value)
    local old = self.values[id]
    if type(value) ~= 'table' and value == old then return end
    self.values[id] = value
    self.Changed:Fire(id,copy(value),copy(old))
end
function Store:Snapshot() return copy(self.values) end
function Store:Export()
    local values = self:Snapshot()
    for id,def in pairs(self.definitions) do
        if def.Kind == 'ColorPicker' then
            local color = values[id].Color
            values[id] = {R = color.R,G = color.G,B = color.B,Alpha = values[id].Alpha}
        end
    end
    return HttpService:JSONEncode({Version = 1,Values = values})
end
function Store:Import(json)
    local data = HttpService:JSONDecode(json)
    assert(type(data) == 'table' and data.Version == 1 and type(data.Values) == 'table','Invalid VeyraUI config')
    local pending = {}
    for id,value in pairs(data.Values) do
        local def = self.definitions[id]
        if def then
            if def.Kind == 'ColorPicker' then
                assert(type(value) == 'table','Invalid color')
                for _,channel in ipairs({'R','G','B'}) do
                    local n = value[channel]
                    assert(type(n) == 'number' and n == n and n >= 0 and n <= 1,'Invalid color channel')
                end
                value = {Color = Color3.new(value.R,value.G,value.B),Alpha = value.Alpha}
            end
            pending[id] = normalize(def,value)
        end
    end
    local old = self:Snapshot()
    for id,value in pairs(pending) do self.values[id] = value end
    for id,value in pairs(pending) do self.Changed:Fire(id,copy(value),old[id]) end
end
function Store:Destroy() self.Changed:Destroy() end
return Store

