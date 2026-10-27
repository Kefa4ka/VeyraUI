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
