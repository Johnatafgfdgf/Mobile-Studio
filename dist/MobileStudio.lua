--[[
    Mobile Studio v0.2.0
    Runtime build for Studio Lite

    Goal: Roblox Studio-like mobile shell with real local Workspace tools.
    This build is intentionally client-side. Project persistence/export/publish
    will be added in later milestones.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

local VERSION = "0.2.0"

local THEME = {
    Back = Color3.fromRGB(31, 31, 33),
    Back2 = Color3.fromRGB(37, 37, 39),
    Back3 = Color3.fromRGB(44, 44, 47),
    Back4 = Color3.fromRGB(51, 51, 54),
    Border = Color3.fromRGB(67, 67, 71),
    BorderSoft = Color3.fromRGB(57, 57, 61),
    Text = Color3.fromRGB(232, 232, 235),
    TextDim = Color3.fromRGB(171, 171, 176),
    TextFaint = Color3.fromRGB(126, 126, 132),
    Accent = Color3.fromRGB(0, 120, 215),
    AccentHover = Color3.fromRGB(18, 137, 232),
    Select = Color3.fromRGB(48, 82, 111),
    Error = Color3.fromRGB(235, 99, 99),
    Warn = Color3.fromRGB(230, 177, 82),
    Good = Color3.fromRGB(112, 194, 134),
}

local FONT = Enum.Font.Gotham
local FONT_MED = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_CODE = Enum.Font.Code

local function setSafe(obj, prop, value)
    pcall(function()
        obj[prop] = value
    end)
end

local function create(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        setSafe(obj, k, v)
    end
    obj.Parent = parent
    return obj
end

local function stroke(parent, transparency)
    return create("UIStroke", {
        Color = THEME.Border,
        Thickness = 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function corner(parent, px)
    return create("UICorner", {
        CornerRadius = UDim.new(0, px or 3),
    }, parent)
end

local function padding(parent, l, r, t, b)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
    }, parent)
end

local function label(parent, text, size, pos, props)
    props = props or {}
    local o = create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = props.TextColor3 or THEME.Text,
        TextSize = props.TextSize or 12,
        Font = props.Font or FONT,
        TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
        TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center,
        TextWrapped = props.TextWrapped or false,
        Size = size or UDim2.fromScale(1, 1),
        Position = pos or UDim2.new(),
        ZIndex = props.ZIndex or 1,
    }, parent)
    return o
end

local function button(parent, text, size, pos, props)
    props = props or {}
    local o = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = props.BackgroundColor3 or THEME.Back3,
        BackgroundTransparency = props.BackgroundTransparency or 0,
        BorderSizePixel = 0,
        Text = text or "",
        TextColor3 = props.TextColor3 or THEME.Text,
        TextSize = props.TextSize or 11,
        Font = props.Font or FONT_MED,
        Size = size or UDim2.new(0, 70, 0, 28),
        Position = pos or UDim2.new(),
        ZIndex = props.ZIndex or 2,
    }, parent)
    if props.Corner ~= false then
        corner(o, props.CornerRadius or 2)
    end
    if props.Stroke then
        stroke(o, props.StrokeTransparency or 0.35)
    end

    o.MouseEnter:Connect(function()
        if o.Active and o.BackgroundTransparency < 1 then
            o.BackgroundColor3 = props.HoverColor or THEME.Back4
        end
    end)
    o.MouseLeave:Connect(function()
        if o:GetAttribute("Selected") then
            o.BackgroundColor3 = THEME.Accent
        else
            o.BackgroundColor3 = props.BackgroundColor3 or THEME.Back3
        end
    end)
    return o
end

local function textbox(parent, text, placeholder, size, pos)
    local o = create("TextBox", {
        BackgroundColor3 = THEME.Back,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Text = text or "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = THEME.TextFaint,
        TextColor3 = THEME.Text,
        TextSize = 11,
        Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = size,
        Position = pos,
        ZIndex = 5,
    }, parent)
    corner(o, 2)
    stroke(o, 0.45)
    padding(o, 6, 6, 0, 0)
    return o
end

local old = playerGui:FindFirstChild("MobileStudio")
if old then old:Destroy() end

local screen = create("ScreenGui", {
    Name = "MobileStudio",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    DisplayOrder = 5000,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)
setSafe(screen, "ClipToDeviceSafeArea", true)

local shell = create("Frame", {
    Name = "Shell",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, screen)

local TOP_H = 34
local TAB_H = 29
local TOOL_H = 42
local STATUS_H = 24
local HEADER_TOTAL = TOP_H + TAB_H + TOOL_H

local top = create("Frame", {
    Name = "TopCommandBar",
    Size = UDim2.new(1, 0, 0, TOP_H),
    BackgroundColor3 = THEME.Back2,
    BorderSizePixel = 0,
    ZIndex = 50,
}, shell)
create("Frame", {
    Name = "BottomLine",
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = THEME.BorderSoft,
    BorderSizePixel = 0,
    ZIndex = 51,
}, top)

local topLeft = create("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, 0),
    Size = UDim2.new(0, 170, 1, 0),
    ZIndex = 52,
}, top)

local undoBtn = button(topLeft, "Undo", UDim2.new(0, 54, 0, 24), UDim2.new(0, 0, 0.5, -12), {Corner=false, BackgroundColor3=THEME.Back2})
local redoBtn = button(topLeft, "Redo", UDim2.new(0, 54, 0, 24), UDim2.new(0, 55, 0.5, -12), {Corner=false, BackgroundColor3=THEME.Back2})

local projectTitle = label(top, "Mobile Studio", UDim2.new(0.42, 0, 1, 0), UDim2.new(0.29, 0, 0, 0), {
    TextXAlignment = Enum.TextXAlignment.Center,
    Font = FONT_MED,
    TextSize = 12,
    ZIndex = 52,
})

local topRight = create("Frame", {
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -6, 0, 0),
    Size = UDim2.new(0, 310, 1, 0),
    ZIndex = 52,
}, top)

