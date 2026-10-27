local F = require(script.Parent.Parent.core.Factory)
local Section = require(script.Parent.Section)
local Tab = {}
Tab.__index = Tab
function Tab.new(window,title)
    local page = F.new('ScrollingFrame',{Name = title,Position = UDim2.fromOffset(23,52),Size = UDim2.fromOffset(476,489),
        BackgroundTransparency = 1,BorderSizePixel = 0,ScrollBarThickness = 3,ScrollBarImageColor3 = window.Theme.Track,
        CanvasSize = UDim2.fromOffset(0,0),ScrollingDirection = Enum.ScrollingDirection.Y,Visible = false,ZIndex = 3},window.Main)
    return setmetatable({Window = window,Title = title,Page = page,Sections = {}},Tab)
end
function Tab:Section(title,column)
    local section = Section.new(self,title,column or 1)
    table.insert(self.Sections,section)
    self:Reflow()
    return section
end
function Tab:Reflow()
    local heights = {10,10}
    for _,section in ipairs(self.Sections) do
        local c = section.Column
        section.Frame.Position = UDim2.fromOffset(c == 2 and 249 or 19,heights[c])
        heights[c] = heights[c]+section.Height+15
    end
    self.Page.CanvasSize = UDim2.fromOffset(0,math.max(heights[1],heights[2]))
end
return Tab
