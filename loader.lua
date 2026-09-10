-- Mobile Studio bootstrap
-- Paste this in a LocalScript under StarterGui > StudioUI in Studio Lite.
-- The bootstrap intentionally contains no API keys or account secrets.

local BUILD_URL = "https://raw.githubusercontent.com/Johnatafgfdgf/Mobile-Studio/main/dist/MobileStudio.lua"

local function fail(message)
	warn("[Mobile Studio] " .. tostring(message))

	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	if not player then
		return
	end

	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end

	local old = playerGui:FindFirstChild("MobileStudioLoaderError")
	if old then old:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "MobileStudioLoaderError"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 999999
	gui.Parent = playerGui

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.new(0.86, 0, 0, 180)
	card.BackgroundColor3 = Color3.fromRGB(37, 37, 39)
	card.BorderColor3 = Color3.fromRGB(74, 74, 78)
	card.Parent = gui

	local title = Instance.new("TextLabel")
	title.Position = UDim2.new(0, 14, 0, 12)
	title.Size = UDim2.new(1, -28, 0, 30)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(240, 240, 242)
	title.Text = "Mobile Studio nao conseguiu carregar a build remota"
	title.Parent = card

	local body = Instance.new("TextLabel")
	body.Position = UDim2.new(0, 14, 0, 49)
	body.Size = UDim2.new(1, -28, 1, -62)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.Gotham
	body.TextSize = 12
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextColor3 = Color3.fromRGB(193, 193, 198)
	body.Text = tostring(message) .. "\n\nSe o Studio Lite bloquear HTTP/loadstring nesse tipo de LocalScript, use temporariamente o arquivo dist/MobileStudio.lua como script unico."
	body.Parent = card
end

local function getSource(url)
	local ok, result = pcall(function()
		if type(game.HttpGet) == "function" then
			return game:HttpGet(url, true)
		end
	end)
	if ok and type(result) == "string" and #result > 0 then
		return result
	end

	local HttpService = game:GetService("HttpService")
	ok, result = pcall(function()
		return HttpService:GetAsync(url, true)
	end)
	if ok and type(result) == "string" and #result > 0 then
		return result
	end

	return nil, result
end

local source, httpError = getSource(BUILD_URL)
if not source then
	fail("HTTP indisponivel neste contexto. " .. tostring(httpError or ""))
	return
end

local compiler = rawget(getfenv and getfenv() or _G, "loadstring") or loadstring
if type(compiler) ~= "function" then
	fail("loadstring nao esta disponivel neste contexto do Studio Lite.")
	return
end

local fn, compileError = compiler(source, "MobileStudio")
if not fn then
	fail("Erro compilando a build: " .. tostring(compileError))
	return
end

local ok, runtimeError = pcall(fn)
if not ok then
	fail("Erro iniciando a build: " .. tostring(runtimeError))
end
