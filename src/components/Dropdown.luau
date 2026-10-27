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
