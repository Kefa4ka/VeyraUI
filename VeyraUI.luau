-- Generated from src/ by build.py. Edit source modules, then rebuild.
-- This bundle contains library code only. No network requests or game-specific actions.
local factories, nodes, cache, loading = {}, {}, {}, {}
local function node(path)
    if nodes[path] then return nodes[path] end
    local value = {Path = path}
    nodes[path] = value
    return setmetatable(value,{__index = function(_,key)
        if key == 'Parent' then return node(path:match('^(.*)/[^/]+$') or '') end
        return node(path == '' and key or path..'/'..key)
    end})
end
factories["components/Button"] = function(script, require)
local C = require(script.Parent.Common)
return function(section,o)
    local h = C.row(section,o,25,'Button')
    local button,label = C.field(h.Frame,0,h.Window.Theme,o.Text or 'button')
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextColor3 = h.Window.Theme.Text
    h.Window.Scope:Add(button.Activated:Connect(function()
        if o.Callback then o.Callback(h.Window) end
        h.Window.Action:Fire(o.Action or o.Text,h.Window)
    end))
    return h
end

end

factories["components/ColorPicker"] = function(script, require)
local F = require(script.Parent.Parent.core.Factory)
local Input = require(script.Parent.Parent.core.Input)
local C = require(script.Parent.Common)
local Picker = {}
function Picker.Attach(handle,id,default,standalone)
    local w,t = handle.Window,handle.Window.Theme
    w.Store:Define(id,{Kind = 'ColorPicker',Default = default})
    local colorHandle = {Options = {Id = id},Frame = handle.Frame,Window = w}
    function colorHandle:Get() return w.Store:Get(id) end
    function colorHandle:Set(value) w.Store:Set(id,value) end
    function colorHandle:OnChanged(callback)
        return w.Scope:Add(w.Store.Changed:Connect(function(key,value) if key == id then callback(value) end end))
    end
    w.Controls[id] = colorHandle
    local swatch = F.button(handle.Frame,'ColorSwatch',standalone and 20 or 151,1,standalone and 150 or 20,8,t)
    swatch.ZIndex = 8
    swatch.BackgroundTransparency = 0
    F.stroke(swatch,t.Black)
    local function paint(value) swatch.BackgroundColor3 = value.Color; swatch.BackgroundTransparency = 1-value.Alpha end
    paint(colorHandle:Get()); colorHandle:OnChanged(paint)
    w.Scope:Add(swatch.Activated:Connect(function()
        if w.PopupOwner == colorHandle then w:ClosePopup(); return end
        local popup,scope = w:OpenPopup(colorHandle,swatch,198,228)
        local initial = colorHandle:Get()
        local hue,sat,val = initial.Color:ToHSV()
        local alpha = initial.Alpha
        local square = F.frame(popup,'SaturationValue',8,8,162,150,Color3.fromHSV(hue,1,1),102)
        local white = F.frame(square,'White',0,0,162,150,Color3.new(1,1,1),103)
        F.new('UIGradient',{Transparency = NumberSequence.new(0,1)},white)
        local black = F.frame(square,'Black',0,0,162,150,t.Black,104)
        F.new('UIGradient',{Transparency = NumberSequence.new(1,0),Rotation = 90},black)
        local marker = F.frame(square,'Cursor',0,0,5,5,Color3.new(1,1,1),106)
        F.stroke(marker,t.Black)
        local svInput = F.button(square,'SVInput',0,0,162,150,t)
        svInput.ZIndex = 105
        local hueBar = F.frame(popup,'Hue',178,8,12,150,Color3.new(1,1,1),102)
        local colors = {}
        for i = 0,6 do table.insert(colors,ColorSequenceKeypoint.new(i/6,Color3.fromHSV(i/6,1,1))) end
        F.new('UIGradient',{Color = ColorSequence.new(colors),Rotation = 90},hueBar)
        local hueInput = F.button(hueBar,'HueInput',0,0,12,150,t)
        local hueMarker = F.frame(hueBar,'Cursor',-2,0,16,2,t.Text,106)
        local alphaBar = F.frame(popup,'Alpha',8,170,182,10,initial.Color,102)
        -- Checkerboard under the alpha ramp.
        for i = 0,25 do
            local tile = F.frame(alphaBar,'Checker',i*7,0,7,10,i%2 == 0 and t.Track or t.Off,102)
            tile.Size = UDim2.fromOffset(math.min(7,182-i*7),10)
        end
        local alphaRamp = F.frame(alphaBar,'Ramp',0,0,182,10,initial.Color,103)
        F.new('UIGradient',{Transparency = NumberSequence.new(1,0)},alphaRamp)
        local alphaMarker = F.frame(alphaBar,'Cursor',0,-2,2,14,t.Text,106)
        local alphaInput = F.button(alphaBar,'AlphaInput',0,-3,182,16,t)
        alphaInput.ZIndex = 105
        local hex = F.new('TextBox',{Name = 'Hex',Position = UDim2.fromOffset(8,190),Size = UDim2.fromOffset(108,22),
            BackgroundColor3 = t.Control,BorderSizePixel = 0,Font = t.Font,TextSize = 11,TextColor3 = t.Text,
            ClearTextOnFocus = false,Text = '',ZIndex = 104},popup)
        F.stroke(hex,t.Black)
        local alphaText = F.text(popup,'',122,190,70,22,t,104)
        local function render()
            local color = Color3.fromHSV(hue,sat,val)
            square.BackgroundColor3 = Color3.fromHSV(hue,1,1)
            marker.Position = UDim2.fromOffset(sat*158,(1-val)*146)
            hueMarker.Position = UDim2.fromOffset(-2,hue*148)
            alphaMarker.Position = UDim2.fromOffset(alpha*180,-2)
            alphaRamp.BackgroundColor3 = color
            hex.Text = '#'..color:ToHex():upper()
            alphaText.Text = 'alpha '..math.round(alpha*100)..'%'
        end
        local function commit() render(); colorHandle:Set({Color = Color3.fromHSV(hue,sat,val),Alpha = alpha}) end
        Input.drag(svInput,scope,function(p)
            sat = math.clamp((p.X-square.AbsolutePosition.X)/square.AbsoluteSize.X,0,1)
            val = 1-math.clamp((p.Y-square.AbsolutePosition.Y)/square.AbsoluteSize.Y,0,1)
            commit()
        end)
        Input.drag(hueInput,scope,function(p)
            hue = math.clamp((p.Y-hueBar.AbsolutePosition.Y)/hueBar.AbsoluteSize.Y,0,1); commit()
        end)
        Input.drag(alphaInput,scope,function(p)
            alpha = math.clamp((p.X-alphaBar.AbsolutePosition.X)/alphaBar.AbsoluteSize.X,0,1); commit()
        end)
        scope:Add(hex.FocusLost:Connect(function()
            local digits = hex.Text:gsub('#','')
            if #digits == 6 and digits:match('^%x+$') then hue,sat,val = Color3.fromHex(digits):ToHSV(); commit()
            else render() end
        end))
        scope:Add(w.Store.Changed:Connect(function(key,value)
            if key == id then hue,sat,val = value.Color:ToHSV(); alpha = value.Alpha; render() end
        end))
        render()
    end))
    return colorHandle
end
function Picker.new(section,o)
    o.Default = o.Default or {Color = Color3.new(1,1,1),Alpha = 1}
    local h = C.row(section,o,30,'ColorPicker')
    F.text(h.Frame,o.Text or 'color',20,-3,170,15,h.Window.Theme)
    local child = F.frame(h.Frame,'SwatchRow',0,15,191,15,h.Window.Theme.Group)
    child.BackgroundTransparency = 1
    Picker.Attach({Frame = child,Window = h.Window},o.Id,o.Default,true)
    return h
