local F = require(script.Parent.Parent.core.Factory)
local C = require(script.Parent.Common)
return function(section,o)
    local h = C.row(section,o,15,'Label')
    local label = F.text(h.Frame,o.Text or '',20,-3,170,15,h.Window.Theme)
    function h:SetText(text) label.Text = text end
    return h
end
