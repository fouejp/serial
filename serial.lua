--[[ 
Serial-Style UI (Run-ready, pure Roblox Lua) + JSON Configs
- Solid black window with dark-blue glow, title bar on top (drag from bar only)
- Tabs: Combat | Target | Misc | Config
- Two-column sections (side-by-side), section titles on top
- Compact controls (smaller toggles, sliders, dropdowns)
- Smooth circle toggles (click the circle only)
- Dropdowns render over everything and show an arrow indicator
- Sliders support mouse + touch and won't drag the window
- Auto-size for PC vs Mobile
- JSON Config system in workspace/CFG (auto-created). List auto-populates; Save/Load/Delete.
]]

--// Services
local CoreGui     = game:GetService("CoreGui")
local UIS         = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

--// Device sizing
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local WIN_W, WIN_H = (isMobile and 370 or 420), (isMobile and 390 or 420)

--// Theme
local COLORS = {
    bg          = Color3.fromRGB(12, 12, 12),
    bar         = Color3.fromRGB(0, 0, 0),
    text        = Color3.fromRGB(235, 235, 235),
    accent      = Color3.fromRGB(40, 80, 200),
    accentFill  = Color3.fromRGB(0, 120, 255),
    tabIdle     = Color3.fromRGB(26, 26, 26),
    tabText     = Color3.fromRGB(235, 235, 235),
    sectionBg   = Color3.fromRGB(18, 18, 18),
    ctrlBg      = Color3.fromRGB(26, 26, 26),
    ctrlBg2     = Color3.fromRGB(34, 34, 34),
    sliderTrack = Color3.fromRGB(60, 70, 120),
    sliderFill  = Color3.fromRGB(0, 150, 255),
    toggleOff   = Color3.fromRGB(80, 80, 80),
    arrowOff    = Color3.fromRGB(220, 220, 220),
    warn        = Color3.fromRGB(255, 200, 130),
    ok          = Color3.fromRGB(140, 220, 140),
    bad         = Color3.fromRGB(230, 120, 120),
}

--// Helpers
local function round(frame, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = frame
    return c
end
local function stroke(frame, color, thickness, transp)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = color or Color3.new(0,0,0)
    s.Thickness = thickness or 1
    s.Transparency = transp or 0
    s.Parent = frame
    return s
end
local function pad(frame, px)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0,px)
    p.PaddingBottom = UDim.new(0,px)
    p.PaddingLeft = UDim.new(0,px)
    p.PaddingRight = UDim.new(0,px)
    p.Parent = frame
    return p
end
local function clamp(v, mn, mx) return (v < mn and mn) or (v > mx and mx) or v end
local function roundStep(v, step)
    step = step or 1
    return math.floor((v/step)+0.5) * step
end
local function fmtValue(v, step)
    if (step or 1) < 1 then
        return string.format("%.2f", v)
    else
        return tostring(math.floor(v + 0.5))
    end
end

--// Root GUI
local SG = Instance.new("ScreenGui")
SG.Name = "SerialStyleUI"
SG.IgnoreGuiInset = true
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = CoreGui

--// Window
local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.new(0, WIN_W, 0, WIN_H)
Window.Position = UDim2.new(0.5, -math.floor(WIN_W/2), 0.5, -math.floor(WIN_H/2))
Window.BackgroundColor3 = COLORS.bg
Window.BorderSizePixel = 0
Window.ClipsDescendants = true
Window.Parent = SG
round(Window, 14)
stroke(Window, COLORS.accent, 2, 0.1)
do local g = stroke(Window, COLORS.accent, 6, 0.85); g.LineJoinMode = Enum.LineJoinMode.Round end

--// Top bar (drag area)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = COLORS.bar
TopBar.BorderSizePixel = 0
TopBar.ClipsDescendants = true
TopBar.Parent = Window
round(TopBar, 14)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Serial"
Title.TextColor3 = COLORS.text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.Parent = TopBar

