--[[
    mylib.lua — Roblox UI Library
    Theme: Bloody Dark (ported from mylib_v4_final.html)
    API:
        local Library = loadstring(game:HttpGet("..."))()
        local UI      = Library._new()
        local Cat     = UI:create_category("Name")
        local Tab     = Cat:create_tab("Name", "ImageId")
        local Group   = Tab:create_group("Name", "left"|"right")
        Group:create_toggle(id, { title, default, callback })
        Group:create_dropdown(id, { title, options, default, callback })
        Group:create_slider(id, { title, minimum, maximum, default, rounding, callback })
]]

-- ─── Colour palette (hex → RGB) ────────────────────────────────────────────
local function hex(h)
    -- *translating css hex into Color3 without a helper lib*
    h = h:gsub("#","")
    return Color3.fromRGB(
        tonumber(h:sub(1,2),16),
        tonumber(h:sub(3,4),16),
        tonumber(h:sub(5,6),16)
    )
end

local C = {
    bg0  = hex("#040000"), bg1  = hex("#080000"), bg2 = hex("#0e0000"),
    bg3  = hex("#130000"), bg4  = hex("#190000"),
    r0   = hex("#2a0000"), r1   = hex("#480000"), r2  = hex("#680000"),
    r3   = hex("#8c0000"), r4   = hex("#b52a2a"), r5  = hex("#d94040"),
    r6   = hex("#f05050"), r7   = hex("#ff7070"),
    brd0 = hex("#160000"), brd1 = hex("#220000"), brd2 = hex("#330000"),
    t1   = hex("#4a1a1a"), t2   = hex("#7a3535"), t3   = hex("#a86060"),
    t4   = hex("#d09090"), t5   = hex("#ecc0c0"), th   = hex("#fff5f5"),
    green = hex("#2a8a2a"),
}

-- ─── Utility ────────────────────────────────────────────────────────────────
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService     = cloneref(game:GetService("TweenService"))
local CoreGui          = cloneref(game:GetService("CoreGui"))
local RunService       = cloneref(game:GetService("RunService"))

local function tween(obj, props, t, style, dir)
    -- *smooth tween wrapper, style defaults to Quad Out*
    local ti = TweenInfo.new(
        t or 0.18,
        Enum.EasingStyle[style or "Quad"],
        Enum.EasingDirection[dir or "Out"]
    )
    TweenService:Create(obj, ti, props):Play()
end

local function make(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(r, parent)
    return make("UICorner", {CornerRadius = UDim.new(0, r or 5)}, parent)
end

local function stroke(color, thickness, parent)
    return make("UIStroke", {Color = color, Thickness = thickness or 1}, parent)
end

local function padding(t,b,l,r, parent)
    return make("UIPadding",{
        PaddingTop    = UDim.new(0,t),
        PaddingBottom = UDim.new(0,b),
        PaddingLeft   = UDim.new(0,l),
        PaddingRight  = UDim.new(0,r),
    }, parent)
end

-- ─── Notification system ────────────────────────────────────────────────────
local notifHolder
local function ensureNotifHolder()
    if notifHolder and notifHolder.Parent then return notifHolder end
    local sg = CoreGui:FindFirstChild("mylib_Notifications")
    if not sg then
        sg = make("ScreenGui",{
            Name            = "mylib_Notifications",
            ResetOnSpawn    = false,
            IgnoreGuiInset  = true,
            ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        }, CoreGui)
    end
    local h = sg:FindFirstChild("Holder")
    if not h then
        h = make("Frame",{
            Name               = "Holder",
            AnchorPoint        = Vector2.new(1,0),
            Position           = UDim2.new(1,-18,0,18),
            Size               = UDim2.fromOffset(300,0),
            BackgroundTransparency = 1,
        }, sg)
        local l = make("UIListLayout",{
            Padding                = UDim.new(0,8),
            HorizontalAlignment    = Enum.HorizontalAlignment.Right,
            VerticalAlignment      = Enum.VerticalAlignment.Top,
            SortOrder              = Enum.SortOrder.LayoutOrder,
        }, h)
        l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            h.Size = UDim2.new(0,300,0,l.AbsoluteContentSize.Y+4)
        end)
    end
    notifHolder = h
    return h
end