end
return Picker

end

factories["components/Common"] = function(script, require)
local F = require(script.Parent.Parent.core.Factory)
local Common = {}
function Common.row(section,o,height,kind)
    local window = section.Window
    local row = F.frame(section.Frame,o.Id or o.Text or kind,10,0,191,height,window.Theme.Group)
    row.BackgroundTransparency = 1
    local handle = {Frame = row,Height = height,Options = o,Window = window,Section = section,Visible = true}
    if o.Id then
        o.Kind = kind
        window.Store:Define(o.Id,o)
        window.Controls[o.Id] = handle
    end
    function handle:Get() return window.Store:Get(o.Id) end
    function handle:Set(value) window.Store:Set(o.Id,value) end
    function handle:OnChanged(callback)
        return window.Scope:Add(window.Store.Changed:Connect(function(id,value)
            if id == o.Id then callback(value) end
        end))
    end
    function handle:SetVisible(visible) self.Visible = visible; section:Reflow() end
    function handle:Watch(render)
        render(self:Get())
        return self:OnChanged(render)
    end
    if o.Id and o.Callback then handle:OnChanged(o.Callback) end
    table.insert(section.Rows,handle)
    return handle
end
function Common.field(row,y,theme,text)
    local button = F.button(row,'Field',20,y,150,20,theme)
    button.BackgroundTransparency = 0
    button.BackgroundColor3 = theme.Control
    F.stroke(button,theme.Black)
    F.gradient(button,Color3.new(1,1,1),Color3.fromRGB(190,190,190))
    local label = F.text(button,text or '',10,0,128,20,theme,button.ZIndex+1)
    label.TextColor3 = theme.Muted
    label.TextTruncate = Enum.TextTruncate.AtEnd
    return button,label
end
return Common

end

