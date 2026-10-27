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
