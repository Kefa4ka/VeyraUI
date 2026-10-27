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
