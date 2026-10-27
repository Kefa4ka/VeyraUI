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
