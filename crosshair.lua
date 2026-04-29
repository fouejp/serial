local Drawing = loadstring(game:HttpGet('https://raw.githubusercontent.com/LionTheGreatRealFrFr/Assets/refs/heads/main/DrawingLib'))()

getgenv().crosshair = {
    enabled = false,
    text = false,
    textcolor = Color3.fromRGB(189, 172, 255),
    indicator = false,
    indicatortext = "Unsafe",
    textsize = 14,
    textoffset = 75,
    refreshrate = 0,
    mode = 'Middle', -- Middle, Mouse, Custom
    position = Vector2.new(0, 0),
    lines = 4, -- Change this value to test different line counts
    width = 1.8,
    length = 15,
    radius = 11,
    color = Color3.fromRGB(189, 172, 255),
    textcolor = Color3.fromRGB(189, 172, 255),
    spin = false,
    spin_speed = 150,
    spin_max = 340,
    spin_style = Enum.EasingStyle.Circular, -- Linear for normal smooth spin
    resize = false, -- animate the length
    resize_speed = 150,
    resize_min = 5,
    resize_max = 22,
}

local runservice = game:GetService('RunService')
local inputservice = game:GetService('UserInputService')
local tweenservice = game:GetService('TweenService')
local camera = workspace.CurrentCamera

local last_render = 0

local drawings = {
    crosshair = {},
    text = {
        Text = Drawing.new('Text'),
        Indicator = Drawing.new('Text')
    }
}

drawings.text.Text.Size = crosshair.textsize
drawings.text.Text.Font = 2
drawings.text.Text.Outline = true
drawings.text.Text.Text = "Serial.Xyz"
drawings.text.Text.Color = crosshair.textcolor
drawings.text.Text.Center = true

drawings.text.Indicator.Size = crosshair.textsize
drawings.text.Indicator.Font = 2
drawings.text.Indicator.Outline = true
drawings.text.Indicator.Center = true
drawings.text.Indicator.Color = Color3.new(1, 1, 1)

local currentLines = crosshair.lines -- Track the current number of lines
local currentWidth = crosshair.width -- Track the current width

local function createCrosshairLines()
    for _, line in pairs(drawings.crosshair) do
        line[1]:Remove() -- Remove outline
        line[2]:Remove() -- Remove inline
    end
    drawings.crosshair = {}

    for idx = 1, crosshair.lines do
        local outline = Drawing.new('Line')
        outline.Color = Color3.new(0, 0, 0)
        outline.Thickness = crosshair.width + 2
        outline.ZIndex = 1 -- Lower ZIndex for outline

        local inline = Drawing.new('Line')
        inline.Color = crosshair.color
        inline.Thickness = crosshair.width
        inline.ZIndex = 2 -- Higher ZIndex for inline

        drawings.crosshair[idx] = {outline, inline}
    end
end

createCrosshairLines() -- Initialize crosshair lines

function solve(angle, radius)
    return Vector2.new(
        math.sin(math.rad(angle)) * radius,
        math.cos(math.rad(angle)) * radius
    )
end

runservice.PostSimulation:Connect(function()
    local _tick = tick()

    if _tick - last_render > crosshair.refreshrate then
        last_render = _tick

        if currentLines ~= crosshair.lines or currentWidth ~= crosshair.width then
            currentLines = crosshair.lines
            currentWidth = crosshair.width
            createCrosshairLines() -- Recreate the lines if the count or width has changed
        end

        local position = (
            crosshair.mode == 'Middle' and camera.ViewportSize / 2 or
            crosshair.mode == 'Mouse' and inputservice:GetMouseLocation() or
            crosshair.position
        )

        local text = drawings.text.Text
        local indicator = drawings.text.Indicator

        text.Visible = crosshair.text
        indicator.Visible = crosshair.text and crosshair.indicator
        
        local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

        if crosshair.text then
            text.Position = Vector2.new(center.X, center.Y + crosshair.textoffset)
            text.Color = crosshair.textcolor
            text.Size = crosshair.textsize
            
            indicator.Text = crosshair.indicatortext
            indicator.Position = Vector2.new(center.X, center.Y + crosshair.textoffset + 15)
            indicator.Size = crosshair.textsize
        end
        
        if crosshair.enabled then
            for idx = 1, crosshair.lines do
                local outline = drawings.crosshair[idx][1] -- Outline
                local inline = drawings.crosshair[idx][2]  -- Inline

                local angle = (idx - 1) * (360 / crosshair.lines) -- Distribute angles evenly
                local length = crosshair.length

                if crosshair.spin then
                    local spin_angle = -_tick * crosshair.spin_speed % crosshair.spin_max
                    angle = angle + tweenservice:GetValue(spin_angle / 360, crosshair.spin_style, Enum.EasingDirection.InOut) * 360
                end

                if crosshair.resize then
                    local resize_length = tick() * crosshair.resize_speed % 180
                    length = crosshair.resize_min + math.sin(math.rad(resize_length)) * crosshair.resize_max
                end

                inline.Visible = true
                inline.Color = crosshair.color
                inline.From = position + solve(angle, crosshair.radius)
                inline.To = position + solve(angle, crosshair.radius + length)
                inline.Thickness = crosshair.width

                outline.Visible = true
                outline.From = position + solve(angle, crosshair.radius - 1)
                outline.To = position + solve(angle, crosshair.radius + length + 1)
                outline.Thickness = crosshair.width + 1.5    
            end
        else
            for idx = 1, crosshair.lines do
                drawings.crosshair[idx][1].Visible = false -- Outline
                drawings.crosshair[idx][2].Visible = false -- Inline
            end
        end
    end
end)

return crosshair