local function Notify(title, content, duration)
    -- *notifications: 320px card, TweenSize in/out, red top accent bar*
    duration = duration or 3
    task.spawn(function()
        pcall(function()
            local h = ensureNotifHolder()

            local card = make("Frame",{
                Name               = "Notif",
                Size               = UDim2.fromOffset(300,0),
                BackgroundColor3   = C.bg2,
                BorderSizePixel    = 0,
                ClipsDescendants   = true,
                BackgroundTransparency = 0.06,
            }, h)
            corner(8, card)
            stroke(C.r2, 1, card)

            -- accent bar top
            make("Frame",{
                Size             = UDim2.new(1,0,0,2),
                BackgroundColor3 = C.r5,
                BorderSizePixel  = 0,
            }, card)

            local inner = make("Frame",{
                Size               = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
            }, card)
            padding(8,8,12,12, inner)

            local layout = make("UIListLayout",{
                Padding           = UDim.new(0,3),
                SortOrder         = Enum.SortOrder.LayoutOrder,
                FillDirection     = Enum.FillDirection.Vertical,
            }, inner)

            make("TextLabel",{
                Size               = UDim2.new(1,0,0,16),
                BackgroundTransparency = 1,
                Text               = tostring(title),
                TextColor3         = C.r6,
                TextSize           = 12,
                Font               = Enum.Font.GothamBold,
                TextXAlignment     = Enum.TextXAlignment.Left,
                RichText           = true,
                LayoutOrder        = 0,
            }, inner)

            local contentLbl = make("TextLabel",{
                Size               = UDim2.new(1,0,0,0),
                BackgroundTransparency = 1,
                Text               = tostring(content),
                TextColor3         = C.t4,
                TextSize           = 11,
                Font               = Enum.Font.Gotham,
                TextXAlignment     = Enum.TextXAlignment.Left,
                TextWrapped        = true,
                LayoutOrder        = 1,
                AutomaticSize      = Enum.AutomaticSize.Y,
            }, inner)

            -- measure height after content autosize
            task.wait()
            local h_content = layout.AbsoluteContentSize.Y + 20
            card.Size = UDim2.fromOffset(300, h_content)

            -- slide in
            card.Position = UDim2.new(1,300,0,0)
            tween(card, {Position = UDim2.new(0,0,0,0)}, 0.3, "Back","Out")

            task.wait(duration)

            tween(card, {Position = UDim2.new(1,320,0,0)}, 0.25,"Quad","In")
            task.wait(0.3)
            card:Destroy()
        end)
    end)
end

-- ─── Toggle widget ──────────────────────────────────────────────────────────
local function buildToggle(id, cfg, parent)
    -- *toggle: 32x17 pill, red when on, animated knob*
    local state = cfg.default or false

    local row = make("Frame",{
        Size               = UDim2.new(1,0,0,28),
        BackgroundColor3   = C.bg2,
        BorderSizePixel    = 0,
    }, parent)
    corner(5, row)
    stroke(C.brd0, 1, row)
    padding(0,0,10,10, row)

    local lbl = make("TextLabel",{
        Size               = UDim2.new(1,-44,1,0),
        BackgroundTransparency = 1,
        Text               = cfg.title or id,
        TextColor3         = C.t4,
        TextSize           = 11,
        Font               = Enum.Font.Gotham,
        TextXAlignment     = Enum.TextXAlignment.Left,
    }, row)

    local pill = make("Frame",{
        AnchorPoint        = Vector2.new(1,0.5),
        Position           = UDim2.new(1,0,0.5,0),
        Size               = UDim2.fromOffset(32,17),
        BackgroundColor3   = state and C.r3 or C.brd1,
        BorderSizePixel    = 0,
    }, row)
    corner(9, pill)
    stroke(state and C.r4 or C.brd2, 1, pill)

    local knob = make("Frame",{
        Position           = UDim2.fromOffset(state and 15 or 2, 2),
        Size               = UDim2.fromOffset(11,11),
        BackgroundColor3   = state and C.r7 or C.t2,
        BorderSizePixel    = 0,
    }, pill)
    corner(6, knob)

    local function setState(v)
        -- *knob slides, pill recolours*
        state = v
        tween(pill,  {BackgroundColor3 = v and C.r3 or C.brd1}, 0.18)
        tween(knob,  {
            Position         = UDim2.fromOffset(v and 15 or 2, 2),
            BackgroundColor3 = v and C.r7 or C.t2,
        }, 0.18)
        if cfg.callback then
            task.spawn(cfg.callback, state)
        end
    end

    pill.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            setState(not state)
        end
    end)

    -- hover glow
    row.MouseEnter:Connect(function()
        tween(row, {BackgroundColor3 = C.bg3}, 0.15)
    end)
    row.MouseLeave:Connect(function()
        tween(row, {BackgroundColor3 = C.bg2}, 0.15)
    end)

    return { set = setState, get = function() return state end }