-- Dragging (TopBar only)
do
    local dragging = false
    local dragStart, startPos, dragInput
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

--// Tab bar
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.BackgroundTransparency = 1
TabBar.Size = UDim2.new(1, 0, 0, 28)
TabBar.Position = UDim2.new(0, 0, 0, 30)
TabBar.Parent = Window
TabBar.ClipsDescendants = true
pad(TabBar, 6)

local TabList = Instance.new("UIListLayout")
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabList.Padding = UDim.new(0, 11)
TabList.SortOrder = Enum.SortOrder.LayoutOrder -- 👈 key line
TabList.Parent = TabBar

--// Pages holder
local Pages = Instance.new("Frame")
Pages.Name = "Pages"
Pages.BackgroundTransparency = 1
Pages.Size = UDim2.new(1, -10, 1, -(30 + 28 + 12))
Pages.Position = UDim2.new(0, 5, 0, 30 + 28 + 6)
Pages.Parent = Window
Pages.ClipsDescendants = true

--// Control registry (for configs)
local Controls = {} -- key -> {Get=fn, Set=fn}
local function reg(key, obj) Controls[key] = obj return obj end

--// Tab factory
local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Name = "Tab_"..name
    btn.AutoButtonColor = true
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = COLORS.tabText
    btn.BackgroundColor3 = COLORS.tabIdle
    btn.Size = UDim2.new(0, math.max(64, #name * 7), 1, 0)
    btn.Parent = TabBar
    round(btn, 8)
    local outline = stroke(btn, COLORS.accent, 1, 0.6)

    local page = Instance.new("ScrollingFrame")
    page.Name = "Page_"..name
    page.BackgroundTransparency = 1
    page.Size = UDim2.new(1, 0, 1, 0)
    page.ScrollBarThickness = 5
    page.Visible = true
    page.Parent = Pages
    page.ClipsDescendants = true
    page.ZIndex = 1
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0,0,0,0)

    -- Two-column layout inside each page
    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Horizontal
    list.Wraps = true -- ✅ allows wrapping into two columns
    list.HorizontalAlignment = Enum.HorizontalAlignment.Left
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)
    list.Parent = page


    local function setActive()
        for _,child in ipairs(TabBar:GetChildren()) do
            if child:IsA("TextButton") then
                for _,s in ipairs(child:GetChildren()) do
                    if s:IsA("UIStroke") then s.Transparency = 0.6 end
                end
            end
        end
        for _,p in ipairs(Pages:GetChildren()) do
            if p:IsA("ScrollingFrame") then p.Visible = false end
        end
        page.Visible = true
        outline.Transparency = 0
    end
    btn.MouseButton1Click:Connect(setActive)

-- Section factory
local function CreateSection(titleText, customHeight)
    local section = Instance.new("Frame")
    section.Name = "Section_"..titleText
    section.BackgroundColor3 = COLORS.sectionBg
    section.BorderSizePixel = 0
    section.Parent = page
    section.ClipsDescendants = true
    round(section, 10)
    stroke(section, COLORS.accent, 1, 0.5)
    pad(section, 6)
    section.ZIndex = 5

    if customHeight then
        section.Size = UDim2.new(0.5, -6, 0, customHeight)
    else
        section.Size = UDim2.new(0.5, -6, 0, 200) -- fallback minimum
        section.AutomaticSize = Enum.AutomaticSize.Y
    end

        local header = Instance.new("TextLabel")
        header.BackgroundTransparency = 1
        header.Size = UDim2.new(1, -4, 0, 16)
        header.Position = UDim2.new(0, 2, 0, 0)
        header.Text = titleText
        header.TextColor3 = Color3.fromRGB(180, 200, 255)
        header.Font = Enum.Font.GothamBold
        header.TextSize = 12
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Parent = section
        header.ZIndex = 6

        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.new(1, 0, 1, -20)
        holder.Position = UDim2.new(0, 0, 0, 20)
        holder.Parent = section
        holder.ClipsDescendants = true
        holder.ZIndex = 6

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 7)
        list.FillDirection = Enum.FillDirection.Vertical
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = holder

        local API = {}

        function API:Label(text, color)
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Size = UDim2.new(1, -2, 0, 16)
            l.Text = text
            l.TextColor3 = color or COLORS.tabText
            l.Font = Enum.Font.Gotham
            l.TextSize = 12
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.Parent = holder
            l.ZIndex = 7
            return l
        end

        function API:Button(text, callback)
            local b = Instance.new("TextButton")
            b.AutoButtonColor = true
            b.Size = UDim2.new(1, 0, 0, 24)
            b.BackgroundColor3 = COLORS.ctrlBg2
            b.Text = text
            b.TextColor3 = COLORS.tabText
            b.Font = Enum.Font.GothamBold
            b.TextSize = 12
            b.Parent = holder
            b.ZIndex = 7
            round(b, 6)
            stroke(b, COLORS.accent, 1, 0.8)
            b.MouseButton1Click:Connect(function()
                if callback then task.spawn(callback) end
            end)
            return b
        end