factories["components/Dropdown"] = function(script, require)
local F = require(script.Parent.Parent.core.Factory)
local C = require(script.Parent.Common)
return function(section,o)
    assert(type(o.Items) == 'table' and #o.Items > 0,'Dropdown needs Items')
    local multi = o.Multi == true
    if o.Default == nil then o.Default = multi and {} or o.Items[1] end
    local labeled = o.Text and #o.Text > 0
    local h = C.row(section,o,labeled and 40 or 25,multi and 'MultiDropdown' or 'Dropdown')
    local w,t = h.Window,h.Window.Theme
    if labeled then F.text(h.Frame,o.Text,20,-3,160,15,t) end
    local field,label = C.field(h.Frame,labeled and 15 or 0,t)
    F.text(field,'▾',137,0,12,20,t,field.ZIndex+1)
    h:Watch(function(value) label.Text = multi and (#value == 0 and 'off' or table.concat(value,', ')) or value end)
    w.Scope:Add(field.Activated:Connect(function()
        if w.PopupOwner == h then w:ClosePopup(); return end
        local popup,scope = w:OpenPopup(h,field,150,math.min(220,#o.Items*18+8))
        local list = F.new('ScrollingFrame',{Name = 'Options',Size = UDim2.fromScale(1,1),BackgroundTransparency = 1,
            BorderSizePixel = 0,ScrollBarThickness = 3,CanvasSize = UDim2.fromOffset(0,#o.Items*18+8),ZIndex = 102},popup)
        local labels = {}
        local function paint()
            local value = h:Get()
            for i,option in ipairs(o.Items) do
                local selected = multi and table.find(value,option) ~= nil or (not multi and value == option)
                labels[i].TextColor3 = selected and w.Accent or t.Muted
            end
        end
        for i,option in ipairs(o.Items) do
            local button = F.button(list,'Option'..i,4,4+(i-1)*18,140,18,t)
            labels[i] = F.text(button,option,6,0,132,18,t,104)
            scope:Add(button.Activated:Connect(function()
                if multi then
                    local values = h:Get()
                    local index = table.find(values,option)
                    if index then table.remove(values,index) else table.insert(values,option) end
                    h:Set(values); paint()
                else h:Set(option); w:ClosePopup() end
            end))
        end
        scope:Add(w.Store.Changed:Connect(function(id) if id == o.Id then paint() end end))
        scope:Add(w.AccentChanged:Connect(paint))
        paint()
    end))
    return h
end

end

factories["components/Keybind"] = function(script, require)
local UIS = game:GetService('UserInputService')
local F = require(script.Parent.Parent.core.Factory)
local C = require(script.Parent.Common)
return function(section,o)
    o.Default = o.Default or 'none'
    local h = C.row(section,o,40,'Keybind')
    local w,t = h.Window,h.Window.Theme
    F.text(h.Frame,o.Text or 'key',20,-3,160,15,t)
    local button,label = C.field(h.Frame,15,t)
    h:Watch(function(value) label.Text = value end)
    w.Scope:Add(button.Activated:Connect(function()
        if w.CaptureCancel then w.CaptureCancel() end
        label.Text = '...'
        w.Capture = h
        w.CaptureCancel = function() label.Text = h:Get(); w.Capture = nil; w.CaptureCancel = nil end
    end))
    local function matches(input)
        local value = h:Get()
        return value ~= 'none' and (input.KeyCode.Name == value or input.UserInputType.Name == value)
    end
    if o.OnPressed then
        w.Scope:Add(UIS.InputBegan:Connect(function(input,processed)
            if not processed and not w.Capture and input ~= w.LastCapturedInput and not UIS:GetFocusedTextBox() and matches(input) then o.OnPressed(input) end
        end))
    end
    if o.OnReleased then w.Scope:Add(UIS.InputEnded:Connect(function(input) if matches(input) then o.OnReleased(input) end end)) end
    return h
end

end

factories["components/Label"] = function(script, require)
local F = require(script.Parent.Parent.core.Factory)
local C = require(script.Parent.Common)
return function(section,o)
    local h = C.row(section,o,15,'Label')
    local label = F.text(h.Frame,o.Text or '',20,-3,170,15,h.Window.Theme)
    function h:SetText(text) label.Text = text end
    return h
end

end

factories["components/Slider"] = function(script, require)
local F = require(script.Parent.Parent.core.Factory)
local Input = require(script.Parent.Parent.core.Input)
local C = require(script.Parent.Common)
return function(section,o)
    assert(type(o.Min) == 'number' and type(o.Max) == 'number' and o.Max > o.Min,'Slider needs Min < Max')
    assert((o.Step or 1) > 0,'Step must be positive')
    if o.Default == nil then o.Default = o.Min end
    local labeled = o.Text and #o.Text > 0
    local h = C.row(section,o,labeled and 30 or 15,'Slider')
    local w,t = h.Window,h.Window.Theme
    local y = labeled and 15 or 0
    if labeled then F.text(h.Frame,o.Text,20,-3,160,15,t) end
    local track = F.frame(h.Frame,'Track',20,y,150,6,t.Track)
    F.stroke(track,t.Black)
    F.gradient(track,Color3.new(1,1,1),Color3.fromRGB(170,170,170))
    local fill = F.frame(track,'Fill',0,0,0,6,w.Accent)
    local valueLabel = F.text(h.Frame,'',21,y-2,150,13,t,track.ZIndex+2)
    valueLabel.TextColor3 = Color3.new(1,1,1)
    local hit = F.button(h.Frame,'TrackInput',19,y-4,152,15,t)
    local minus = F.button(h.Frame,'Minus',0,y-5,16,16,t,'-')
    local plus = F.button(h.Frame,'Plus',176,y-5,15,16,t,'+')
    local function update(p)
        local ratio = math.clamp((p.X-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
        h:Set(o.Min+(o.Max-o.Min)*ratio)
    end
    Input.drag(hit,w.Scope,update)
    w.Scope:Add(minus.Activated:Connect(function() h:Set(h:Get()-(o.Step or 1)) end))
    w.Scope:Add(plus.Activated:Connect(function() h:Set(h:Get()+(o.Step or 1)) end))
    h:Watch(function(value)
        local ratio = (value-o.Min)/(o.Max-o.Min)
        fill.Size = UDim2.fromScale(ratio,1)
        valueLabel.Text = tostring(math.round(value*1000)/1000)..(o.Suffix or '')
        valueLabel.Position = UDim2.fromOffset(21+math.min(115,ratio*138),y-2)
        valueLabel.Size = UDim2.fromOffset(155-math.min(115,ratio*138),13)
    end)
    w.Scope:Add(w.AccentChanged:Connect(function(color) fill.BackgroundColor3 = color end))
    return h
end

end

factories["components/Toggle"] = function(script, require)
local F = require(script.Parent.Parent.core.Factory)
local C = require(script.Parent.Common)
local ColorPicker = require(script.Parent.ColorPicker)
return function(section,o)
    if o.Default == nil then o.Default = false end
    local h = C.row(section,o,15,'Toggle')
    local t,w = h.Window.Theme,h.Window
    local click = F.button(h.Frame,'Toggle',0,-3,185,15,t)
    local box = F.frame(click,'Box',0,4,8,8,t.Black)
    local fill = F.frame(box,'Fill',1,1,6,6,t.Off)
    local gradient = F.gradient(fill,Color3.new(1,1,1),Color3.fromRGB(210,210,210))
    F.text(click,o.Text or o.Id,20,0,165,15,t)
    w.Scope:Add(click.Activated:Connect(function() h:Set(not h:Get()) end))
    h:Watch(function(value) fill.BackgroundColor3 = value and w.Accent or t.Off; gradient.Enabled = value end)
    w.Scope:Add(w.AccentChanged:Connect(function(color) if h:Get() then fill.BackgroundColor3 = color end end))
    if o.ColorId then
        ColorPicker.Attach(h,o.ColorId,{Color = Color3.new(1,1,1),Alpha = 1})
    end
    return h
end

end

factories["core/Factory"] = function(script, require)
local F = {}
function F.new(class, props, parent)
    local object = Instance.new(class)
    for key, value in pairs(props or {}) do object[key] = value end
    object.Parent = parent
    return object
end
function F.frame(parent, name, x, y, w, h, color, z)
    return F.new('Frame', {Name = name, Position = UDim2.fromOffset(x,y), Size = UDim2.fromOffset(w,h),
        BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z or (parent:IsA('GuiObject') and parent.ZIndex or 1)}, parent)
end
function F.text(parent, text, x, y, w, h, theme, z)
    return F.new('TextLabel', {Name = 'Label', Text = text, Position = UDim2.fromOffset(x,y),
        Size = UDim2.fromOffset(w,h), BackgroundTransparency = 1, BorderSizePixel = 0,
        Font = theme.Font, TextSize = theme.TextSize, TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = z or (parent:IsA('GuiObject') and parent.ZIndex or 1)}, parent)
end
function F.button(parent, name, x, y, w, h, theme, text)
    return F.new('TextButton', {Name = name, Position = UDim2.fromOffset(x,y), Size = UDim2.fromOffset(w,h),
        BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = text or '',
        Font = theme.Font, TextSize = theme.TextSize, TextColor3 = theme.Text, ZIndex = (parent:IsA('GuiObject') and parent.ZIndex or 1) + 1}, parent)
end
function F.stroke(parent, color)
    return F.new('UIStroke', {Color = color, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, parent)
end
function F.gradient(parent, top, bottom)
    return F.new('UIGradient', {Color = ColorSequence.new(top,bottom), Rotation = 90}, parent)
end
function F.chrome(parent, name, size, theme)
    local root = F.frame(parent,name,0,0,size.X,size.Y,theme.Black,2)
    local a = F.frame(root,'OuterLine',1,1,size.X-2,size.Y-2,theme.Outer)
    local b = F.frame(a,'Between',1,1,size.X-4,size.Y-4,theme.Between)
    local c = F.frame(b,'InnerLine',3,3,size.X-10,size.Y-10,theme.Outer)
    F.frame(c,'Face',1,1,size.X-12,size.Y-12,theme.Face)
    return root
end
return F

end

factories["core/Input"] = function(script, require)
local UIS = game:GetService('UserInputService')
local Input = {}
function Input.point(input) return Vector2.new(input.Position.X,input.Position.Y) end
function Input.primary(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end
function Input.drag(target,scope,changed,began,ended)
    local active, origin
    scope:Add(target.InputBegan:Connect(function(input)
        if not Input.primary(input) then return end
        active,origin = input,Input.point(input)
        if began then began(origin,input) end
        changed(origin,Vector2.zero,input)
    end))
    scope:Add(UIS.InputChanged:Connect(function(input)
        if not active then return end
        if (active.UserInputType == Enum.UserInputType.Touch and input == active)
            or (active.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
            local p = Input.point(input)
            changed(p,p-origin,active)
        end
    end))
    scope:Add(UIS.InputEnded:Connect(function(input)
        if input == active then active = nil; if ended then ended() end end
    end))
end
function Input.move(handle,target,window,scope)
    local start
    Input.drag(handle,scope,function(_,delta)
        local scale = window.Scale
        local size = window.Screen.AbsoluteSize / scale
        local pos = start + delta / scale
        target.Position = UDim2.fromOffset(math.clamp(pos.X,0,math.max(0,size.X-target.Size.X.Offset)),
            math.clamp(pos.Y,0,math.max(0,size.Y-target.Size.Y.Offset)))
        window:ClosePopup()
    end,function() start = Vector2.new(target.Position.X.Offset,target.Position.Y.Offset) end)
end
return Input

end

factories["core/Janitor"] = function(script, require)
local Janitor = {}
Janitor.__index = Janitor
function Janitor.new() return setmetatable({items = {}, dead = false}, Janitor) end
function Janitor:Add(item)
    if self.dead then
        if typeof(item) == 'RBXScriptConnection' then item:Disconnect()
        elseif type(item) == 'function' then item() else item:Destroy() end
    else table.insert(self.items, item) end
    return item
end
function Janitor:Destroy()
    if self.dead then return end
    self.dead = true
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        local ok, err = pcall(function()
            if typeof(item) == 'RBXScriptConnection' then item:Disconnect()
            elseif type(item) == 'function' then item() else item:Destroy() end
        end)
        if not ok then warn('VeyraUI cleanup: ' .. tostring(err)) end
    end
    table.clear(self.items)
end
return Janitor

end

factories["core/Signal"] = function(script, require)
local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({listeners = {}, dead = false}, Signal) end
function Signal:Connect(callback)
    assert(not self.dead, 'Signal is destroyed')
    local connection = {Connected = true}
    self.listeners[connection] = callback
    local owner = self
    function connection:Disconnect()
        self.Connected = false
        owner.listeners[self] = nil
    end
    connection.Destroy = connection.Disconnect
    return connection
end
function Signal:Fire(...)
    local pending = {}
    for connection, callback in pairs(self.listeners) do table.insert(pending, {connection, callback}) end
    for _, entry in ipairs(pending) do
        if entry[1].Connected then
            local ok, err = pcall(entry[2], ...)
            if not ok then warn('VeyraUI callback: ' .. tostring(err)) end
        end
    end
end
function Signal:Destroy()
    self.dead = true
    for connection in pairs(self.listeners) do connection.Connected = false end
    table.clear(self.listeners)
end
return Signal

end

factories["core/Store"] = function(script, require)
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


end

factories["core/Theme"] = function(script, require)
return {
    Accent = Color3.fromRGB(181, 0, 41), AccentShade = Color3.fromRGB(156, 0, 16),
    Face = Color3.fromRGB(16, 16, 16), Group = Color3.fromRGB(14, 14, 14),
    Outer = Color3.fromRGB(57, 57, 57), Between = Color3.fromRGB(35, 35, 35),
    Border = Color3.fromRGB(38, 38, 38), Black = Color3.new(0, 0, 0),
    Text = Color3.fromRGB(206, 206, 206), Muted = Color3.fromRGB(153, 153, 153),
    Control = Color3.fromRGB(29, 29, 29), Track = Color3.fromRGB(60, 60, 60),
    Off = Color3.fromRGB(69, 69, 69), Font = Enum.Font.Arial, TextSize = 11,
    WindowSize = Vector2.new(522, 560), PreviewSize = Vector2.new(280, 360),
}

end

factories[""] = function(script, require)
local Window = require(script.layout.Window)
local Preview = require(script.preview.Preview)
local MeshAsset = require(script.preview.MeshAsset)
local Janitor = require(script.core.Janitor)
local Library = {Version = '1.0.0'}
function Library.new(options) return Window.new(options) end
Library.CreateWindow = Library.new
function Library.LocalMesh(path) return MeshAsset.FromFile(path) end
function Library.NewScope() return Janitor.new() end
function Window:CreatePreview(options)
    if self.Preview then self.Preview:Destroy() end
    self.Preview = Preview.new(self,options)
    self:Fit()
    return self.Preview
end
return Library

end

factories["layout/Section"] = function(script, require)
local F = require(script.Parent.Parent.core.Factory)
local Components = {
    Toggle = require(script.Parent.Parent.components.Toggle),
    Slider = require(script.Parent.Parent.components.Slider),
    Dropdown = require(script.Parent.Parent.components.Dropdown),
    Keybind = require(script.Parent.Parent.components.Keybind),
    ColorPicker = require(script.Parent.Parent.components.ColorPicker).new,
    Button = require(script.Parent.Parent.components.Button),
    Label = require(script.Parent.Parent.components.Label),
}
local Section = {}
Section.__index = Section
function Section.new(tab,title,column)
    local t = tab.Window.Theme
    local self = setmetatable({Window = tab.Window,Tab = tab,Rows = {},Column = column,Height = 30},Section)
    self.Frame = F.frame(tab.Page,title,0,0,211,30,t.Group)
    F.stroke(self.Frame,t.Black)
    local border = F.frame(self.Frame,'InsetBorder',1,1,209,28,t.Group)
    border.BackgroundTransparency = 1
    border.Size = UDim2.new(1,-2,1,-2)
    F.stroke(border,t.Border)
    local label = F.text(self.Frame,title,10,-7,math.max(20,#title*5.5+5),14,t,4)
    label.BackgroundTransparency = 0
    label.BackgroundColor3 = t.Group
    self.Window.Scope:Add(self.Window.Store.Changed:Connect(function() self:Reflow() end))
    return self
end
function Section:Reflow()
    local y = 15
    for _,row in ipairs(self.Rows) do
        local visible = row.Visible
        if row.Options.VisibleWhen then visible = visible and row.Options.VisibleWhen(self.Window.Store) end
        row.Frame.Visible = visible
        if visible then row.Frame.Position = UDim2.fromOffset(10,y); y = y+row.Height end
    end
    self.Height = y+5
    self.Frame.Size = UDim2.fromOffset(211,self.Height)
    self.Tab:Reflow()
end
function Section:Add(kind,options)
    local constructor = assert(Components[kind],'Unknown control: '..tostring(kind))
    local handle = constructor(self,options)
    self:Reflow()
    return handle
end
for kind in pairs(Components) do
    Section[kind] = function(self,options) return self:Add(kind,options) end
end
function Section:MultiDropdown(options) options.Multi = true; return self:Add('Dropdown',options) end
return Section

end

factories["layout/Tab"] = function(script, require)
local F = require(script.Parent.Parent.core.Factory)
local Section = require(script.Parent.Section)
local Tab = {}
Tab.__index = Tab
function Tab.new(window,title)
    local page = F.new('ScrollingFrame',{Name = title,Position = UDim2.fromOffset(23,52),Size = UDim2.fromOffset(476,489),
        BackgroundTransparency = 1,BorderSizePixel = 0,ScrollBarThickness = 3,ScrollBarImageColor3 = window.Theme.Track,
        CanvasSize = UDim2.fromOffset(0,0),ScrollingDirection = Enum.ScrollingDirection.Y,Visible = false,ZIndex = 3},window.Main)
    return setmetatable({Window = window,Title = title,Page = page,Sections = {}},Tab)
end
function Tab:Section(title,column)
    local section = Section.new(self,title,column or 1)
    table.insert(self.Sections,section)
    self:Reflow()
    return section
end
function Tab:Reflow()
    local heights = {10,10}
    for _,section in ipairs(self.Sections) do
        local c = section.Column
        section.Frame.Position = UDim2.fromOffset(c == 2 and 249 or 19,heights[c])
        heights[c] = heights[c]+section.Height+15
    end
    self.Page.CanvasSize = UDim2.fromOffset(0,math.max(heights[1],heights[2]))
end
return Tab

end

factories["layout/Window"] = function(script, require)
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local F = require(script.Parent.Parent.core.Factory)
local Theme = require(script.Parent.Parent.core.Theme)
local Janitor = require(script.Parent.Parent.core.Janitor)
local Signal = require(script.Parent.Parent.core.Signal)
local Store = require(script.Parent.Parent.core.Store)
local Input = require(script.Parent.Parent.core.Input)
local Tab = require(script.Parent.Tab)
local Window = {}
Window.__index = Window
local function defaultParent()
    if type(gethui) == 'function' then
        local ok,parent = pcall(gethui)
        if ok and typeof(parent) == 'Instance' then return parent end
    end
    local core = game:GetService('CoreGui')
    local probe = Instance.new('Folder')
    local ok = pcall(function() probe.Parent = core end)
    probe:Destroy()
    if ok then return core end
    return Players.LocalPlayer:WaitForChild('PlayerGui')
end
function Window.new(options)
    options = options or {}
    local self = setmetatable({Scope = Janitor.new(),Store = Store.new(),Controls = {},Tabs = {},
        Theme = table.clone(Theme),AccentChanged = Signal.new(),Action = Signal.new(),
        Visible = true,Destroyed = false,Scale = 1,Options = options},Window)
    for key,value in pairs(options.Theme or {}) do self.Theme[key] = value end
    self.Accent = options.Accent or self.Theme.Accent
    self.Scope:Add(self.Store); self.Scope:Add(self.AccentChanged); self.Scope:Add(self.Action)
    self.Screen = F.new('ScreenGui',{Name = options.Name or 'VeyraUI',ResetOnSpawn = false,
        ScreenInsets = Enum.ScreenInsets.None,DisplayOrder = options.DisplayOrder or 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Global},nil)
    self.Scope:Add(self.Screen)
    self.Root = F.new('CanvasGroup',{Name = 'Desktop',Size = UDim2.fromScale(1,1),BackgroundTransparency = 1,
        BorderSizePixel = 0,ZIndex = 1},self.Screen)
    self.UIScale = F.new('UIScale',{Scale = 1},self.Root)
    self.Main = F.chrome(self.Root,'Menu',self.Theme.WindowSize,self.Theme)
    self.Main.Position = UDim2.fromOffset(30,50)
    local header = F.button(self.Main,'DragTitle',6,6,510,16,self.Theme)
    local brand = F.text(header,options.Title or 'veyra',0,-5,510,20,self.Theme,6)
    brand.TextXAlignment = Enum.TextXAlignment.Center
    brand.TextColor3 = self.Accent
    brand.TextStrokeTransparency = 0
    Input.move(header,self.Main,self,self.Scope)
    local panel = F.frame(self.Main,'ContentBorder',20,44,482,500,self.Theme.Black)
    local inner = F.frame(panel,'Inset',1,1,480,498,self.Theme.Border)
    F.frame(inner,'ContentFace',1,1,478,496,self.Theme.Face)
    self.TabBar = F.frame(self.Main,'Tabs',17,20,488,20,self.Theme.Face,5)
    self.TabBar.BackgroundTransparency = 1
    local opener = F.button(self.Screen,'MenuToggle',8,8,62,24,self.Theme,'menu')
    opener.BackgroundTransparency = 0.1; opener.BackgroundColor3 = self.Theme.Face; opener.ZIndex = 200
    F.stroke(opener,self.Theme.Outer)
    self.Scope:Add(opener.Activated:Connect(function() self:SetVisible(not self.Visible) end))
    self.Scope:Add(UIS.InputBegan:Connect(function(input,processed)
        if self.Capture then
            local h = self.Capture
            local key
            if input.KeyCode == Enum.KeyCode.Escape then key = 'none'
            elseif input.UserInputType == Enum.UserInputType.Keyboard then key = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then key = input.UserInputType.Name end
            if key then self.LastCapturedInput = input; self.CaptureCancel(); h:Set(key) end
            return
        end
        if input.KeyCode == Enum.KeyCode.Escape and self.Popup then self:ClosePopup(); return end
        if not processed and not UIS:GetFocusedTextBox() and input.KeyCode == (options.ToggleKey or Enum.KeyCode.Insert) then
            self:SetVisible(not self.Visible)
        end
    end))
    local function fit()
        self:ClosePopup()
        local size = self.Screen.AbsoluteSize
        if size.X <= 0 or size.Y <= 0 then return end
        self.Scale = math.max(0.2,math.min(options.Scale or 1,(size.X-40)/842,(size.Y-70)/560))
        self.UIScale.Scale = self.Scale
        self.Root.Size = UDim2.fromOffset(size.X/self.Scale,size.Y/self.Scale)
        for _,frame in ipairs({self.Main,self.Preview and self.Preview.Frame}) do
            if frame then
                frame.Position = UDim2.fromOffset(math.clamp(frame.Position.X.Offset,0,math.max(0,size.X/self.Scale-frame.Size.X.Offset)),
                    math.clamp(frame.Position.Y.Offset,0,math.max(0,size.Y/self.Scale-frame.Size.Y.Offset)))
            end
        end
    end
    self.Scope:Add(self.Screen:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit))
    self.Scope:Add(self.AccentChanged:Connect(function(color)
        brand.TextColor3 = color
        self:UpdateTabs()
    end))
    self.Scope:Add(self.Store.Changed:Connect(function(id,value)
        if id == 'accent' and not self.Store:Get('rainbow') then self:SetAccent(value.Color) end
        if id == 'rainbow' and not value then
            local accent = self.Store:Get('accent'); self:SetAccent(accent and accent.Color or self.Theme.Accent)
        end
    end))
    local tick = 0
    self.Scope:Add(RunService.RenderStepped:Connect(function(dt)
        tick = tick+dt
        if self.Visible and self.Store:Get('rainbow') and tick > 1/30 then
            tick = 0; self:SetAccent(Color3.fromHSV((os.clock()*0.1)%1,1,0.85))
        end
    end))
    self.Fit = fit
    self.Screen.Parent = options.Parent or defaultParent()
    fit()
    self.Scope:Add(function() self:ClosePopup(); if self.Fade then self.Fade:Cancel() end end)
    return self
end
function Window:SetAccent(color)
    if self.Accent == color then return end
    self.Accent = color; self.AccentChanged:Fire(color)
end
function Window:UpdateTabs()
    local count = #self.Tabs
    if count == 0 then return end
    local width = 488/count
    for index,tab in ipairs(self.Tabs) do
        tab.Button.Position = UDim2.fromOffset((index-1)*width,0)
        tab.Button.Size = UDim2.fromOffset(width-4,20)
        tab.Line.Size = UDim2.new(1,0,0,self.SelectedTab == tab and 3 or 2)
        tab.Line.BackgroundColor3 = self.SelectedTab == tab and self.Accent or Color3.fromRGB(90,90,94)
    end
end
function Window:Tab(title)
    local tab = Tab.new(self,title)
    tab.Button = F.button(self.TabBar,title,0,0,70,20,self.Theme,title)
    tab.Button.TextTruncate = Enum.TextTruncate.AtEnd
    tab.Line = F.frame(tab.Button,'Underline',0,18,70,2,self.Theme.Off,6)
    F.gradient(tab.Line,Color3.new(1,1,1),Color3.fromRGB(160,160,160))
    table.insert(self.Tabs,tab)
    self.Scope:Add(tab.Button.Activated:Connect(function() self:SelectTab(tab) end))
    if not self.SelectedTab then self:SelectTab(tab) end
    self:UpdateTabs()
    return tab
end
function Window:SelectTab(tab)
    if type(tab) == 'string' then
        local name = tab; tab = nil
        for _,candidate in ipairs(self.Tabs) do if candidate.Title == name then tab = candidate; break end end
    end
    assert(tab and table.find(self.Tabs,tab),'Unknown tab')
    self:ClosePopup()
    if self.CaptureCancel then self.CaptureCancel() end
    self.SelectedTab = tab
    for _,item in ipairs(self.Tabs) do item.Page.Visible = item == tab end
    self:UpdateTabs()
end
function Window:OpenPopup(owner,anchor,width,height)
    self:ClosePopup()
    local scope = Janitor.new()
    self.PopupScope,self.PopupOwner = scope,owner
    local blocker = F.button(self.Screen,'PopupDismiss',0,0,0,0,self.Theme)
    blocker.Size = UDim2.fromScale(1,1); blocker.ZIndex = 100
    scope:Add(blocker)
    local screen = self.Screen.AbsoluteSize
    local x = math.clamp(anchor.AbsolutePosition.X,0,math.max(0,screen.X-width*self.Scale-2))
    local y = anchor.AbsolutePosition.Y+anchor.AbsoluteSize.Y+2
    if y+height*self.Scale > screen.Y then y = math.max(0,anchor.AbsolutePosition.Y-height*self.Scale-2) end
    local popup = F.frame(self.Screen,'Popup',x,y,width,height,self.Theme.Control,101)
    F.new('UIScale',{Scale = self.Scale},popup)
    F.stroke(popup,self.Theme.Black)
    scope:Add(popup); scope:Add(blocker.Activated:Connect(function() self:ClosePopup() end))
    self.Popup = popup
    return popup,scope
end
function Window:ClosePopup()
    local scope = self.PopupScope
    self.PopupScope,self.PopupOwner,self.Popup = nil,nil,nil
    if scope then scope:Destroy() end
end
function Window:SetVisible(visible)
    if self.Destroyed then return end
    self.Visible = visible
    self:ClosePopup()
    if self.CaptureCancel then self.CaptureCancel() end
    if self.Fade then self.Fade:Cancel() end
    self.Root.Visible = true
    local speed = self.Store:Get('fade_speed') or 5
    local duration = speed == 0 and 0 or 0.5/speed
    self.Fade = TweenService:Create(self.Root,TweenInfo.new(duration),{GroupTransparency = visible and 0 or 1})
    self.Fade:Play()
    -- A cancelled tween must not hide a newly reopened window.
    task.delay(duration,function() if not self.Destroyed and self.Visible == false then self.Root.Visible = false end end)
end
function Window:Use(name,factory)
    self.Modules = self.Modules or {}
    assert(self.Modules[name] == nil,'Module already mounted: '..name)
    assert(type(factory) == 'function','Module must return a function(window)')
    local value = factory(self)
    self.Modules[name] = value or true
    if type(value) == 'function' or typeof(value) == 'RBXScriptConnection' or (type(value) == 'table' and value.Destroy) then
        self.Scope:Add(value)
    end
    return value
end
function Window:Get(id) return self.Store:Get(id) end
function Window:Set(id,value) self.Store:Set(id,value) end
function Window:OnChanged(callback) return self.Scope:Add(self.Store.Changed:Connect(callback)) end
function Window:ExportConfig() return self.Store:Export() end
function Window:ImportConfig(json) self.Store:Import(json) end
function Window:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    if self.Preview then self.Preview:Destroy() end
    if self.CaptureCancel then self.CaptureCancel() end
    self.Scope:Destroy()
end
return Window

end

factories["preview/MeshAsset"] = function(script, require)
local MeshAsset = {}
function MeshAsset.FromFile(path)
    assert(type(readfile) == 'function','LocalMesh requires executor readfile()')
    assert(type(getcustomasset) == 'function','LocalMesh requires executor getcustomasset()')
    local file = readfile(path)
    assert(file:sub(1,13) == 'version 2.00\n','Expected a Roblox FileMesh v2 file')
    local headerSize,vertexSize,_,count = string.unpack('<I2I1I1I4',file,14)
    assert(vertexSize == 36 or vertexSize == 40,'Unsupported mesh vertex size')
    assert(count > 0 and count <= 1000000,'Invalid vertex count')
    local start = 14+headerSize
    assert(#file >= start-1+count*vertexSize,'Truncated mesh')
    local minX,minY,minZ,maxX,maxY,maxZ = math.huge,math.huge,math.huge,-math.huge,-math.huge,-math.huge
    for index = 0,count-1 do
        local x,y,z = string.unpack('<fff',file,start+index*vertexSize)
        minX = math.min(minX,x); minY = math.min(minY,y); minZ = math.min(minZ,z)
        maxX = math.max(maxX,x); maxY = math.max(maxY,y); maxZ = math.max(maxZ,z)
    end
    return {MeshId = getcustomasset(path),Size = Vector3.new(maxX-minX,maxY-minY,maxZ-minZ),
        MeshCenter = Vector3.new((maxX+minX)/2,(maxY+minY)/2,(maxZ+minZ)/2)}
end
return MeshAsset

end

factories["preview/Overlay"] = function(script, require)
local F = require(script.Parent.Parent.core.Factory)
local Input = require(script.Parent.Parent.core.Input)
local Overlay = {}
Overlay.__index = Overlay
function Overlay.new(preview)
    local w,t = preview.Window,preview.Window.Theme
    local root = F.frame(preview.Area,'Overlay',0,0,preview.Area.Size.X.Offset,preview.Area.Size.Y.Offset,t.Face,12)
    root.BackgroundTransparency = 1
    local self = setmetatable({Preview = preview,Window = w,Root = root,Offsets = {},Elements = {},BoxLines = {},Skeleton = {}},Overlay)
    for i = 1,8 do self.BoxLines[i] = F.frame(root,'Box'..i,0,0,1,1,t.Text,12) end
    local function element(name,text,width,height)
        local frame = F.frame(root,name,0,0,width,height,t.Face,13)
        frame.BackgroundTransparency = 1; frame.Active = true
        local label = F.text(frame,text,0,0,width,height,t,14)
        label.TextSize = 10; label.TextStrokeTransparency = 0.3
        label.TextXAlignment = Enum.TextXAlignment.Center
        self.Elements[name] = {Frame = frame,Label = label}
        self.Offsets[name] = Vector2.zero
        local start
        Input.drag(frame,preview.Scope,function(_,delta)
            local areaSize = root.AbsoluteSize / w.Scale
            local offset = start+delta/w.Scale
            local anchor = self.Elements[name].Anchor or Vector2.zero
            self.Offsets[name] = Vector2.new(math.clamp(offset.X,-anchor.X,areaSize.X-width-anchor.X),
                math.clamp(offset.Y,-anchor.Y,areaSize.Y-height-anchor.Y))
        end,function() start = self.Offsets[name]; preview.LastInteraction = os.clock() end,function()
            preview.LastInteraction = os.clock()
        end)
        return self.Elements[name]
    end
    element('Name','preview player',120,13)
    local health = element('Health','82',20,13)
    health.Bar = F.frame(root,'HealthTrack',0,0,2,100,t.Black,12)
    health.Fill = F.frame(health.Bar,'Health',0,0,2,82,Color3.fromRGB(80,180,205),13)
    element('Flags','$1334\nstatus\nflex',65,36)
    element('Weapon','AK-47',90,14)
    element('Distance','71m',70,13)
    self.Ammo = F.frame(root,'Ammo',0,0,40,2,Color3.fromRGB(80,160,220),12)
    for i = 1,12 do self.Skeleton[i] = F.frame(root,'Bone'..i,0,0,1,1,t.Text,13) end
    return self
end
function Overlay:SetData(data)
    self.Data = data
end
local function line(frame,a,b,color)
    local delta = b-a
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.Position = UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
    frame.Size = UDim2.fromOffset(delta.Magnitude,1)
    frame.Rotation = math.deg(math.atan2(delta.Y,delta.X))
    frame.BackgroundColor3 = color
end
function Overlay:Update(box)
    local w,p = self.Window,self.Preview
    local state = w.Store
    local data = self.Data or {}
    local function get(id)
        local bind = p.Bindings[id] or id
        if state.definitions[bind] then return state:Get(bind) end
        return p.Display[id]
    end
    local function enabled(id) return get(id) == true end
    local function color(id)
        local value = get(id)
        return value and value.Color or w.Theme.Text,value and value.Alpha or 1
    end
    local left,top,right,bottom = box[1],box[2],box[3],box[4]
    local width,height = right-left,bottom-top
    local boxColor,boxAlpha = color('player_enemy_box_color')
    local corner = get('player_box_type') == 'cornered'
    local points
    if corner then
        local x,y = math.min(14,width/3),math.min(18,height/4)
        points = {{left,top,left+x,top},{left,top,left,top+y},{right-x,top,right,top},{right,top,right,top+y},
            {left,bottom,left+x,bottom},{left,bottom-y,left,bottom},{right-x,bottom,right,bottom},{right,bottom-y,right,bottom}}
    else
        points = {{left,top,right,top},{right,top,right,bottom},{left,bottom,right,bottom},{left,top,left,bottom}}
    end
    for i,frame in ipairs(self.BoxLines) do
        frame.Visible = enabled('player_enemy_box') and points[i] ~= nil
        if points[i] then
            local s = points[i]; line(frame,Vector2.new(s[1],s[2]),Vector2.new(s[3],s[4]),boxColor)
            frame.BackgroundTransparency = 1-boxAlpha
        end
    end
    local center = (left+right)/2
    local anchors = {Name = Vector2.new(center-60,top-15),Health = Vector2.new(left-23,(top+bottom)/2-6),
        Flags = Vector2.new(right+4,top),Weapon = Vector2.new(center-45,bottom+3),Distance = Vector2.new(center-35,bottom+19)}
    local ids = {Name = 'player_name',Health = 'player_health',Flags = 'player_flags',Weapon = 'player_weapon',Distance = 'player_distance'}
    for name,element in pairs(self.Elements) do
        element.Frame.Visible = enabled(ids[name])
        element.Anchor = anchors[name]
        local pos = anchors[name]+self.Offsets[name]
        element.Frame.Position = UDim2.fromOffset(pos.X,pos.Y)
    end
    local nameColor,nameAlpha = color('player_name_color')
    self.Elements.Name.Label.Text = data.Name or 'preview player'
    self.Elements.Name.Label.TextColor3 = nameColor; self.Elements.Name.Label.TextTransparency = 1-nameAlpha
    local distanceColor,distanceAlpha = color('player_distance_color')
    self.Elements.Distance.Label.Text = tostring(data.Distance or 71)..'m'
    self.Elements.Distance.Label.TextColor3 = distanceColor; self.Elements.Distance.Label.TextTransparency = 1-distanceAlpha
    local hp = math.clamp(data.Health or 82,0,100)
    local health = self.Elements.Health
    health.Label.Text = tostring(hp)
    local healthOffset = self.Offsets.Health
    health.Bar.Visible = enabled('player_health')
    health.Bar.Position = UDim2.fromOffset(left-4+healthOffset.X,top+healthOffset.Y)
    health.Bar.Size = UDim2.fromOffset(2,height)
    health.Fill.Position = UDim2.fromScale(0,1-hp/100); health.Fill.Size = UDim2.fromScale(1,hp/100)
    local selection = get('player_flags_selection') or {'money'}
    local flags = {}
    for _,flag in ipairs(selection) do table.insert(flags,flag == 'money' and ('$'..tostring(data.Money or 1334)) or flag) end
    self.Elements.Flags.Label.Text = table.concat(flags,'\n')
    self.Elements.Flags.Label.TextXAlignment = Enum.TextXAlignment.Left
    local weaponModes = get('player_weapon_display') or {'icon','text'}
    local text = {}
    if table.find(weaponModes,'icon') then table.insert(text,'━╋━') end
    if table.find(weaponModes,'text') then table.insert(text,data.Weapon or 'AK-47') end
    self.Elements.Weapon.Label.Text = table.concat(text,' ')
    self.Ammo.Visible = enabled('player_ammo')
    self.Ammo.Position = UDim2.fromOffset(left,bottom+1)
    self.Ammo.Size = UDim2.fromOffset(width*math.clamp(data.Ammo or 0.72,0,1),2)
    local joints = {{.5,.1},{.5,.25},{.5,.5},{.28,.27},{.15,.44},{.72,.27},{.85,.44},{.38,.64},{.32,.82},{.29,.98},{.62,.64},{.68,.82},{.71,.98}}
    local links = {{1,2},{2,3},{2,4},{4,5},{2,6},{6,7},{3,8},{8,9},{9,10},{3,11},{11,12},{12,13}}
    for i,pair in ipairs(links) do
        local frame = self.Skeleton[i]; frame.Visible = enabled('player_skeleton')
        if frame.Visible then
            local a,b = joints[pair[1]],joints[pair[2]]
            line(frame,Vector2.new(left+a[1]*width,top+a[2]*height),Vector2.new(left+b[1]*width,top+b[2]*height),w.Theme.Text)
        end
    end
end
return Overlay

end

factories["preview/Preview"] = function(script, require)
local RunService = game:GetService('RunService')
local ContentProvider = game:GetService('ContentProvider')
local F = require(script.Parent.Parent.core.Factory)
local Input = require(script.Parent.Parent.core.Input)
local Janitor = require(script.Parent.Parent.core.Janitor)
local Signal = require(script.Parent.Parent.core.Signal)
local Overlay = require(script.Parent.Overlay)
local Preview = {}
Preview.__index = Preview
local keys = {
    Box = 'player_enemy_box',BoxType = 'player_box_type',BoxColor = 'player_enemy_box_color',
    Name = 'player_name',NameColor = 'player_name_color',Health = 'player_health',
    Distance = 'player_distance',DistanceColor = 'player_distance_color',Weapon = 'player_weapon',
    WeaponDisplay = 'player_weapon_display',Flags = 'player_flags',FlagSelection = 'player_flags_selection',
    Ammo = 'player_ammo',Skeleton = 'player_skeleton',Dormant = 'player_dormant',
}
function Preview.new(window,options)
    options = options or {}
    assert(options.Model or options.MeshId,'Preview needs Model or MeshId; use Library.LocalMesh(path) for a local .mesh')
    local self = setmetatable({Window = window,Scope = Janitor.new(),Options = options,Display = {},Bindings = {},
        Yaw = math.pi,Pitch = 0,Zoom = 1,LastInteraction = os.clock(),Paused = options.AutoRotate == false,
        Destroyed = false,Parts = {},Loaded = Signal.new(),IsLoaded = false},Preview)
    self.Scope:Add(self.Loaded)
    local w,t = window,window.Theme
    self.Frame = F.chrome(w.Root,'Preview',t.PreviewSize,t)
    self.Scope:Add(self.Frame)
    self.Frame.Position = UDim2.fromOffset(582,50)
    local title = F.button(self.Frame,'DragTitle',6,6,268,30,t,options.Title or 'esp preview')
    title.TextSize = 11
    Input.move(title,self.Frame,w,self.Scope)
    local accent = F.frame(self.Frame,'Accent',12,35,256,4,w.Accent,5)
    F.gradient(accent,Color3.new(1,1,1),Color3.fromRGB(170,170,170))
    local area = F.frame(self.Frame,'Content',16,45,248,299,t.Group,3)
    F.stroke(area,t.Border); area.ClipsDescendants = true
    self.Area = area
    self.Viewport = F.new('ViewportFrame',{Name = 'ModelViewport',Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,BorderSizePixel = 0,Ambient = Color3.fromRGB(95,95,95),
        LightColor = Color3.fromRGB(240,240,240),LightDirection = Vector3.new(-1,-1,-2),ZIndex = 4},area)
    self.World = F.new('WorldModel',{Name = 'PreviewWorld'},self.Viewport)
    self.Camera = F.new('Camera',{Name = 'PreviewCamera',FieldOfView = 32},self.Viewport)
    self.Viewport.CurrentCamera = self.Camera
    local rotate = F.button(area,'RotateInput',0,0,248,299,t)
    rotate.ZIndex = 7
    self.Status = F.text(area,'loading model...',0,130,248,20,t,10)
    self.Status.TextXAlignment = Enum.TextXAlignment.Center
    self.Overlay = Overlay.new(self)
    self:SetOptions({Box = true,Name = true,Health = true,Distance = true,Weapon = true,Flags = true,Ammo = false,Skeleton = false})
    self:SetOptions(options.Display or {})
    self:Bind(options.Bindings or {})
    self.Overlay:SetData(options.Data or {})
    local yaw,pitch
    Input.drag(rotate,self.Scope,function(_,delta)
        self.Yaw = yaw+delta.X*0.01/w.Scale
        self.Pitch = math.clamp(pitch+delta.Y*0.01/w.Scale,-0.65,0.85)
        self.LastInteraction = os.clock()
    end,function() yaw,pitch = self.Yaw,self.Pitch; self.Dragging = true end,function()
        self.Dragging = false; self.LastInteraction = os.clock()
    end)
    self.Scope:Add(rotate.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then self.Paused = not self.Paused end
    end))
    self.Scope:Add(rotate.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            self.Zoom = math.clamp(self.Zoom+input.Position.Z*0.1,0.5,2.5)
            self.LastInteraction = os.clock()
        end
    end))
    self.Scope:Add(w.AccentChanged:Connect(function(color)
        accent.BackgroundColor3 = color
        if not options.Color then self:UpdateAppearance() end
    end))
    self.Scope:Add(w.Store.Changed:Connect(function(id)
        if id == 'glow_reflectivity' or id == 'glow_translucency' or id == 'glow_shine' or id == 'player_dormant' then
            self:UpdateAppearance()
        end
    end))
    self.Scope:Add(RunService.RenderStepped:Connect(function(dt)
        if self.Destroyed or not w.Visible or not self.IsLoaded then return end
        if not self.Paused and not self.Dragging and os.clock()-self.LastInteraction > 2 then self.Yaw = self.Yaw+dt*0.3 end
        self:Render()
    end))
    task.spawn(function()
        local ok,err = pcall(function() self:LoadModel() end)
        if not ok and not self.Destroyed then
            self.Status.Text = 'model failed to load'
            self.Error = tostring(err); warn('VeyraUI preview: '..tostring(err))
            self.Loaded:Fire(false,tostring(err))
        end
    end)
    w:Fit()
    return self
end
function Preview:LoadModel()
    local o = self.Options
    local model,mesh
    if o.Model then
        assert(o.Model:IsA('Model'),'Model must be a Roblox Model')
        model = o.Model:Clone()
        for _,item in ipairs(model:GetDescendants()) do
            if item:IsA('BaseScript') then item:Destroy()
            elseif item:IsA('BasePart') then item.Anchored = true; item.CanCollide = false; item.CanTouch = false; item.CanQuery = false end
        end
        local center = model:GetBoundingBox()
        model:PivotTo(CFrame.new(-center.Position)*model:GetPivot())
    else
        local size = assert(o.Size,'MeshId preview also needs Size (Library.LocalMesh fills it automatically)')
        model = F.new('Model',{Name = 'PreviewModel'},nil)
        local part = F.new('Part',{Name = 'Mesh',Size = size,CFrame = CFrame.identity,Anchored = true,
            CanCollide = false,CanQuery = false,CanTouch = false,CastShadow = false,
            Material = Enum.Material.SmoothPlastic,Color = o.Color or self.Window.Accent},model)
        mesh = F.new('SpecialMesh',{Name = 'OriginalMesh',MeshType = Enum.MeshType.FileMesh,
            MeshId = o.MeshId,TextureId = o.TextureId or '',Scale = o.MeshScale or Vector3.one,
            Offset = -(o.MeshCenter or Vector3.zero)},part)
    end
    if self.Destroyed then model:Destroy(); return end
    model.Parent = self.World
    self.Model = model
    for _,part in ipairs(model:GetDescendants()) do if part:IsA('BasePart') then table.insert(self.Parts,part) end end
    self.BoundsCF,self.BoundsSize = model:GetBoundingBox()
    if mesh then
        local failed
        ContentProvider:PreloadAsync({mesh},function(_,status)
            if status ~= Enum.AssetFetchStatus.Success then failed = status.Name end
        end)
        if failed then error('Local mesh loading is unsupported or failed: '..failed) end
    end
    if self.Destroyed then return end
    self.Status.Visible = false
    self.IsLoaded = true
    self:UpdateAppearance(); self:Render()
    self.Loaded:Fire(true)
end
function Preview:SetOptions(options)
    for key,value in pairs(options) do self.Display[keys[key] or key] = value end
end
function Preview:Bind(bindings)
    for key,id in pairs(bindings) do self.Bindings[keys[key] or key] = id end
end
function Preview:SetData(data) self.Overlay:SetData(data) end
function Preview:ResetView() self.Yaw,self.Pitch,self.Zoom = math.pi,0,1; self.LastInteraction = os.clock() end
function Preview:UpdateAppearance()
    if self.Destroyed then return end
    local state = self.Window.Store
    local opacity = (state:Get('glow_translucency') or 0)/100*0.85
    if state:Get('player_dormant') then opacity = math.max(opacity,0.55) end
    for _,part in ipairs(self.Parts) do
        if not self.Options.PreserveMaterials then part.Color = self.Options.Color or self.Window.Accent end
        part.Reflectance = (state:Get('glow_reflectivity') or 0)/100*0.6
        part.Transparency = opacity
    end
    self.Viewport.LightColor = Color3.fromRGB(220,220,220):Lerp(Color3.new(1,1,1),(state:Get('glow_shine') or 0)/100)
end
function Preview:Render()
    local size = self.BoundsSize
    local height,width = self.Area.Size.Y.Offset,self.Area.Size.X.Offset
    local tan = math.tan(math.rad(self.Camera.FieldOfView)/2)
    local distance = (math.max(size.Y,size.X/(width/height))/(2*tan)*1.3+size.Z/2)/self.Zoom
    local direction = Vector3.new(math.sin(self.Yaw)*math.cos(self.Pitch),math.sin(self.Pitch),math.cos(self.Yaw)*math.cos(self.Pitch))
    local center = self.BoundsCF.Position
    local camera = CFrame.lookAt(center+direction*distance,center)
    self.Camera.CFrame = camera; self.Camera.Focus = CFrame.new(center)
    local minX,minY,maxX,maxY = math.huge,math.huge,-math.huge,-math.huge
    for x = -1,1,2 do for y = -1,1,2 do for z = -1,1,2 do
        local corner = self.BoundsCF:PointToWorldSpace(Vector3.new(size.X*x,size.Y*y,size.Z*z)/2)
        local q = camera:PointToObjectSpace(corner)
        local depth = math.max(0.01,-q.Z)
        local sx,sy = width/2+q.X/depth*height/(2*tan),height/2-q.Y/depth*height/(2*tan)
        minX = math.min(minX,sx); minY = math.min(minY,sy); maxX = math.max(maxX,sx); maxY = math.max(maxY,sy)
    end end end
    self.Overlay:Update({minX,minY,maxX,maxY})
end
function Preview:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    self.Scope:Destroy()
    if self.Window.Preview == self then self.Window.Preview = nil end
end
return Preview

end
local nativeRequire = require
local function import(target)
    if type(target) ~= 'table' or not target.Path then return nativeRequire(target) end
    local path = target.Path
    if cache[path] ~= nil then return cache[path] end
    assert(not loading[path], 'Circular module dependency: '..path)
    local factory = assert(factories[path], 'Module not found: '..path)
    loading[path] = true
    local ok, result = pcall(factory, target, import)
    loading[path] = nil
    if not ok then error(result, 2) end
    assert(result ~= nil, 'Module returned nil: '..path)
    cache[path] = result
    return result
end
return import(node(''))