end

-- ─── Dropdown widget ─────────────────────────────────────────────────────────
local function buildDropdown(id, cfg, parent)
    -- *dropdown: button that spawns a floating option list above siblings*
    local options = cfg.options or {}
    local selected = cfg.default or options[1] or ""
    local open = false

    local wrap = make("Frame",{
        Size               = UDim2.new(1,0,0,46),
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        ClipsDescendants   = false,
    }, parent)

    local lbl = make("TextLabel",{
        Size               = UDim2.new(1,0,0,14),
        BackgroundTransparency = 1,
        Text               = cfg.title or id,
        TextColor3         = C.t3,
        TextSize           = 10,
        Font               = Enum.Font.Gotham,
        TextXAlignment     = Enum.TextXAlignment.Left,
    }, wrap)

    local btn = make("TextButton",{
        Position           = UDim2.fromOffset(0,16),
        Size               = UDim2.new(1,0,0,26),
        BackgroundColor3   = C.bg0,
        BorderSizePixel    = 0,
        Text               = "",
        AutoButtonColor    = false,
    }, wrap)
    corner(5, btn)
    stroke(C.brd1, 1, btn)
    padding(0,0,8,28, btn)

    local selLbl = make("TextLabel",{
        Size               = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text               = selected,
        TextColor3         = C.t5,
        TextSize           = 11,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Left,
    }, btn)

    -- chevron
    local chev = make("TextLabel",{
        AnchorPoint        = Vector2.new(1,0.5),
        Position           = UDim2.new(1,-8,0.5,0),
        Size               = UDim2.fromOffset(14,14),
        BackgroundTransparency = 1,
        Text               = "▾",
        TextColor3         = C.r4,
        TextSize           = 13,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Center,
    }, btn)

    -- floating list
    local list = make("Frame",{
        Position           = UDim2.new(0,0,1,2),
        Size               = UDim2.new(1,0,0,0),
        BackgroundColor3   = C.bg3,
        BorderSizePixel    = 0,
        ClipsDescendants   = true,
        ZIndex             = 100,
        Visible            = false,
    }, btn)
    corner(5, list)
    stroke(C.r1, 1, list)

    local listLayout = make("UIListLayout",{
        SortOrder          = Enum.SortOrder.LayoutOrder,
        Padding            = UDim.new(0,1),
    }, list)

    local function closeList()
        open = false
        tween(chev, {Rotation = 0}, 0.15)
        tween(list, {Size = UDim2.new(1,0,0,0)}, 0.15)
        task.wait(0.15)
        list.Visible = false
    end

    local function openList()
        open = true
        list.Visible = true
        tween(chev, {Rotation = 180}, 0.15)
        local h = #options * 26 + 4
        tween(list, {Size = UDim2.new(1,0,0,h)}, 0.18)
    end

    -- populate list items
    for i, opt in ipairs(options) do
        local item = make("TextButton",{
            Size               = UDim2.new(1,0,0,26),
            BackgroundColor3   = C.bg3,
            BorderSizePixel    = 0,
            Text               = "",
            AutoButtonColor    = false,
            LayoutOrder        = i,
            ZIndex             = 101,
        }, list)
        padding(0,0,8,8, item)

        local itemLbl = make("TextLabel",{
            Size               = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            Text               = opt,
            TextColor3         = C.t4,
            TextSize           = 11,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
            ZIndex             = 102,
        }, item)

        item.MouseEnter:Connect(function()
            tween(item, {BackgroundColor3 = C.r0}, 0.1)
            tween(itemLbl, {TextColor3 = C.th}, 0.1)
        end)
        item.MouseLeave:Connect(function()
            tween(item, {BackgroundColor3 = C.bg3}, 0.1)
            tween(itemLbl, {TextColor3 = C.t4}, 0.1)
        end)

        item.MouseButton1Click:Connect(function()
            selected = opt
            selLbl.Text = opt
            closeList()
            if cfg.callback then task.spawn(cfg.callback, opt) end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        if open then closeList() else openList() end
    end)

    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = C.bg2}, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = C.bg0}, 0.12)
    end)

    return {
        set = function(v)
            selected = v
            selLbl.Text = v
            if cfg.callback then task.spawn(cfg.callback, v) end
        end,
        get = function() return selected end,
    }
