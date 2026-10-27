local base = 'https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main'
local UI = loadstring(game:HttpGet(base .. '/VeyraUI.luau'))()
local window = UI.new({Title = 'veyra'})

local tab = window:Tab('general')
local settings = tab:Section('settings', 1)
settings:Toggle({Id = 'enabled', Text = 'enabled', Default = false, Callback = function(value)
    print(value)
end})
settings:Slider({Id = 'speed', Text = 'speed', Min = 1, Max = 100, Default = 25})
settings:Dropdown({Id = 'mode', Text = 'mode', Items = {'normal', 'fast'}, Default = 'normal'})

local appearance = tab:Section('appearance', 2)
appearance:ColorPicker({Id = 'accent', Text = 'accent', Default = {Color = Color3.fromRGB(181, 0, 41), Alpha = 1}})
appearance:Keybind({Id = 'action', Text = 'action key', Default = 'E', OnPressed = function()
    print('action')
end})
appearance:Button({Text = 'unload', Callback = function() window:Destroy() end})

-- window:Use('my module', loadstring(game:HttpGet(base .. '/modules/MyModule.luau'))())
-- window:CreatePreview({Model = yourModel, PreserveMaterials = true})
-- window:CreatePreview(UI.LocalMesh('my-model.mesh'))

return window
