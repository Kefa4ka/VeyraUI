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