local explorerToggle = button(topRight, "Explorer", UDim2.new(0, 76, 0, 24), UDim2.new(0, 72, 0.5, -12), {Corner=false, BackgroundColor3=THEME.Back2})
local propertiesToggle = button(topRight, "Properties", UDim2.new(0, 82, 0, 24), UDim2.new(0, 150, 0.5, -12), {Corner=false, BackgroundColor3=THEME.Back2})
local outputToggle = button(topRight, "Output", UDim2.new(0, 66, 0, 24), UDim2.new(0, 234, 0.5, -12), {Corner=false, BackgroundColor3=THEME.Back2})

local tabs = create("Frame", {
    Name = "Tabs",
    Position = UDim2.new(0, 0, 0, TOP_H),
    Size = UDim2.new(1, 0, 0, TAB_H),
    BackgroundColor3 = THEME.Back2,
    BorderSizePixel = 0,
    ZIndex = 45,
}, shell)

local tabStrip = create("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, 0),
    Size = UDim2.new(1, -16, 1, 0),
    ZIndex = 46,
}, tabs)
local tabLayout = create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 1),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, tabStrip)

local toolbar = create("Frame", {
    Name = "ContextToolbar",
    Position = UDim2.new(0, 0, 0, TOP_H + TAB_H),
    Size = UDim2.new(1, 0, 0, TOOL_H),
    BackgroundColor3 = THEME.Back3,
    BorderSizePixel = 0,
    ZIndex = 40,
}, shell)
create("Frame", {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = THEME.BorderSoft,
    BorderSizePixel = 0,
    ZIndex = 41,
}, toolbar)

local toolbarScroll = create("ScrollingFrame", {
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.X,
    ScrollingDirection = Enum.ScrollingDirection.X,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = THEME.TextFaint,
    ZIndex = 42,
}, toolbar)
local toolbarContent = create("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    ZIndex = 43,
}, toolbarScroll)
padding(toolbarContent, 8, 8, 5, 4)
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, toolbarContent)

local workspaceArea = create("Frame", {
    Name = "WorkspaceArea",
    Position = UDim2.new(0, 0, 0, HEADER_TOTAL),
    Size = UDim2.new(1, 0, 1, -(HEADER_TOTAL + STATUS_H)),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 1,
}, shell)

local status = create("Frame", {
    Name = "StatusBar",
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, STATUS_H),
    BackgroundColor3 = THEME.Back2,
    BorderSizePixel = 0,
    ZIndex = 70,
}, shell)
create("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = THEME.BorderSoft,
    BorderSizePixel = 0,
    ZIndex = 71,
}, status)
local statusLeft = label(status, "Ready", UDim2.new(0.62, -8, 1, 0), UDim2.new(0, 8, 0, 0), {TextColor3=THEME.TextDim, TextSize=10, ZIndex=72})
local statusRight = label(status, "v" .. VERSION, UDim2.new(0.38, -8, 1, 0), UDim2.new(0.62, 0, 0, 0), {TextColor3=THEME.TextFaint, TextSize=10, TextXAlignment=Enum.TextXAlignment.Right, ZIndex=72})

local explorer = create("Frame", {
    Name = "Explorer",
    BackgroundColor3 = THEME.Back2,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 275, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    ZIndex = 20,
}, workspaceArea)
stroke(explorer, 0.45)

local properties = create("Frame", {
    Name = "Properties",
    BackgroundColor3 = THEME.Back2,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(1, 0),
    Size = UDim2.new(0, 300, 1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    ZIndex = 20,
}, workspaceArea)
stroke(properties, 0.45)

local outputTray = create("Frame", {
    Name = "OutputTray",
    BackgroundColor3 = THEME.Back2,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 0),
    Visible = false,
    ZIndex = 60,
}, workspaceArea)
stroke(outputTray, 0.4)

local outputHeader = create("Frame", {
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = THEME.Back3,
    BorderSizePixel = 0,
    ZIndex = 61,
}, outputTray)
label(outputHeader, "Output", UDim2.new(0, 100, 1, 0), UDim2.new(0, 9, 0, 0), {Font=FONT_MED, TextSize=11, ZIndex=62})
local outputClear = button(outputHeader, "Clear", UDim2.new(0, 54, 0, 22), UDim2.new(1, -62, 0.5, -11), {Corner=false, BackgroundColor3=THEME.Back3, ZIndex=62})
local outputList = create("ScrollingFrame", {
    Position = UDim2.new(0, 0, 0, 28),
    Size = UDim2.new(1, 0, 1, -28),
    BackgroundColor3 = THEME.Back,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = THEME.TextFaint,
    ZIndex = 61,
}, outputTray)
padding(outputList, 6, 6, 4, 4)
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    Padding = UDim.new(0, 1),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, outputList)

local explorerHeader = create("Frame", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = THEME.Back3,
    BorderSizePixel = 0,
    ZIndex = 21,
}, explorer)
label(explorerHeader, "Explorer", UDim2.new(1, -70, 1, 0), UDim2.new(0, 8, 0, 0), {Font=FONT_MED, TextSize=11, ZIndex=22})
local explorerAdd = button(explorerHeader, "+", UDim2.new(0, 28, 0, 24), UDim2.new(1, -60, 0.5, -12), {Corner=false, BackgroundColor3=THEME.Back3, TextSize=16, ZIndex=22})
local explorerClose = button(explorerHeader, "X", UDim2.new(0, 28, 0, 24), UDim2.new(1, -30, 0.5, -12), {Corner=false, BackgroundColor3=THEME.Back3, ZIndex=22})

local explorerSearch = textbox(explorer, "", "Search Explorer", UDim2.new(1, -10, 0, 27), UDim2.new(0, 5, 0, 35))
explorerSearch.ZIndex = 22

