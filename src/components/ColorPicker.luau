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
