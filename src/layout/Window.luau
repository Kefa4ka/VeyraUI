local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local F = require(script.Parent.Parent.core.Factory)
local Theme = require(script.Parent.Parent.core.Theme)
local Janitor = require(script.Parent.Parent.core.Janitor)
local Signal = require(script.Parent.Parent.core.Signal)
local Store = require(script.Parent.Parent.core.Store)
local Input = require(script.Parent.Parent.core.Input)
local Tab = require(script.Parent.Tab)
local Window = {}
Window.__index = Window
local function defaultParent()
    if type(gethui) == 'function' then
        local ok,parent = pcall(gethui)
        if ok and typeof(parent) == 'Instance' then return parent end
    end
    local core = game:GetService('CoreGui')
    local probe = Instance.new('Folder')
    local ok = pcall(function() probe.Parent = core end)
    probe:Destroy()
    if ok then return core end
    return Players.LocalPlayer:WaitForChild('PlayerGui')
end
function Window.new(options)
    options = options or {}
    local self = setmetatable({Scope = Janitor.new(),Store = Store.new(),Controls = {},Tabs = {},
        Theme = table.clone(Theme),AccentChanged = Signal.new(),Action = Signal.new(),
        Visible = true,Destroyed = false,Scale = 1,Options = options},Window)
    for key,value in pairs(options.Theme or {}) do self.Theme[key] = value end
    self.Accent = options.Accent or self.Theme.Accent
    self.Scope:Add(self.Store); self.Scope:Add(self.AccentChanged); self.Scope:Add(self.Action)
    self.Screen = F.new('ScreenGui',{Name = options.Name or 'VeyraUI',ResetOnSpawn = false,
        ScreenInsets = Enum.ScreenInsets.None,DisplayOrder = options.DisplayOrder or 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Global},nil)
    self.Scope:Add(self.Screen)
    self.Root = F.new('CanvasGroup',{Name = 'Desktop',Size = UDim2.fromScale(1,1),BackgroundTransparency = 1,
        BorderSizePixel = 0,ZIndex = 1},self.Screen)
    self.UIScale = F.new('UIScale',{Scale = 1},self.Root)
    self.Main = F.chrome(self.Root,'Menu',self.Theme.WindowSize,self.Theme)
    self.Main.Position = UDim2.fromOffset(30,50)
    local header = F.button(self.Main,'DragTitle',6,6,510,16,self.Theme)
    local brand = F.text(header,options.Title or 'veyra',0,-5,510,20,self.Theme,6)
    brand.TextXAlignment = Enum.TextXAlignment.Center
    brand.TextColor3 = self.Accent
    brand.TextStrokeTransparency = 0
    Input.move(header,self.Main,self,self.Scope)
    local panel = F.frame(self.Main,'ContentBorder',20,44,482,500,self.Theme.Black)
    local inner = F.frame(panel,'Inset',1,1,480,498,self.Theme.Border)
    F.frame(inner,'ContentFace',1,1,478,496,self.Theme.Face)
    self.TabBar = F.frame(self.Main,'Tabs',17,20,488,20,self.Theme.Face,5)
    self.TabBar.BackgroundTransparency = 1
    local opener = F.button(self.Screen,'MenuToggle',8,8,62,24,self.Theme,'menu')
    opener.BackgroundTransparency = 0.1; opener.BackgroundColor3 = self.Theme.Face; opener.ZIndex = 200
    F.stroke(opener,self.Theme.Outer)
    self.Scope:Add(opener.Activated:Connect(function() self:SetVisible(not self.Visible) end))
    self.Scope:Add(UIS.InputBegan:Connect(function(input,processed)
        if self.Capture then
            local h = self.Capture
            local key
            if input.KeyCode == Enum.KeyCode.Escape then key = 'none'
            elseif input.UserInputType == Enum.UserInputType.Keyboard then key = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then key = input.UserInputType.Name end
            if key then self.LastCapturedInput = input; self.CaptureCancel(); h:Set(key) end
            return
        end
        if input.KeyCode == Enum.KeyCode.Escape and self.Popup then self:ClosePopup(); return end
        if not processed and not UIS:GetFocusedTextBox() and input.KeyCode == (options.ToggleKey or Enum.KeyCode.Insert) then
            self:SetVisible(not self.Visible)
        end
    end))
    local function fit()
        self:ClosePopup()
        local size = self.Screen.AbsoluteSize
        if size.X <= 0 or size.Y <= 0 then return end
        self.Scale = math.max(0.2,math.min(options.Scale or 1,(size.X-40)/842,(size.Y-70)/560))
        self.UIScale.Scale = self.Scale
        self.Root.Size = UDim2.fromOffset(size.X/self.Scale,size.Y/self.Scale)
        for _,frame in ipairs({self.Main,self.Preview and self.Preview.Frame}) do
            if frame then
                frame.Position = UDim2.fromOffset(math.clamp(frame.Position.X.Offset,0,math.max(0,size.X/self.Scale-frame.Size.X.Offset)),
                    math.clamp(frame.Position.Y.Offset,0,math.max(0,size.Y/self.Scale-frame.Size.Y.Offset)))
            end
        end
    end
    self.Scope:Add(self.Screen:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit))
    self.Scope:Add(self.AccentChanged:Connect(function(color)
        brand.TextColor3 = color
        self:UpdateTabs()
    end))
    self.Scope:Add(self.Store.Changed:Connect(function(id,value)
        if id == 'accent' and not self.Store:Get('rainbow') then self:SetAccent(value.Color) end
        if id == 'rainbow' and not value then
            local accent = self.Store:Get('accent'); self:SetAccent(accent and accent.Color or self.Theme.Accent)
        end
    end))
    local tick = 0
    self.Scope:Add(RunService.RenderStepped:Connect(function(dt)
        tick = tick+dt
        if self.Visible and self.Store:Get('rainbow') and tick > 1/30 then
            tick = 0; self:SetAccent(Color3.fromHSV((os.clock()*0.1)%1,1,0.85))
        end
    end))
    self.Fit = fit
    self.Screen.Parent = options.Parent or defaultParent()
    fit()
    self.Scope:Add(function() self:ClosePopup(); if self.Fade then self.Fade:Cancel() end end)
    return self
