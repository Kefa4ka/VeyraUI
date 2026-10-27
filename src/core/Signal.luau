local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({listeners = {}, dead = false}, Signal) end
function Signal:Connect(callback)
    assert(not self.dead, 'Signal is destroyed')
    local connection = {Connected = true}
    self.listeners[connection] = callback
    local owner = self
    function connection:Disconnect()
        self.Connected = false
        owner.listeners[self] = nil
    end
    connection.Destroy = connection.Disconnect
    return connection
end
function Signal:Fire(...)
    local pending = {}
    for connection, callback in pairs(self.listeners) do table.insert(pending, {connection, callback}) end
    for _, entry in ipairs(pending) do
        if entry[1].Connected then
            local ok, err = pcall(entry[2], ...)
            if not ok then warn('VeyraUI callback: ' .. tostring(err)) end
        end
    end
end
function Signal:Destroy()
    self.dead = true
    for connection in pairs(self.listeners) do connection.Connected = false end
    table.clear(self.listeners)
end
return Signal
