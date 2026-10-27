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