end

-- ─── Slider widget ───────────────────────────────────────────────────────────
local function buildSlider(id, cfg, parent)
    -- *slider: full-width track, draggable thumb, live value label*
    local min  = cfg.minimum or 0
    local max  = cfg.maximum or 100
    local val  = cfg.default or min
    local rnd  = cfg.rounding ~= false

    local wrap = make("Frame",{
        Size               = UDim2.new(1,0,0,44),
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
    }, parent)

    local header = make("Frame",{
        Size               = UDim2.new(1,0,0,16),
        BackgroundTransparency = 1,
    }, wrap)

    make("TextLabel",{
        Size               = UDim2.new(0.7,0,1,0),
        BackgroundTransparency = 1,
        Text               = cfg.title or id,
        TextColor3         = C.t4,
        TextSize           = 11,
        Font               = Enum.Font.Gotham,
        TextXAlignment     = Enum.TextXAlignment.Left,
    }, header)

    local valLbl = make("TextLabel",{
        Size               = UDim2.new(0.3,0,1,0),
        Position           = UDim2.fromOffset(0,0),
        AnchorPoint        = Vector2.new(1,0),
        BackgroundTransparency = 1,
        Text               = tostring(rnd and math.round(val) or val),
        TextColor3         = C.r5,
        TextSize           = 11,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Right,
        AnchorPoint        = Vector2.new(1,0),
        Position           = UDim2.new(1,0,0,0),
    }, header)

    local track = make("Frame",{
        Position           = UDim2.fromOffset(0,22),
        Size               = UDim2.new(1,0,0,4),
        BackgroundColor3   = C.brd1,
        BorderSizePixel    = 0,
    }, wrap)
    corner(2, track)
    stroke(C.brd0, 1, track)

    local fill = make("Frame",{
        Size               = UDim2.new((val - min)/(max - min),0,1,0),
        BackgroundColor3   = C.r4,
        BorderSizePixel    = 0,
    }, track)
    corner(2, fill)

    local thumb = make("Frame",{
        AnchorPoint        = Vector2.new(0.5,0.5),
        Position           = UDim2.new((val - min)/(max - min),0,0.5,0),
        Size               = UDim2.fromOffset(14,14),
        BackgroundColor3   = C.r4,
        BorderSizePixel    = 0,
        ZIndex             = 5,
    }, track)
    corner(7, thumb)
    stroke(C.r6, 2, thumb)

    local dragging = false

    local function updateFromX(absX)
        local trackStart = track.AbsolutePosition.X
        local trackW     = track.AbsoluteSize.X
        local pct        = math.clamp((absX - trackStart) / trackW, 0, 1)
        val = min + pct * (max - min)
        if rnd then val = math.round(val) end
        val = math.clamp(val, min, max)
        local fp = (val - min) / (max - min)
        fill.Size     = UDim2.new(fp, 0, 1, 0)
        thumb.Position = UDim2.new(fp, 0, 0.5, 0)
        valLbl.Text   = tostring(val)
        if cfg.callback then task.spawn(cfg.callback, val) end
    end

    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            tween(thumb, {Size = UDim2.fromOffset(16,16)}, 0.1)
        end
    end)

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(inp.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or
                         inp.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(inp.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                tween(thumb, {Size = UDim2.fromOffset(14,14)}, 0.1)
            end
        end
    end)

    return {
        set = function(v)
            val = math.clamp(v, min, max)
            if rnd then val = math.round(val) end
            local fp = (val - min) / (max - min)
            fill.Size      = UDim2.new(fp,0,1,0)
            thumb.Position = UDim2.new(fp,0,0.5,0)
            valLbl.Text    = tostring(val)
        end,
        get = function() return val end,
    }
end

-- ─── Group ───────────────────────────────────────────────────────────────────
local function buildGroup(name, side, parent)
    -- *group: titled card, stacks widgets vertically inside*
    local frame = make("Frame",{
        Size               = UDim2.new(0.5,-5,0,0),
        BackgroundColor3   = C.bg1,
        BorderSizePixel    = 0,
        AutomaticSize      = Enum.AutomaticSize.Y,
        LayoutOrder        = (side == "right") and 1 or 0,
    }, parent)
    corner(7, frame)
    stroke(C.brd0, 1, frame)
    padding(8,8,8,8, frame)

    local header = make("TextLabel",{
        Size               = UDim2.new(1,0,0,18),
        BackgroundTransparency = 1,
        Text               = name,
        TextColor3         = C.r3,
        TextSize           = 9,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Left,
        TextTransparency   = 0,
        LayoutOrder        = -1,
    }, frame)

    -- separator under header
    local sep = make("Frame",{
        Size               = UDim2.new(1,0,0,1),
        BackgroundColor3   = C.brd0,
        BorderSizePixel    = 0,
        LayoutOrder        = 0,
    }, frame)

    local content = make("Frame",{
        Size               = UDim2.new(1,0,0,0),
        BackgroundTransparency = 1,
        AutomaticSize      = Enum.AutomaticSize.Y,
        LayoutOrder        = 1,
    }, frame)

    local listLayout = make("UIListLayout",{
        Padding            = UDim.new(0,5),
        SortOrder          = Enum.SortOrder.LayoutOrder,
    }, content)

    local grpLayout = make("UIListLayout",{
        Padding            = UDim.new(0,5),
        SortOrder          = Enum.SortOrder.LayoutOrder,
    }, frame)

    -- *widgets register into content frame*
    local G = {}

    function G:create_toggle(id, cfg)
        return buildToggle(id, cfg, content)
    end

    function G:create_dropdown(id, cfg)
        return buildDropdown(id, cfg, content)
    end

    function G:create_slider(id, cfg)
        return buildSlider(id, cfg, content)
    end

    return G
end

-- ─── Tab ─────────────────────────────────────────────────────────────────────
local function buildTab(name, imageId, tabBar, bodyContainer, tabList)
    -- *tab button in bar + two-column group container*
    local tabBtn = make("TextButton",{
        Size               = UDim2.new(0,0,1,0),
        AutomaticSize      = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        Text               = "",
        AutoButtonColor    = false,
    }, tabBar)
    padding(0,0,12,12, tabBtn)

    -- tab icon (if provided)
    if imageId and imageId ~= "" then
        make("ImageLabel",{
            Size               = UDim2.fromOffset(14,14),
            BackgroundTransparency = 1,
            Image              = "rbxassetid://" .. imageId,
            Position           = UDim2.fromOffset(12,7),
        }, tabBtn)
    end

    local tabLbl = make("TextLabel",{
        Size               = UDim2.new(1,imageId ~= "" and -18 or 0,1,0),
        Position           = UDim2.fromOffset(imageId ~= "" and 30 or 0, 0),
        BackgroundTransparency = 1,
        Text               = name,
        TextColor3         = C.t2,
        TextSize           = 11,
        Font               = Enum.Font.Gotham,
        TextXAlignment     = Enum.TextXAlignment.Center,
    }, tabBtn)

    -- underline bar
    local underline = make("Frame",{
        AnchorPoint        = Vector2.new(0,1),
        Position           = UDim2.new(0,0,1,0),
        Size               = UDim2.new(1,0,0,2),
        BackgroundColor3   = C.r5,
        BorderSizePixel    = 0,
        Visible            = false,
    }, tabBtn)

    -- body pane (two-column grid)
    local pane = make("ScrollingFrame",{
        Size               = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.r1,
        CanvasSize         = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible            = false,
    }, bodyContainer)
    padding(10,10,10,10, pane)

    local grid = make("Frame",{
        Size               = UDim2.new(1,0,0,0),
        BackgroundTransparency = 1,
        AutomaticSize      = Enum.AutomaticSize.Y,
    }, pane)

    local gridLayout = make("UIGridLayout",{
        CellSize           = UDim2.new(0.5,-5,0,0),
        CellPadding        = UDim2.fromOffset(10,10),
        FillDirectionMaxCells = 2,
        SortOrder          = Enum.SortOrder.LayoutOrder,
    }, grid)

    -- disable grid for auto-height groups
    gridLayout:Destroy()
    local twoCol = make("Frame",{
        Size               = UDim2.new(1,0,0,0),
        BackgroundTransparency = 1,
        AutomaticSize      = Enum.AutomaticSize.Y,
    }, pane)

    local colLayout = make("UIListLayout",{
        FillDirection      = Enum.FillDirection.Horizontal,
        Padding            = UDim.new(0,10),
        VerticalAlignment  = Enum.VerticalAlignment.Top,
        SortOrder          = Enum.SortOrder.LayoutOrder,
    }, twoCol)

    -- left column
    local leftCol = make("Frame",{
        Size               = UDim2.new(0.5,-5,0,0),
        BackgroundTransparency = 1,
        AutomaticSize      = Enum.AutomaticSize.Y,
        LayoutOrder        = 0,
    }, twoCol)
    local leftLayout = make("UIListLayout",{
        Padding            = UDim.new(0,8),
        SortOrder          = Enum.SortOrder.LayoutOrder,
    }, leftCol)

    -- right column
    local rightCol = make("Frame",{
        Size               = UDim2.new(0.5,-5,0,0),
        BackgroundTransparency = 1,
        AutomaticSize      = Enum.AutomaticSize.Y,
        LayoutOrder        = 1,
    }, twoCol)
    local rightLayout = make("UIListLayout",{
        Padding            = UDim.new(0,8),
        SortOrder          = Enum.SortOrder.LayoutOrder,
    }, rightCol)

    local T = { _pane = pane, _btn = tabBtn }

    function T:activate()
        pane.Visible     = true
        underline.Visible = true
        tween(tabLbl, {TextColor3 = C.r6}, 0.15)
    end

    function T:deactivate()
        pane.Visible     = false
        underline.Visible = false
        tween(tabLbl, {TextColor3 = C.t2}, 0.15)
    end

    function T:create_group(name, side)
        -- *groups go left or right col*
        local col = (side == "right") and rightCol or leftCol
        return buildGroup(name, side, col)
    end

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(tabList) do t:deactivate() end
        T:activate()
    end)

    tabBtn.MouseEnter:Connect(function()
        if not pane.Visible then
            tween(tabLbl, {TextColor3 = C.t4}, 0.1)
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if not pane.Visible then
            tween(tabLbl, {TextColor3 = C.t2}, 0.1)
        end
    end)

    table.insert(tabList, T)
    return T