-- Toggle with optional keybind row
function API:Toggle(key, text, default, callback, opts)
    opts = opts or {}

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 18)
    row.BackgroundTransparency = 1
    row.Parent = holder
    row.ZIndex = 7

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -32, 1, 0)
    label.Position = UDim2.new(0, 4, 0, 0)
    label.Text = text
    label.TextColor3 = COLORS.tabText
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    label.ZIndex = 8

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(1, -20, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(0,0,0)
    knob.Parent = row
    knob.ZIndex = 10
    round(knob, 9)
    local ring = stroke(knob, COLORS.toggleOff, 2, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = COLORS.accentFill
    fill.BackgroundTransparency = 0.3
    fill.Parent = knob
    fill.ZIndex = 11
    round(fill, 9)

    local on = default and true or false
    local function set(v)
        on = v and true or false
        ring.Color = on and COLORS.accent or COLORS.toggleOff
        fill:TweenSize(UDim2.new(on and 1 or 0, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.18, true)
        if callback then task.spawn(callback, on) end
    end
    set(on)

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
        or input.UserInputType == Enum.UserInputType.Touch then
            set(not on)
        end
    end)

--------------------------------------------------------------------
-- Optional Keybind Row (with reset-to-default)
--------------------------------------------------------------------
local boundKey = nil
local keyBtn
local capturing = false
local defaultKey = opts.Key -- save default

if opts.Key then
    local keyRow = Instance.new("Frame")
    keyRow.Size = UDim2.new(1, 0, 0, 20)
    keyRow.BackgroundTransparency = 1
    keyRow.Parent = holder
    keyRow.ZIndex = 7

    keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0, 80, 1, 0)
    keyBtn.Position = UDim2.new(1, -84, 0, 0)
    keyBtn.BackgroundColor3 = COLORS.ctrlBg2
    keyBtn.Text = "[ Set Key ]"
    keyBtn.TextColor3 = COLORS.tabText
    keyBtn.Font = Enum.Font.Gotham
    keyBtn.TextSize = 11
    keyBtn.Parent = keyRow
    keyBtn.ZIndex = 8
    round(keyBtn, 6)

    -- preload default bind
    if typeof(defaultKey) == "EnumItem" then
        boundKey = defaultKey
        keyBtn.Text = "["..boundKey.Name.."]"
    end

    keyBtn.MouseButton1Click:Connect(function()
        if capturing then
            -- second click cancels and resets
            boundKey = defaultKey
            keyBtn.Text = defaultKey and ("["..defaultKey.Name.."]") or "[ Set Key ]"
            capturing = false
        else
            capturing = true
            keyBtn.Text = "[ Press Key ]"
        end
    end)

    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if capturing then
            if input.UserInputType == Enum.UserInputType.Keyboard 
            or input.UserInputType == Enum.UserInputType.Gamepad1 then
                boundKey = input.KeyCode
                keyBtn.Text = "["..boundKey.Name.."]"
                capturing = false
            end
        elseif boundKey and input.KeyCode == boundKey then
            set(not on)
        end
    end)