end
function Window:SetAccent(color)
    if self.Accent == color then return end
    self.Accent = color; self.AccentChanged:Fire(color)
end
function Window:UpdateTabs()
    local count = #self.Tabs
    if count == 0 then return end
    local width = 488/count
    for index,tab in ipairs(self.Tabs) do
        tab.Button.Position = UDim2.fromOffset((index-1)*width,0)
        tab.Button.Size = UDim2.fromOffset(width-4,20)
        tab.Line.Size = UDim2.new(1,0,0,self.SelectedTab == tab and 3 or 2)
        tab.Line.BackgroundColor3 = self.SelectedTab == tab and self.Accent or Color3.fromRGB(90,90,94)
    end
end
function Window:Tab(title)
    local tab = Tab.new(self,title)
    tab.Button = F.button(self.TabBar,title,0,0,70,20,self.Theme,title)
    tab.Button.TextTruncate = Enum.TextTruncate.AtEnd
    tab.Line = F.frame(tab.Button,'Underline',0,18,70,2,self.Theme.Off,6)
    F.gradient(tab.Line,Color3.new(1,1,1),Color3.fromRGB(160,160,160))
    table.insert(self.Tabs,tab)
    self.Scope:Add(tab.Button.Activated:Connect(function() self:SelectTab(tab) end))
    if not self.SelectedTab then self:SelectTab(tab) end
    self:UpdateTabs()
    return tab
end
function Window:SelectTab(tab)
    if type(tab) == 'string' then
        local name = tab; tab = nil
        for _,candidate in ipairs(self.Tabs) do if candidate.Title == name then tab = candidate; break end end
    end
    assert(tab and table.find(self.Tabs,tab),'Unknown tab')
    self:ClosePopup()
    if self.CaptureCancel then self.CaptureCancel() end
    self.SelectedTab = tab
    for _,item in ipairs(self.Tabs) do item.Page.Visible = item == tab end
    self:UpdateTabs()
end
function Window:OpenPopup(owner,anchor,width,height)
    self:ClosePopup()
    local scope = Janitor.new()
    self.PopupScope,self.PopupOwner = scope,owner
    local blocker = F.button(self.Screen,'PopupDismiss',0,0,0,0,self.Theme)
    blocker.Size = UDim2.fromScale(1,1); blocker.ZIndex = 100
    scope:Add(blocker)
    local screen = self.Screen.AbsoluteSize
    local x = math.clamp(anchor.AbsolutePosition.X,0,math.max(0,screen.X-width*self.Scale-2))
    local y = anchor.AbsolutePosition.Y+anchor.AbsoluteSize.Y+2
    if y+height*self.Scale > screen.Y then y = math.max(0,anchor.AbsolutePosition.Y-height*self.Scale-2) end
    local popup = F.frame(self.Screen,'Popup',x,y,width,height,self.Theme.Control,101)
    F.new('UIScale',{Scale = self.Scale},popup)
    F.stroke(popup,self.Theme.Black)
    scope:Add(popup); scope:Add(blocker.Activated:Connect(function() self:ClosePopup() end))
    self.Popup = popup
    return popup,scope
end
function Window:ClosePopup()
    local scope = self.PopupScope
    self.PopupScope,self.PopupOwner,self.Popup = nil,nil,nil
    if scope then scope:Destroy() end
end
function Window:SetVisible(visible)
    if self.Destroyed then return end
    self.Visible = visible
    self:ClosePopup()
    if self.CaptureCancel then self.CaptureCancel() end
    if self.Fade then self.Fade:Cancel() end
    self.Root.Visible = true
    local speed = self.Store:Get('fade_speed') or 5
    local duration = speed == 0 and 0 or 0.5/speed
    self.Fade = TweenService:Create(self.Root,TweenInfo.new(duration),{GroupTransparency = visible and 0 or 1})
    self.Fade:Play()
    -- A cancelled tween must not hide a newly reopened window.
    task.delay(duration,function() if not self.Destroyed and self.Visible == false then self.Root.Visible = false end end)
end
function Window:Use(name,factory)
    self.Modules = self.Modules or {}
    assert(self.Modules[name] == nil,'Module already mounted: '..name)
    assert(type(factory) == 'function','Module must return a function(window)')
    local value = factory(self)
    self.Modules[name] = value or true
    if type(value) == 'function' or typeof(value) == 'RBXScriptConnection' or (type(value) == 'table' and value.Destroy) then
        self.Scope:Add(value)
    end
    return value
end
function Window:Get(id) return self.Store:Get(id) end
function Window:Set(id,value) self.Store:Set(id,value) end
function Window:OnChanged(callback) return self.Scope:Add(self.Store.Changed:Connect(callback)) end
function Window:ExportConfig() return self.Store:Export() end
function Window:ImportConfig(json) self.Store:Import(json) end
function Window:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    if self.Preview then self.Preview:Destroy() end
    if self.CaptureCancel then self.CaptureCancel() end
    self.Scope:Destroy()
end
return Window