end

-- ─── Category (main window) ──────────────────────────────────────────────────
local function buildCategory(name)
    -- *root window: titlebar + tab bar + body, draggable*
    local sg = make("ScreenGui",{
        Name               = "mylib_" .. name,
        ResetOnSpawn       = false,
        IgnoreGuiInset     = true,
        ZIndexBehavior     = Enum.ZIndexBehavior.Sibling,
    }, CoreGui)

    -- outer panel
    local panel = make("Frame",{
        AnchorPoint        = Vector2.new(0.5,0.5),
        Position           = UDim2.new(0.5,0,0.5,0),
        Size               = UDim2.fromOffset(760,520),
        BackgroundColor3   = C.bg1,
        BorderSizePixel    = 0,
        ClipsDescendants   = false,
    }, sg)
    corner(10, panel)
    stroke(C.brd1, 1, panel)

    -- scanline effect
    local scanline = make("Frame",{
        Size               = UDim2.new(1,0,0,2),
        BackgroundColor3   = C.r5,
        BorderSizePixel    = 0,
        ZIndex             = 200,
        BackgroundTransparency = 0.3,
    }, panel)

    task.spawn(function()
        -- *scanline crawls from top to bottom forever*
        while sg.Parent do
            local h = panel.AbsoluteSize.Y
            for i = -2, h, 1 do
                if not sg.Parent then break end
                scanline.Position = UDim2.new(0,0,0,i)
                task.wait(0.006)
            end
        end
    end)

    -- ── titlebar ──
    local titlebar = make("Frame",{
        Size               = UDim2.new(1,0,0,36),
        BackgroundColor3   = C.bg0,
        BorderSizePixel    = 0,
        ZIndex             = 50,
    }, panel)
    corner(10, titlebar)
    stroke(C.brd1, 1, titlebar)
    padding(0,0,14,14, titlebar)

    -- traffic dots
    local dotFrame = make("Frame",{
        Size               = UDim2.fromOffset(60,12),
        Position           = UDim2.fromOffset(0,12),
        BackgroundTransparency = 1,
    }, titlebar)

    local dotColors = {hex("#6a0000"), hex("#5c3600"), hex("#1a4a1a")}
    for i,dc in ipairs(dotColors) do
        local d = make("Frame",{
            Position           = UDim2.fromOffset((i-1)*17, 0),
            Size               = UDim2.fromOffset(11,11),
            BackgroundColor3   = dc,
            BorderSizePixel    = 0,
        }, dotFrame)
        corner(6, d)
        stroke(dc:Lerp(Color3.new(1,1,1),0.15), 1, d)
    end

    -- title text
    make("TextLabel",{
        AnchorPoint        = Vector2.new(0,0.5),
        Position           = UDim2.new(0,70,0.5,0),
        Size               = UDim2.new(0.5,0,1,0),
        BackgroundTransparency = 1,
        Text               = "my" .. "lib  ·  " .. name,
        TextColor3         = C.t4,
        TextSize           = 11,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Left,
        RichText           = false,
        ZIndex             = 51,
    }, titlebar)

    -- status pill
    local pillFrame = make("Frame",{
        AnchorPoint        = Vector2.new(1,0.5),
        Position           = UDim2.new(1,0,0.5,0),
        Size               = UDim2.fromOffset(90,18),
        BackgroundColor3   = C.bg2,
        BorderSizePixel    = 0,
    }, titlebar)
    corner(9, pillFrame)
    stroke(C.brd1, 1, pillFrame)
    padding(0,0,8,8, pillFrame)

    local pillDot = make("Frame",{
        AnchorPoint        = Vector2.new(0,0.5),
        Position           = UDim2.new(0,0,0.5,0),
        Size               = UDim2.fromOffset(5,5),
        BackgroundColor3   = C.green,
        BorderSizePixel    = 0,
    }, pillFrame)
    corner(3, pillDot)

    make("TextLabel",{
        AnchorPoint        = Vector2.new(0,0.5),
        Position           = UDim2.new(0,10,0.5,0),
        Size               = UDim2.new(1,-10,1,0),
        BackgroundTransparency = 1,
        Text               = "Attached",
        TextColor3         = C.t3,
        TextSize           = 9,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Left,
    }, pillFrame)

    -- blink the pill dot
    task.spawn(function()
        while sg.Parent do
            tween(pillDot, {BackgroundTransparency = 0.5}, 1.1)
            task.wait(1.1)
            tween(pillDot, {BackgroundTransparency = 0}, 1.1)
            task.wait(1.1)
        end
    end)

    -- ── tab bar ──
    local tabBar = make("Frame",{
        Position           = UDim2.fromOffset(0,36),
        Size               = UDim2.new(1,0,0,32),
        BackgroundColor3   = C.bg0,
        BorderSizePixel    = 0,
        ClipsDescendants   = true,
    }, panel)
    stroke(C.brd1, 1, tabBar)

    local tabBarLayout = make("UIListLayout",{
        FillDirection      = Enum.FillDirection.Horizontal,
        SortOrder          = Enum.SortOrder.LayoutOrder,
        VerticalAlignment  = Enum.VerticalAlignment.Center,
    }, tabBar)

    -- ── body ──
    local body = make("Frame",{
        Position           = UDim2.fromOffset(0,68),
        Size               = UDim2.new(1,0,1,-68),
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        ClipsDescendants   = true,
    }, panel)

    -- ── drag logic ──
    local dragging, dragStart, panelStart = false, nil, nil

    titlebar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging    = true
            dragStart   = inp.Position
            panelStart  = panel.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            panel.Position = UDim2.new(
                panelStart.X.Scale,
                panelStart.X.Offset + delta.X,
                panelStart.Y.Scale,
                panelStart.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- ── toggle visibility keybind (RightShift) ──
    UserInputService.InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == Enum.KeyCode.RightShift then
            panel.Visible = not panel.Visible
        end
    end)

    local tabList = {}
    local Cat = {}

    function Cat:create_tab(name, imageId)
        local T = buildTab(name, imageId or "", tabBar, body, tabList)
        if #tabList == 1 then T:activate() end
        return T
    end

    return Cat
end

-- ─── Library root ────────────────────────────────────────────────────────────
local Library = {}

function Library._new()
    -- *returns a UI handle with create_category + Notify wired in*
    local UI = {}

    function UI:create_category(name)
        return buildCategory(name)
    end

    UI.Notify = Notify

    return UI
end

Library.Notify = Notify

return Library