end

return reg(key, {
    Set = set,
    Get = function() return on end,
    Bind = function(k)
        boundKey = k
        if keyBtn then keyBtn.Text = "["..k.Name.."]" end
    end,
    GetBind = function() return boundKey end,
})
end

-- Slider (supports step; mouse + touch; does not drag window)
function API:Slider(key, labelText, min, max, default, step, callback)
    min, max = min or 0, max or 100
    step = step or 1
    local value = clamp(default or min, min, max)
    value = roundStep(value, step)

    local root = Instance.new("Frame")
    root.Size = UDim2.new(1, 0, 0, 36)
    root.BackgroundColor3 = COLORS.ctrlBg
    root.Parent = holder
    root.ZIndex = 7
    round(root, 6)
    stroke(root, COLORS.accent, 1, 0.8)

    local top = Instance.new("Frame")
    top.BackgroundTransparency = 1
    top.Size = UDim2.new(1, -10, 0, 16)
    top.Position = UDim2.new(0, 5, 0, 2)
    top.Parent = root
    top.ZIndex = 8

    local nameL = Instance.new("TextLabel")
    nameL.BackgroundTransparency = 1
    nameL.Size = UDim2.new(1, -40, 1, 0)
    nameL.Text = labelText or "Slider"
    nameL.TextColor3 = COLORS.tabText
    nameL.Font = Enum.Font.Gotham
    nameL.TextSize = 12
    nameL.TextXAlignment = Enum.TextXAlignment.Left
    nameL.Parent = top
    nameL.ZIndex = 9

    local valL = Instance.new("TextLabel")
    valL.BackgroundTransparency = 1
    valL.Size = UDim2.new(0, 44, 1, 0)
    valL.Position = UDim2.new(1, -44, 0, 0)
    valL.Text = fmtValue(value, step)
    valL.TextColor3 = COLORS.tabText
    valL.Font = Enum.Font.Gotham
    valL.TextSize = 12
    valL.TextXAlignment = Enum.TextXAlignment.Right
    valL.Parent = top
    valL.ZIndex = 9

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -10, 0, 6)
    track.Position = UDim2.new(0, 5, 0, 22)
    track.BackgroundColor3 = COLORS.sliderTrack
    track.Parent = root
    track.ZIndex = 8
    round(track, 3)

    local function ratioFromValue(v)
        return (v - min) / (max - min)
    end

    local fill = Instance.new("Frame")
    local pct = ratioFromValue(value)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = COLORS.sliderFill
    fill.Parent = track
    fill.ZIndex = 9
    round(fill, 3)

    -- Hover effect (smooth tween)
    local TweenService = game:GetService("TweenService")
    local hoverIn = TweenService:Create(fill, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(0, 180, 255) })
    local hoverOut = TweenService:Create(fill, TweenInfo.new(0.2), { BackgroundColor3 = COLORS.sliderFill })

    track.MouseEnter:Connect(function()
        hoverOut:Cancel()
        hoverIn:Play()
    end)
    track.MouseLeave:Connect(function()
        hoverIn:Cancel()
        hoverOut:Play()
    end)

    local dragging = false
    local function setFromX(x)
        local p = clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local raw = min + (max - min) * p
        value = clamp(roundStep(raw, step), min, max)
        fill.Size = UDim2.new(ratioFromValue(value), 0, 1, 0)
        valL.Text = fmtValue(value, step)
        if callback then callback(value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)

    local function set(v)
        v = clamp(tonumber(v) or value, min, max)
        value = roundStep(v, step)
        fill.Size = UDim2.new(ratioFromValue(value), 0, 1, 0)
        valL.Text = fmtValue(value, step)
        if callback then callback(value) end
    end

    set(value)
    return reg(key, { Set = set, Get = function() return value end })
end