local explorerList = create("ScrollingFrame", {
    Position = UDim2.new(0, 0, 0, 67),
    Size = UDim2.new(1, 0, 1, -67),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = THEME.TextFaint,
    ZIndex = 21,
}, explorer)
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, explorerList)

local propertiesHeader = create("Frame", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = THEME.Back3,
    BorderSizePixel = 0,
    ZIndex = 21,
}, properties)
local propertiesTitle = label(propertiesHeader, "Properties", UDim2.new(1, -40, 1, 0), UDim2.new(0, 8, 0, 0), {Font=FONT_MED, TextSize=11, ZIndex=22})
local propertiesClose = button(propertiesHeader, "X", UDim2.new(0, 28, 0, 24), UDim2.new(1, -30, 0.5, -12), {Corner=false, BackgroundColor3=THEME.Back3, ZIndex=22})
local propertiesSearch = textbox(properties, "", "Search Properties", UDim2.new(1, -10, 0, 27), UDim2.new(0, 5, 0, 35))
propertiesSearch.ZIndex = 22
local propertiesList = create("ScrollingFrame", {
    Position = UDim2.new(0, 0, 0, 67),
    Size = UDim2.new(1, 0, 1, -67),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = THEME.TextFaint,
    ZIndex = 21,
}, properties)
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, propertiesList)

local toolDock = create("Frame", {
    Name = "TouchToolDock",
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -12),
    Size = UDim2.new(0, 306, 0, 38),
    BackgroundColor3 = THEME.Back2,
    BackgroundTransparency = 0.03,
    BorderSizePixel = 0,
    ZIndex = 15,
}, workspaceArea)
corner(toolDock, 3)
stroke(toolDock, 0.25)
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 2),
}, toolDock)
padding(toolDock, 4, 4, 3, 3)

local selectionBox = create("SelectionBox", {
    Name = "MobileStudioSelection",
    Color3 = THEME.Accent,
    LineThickness = 0.035,
    SurfaceTransparency = 1,
    Adornee = nil,
}, Workspace)

local highlight = create("Highlight", {
    Name = "MobileStudioHighlight",
    FillTransparency = 1,
    OutlineColor = THEME.Accent,
    OutlineTransparency = 0,
    Enabled = false,
}, Workspace)

local undoStack = {}
local redoStack = {}
local selected = nil
local activeTool = "Select"
local explorerVisible = true
local propertiesVisible = true
local outputVisible = false
local dockedPanels = false
local expanded = {}
local outputRows = {}
local selectedRow = nil
local activeTab = "Home"
local tabButtons = {}
local toolButtons = {}
local fpsValue = 0

local function statusMessage(text)
    statusLeft.Text = tostring(text)
end

local function pushHistory(labelText, undoFn, redoFn)
    table.insert(undoStack, {label=labelText, undo=undoFn, redo=redoFn})
    if #undoStack > 80 then table.remove(undoStack, 1) end
    table.clear(redoStack)
    statusMessage(labelText)
end

local function doUndo()
    local item = table.remove(undoStack)
    if not item then
        statusMessage("Nothing to undo")
        return
    end
    local ok, err = pcall(item.undo)
    if ok then
        table.insert(redoStack, item)
        statusMessage("Undo: " .. item.label)
    else
        warn("[Mobile Studio] Undo failed: " .. tostring(err))
    end
end

local function doRedo()
    local item = table.remove(redoStack)
    if not item then
        statusMessage("Nothing to redo")
        return
    end
    local ok, err = pcall(item.redo)
    if ok then
        table.insert(undoStack, item)
        statusMessage("Redo: " .. item.label)
    else
        warn("[Mobile Studio] Redo failed: " .. tostring(err))
    end
end

undoBtn.MouseButton1Click:Connect(doUndo)
redoBtn.MouseButton1Click:Connect(doRedo)

