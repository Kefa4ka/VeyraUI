local Janitor = {}
Janitor.__index = Janitor
function Janitor.new() return setmetatable({items = {}, dead = false}, Janitor) end
function Janitor:Add(item)
    if self.dead then
        if typeof(item) == 'RBXScriptConnection' then item:Disconnect()
        elseif type(item) == 'function' then item() else item:Destroy() end
    else table.insert(self.items, item) end
    return item
end
function Janitor:Destroy()
    if self.dead then return end
    self.dead = true
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        local ok, err = pcall(function()
            if typeof(item) == 'RBXScriptConnection' then item:Disconnect()
            elseif type(item) == 'function' then item() else item:Destroy() end
        end)
        if not ok then warn('VeyraUI cleanup: ' .. tostring(err)) end
    end
    table.clear(self.items)
end
return Janitor
