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
