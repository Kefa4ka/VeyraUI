local RunService = game:GetService('RunService')
local ContentProvider = game:GetService('ContentProvider')
local F = require(script.Parent.Parent.core.Factory)
local Input = require(script.Parent.Parent.core.Input)
local Janitor = require(script.Parent.Parent.core.Janitor)
local Signal = require(script.Parent.Parent.core.Signal)
local Overlay = require(script.Parent.Overlay)
local Preview = {}
Preview.__index = Preview
local keys = {
    Box = 'player_enemy_box',BoxType = 'player_box_type',BoxColor = 'player_enemy_box_color',
    Name = 'player_name',NameColor = 'player_name_color',Health = 'player_health',
    Distance = 'player_distance',DistanceColor = 'player_distance_color',Weapon = 'player_weapon',
    WeaponDisplay = 'player_weapon_display',Flags = 'player_flags',FlagSelection = 'player_flags_selection',
    Ammo = 'player_ammo',Skeleton = 'player_skeleton',Dormant = 'player_dormant',
}
function Preview.new(window,options)
    options = options or {}
    assert(options.Model or options.MeshId,'Preview needs Model or MeshId; use Library.LocalMesh(path) for a local .mesh')
    local self = setmetatable({Window = window,Scope = Janitor.new(),Options = options,Display = {},Bindings = {},
        Yaw = math.pi,Pitch = 0,Zoom = 1,LastInteraction = os.clock(),Paused = options.AutoRotate == false,
        Destroyed = false,Parts = {},Loaded = Signal.new(),IsLoaded = false},Preview)
    self.Scope:Add(self.Loaded)
    local w,t = window,window.Theme
    self.Frame = F.chrome(w.Root,'Preview',t.PreviewSize,t)
    self.Scope:Add(self.Frame)
    self.Frame.Position = UDim2.fromOffset(582,50)
    local title = F.button(self.Frame,'DragTitle',6,6,268,30,t,options.Title or 'esp preview')
    title.TextSize = 11
    Input.move(title,self.Frame,w,self.Scope)
    local accent = F.frame(self.Frame,'Accent',12,35,256,4,w.Accent,5)
    F.gradient(accent,Color3.new(1,1,1),Color3.fromRGB(170,170,170))
    local area = F.frame(self.Frame,'Content',16,45,248,299,t.Group,3)
    F.stroke(area,t.Border); area.ClipsDescendants = true
    self.Area = area
    self.Viewport = F.new('ViewportFrame',{Name = 'ModelViewport',Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,BorderSizePixel = 0,Ambient = Color3.fromRGB(95,95,95),
        LightColor = Color3.fromRGB(240,240,240),LightDirection = Vector3.new(-1,-1,-2),ZIndex = 4},area)
    self.World = F.new('WorldModel',{Name = 'PreviewWorld'},self.Viewport)
    self.Camera = F.new('Camera',{Name = 'PreviewCamera',FieldOfView = 32},self.Viewport)
    self.Viewport.CurrentCamera = self.Camera
    local rotate = F.button(area,'RotateInput',0,0,248,299,t)
    rotate.ZIndex = 7
    self.Status = F.text(area,'loading model...',0,130,248,20,t,10)
    self.Status.TextXAlignment = Enum.TextXAlignment.Center
    self.Overlay = Overlay.new(self)
    self:SetOptions({Box = true,Name = true,Health = true,Distance = true,Weapon = true,Flags = true,Ammo = false,Skeleton = false})
    self:SetOptions(options.Display or {})
    self:Bind(options.Bindings or {})
    self.Overlay:SetData(options.Data or {})
    local yaw,pitch
    Input.drag(rotate,self.Scope,function(_,delta)
        self.Yaw = yaw+delta.X*0.01/w.Scale
        self.Pitch = math.clamp(pitch+delta.Y*0.01/w.Scale,-0.65,0.85)
        self.LastInteraction = os.clock()
    end,function() yaw,pitch = self.Yaw,self.Pitch; self.Dragging = true end,function()
        self.Dragging = false; self.LastInteraction = os.clock()
    end)
    self.Scope:Add(rotate.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then self.Paused = not self.Paused end
    end))
    self.Scope:Add(rotate.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            self.Zoom = math.clamp(self.Zoom+input.Position.Z*0.1,0.5,2.5)
            self.LastInteraction = os.clock()
        end
    end))
    self.Scope:Add(w.AccentChanged:Connect(function(color)
        accent.BackgroundColor3 = color
        if not options.Color then self:UpdateAppearance() end
    end))
    self.Scope:Add(w.Store.Changed:Connect(function(id)
        if id == 'glow_reflectivity' or id == 'glow_translucency' or id == 'glow_shine' or id == 'player_dormant' then
            self:UpdateAppearance()
        end
    end))
    self.Scope:Add(RunService.RenderStepped:Connect(function(dt)
        if self.Destroyed or not w.Visible or not self.IsLoaded then return end
        if not self.Paused and not self.Dragging and os.clock()-self.LastInteraction > 2 then self.Yaw = self.Yaw+dt*0.3 end
        self:Render()
    end))
    task.spawn(function()
        local ok,err = pcall(function() self:LoadModel() end)
        if not ok and not self.Destroyed then
            self.Status.Text = 'model failed to load'
            self.Error = tostring(err); warn('VeyraUI preview: '..tostring(err))
            self.Loaded:Fire(false,tostring(err))
        end
    end)
    w:Fit()
    return self