function API:TextBox(key, labelText, default, callback, opts)
    opts = opts or {}
    local current = default or ""

    -- root container (label + textbox)
    local root = Instance.new("Frame")
    root.Size = UDim2.new(1, 0, 0, 44) -- taller to fit label
    root.BackgroundTransparency = 1
    root.Parent = holder
    root.ZIndex = 20

    -- label above
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -4, 0, 14)
    lbl.Position = UDim2.new(0, 2, 0, 0)
    lbl.Text = labelText or "Textbox"
    lbl.TextColor3 = COLORS.tabText
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = root
    lbl.ZIndex = 21

    -- box container
    local boxHolder = Instance.new("Frame")
    boxHolder.Size = UDim2.new(1, 0, 0, 24)
    boxHolder.Position = UDim2.new(0, 0, 0, 18)
    boxHolder.BackgroundColor3 = COLORS.ctrlBg
    boxHolder.Parent = root
    boxHolder.ZIndex = 20
    round(boxHolder, 6)
    stroke(boxHolder, COLORS.accent, 1, 0.8)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -8, 1, -8)
    box.Position = UDim2.new(0, 4, 0, 4)
    box.BackgroundColor3 = COLORS.ctrlBg2
    box.Text = tostring(current)
    box.TextColor3 = COLORS.tabText
    box.PlaceholderText = "Enter value"
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.Parent = boxHolder
    box.ZIndex = 21
    round(box, 6)

    local function apply(val)
        if opts.NumbersOnly then
            local num = tonumber(val)
            if num then
                current = num
                if callback then callback(num) end
            else
                box.Text = tostring(current)
            end
        else
            current = val
            if callback then callback(val) end
        end
    end

    box.FocusLost:Connect(function() apply(box.Text) end)

    return reg(key, {
        Set = function(v) box.Text = tostring(v) apply(v) end,
        Get = function() return current end
    })
end