local function clearChildrenExceptLayouts(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

local function logLine(text, kind)
    local color = THEME.TextDim
    if kind == "error" then color = THEME.Error end
    if kind == "warn" then color = THEME.Warn end
    if kind == "good" then color = THEME.Good end

    local row = label(outputList, tostring(text), UDim2.new(1, -4, 0, 20), nil, {
        Font = FONT_CODE,
        TextSize = 10,
        TextColor3 = color,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 62,
    })
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.TextWrapped = true
    table.insert(outputRows, row)
    if #outputRows > 220 then
        local first = table.remove(outputRows, 1)
        if first then first:Destroy() end
    end
    task.defer(function()
        outputList.CanvasPosition = Vector2.new(0, math.max(0, outputList.AbsoluteCanvasSize.Y - outputList.AbsoluteWindowSize.Y))
    end)
end

outputClear.MouseButton1Click:Connect(function()
    for _, r in ipairs(outputRows) do
        if r then r:Destroy() end
    end
    table.clear(outputRows)
end)

pcall(function()
    LogService.MessageOut:Connect(function(message, messageType)
        if string.find(message, "Mobile Studio", 1, true) then return end
        local kind = nil
        if messageType == Enum.MessageType.MessageError then kind = "error" end
        if messageType == Enum.MessageType.MessageWarning then kind = "warn" end
        logLine(message, kind)
    end)
end)

local function objectDisplayCode(obj)
    if obj:IsA("Model") then return "M" end
    if obj:IsA("BasePart") then return "P" end
    if obj:IsA("Folder") then return "F" end
    if obj:IsA("Script") then return "S" end
    if obj:IsA("LocalScript") then return "L" end
    if obj:IsA("ModuleScript") then return "M" end
    if obj:IsA("ScreenGui") then return "UI" end
    if obj:IsA("GuiObject") then return "G" end
    if obj:IsA("Sound") then return "A" end
    if obj:IsA("Humanoid") then return "H" end
    return ""
end

local coreServices = {}
local serviceNames = {
    "Workspace", "Players", "Lighting", "ReplicatedFirst", "ReplicatedStorage",
    "ServerScriptService", "ServerStorage", "StarterGui", "StarterPack",
    "StarterPlayer", "SoundService"
}
for _, name in ipairs(serviceNames) do
    local ok, service = pcall(function() return game:GetService(name) end)
    if ok and service then table.insert(coreServices, service) end
end

local function hasChildren(obj)
    local ok, children = pcall(function() return obj:GetChildren() end)
    return ok and #children > 0
end

local function clearSelectionVisual()
    selectionBox.Adornee = nil
    highlight.Enabled = false
    highlight.Adornee = nil
end

local rebuildProperties
local rebuildExplorer

local function selectObject(obj)
    selected = obj
    clearSelectionVisual()
    if obj then
        if obj:IsA("BasePart") then
            selectionBox.Adornee = obj
        elseif obj:IsA("Model") then
            highlight.Adornee = obj
            highlight.Enabled = true
        end
        statusMessage("Selected: " .. obj:GetFullName())
    else
        statusMessage("Ready")
    end
    if rebuildExplorer then rebuildExplorer() end
    if rebuildProperties then rebuildProperties() end
end

local function treeRow(obj, depth, order)
    local row = create("TextButton", {
        Name = "TreeRow",
        AutoButtonColor = false,
        BackgroundColor3 = obj == selected and THEME.Select or THEME.Back2,
        BackgroundTransparency = obj == selected and 0 or 1,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.new(1, 0, 0, 24),
        LayoutOrder = order,
        ZIndex = 22,
    }, explorerList)

    local indent = 6 + depth * 14
    local children = hasChildren(obj)
    local caret = label(row, children and (expanded[obj] and "-" or "+") or "", UDim2.new(0, 18, 1, 0), UDim2.new(0, indent, 0, 0), {
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = THEME.TextDim,
        TextSize = 12,
        Font = FONT_MED,
        ZIndex = 23,
    })
    local code = objectDisplayCode(obj)
    local icon = label(row, code, UDim2.new(0, 24, 1, 0), UDim2.new(0, indent + 17, 0, 0), {
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = obj:IsA("BasePart") and Color3.fromRGB(115, 174, 220) or THEME.TextDim,
        TextSize = code == "UI" and 9 or 10,
        Font = FONT_BOLD,
        ZIndex = 23,
    })
    local nameLabel = label(row, obj.Name, UDim2.new(1, -(indent + 45), 1, 0), UDim2.new(0, indent + 42, 0, 0), {
        TextColor3 = THEME.Text,
        TextSize = 11,
        ZIndex = 23,
    })

    row.MouseEnter:Connect(function()
        if obj ~= selected then row.BackgroundColor3 = THEME.Back3; row.BackgroundTransparency = 0 end
    end)
    row.MouseLeave:Connect(function()
        if obj ~= selected then row.BackgroundTransparency = 1 end
    end)

    row.MouseButton1Click:Connect(function()
        selectObject(obj)
    end)

    if children then
        caret.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                expanded[obj] = not expanded[obj]
                rebuildExplorer()
            end
        end)
    end

    return row
end

local explorerRefreshQueued = false
rebuildExplorer = function()
    explorerRefreshQueued = false
    clearChildrenExceptLayouts(explorerList)
    local search = string.lower(explorerSearch.Text or "")
    local order = 0
    local count = 0
    local MAX_ROWS = 450

    local function addNode(obj, depth)
        if count >= MAX_ROWS then return end
        local objectName = string.lower(obj.Name)
        local matches = search == "" or string.find(objectName, search, 1, true) ~= nil or string.find(string.lower(obj.ClassName), search, 1, true) ~= nil

        if search ~= "" then
            if matches then
                order += 1; count += 1
                treeRow(obj, depth, order)
            end
            local ok, children = pcall(function() return obj:GetChildren() end)
            if ok then
                for _, child in ipairs(children) do addNode(child, depth + 1) end
            end
            return
        end

        order += 1; count += 1
        treeRow(obj, depth, order)
        if expanded[obj] then
            local ok, children = pcall(function() return obj:GetChildren() end)
            if ok then
                table.sort(children, function(a, b)
                    if a.ClassName == b.ClassName then return a.Name:lower() < b.Name:lower() end
                    return a.ClassName < b.ClassName
                end)
                for _, child in ipairs(children) do addNode(child, depth + 1) end
            end
        end
    end

    for _, service in ipairs(coreServices) do addNode(service, 0) end
    if count >= MAX_ROWS then
        local cap = label(explorerList, "Tree limited to " .. MAX_ROWS .. " rows", UDim2.new(1, 0, 0, 26), nil, {TextColor3=THEME.Warn, TextSize=10, ZIndex=22})
        cap.LayoutOrder = 999999
        cap.TextXAlignment = Enum.TextXAlignment.Center
    end
end

expanded[Workspace] = true
explorerSearch:GetPropertyChangedSignal("Text"):Connect(function()
    task.defer(rebuildExplorer)
end)

local function queueExplorerRefresh()
    if explorerRefreshQueued then return end
    explorerRefreshQueued = true
    task.delay(0.08, function()
        if screen.Parent then rebuildExplorer() end
    end)
end

Workspace.DescendantAdded:Connect(queueExplorerRefresh)
Workspace.DescendantRemoving:Connect(queueExplorerRefresh)

local function propCategory(name)
    local row = create("Frame", {
        Name = "Category_" .. name,
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundColor3 = THEME.Back3,
        BorderSizePixel = 0,
        ZIndex = 22,
    }, propertiesList)
    label(row, name, UDim2.new(1, -8, 1, 0), UDim2.new(0, 8, 0, 0), {Font=FONT_BOLD, TextSize=10, ZIndex=23})
    return row
end