end
function Preview:LoadModel()
    local o = self.Options
    local model,mesh
    if o.Model then
        assert(o.Model:IsA('Model'),'Model must be a Roblox Model')
        model = o.Model:Clone()
        for _,item in ipairs(model:GetDescendants()) do
            if item:IsA('BaseScript') then item:Destroy()
            elseif item:IsA('BasePart') then item.Anchored = true; item.CanCollide = false; item.CanTouch = false; item.CanQuery = false end
        end
        local center = model:GetBoundingBox()
        model:PivotTo(CFrame.new(-center.Position)*model:GetPivot())
    else
        local size = assert(o.Size,'MeshId preview also needs Size (Library.LocalMesh fills it automatically)')
        model = F.new('Model',{Name = 'PreviewModel'},nil)
        local part = F.new('Part',{Name = 'Mesh',Size = size,CFrame = CFrame.identity,Anchored = true,
            CanCollide = false,CanQuery = false,CanTouch = false,CastShadow = false,
            Material = Enum.Material.SmoothPlastic,Color = o.Color or self.Window.Accent},model)
        mesh = F.new('SpecialMesh',{Name = 'OriginalMesh',MeshType = Enum.MeshType.FileMesh,
            MeshId = o.MeshId,TextureId = o.TextureId or '',Scale = o.MeshScale or Vector3.one,
            Offset = -(o.MeshCenter or Vector3.zero)},part)
    end
    if self.Destroyed then model:Destroy(); return end
    model.Parent = self.World
    self.Model = model
    for _,part in ipairs(model:GetDescendants()) do if part:IsA('BasePart') then table.insert(self.Parts,part) end end
    self.BoundsCF,self.BoundsSize = model:GetBoundingBox()
    if mesh then
        local failed
        ContentProvider:PreloadAsync({mesh},function(_,status)
            if status ~= Enum.AssetFetchStatus.Success then failed = status.Name end
        end)
        if failed then error('Local mesh loading is unsupported or failed: '..failed) end
    end
    if self.Destroyed then return end
    self.Status.Visible = false
    self.IsLoaded = true
    self:UpdateAppearance(); self:Render()
    self.Loaded:Fire(true)
end
function Preview:SetOptions(options)
    for key,value in pairs(options) do self.Display[keys[key] or key] = value end
end
function Preview:Bind(bindings)
    for key,id in pairs(bindings) do self.Bindings[keys[key] or key] = id end
end
function Preview:SetData(data) self.Overlay:SetData(data) end
function Preview:ResetView() self.Yaw,self.Pitch,self.Zoom = math.pi,0,1; self.LastInteraction = os.clock() end
function Preview:UpdateAppearance()
    if self.Destroyed then return end
    local state = self.Window.Store
    local opacity = (state:Get('glow_translucency') or 0)/100*0.85
    if state:Get('player_dormant') then opacity = math.max(opacity,0.55) end
    for _,part in ipairs(self.Parts) do
        if not self.Options.PreserveMaterials then part.Color = self.Options.Color or self.Window.Accent end
        part.Reflectance = (state:Get('glow_reflectivity') or 0)/100*0.6
        part.Transparency = opacity
    end
    self.Viewport.LightColor = Color3.fromRGB(220,220,220):Lerp(Color3.new(1,1,1),(state:Get('glow_shine') or 0)/100)
end
function Preview:Render()
    local size = self.BoundsSize
    local height,width = self.Area.Size.Y.Offset,self.Area.Size.X.Offset
    local tan = math.tan(math.rad(self.Camera.FieldOfView)/2)
    local distance = (math.max(size.Y,size.X/(width/height))/(2*tan)*1.3+size.Z/2)/self.Zoom
    local direction = Vector3.new(math.sin(self.Yaw)*math.cos(self.Pitch),math.sin(self.Pitch),math.cos(self.Yaw)*math.cos(self.Pitch))
    local center = self.BoundsCF.Position
    local camera = CFrame.lookAt(center+direction*distance,center)
    self.Camera.CFrame = camera; self.Camera.Focus = CFrame.new(center)
    local minX,minY,maxX,maxY = math.huge,math.huge,-math.huge,-math.huge
    for x = -1,1,2 do for y = -1,1,2 do for z = -1,1,2 do
        local corner = self.BoundsCF:PointToWorldSpace(Vector3.new(size.X*x,size.Y*y,size.Z*z)/2)
        local q = camera:PointToObjectSpace(corner)
        local depth = math.max(0.01,-q.Z)
        local sx,sy = width/2+q.X/depth*height/(2*tan),height/2-q.Y/depth*height/(2*tan)
        minX = math.min(minX,sx); minY = math.min(minY,sy); maxX = math.max(maxX,sx); maxY = math.max(maxY,sy)
    end end end
    self.Overlay:Update({minX,minY,maxX,maxY})
end
function Preview:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    self.Scope:Destroy()
    if self.Window.Preview == self then self.Window.Preview = nil end
end
return Preview
