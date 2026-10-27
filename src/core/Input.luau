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