-- Dropdown (overlay; scrollable; auto-close; arrow glow)
function API:Dropdown(key, labelText, options, default, callback, extra)
    options = options or {}
    extra   = extra or {}
    local maxVisible = extra.MaxVisible or 6
    local itemHeight = 22
    local padY       = 8
    local current    = default or options[1] or "Select"

    -- root row
    local root = Instance.new("Frame")
    root.Size = UDim2.new(1, 0, 0, 28)
    root.BackgroundColor3 = COLORS.ctrlBg
    root.Parent = holder
    root.ZIndex = 20
    root.ClipsDescendants = false
    round(root, 6)
    stroke(root, COLORS.accent, 1, 0.8)

    -- button
    local btn = Instance.new("TextButton")
    btn.AutoButtonColor = false
    btn.Size = UDim2.new(1, -8, 1, -8)
    btn.Position = UDim2.new(0, 4, 0, 4)
    btn.BackgroundColor3 = COLORS.ctrlBg2
    btn.Text = (labelText or "Dropdown")..": "..tostring(current)
    btn.TextColor3 = COLORS.tabText
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = root
    btn.ZIndex = 21
    round(btn, 6)

    -- arrow
    local arrow = Instance.new("TextLabel")
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.Size = UDim2.new(0, 16, 1, 0)
    arrow.Position = UDim2.new(1, -18, 0, 0)
    arrow.TextColor3 = COLORS.arrowOff
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 12
    arrow.Parent = btn
    arrow.ZIndex = 22

    ------------------------------------------------------------------------
    -- POPUP: parent to ScreenGui so it overlays everything and never clips
    ------------------------------------------------------------------------
    local popup = Instance.new("ScrollingFrame")
    popup.Visible = false
    popup.Active = true
    popup.ScrollingDirection = Enum.ScrollingDirection.Y
    popup.BackgroundColor3 = COLORS.ctrlBg
    popup.BorderSizePixel = 0
    popup.Parent = SG                        -- overlay!
    popup.ZIndex = 1000
    popup.ClipsDescendants = true
    popup.ScrollBarThickness = 4
    popup.AutomaticCanvasSize = Enum.AutomaticSize.Y
    popup.CanvasSize = UDim2.new()
    round(popup, 6)
    stroke(popup, COLORS.accent, 1, 0.4)
    pad(popup, 4)

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 4)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = popup

    local function choose(opt)
        current = opt
        btn.Text = (labelText or "Dropdown")..": "..tostring(opt)
        popup.Visible = false
        arrow.TextColor3 = COLORS.arrowOff
        if callback then task.spawn(callback, opt) end
    end

    -- build items once
    for _, opt in ipairs(options) do
        local o = Instance.new("TextButton")
        o.AutoButtonColor = true
        o.Size = UDim2.new(1, 0, 0, itemHeight)
        o.BackgroundColor3 = COLORS.ctrlBg2
        o.Text = tostring(opt)
        o.TextColor3 = COLORS.tabText
        o.Font = Enum.Font.Gotham
        o.TextSize = 12
        o.Parent = popup
        o.ZIndex = 1001
        round(o, 6)
        local st = stroke(o, COLORS.accent, 1, 0.8)
        st.Transparency = (opt == current) and 0.2 or 0.8
        o.MouseButton1Click:Connect(function()
            choose(opt)
        end)
    end

    ------------------------------------------------------------------------
    -- open/close + smart positioning (opens upward if near screen bottom)
    ------------------------------------------------------------------------
    local function openPopup()
        if #options == 0 then return end

        local absPos  = btn.AbsolutePosition
        local absSize = btn.AbsoluteSize

        local wantH   = math.min(maxVisible, #options) * itemHeight + padY
        local screenW = SG.AbsoluteSize.X
        local screenH = SG.AbsoluteSize.Y

        -- try below; if offscreen, open above
        local yBelow = absPos.Y + absSize.Y + 2
        local yAbove = absPos.Y - wantH - 2
        local y = (yBelow + wantH <= screenH) and yBelow or math.max(0, yAbove)

        -- width/left align with button
        local x = math.clamp(absPos.X + 4, 0, math.max(0, screenW - (absSize.X - 8)))
        popup.Position = UDim2.fromOffset(x, y)
        popup.Size     = UDim2.fromOffset(absSize.X - 8, wantH)
        popup.CanvasSize = UDim2.new(0, 0, 0, (#options * itemHeight) + padY)

        popup.Visible = true
        arrow.TextColor3 = COLORS.accentFill
    end

    local function closePopup()
        popup.Visible = false
        arrow.TextColor3 = COLORS.arrowOff
    end

    btn.MouseButton1Click:Connect(function()
        if popup.Visible then closePopup() else openPopup() end
    end)

    ------------------------------------------------------------------------
    -- Auto-close when clicking outside
    ------------------------------------------------------------------------
    local function pointIn(gui, pos)
        local gp, gs = gui.AbsolutePosition, gui.AbsoluteSize
        return pos.X >= gp.X and pos.X <= gp.X + gs.X and pos.Y >= gp.Y and pos.Y <= gp.Y + gs.Y
    end

    local GuiService = game:GetService("GuiService")
    UIS.InputBegan:Connect(function(input, gpe)
        if gpe or not popup.Visible then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
           and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        -- adjust for inset so coordinates match ScreenGui (IgnoreGuiInset = true)
        local m = UIS:GetMouseLocation()
        local inset = GuiService:GetGuiInset()
        local pos = Vector2.new(m.X - inset.X, m.Y - inset.Y)

        if not pointIn(btn, pos) and not pointIn(popup, pos) then
            closePopup()
        end
    end)

    -- safety: close popup if this row gets removed
    root.AncestryChanged:Connect(function(_, parent)
        if not parent then popup:Destroy() end
    end)

    if default then choose(default) end

    return reg(key, {
        Set = function(v) if v ~= nil then choose(v) end end,
        Get = function() return current end
    })
end
        return API
    end

    return page, setActive, CreateSection
end
