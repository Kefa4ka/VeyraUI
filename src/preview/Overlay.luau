local F = require(script.Parent.Parent.core.Factory)
local Input = require(script.Parent.Parent.core.Input)
local Overlay = {}
Overlay.__index = Overlay
function Overlay.new(preview)
    local w,t = preview.Window,preview.Window.Theme
    local root = F.frame(preview.Area,'Overlay',0,0,preview.Area.Size.X.Offset,preview.Area.Size.Y.Offset,t.Face,12)
    root.BackgroundTransparency = 1
    local self = setmetatable({Preview = preview,Window = w,Root = root,Offsets = {},Elements = {},BoxLines = {},Skeleton = {}},Overlay)
    for i = 1,8 do self.BoxLines[i] = F.frame(root,'Box'..i,0,0,1,1,t.Text,12) end
    local function element(name,text,width,height)
        local frame = F.frame(root,name,0,0,width,height,t.Face,13)
        frame.BackgroundTransparency = 1; frame.Active = true
        local label = F.text(frame,text,0,0,width,height,t,14)
        label.TextSize = 10; label.TextStrokeTransparency = 0.3
        label.TextXAlignment = Enum.TextXAlignment.Center
        self.Elements[name] = {Frame = frame,Label = label}
        self.Offsets[name] = Vector2.zero
        local start
        Input.drag(frame,preview.Scope,function(_,delta)
            local areaSize = root.AbsoluteSize / w.Scale
            local offset = start+delta/w.Scale
            local anchor = self.Elements[name].Anchor or Vector2.zero
            self.Offsets[name] = Vector2.new(math.clamp(offset.X,-anchor.X,areaSize.X-width-anchor.X),
                math.clamp(offset.Y,-anchor.Y,areaSize.Y-height-anchor.Y))
        end,function() start = self.Offsets[name]; preview.LastInteraction = os.clock() end,function()
            preview.LastInteraction = os.clock()
        end)
        return self.Elements[name]
    end
    element('Name','preview player',120,13)
    local health = element('Health','82',20,13)
    health.Bar = F.frame(root,'HealthTrack',0,0,2,100,t.Black,12)
    health.Fill = F.frame(health.Bar,'Health',0,0,2,82,Color3.fromRGB(80,180,205),13)
    element('Flags','$1334\nstatus\nflex',65,36)
    element('Weapon','AK-47',90,14)
    element('Distance','71m',70,13)
    self.Ammo = F.frame(root,'Ammo',0,0,40,2,Color3.fromRGB(80,160,220),12)
    for i = 1,12 do self.Skeleton[i] = F.frame(root,'Bone'..i,0,0,1,1,t.Text,13) end
    return self
end
function Overlay:SetData(data)
    self.Data = data
end
local function line(frame,a,b,color)
    local delta = b-a
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.Position = UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
    frame.Size = UDim2.fromOffset(delta.Magnitude,1)
    frame.Rotation = math.deg(math.atan2(delta.Y,delta.X))
    frame.BackgroundColor3 = color