local function propRowBase(name, height)
    local row = create("Frame", {
        Name = "Prop_" .. name,
        Size = UDim2.new(1, 0, 0, height or 28),
        BackgroundColor3 = THEME.Back2,
        BorderSizePixel = 0,
        ZIndex = 22,
    }, propertiesList)
    create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = THEME.BorderSoft,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        ZIndex = 23,
    }, row)
    label(row, name, UDim2.new(0.42, -6, 1, 0), UDim2.new(0, 8, 0, 0), {TextColor3=THEME.TextDim, TextSize=10, ZIndex=24})
    return row
end

local function changeProperty(obj, prop, newValue, historyLabel)
    if not obj or not obj.Parent then return false end
    local okOld, oldValue = pcall(function() return obj[prop] end)
    if not okOld then return false end
    local okSet, err = pcall(function() obj[prop] = newValue end)
    if not okSet then
        statusMessage("Invalid value: " .. tostring(err))
        return false
    end
    pushHistory(historyLabel or ("Change " .. prop),
        function() if obj and obj.Parent then obj[prop] = oldValue end end,
        function() if obj and obj.Parent then obj[prop] = newValue end end)
    return true
end

local function propText(name, value, commit)
    local row = propRowBase(name, 29)
    local box = textbox(row, tostring(value), "", UDim2.new(0.58, -8, 0, 22), UDim2.new(0.42, 0, 0.5, -11))
    box.ZIndex = 25
    box.FocusLost:Connect(function(enterPressed)
        commit(box.Text, box)
    end)
    return box
end

local function propBool(name, value, commit)
    local row = propRowBase(name, 29)
    local b = button(row, value and "On" or "Off", UDim2.new(0.58, -8, 0, 22), UDim2.new(0.42, 0, 0.5, -11), {Corner=false, BackgroundColor3=value and THEME.Accent or THEME.Back3, ZIndex=25})
    b.MouseButton1Click:Connect(function()
        local newValue = not value
        if commit(newValue) then
            value = newValue
            b.Text = value and "On" or "Off"
            b.BackgroundColor3 = value and THEME.Accent or THEME.Back3
        end
    end)
    return b
end

local function propVector3(name, vec, commit)
    local row = propRowBase(name, 54)
    local fieldW = 0.18
    local starts = {0.42, 0.61, 0.80}
    local vals = {vec.X, vec.Y, vec.Z}
    local fields = {}
    for i, axis in ipairs({"X", "Y", "Z"}) do
        label(row, axis, UDim2.new(0, 11, 0, 20), UDim2.new(starts[i], 1, 0, 3), {TextColor3=THEME.TextFaint, TextSize=9, ZIndex=25})
        local box = textbox(row, string.format("%.3f", vals[i]), "", UDim2.new(fieldW, -4, 0, 22), UDim2.new(starts[i], 0, 0, 26))
        box.ZIndex = 25
        fields[i] = box
        box.FocusLost:Connect(function()
            local x = tonumber(fields[1].Text)
            local y = tonumber(fields[2].Text)
            local z = tonumber(fields[3].Text)
            if not x or not y or not z then
                fields[1].Text = string.format("%.3f", vec.X)
                fields[2].Text = string.format("%.3f", vec.Y)
                fields[3].Text = string.format("%.3f", vec.Z)
                statusMessage("Vector3 requires numeric X, Y and Z")
                return
            end
            local newVec = Vector3.new(x, y, z)
            if commit(newVec) then vec = newVec end
        end)
    end
end

rebuildProperties = function()
    clearChildrenExceptLayouts(propertiesList)
    local obj = selected
    if not obj then
        propertiesTitle.Text = "Properties"
        label(propertiesList, "Select an object in Explorer or the world.", UDim2.new(1, -16, 0, 60), nil, {TextColor3=THEME.TextFaint, TextSize=10, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Center, ZIndex=22})
        return
    end

    propertiesTitle.Text = "Properties  -  " .. obj.ClassName
    propCategory("Data")
    propText("Name", obj.Name, function(text, box)
        if text == "" then box.Text = obj.Name; return end
        local ok = changeProperty(obj, "Name", text, "Rename " .. obj.ClassName)
        if ok then queueExplorerRefresh() end
    end)
    propText("ClassName", obj.ClassName, function(_, box) box.Text = obj.ClassName end)

    if obj:IsA("BasePart") then
        propCategory("Transform")
        propVector3("Position", obj.Position, function(v)
            return changeProperty(obj, "Position", v, "Move " .. obj.Name)
        end)
        propVector3("Size", obj.Size, function(v)
            v = Vector3.new(math.max(0.05, v.X), math.max(0.05, v.Y), math.max(0.05, v.Z))
            return changeProperty(obj, "Size", v, "Resize " .. obj.Name)
        end)
        propVector3("Orientation", obj.Orientation, function(v)
            return changeProperty(obj, "Orientation", v, "Rotate " .. obj.Name)
        end)

        propCategory("Appearance")
        propText("Material", tostring(obj.Material):gsub("Enum.Material.", ""), function(text, box)
            local found = nil
            for _, material in ipairs(Enum.Material:GetEnumItems()) do
                if material.Name:lower() == text:lower() then found = material; break end
            end
            if found then
                changeProperty(obj, "Material", found, "Material " .. obj.Name)
                box.Text = found.Name
            else
                box.Text = obj.Material.Name
                statusMessage("Unknown material")
            end
        end)
        propText("Transparency", tostring(obj.Transparency), function(text, box)
            local n = tonumber(text)
            if not n then box.Text=tostring(obj.Transparency); return end
            n = math.clamp(n, 0, 1)
            if changeProperty(obj, "Transparency", n, "Transparency " .. obj.Name) then box.Text=tostring(n) end
        end)

        propCategory("Behavior")
        propBool("Anchored", obj.Anchored, function(v)
            return changeProperty(obj, "Anchored", v, "Anchored " .. obj.Name)
        end)
        propBool("CanCollide", obj.CanCollide, function(v)
            return changeProperty(obj, "CanCollide", v, "CanCollide " .. obj.Name)
        end)
        propBool("CanTouch", obj.CanTouch, function(v)
            return changeProperty(obj, "CanTouch", v, "CanTouch " .. obj.Name)
        end)
        propBool("CanQuery", obj.CanQuery, function(v)
            return changeProperty(obj, "CanQuery", v, "CanQuery " .. obj.Name)
        end)
    end

    if obj:GetAttribute("MobileStudioCreated") ~= nil then
        propCategory("Attributes")
        propText("MobileStudioCreated", tostring(obj:GetAttribute("MobileStudioCreated")), function(_, box)
            box.Text = tostring(obj:GetAttribute("MobileStudioCreated"))
        end)
    end