end
function Overlay:Update(box)
    local w,p = self.Window,self.Preview
    local state = w.Store
    local data = self.Data or {}
    local function get(id)
        local bind = p.Bindings[id] or id
        if state.definitions[bind] then return state:Get(bind) end
        return p.Display[id]
    end
    local function enabled(id) return get(id) == true end
    local function color(id)
        local value = get(id)
        return value and value.Color or w.Theme.Text,value and value.Alpha or 1
    end
    local left,top,right,bottom = box[1],box[2],box[3],box[4]
    local width,height = right-left,bottom-top
    local boxColor,boxAlpha = color('player_enemy_box_color')
    local corner = get('player_box_type') == 'cornered'
    local points
    if corner then
        local x,y = math.min(14,width/3),math.min(18,height/4)
        points = {{left,top,left+x,top},{left,top,left,top+y},{right-x,top,right,top},{right,top,right,top+y},
            {left,bottom,left+x,bottom},{left,bottom-y,left,bottom},{right-x,bottom,right,bottom},{right,bottom-y,right,bottom}}
    else
        points = {{left,top,right,top},{right,top,right,bottom},{left,bottom,right,bottom},{left,top,left,bottom}}
    end
    for i,frame in ipairs(self.BoxLines) do
        frame.Visible = enabled('player_enemy_box') and points[i] ~= nil
        if points[i] then
            local s = points[i]; line(frame,Vector2.new(s[1],s[2]),Vector2.new(s[3],s[4]),boxColor)
            frame.BackgroundTransparency = 1-boxAlpha
        end
    end
    local center = (left+right)/2
    local anchors = {Name = Vector2.new(center-60,top-15),Health = Vector2.new(left-23,(top+bottom)/2-6),
        Flags = Vector2.new(right+4,top),Weapon = Vector2.new(center-45,bottom+3),Distance = Vector2.new(center-35,bottom+19)}
    local ids = {Name = 'player_name',Health = 'player_health',Flags = 'player_flags',Weapon = 'player_weapon',Distance = 'player_distance'}
    for name,element in pairs(self.Elements) do
        element.Frame.Visible = enabled(ids[name])
        element.Anchor = anchors[name]
        local pos = anchors[name]+self.Offsets[name]
        element.Frame.Position = UDim2.fromOffset(pos.X,pos.Y)
    end
    local nameColor,nameAlpha = color('player_name_color')
    self.Elements.Name.Label.Text = data.Name or 'preview player'
    self.Elements.Name.Label.TextColor3 = nameColor; self.Elements.Name.Label.TextTransparency = 1-nameAlpha
    local distanceColor,distanceAlpha = color('player_distance_color')
    self.Elements.Distance.Label.Text = tostring(data.Distance or 71)..'m'
    self.Elements.Distance.Label.TextColor3 = distanceColor; self.Elements.Distance.Label.TextTransparency = 1-distanceAlpha
    local hp = math.clamp(data.Health or 82,0,100)
    local health = self.Elements.Health
    health.Label.Text = tostring(hp)
    local healthOffset = self.Offsets.Health
    health.Bar.Visible = enabled('player_health')
    health.Bar.Position = UDim2.fromOffset(left-4+healthOffset.X,top+healthOffset.Y)
    health.Bar.Size = UDim2.fromOffset(2,height)
    health.Fill.Position = UDim2.fromScale(0,1-hp/100); health.Fill.Size = UDim2.fromScale(1,hp/100)
    local selection = get('player_flags_selection') or {'money'}
    local flags = {}
    for _,flag in ipairs(selection) do table.insert(flags,flag == 'money' and ('$'..tostring(data.Money or 1334)) or flag) end
    self.Elements.Flags.Label.Text = table.concat(flags,'\n')
    self.Elements.Flags.Label.TextXAlignment = Enum.TextXAlignment.Left
    local weaponModes = get('player_weapon_display') or {'icon','text'}
    local text = {}
    if table.find(weaponModes,'icon') then table.insert(text,'━╋━') end
    if table.find(weaponModes,'text') then table.insert(text,data.Weapon or 'AK-47') end
    self.Elements.Weapon.Label.Text = table.concat(text,' ')
    self.Ammo.Visible = enabled('player_ammo')
    self.Ammo.Position = UDim2.fromOffset(left,bottom+1)
    self.Ammo.Size = UDim2.fromOffset(width*math.clamp(data.Ammo or 0.72,0,1),2)
    local joints = {{.5,.1},{.5,.25},{.5,.5},{.28,.27},{.15,.44},{.72,.27},{.85,.44},{.38,.64},{.32,.82},{.29,.98},{.62,.64},{.68,.82},{.71,.98}}
    local links = {{1,2},{2,3},{2,4},{4,5},{2,6},{6,7},{3,8},{8,9},{9,10},{3,11},{11,12},{12,13}}
    for i,pair in ipairs(links) do
        local frame = self.Skeleton[i]; frame.Visible = enabled('player_skeleton')
        if frame.Visible then
            local a,b = joints[pair[1]],joints[pair[2]]
            line(frame,Vector2.new(left+a[1]*width,top+a[2]*height),Vector2.new(left+b[1]*width,top+b[2]*height),w.Theme.Text)
        end
    end
end
return Overlay