end

propertiesSearch:GetPropertyChangedSignal("Text"):Connect(function()
    local q = string.lower(propertiesSearch.Text or "")
    for _, child in ipairs(propertiesList:GetChildren()) do
        if child:IsA("Frame") and child.Name:sub(1,5) == "Prop_" then
            child.Visible = q == "" or string.find(string.lower(child.Name), q, 1, true) ~= nil
        elseif child:IsA("Frame") and child.Name:sub(1,9) == "Category_" then
            child.Visible = q == ""
        end
    end
end)

local function createPart()
    camera = Workspace.CurrentCamera or camera
    local part = Instance.new("Part")
    part.Name = "Part"
    part.Size = Vector3.new(4, 1, 2)
    part.Anchored = true
    part:SetAttribute("MobileStudioCreated", true)
    if camera then
        part.CFrame = CFrame.new(camera.CFrame.Position + camera.CFrame.LookVector * 10)
    else
        part.Position = Vector3.new(0, 5, 0)
    end
    part.Parent = Workspace
    selectObject(part)
    expanded[Workspace] = true
    pushHistory("Create Part",
        function() if part and part.Parent then part.Parent = nil end end,
        function() if part then part.Parent = Workspace end end)
    queueExplorerRefresh()
    logLine("Created Workspace." .. part.Name, "good")
end

local function duplicateSelected()
    local obj = selected
    if not obj or obj == game then return end
    local ok, clone = pcall(function() return obj:Clone() end)
    if not ok or not clone then statusMessage("Object cannot be duplicated"); return end
    local parent = obj.Parent
    clone.Name = obj.Name
    if clone:IsA("BasePart") then clone.CFrame = clone.CFrame * CFrame.new(2, 0, 2) end
    clone.Parent = parent
    selectObject(clone)
    pushHistory("Duplicate " .. obj.Name,
        function() if clone then clone.Parent = nil end end,
        function() if clone then clone.Parent = parent end end)
    queueExplorerRefresh()
end

local function deleteSelected()
    local obj = selected
    if not obj or obj == Workspace or obj:IsA("ServiceProvider") then return end
    local parent = obj.Parent
    if not parent then return end
    local ok, clone = pcall(function() return obj:Clone() end)
    if not ok or not clone then statusMessage("Object cannot be deleted safely"); return end
    local name = obj.Name
    obj:Destroy()
    selectObject(nil)
    local restored = nil
    pushHistory("Delete " .. name,
        function()
            if restored and restored.Parent then return end
            restored = clone:Clone()
            restored.Parent = parent
            selectObject(restored)
        end,
        function()
            if restored and restored.Parent then restored:Destroy(); restored=nil; selectObject(nil) end
        end)
    queueExplorerRefresh()
end

local function toggleSelectedProperty(prop)
    if selected and selected:IsA("BasePart") then
        local old = selected[prop]
        changeProperty(selected, prop, not old, prop .. " " .. selected.Name)
        rebuildProperties()
    end
end

explorerAdd.MouseButton1Click:Connect(createPart)

local function setTool(name)
    activeTool = name
    for toolName, b in pairs(toolButtons) do
        local on = toolName == name
        b:SetAttribute("Selected", on)
        b.BackgroundColor3 = on and THEME.Accent or THEME.Back3
    end
    statusMessage("Tool: " .. name)
end

for _, toolName in ipairs({"Select", "Move", "Scale", "Rotate", "Part"}) do
    local b = button(toolDock, toolName, UDim2.new(0, toolName == "Select" and 58 or 55, 1, -6), nil, {Corner=false, BackgroundColor3=THEME.Back3, TextSize=10, ZIndex=16})
    toolButtons[toolName] = b
    b.MouseButton1Click:Connect(function()
        if toolName == "Part" then
            createPart()
            setTool("Select")
        else
            setTool(toolName)
        end
    end)
end
setTool("Select")

local toolbarTabTools = {
    Home = {
        {"Select", function() setTool("Select") end},
        {"Move", function() setTool("Move") end},
        {"Scale", function() setTool("Scale") end},
        {"Rotate", function() setTool("Rotate") end},
        {"|"},
        {"Part", createPart},
        {"Duplicate", duplicateSelected},
        {"Delete", deleteSelected},
        {"|"},
        {"Anchor", function() toggleSelectedProperty("Anchored") end},
        {"Collide", function() toggleSelectedProperty("CanCollide") end},
    },
    Model = {
        {"Move", function() setTool("Move") end},
        {"Scale", function() setTool("Scale") end},
        {"Rotate", function() setTool("Rotate") end},
        {"|"},
        {"Pivot", nil}, {"Align", nil}, {"Constraints", nil}, {"Solid", nil}, {"Terrain", nil},
    },
    Avatar = {{"Rig Builder", nil}, {"Avatar Setup", nil}, {"Animation", nil}, {"Accessories", nil}},
    UI = {{"ScreenGui", nil}, {"Frame", nil}, {"Text", nil}, {"Image", nil}, {"Layout", nil}, {"Constraints", nil}},
    Script = {{"Script", nil}, {"LocalScript", nil}, {"ModuleScript", nil}, {"Find", nil}, {"Output", function() outputToggle:Activate() end}, {"Command Bar", nil}},
    Plugins = {{"Plugin Manager", nil}, {"Create Plugin", nil}},
}

local function rebuildToolbar(tabName)
    clearChildrenExceptLayouts(toolbarContent)
    local tools = toolbarTabTools[tabName] or {}
    for _, item in ipairs(tools) do
        if item[1] == "|" then
            create("Frame", {Size=UDim2.new(0,1,0,28), BackgroundColor3=THEME.Border, BorderSizePixel=0, ZIndex=44}, toolbarContent)
        else
            local title, callback = item[1], item[2]
            local w = math.clamp(#title * 7 + 18, 48, 96)
            local b = button(toolbarContent, title, UDim2.new(0, w, 0, 30), nil, {
                Corner=false,
                BackgroundColor3=THEME.Back3,
                TextColor3=callback and THEME.Text or THEME.TextFaint,
                TextSize=10,
                ZIndex=44,
            })
            if callback then
                b.MouseButton1Click:Connect(callback)
            else
                b.MouseButton1Click:Connect(function()
                    statusMessage(title .. " is planned for a later milestone")
                end)
            end
        end
    end
end

local function setTab(tabName)
    activeTab = tabName
    for name, b in pairs(tabButtons) do
        local on = name == tabName
        b.TextColor3 = on and THEME.Text or THEME.TextDim
        b.BackgroundColor3 = on and THEME.Back3 or THEME.Back2
        b:SetAttribute("Selected", on)
    end
    rebuildToolbar(tabName)
end

for index, tabName in ipairs({"Home", "Model", "Avatar", "UI", "Script", "Plugins"}) do
    local b = button(tabStrip, tabName, UDim2.new(0, math.max(58, #tabName*8+18), 0, TAB_H-2), nil, {Corner=false, BackgroundColor3=THEME.Back2, TextSize=11, ZIndex=47})
    b.LayoutOrder = index
    tabButtons[tabName] = b
    b.MouseButton1Click:Connect(function() setTab(tabName) end)
end
setTab("Home")

local function setOutputVisible(value)
    outputVisible = value
    outputTray.Visible = value
    if value then
        local h = math.clamp(math.floor((Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize.Y or 700) * 0.32), 145, 260)
        outputTray.Size = UDim2.new(1, 0, 0, h)
    end
end

outputToggle.MouseButton1Click:Connect(function() setOutputVisible(not outputVisible) end)

local function layoutPanels()
    local vp = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(900, 600)
    local w, h = vp.X, vp.Y
    local landscape = w > h
    dockedPanels = landscape and w >= 1180

    if dockedPanels then
        explorer.Size = UDim2.new(0, 260, 1, 0)
        explorer.Position = UDim2.new(0, 0, 0, 0)
        explorer.AnchorPoint = Vector2.new(0, 0)
        properties.Size = UDim2.new(0, 285, 1, 0)
        properties.Position = UDim2.new(1, 0, 0, 0)
        properties.AnchorPoint = Vector2.new(1, 0)
        explorer.Visible = explorerVisible
        properties.Visible = propertiesVisible
    else
        local panelW = math.min(330, math.floor(w * (landscape and 0.43 or 0.88)))
        explorer.Size = UDim2.new(0, panelW, 1, 0)
        explorer.Position = explorerVisible and UDim2.new(0, 0, 0, 0) or UDim2.new(0, -panelW - 3, 0, 0)
        explorer.AnchorPoint = Vector2.new(0, 0)
        explorer.Visible = true
        properties.Size = UDim2.new(0, panelW, 1, 0)
        properties.Position = propertiesVisible and UDim2.new(1, 0, 0, 0) or UDim2.new(1, panelW + 3, 0, 0)
        properties.AnchorPoint = Vector2.new(1, 0)
        properties.Visible = true
    end

    if w < 760 then
        projectTitle.Text = "Mobile Studio"
        explorerToggle.Text = "Explorer"
        propertiesToggle.Text = "Props"
    else
        projectTitle.Text = "Mobile Studio  |  Runtime Project"
        explorerToggle.Text = "Explorer"
        propertiesToggle.Text = "Properties"
    end

    toolDock.Size = UDim2.new(0, math.min(306, w - 24), 0, 38)
end

local function tweenPanel(panel, pos)
    local tween = TweenService:Create(panel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position=pos})
    tween:Play()
end

local function setExplorerVisible(value)
    explorerVisible = value
    if dockedPanels then
        explorer.Visible = value
    else
        local width = explorer.AbsoluteSize.X
        explorer.Visible = true
        tweenPanel(explorer, value and UDim2.new(0,0,0,0) or UDim2.new(0,-width-3,0,0))
    end
end

local function setPropertiesVisible(value)
    propertiesVisible = value
    if dockedPanels then
        properties.Visible = value
    else
        local width = properties.AbsoluteSize.X
        properties.Visible = true
        tweenPanel(properties, value and UDim2.new(1,0,0,0) or UDim2.new(1,width+3,0,0))
    end
end

explorerToggle.MouseButton1Click:Connect(function() setExplorerVisible(not explorerVisible) end)
propertiesToggle.MouseButton1Click:Connect(function() setPropertiesVisible(not propertiesVisible) end)
explorerClose.MouseButton1Click:Connect(function() setExplorerVisible(false) end)
propertiesClose.MouseButton1Click:Connect(function() setPropertiesVisible(false) end)

local function guiAt(x, y)
    local ok, items = pcall(function() return GuiService:GetGuiObjectsAtPosition(x, y) end)
    if not ok then return false end
    for _, item in ipairs(items) do
        if item:IsDescendantOf(screen) and item.Visible then return true end
    end
    return false
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function raycastScreen(screenPos)
    camera = Workspace.CurrentCamera or camera
    if not camera then return nil end
    local char = player.Character
    rayParams.FilterDescendantsInstances = char and {char, selectionBox, highlight} or {selectionBox, highlight}
    local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
    return Workspace:Raycast(ray.Origin, ray.Direction * 5000, rayParams)
end

local drag = nil
local function startManipulation(input, obj)
    if not obj or not obj:IsA("BasePart") or activeTool == "Select" then return end
    drag = {
        input = input,
        tool = activeTool,
        object = obj,
        startPos = Vector2.new(input.Position.X, input.Position.Y),
        startCFrame = obj.CFrame,
        startSize = obj.Size,
    }
end

local function snap(n, step)
    return math.floor(n / step + 0.5) * step
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local p = Vector2.new(input.Position.X, input.Position.Y)
    if guiAt(p.X, p.Y) then return end

    local hit = raycastScreen(p)
    if hit and hit.Instance then
        local obj = hit.Instance
        selectObject(obj)
        startManipulation(input, obj)
    elseif activeTool == "Select" then
        selectObject(nil)
    end
end)

UserInputService.InputChanged:Connect(function(input, processed)
    if not drag or not drag.object or not drag.object.Parent then return end
    local matchesTouch = drag.input.UserInputType == Enum.UserInputType.Touch and input == drag.input
    local matchesMouse = drag.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement
    if not matchesTouch and not matchesMouse then return end

    local now = Vector2.new(input.Position.X, input.Position.Y)
    local delta = now - drag.startPos
    local obj = drag.object
    camera = Workspace.CurrentCamera or camera

    if drag.tool == "Move" and camera then
        local right = camera.CFrame.RightVector
        local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
        if look.Magnitude < 0.01 then look = Vector3.new(0,0,-1) else look = look.Unit end
        local worldDelta = right * (delta.X * 0.03) + look * (-delta.Y * 0.03)
        local p = drag.startCFrame.Position + worldDelta
        p = Vector3.new(snap(p.X, 0.25), snap(p.Y, 0.25), snap(p.Z, 0.25))
        obj.CFrame = CFrame.new(p) * (drag.startCFrame - drag.startCFrame.Position)
    elseif drag.tool == "Scale" then
        local amount = (delta.X - delta.Y) * 0.018
        local s = drag.startSize + Vector3.new(amount, amount, amount)
        obj.Size = Vector3.new(math.max(0.05,s.X), math.max(0.05,s.Y), math.max(0.05,s.Z))
    elseif drag.tool == "Rotate" then
        local angle = snap(delta.X * 0.45, 1)
        obj.CFrame = drag.startCFrame * CFrame.Angles(0, math.rad(angle), 0)
    end
end)

UserInputService.InputEnded:Connect(function(input, processed)
    if not drag then return end
    local touchEnd = drag.input.UserInputType == Enum.UserInputType.Touch and input == drag.input
    local mouseEnd = drag.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1
    if not touchEnd and not mouseEnd then return end

    local d = drag
    drag = nil
    local obj = d.object
    if not obj or not obj.Parent then return end

    if d.tool == "Move" and obj.CFrame ~= d.startCFrame then
        local final = obj.CFrame
        pushHistory("Move " .. obj.Name,
            function() if obj.Parent then obj.CFrame = d.startCFrame; rebuildProperties() end end,
            function() if obj.Parent then obj.CFrame = final; rebuildProperties() end end)
    elseif d.tool == "Scale" and obj.Size ~= d.startSize then
        local final = obj.Size
        pushHistory("Scale " .. obj.Name,
            function() if obj.Parent then obj.Size = d.startSize; rebuildProperties() end end,
            function() if obj.Parent then obj.Size = final; rebuildProperties() end end)
    elseif d.tool == "Rotate" and obj.CFrame ~= d.startCFrame then
        local final = obj.CFrame
        pushHistory("Rotate " .. obj.Name,
            function() if obj.Parent then obj.CFrame = d.startCFrame; rebuildProperties() end end,
            function() if obj.Parent then obj.CFrame = final; rebuildProperties() end end)
    end
    rebuildProperties()
end)

local keyDown = {}
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    keyDown[input.KeyCode] = true
    local ctrl = keyDown[Enum.KeyCode.LeftControl] or keyDown[Enum.KeyCode.RightControl]
    if ctrl and input.KeyCode == Enum.KeyCode.Z then doUndo() end
    if ctrl and input.KeyCode == Enum.KeyCode.Y then doRedo() end
    if ctrl and input.KeyCode == Enum.KeyCode.D then duplicateSelected() end
    if input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.Backspace then deleteSelected() end
end)
UserInputService.InputEnded:Connect(function(input)
    keyDown[input.KeyCode] = nil
end)

local frameCount = 0
local frameTime = 0
RunService.RenderStepped:Connect(function(dt)
    frameCount += 1
    frameTime += dt
    if frameTime >= 1 then
        fpsValue = math.floor(frameCount / frameTime + 0.5)
        frameCount = 0
        frameTime = 0
        local selectedText = selected and (" | " .. selected.Name) or ""
        statusRight.Text = "FPS " .. fpsValue .. selectedText .. " | v" .. VERSION
    end
end)

if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutPanels)
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    camera = Workspace.CurrentCamera
    if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutPanels) end
    layoutPanels()
end)

-- On compact phones, start with panels hidden so the world stays usable.
local vp = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(900,600)
if vp.X < 1180 then
    explorerVisible = false
    propertiesVisible = false
end

layoutPanels()
rebuildExplorer()
rebuildProperties()
logLine("Mobile Studio v" .. VERSION .. " started", "good")
logLine("Explorer, selection, basic Properties, create/duplicate/delete and undo/redo are active.")
logLine("This milestone edits the local runtime. Persistent project serialization and publishing are not active yet.", "warn")

print("[Mobile Studio] v" .. VERSION .. " ready")
