-- NEXON-Style GetKey System
-- Modern GUI with 14-day trial functionality
-- Created: April 7, 2025

local KeySystem = {}
KeySystem.__index = KeySystem

-- Configuration
local CONFIG = {
    TITLE = "NEXON EXECUTOR",
    SUBTITLE = "Premium Exploit",
    THEME = {
        PRIMARY = Color3.fromRGB(0, 120, 215),    -- Blue
        SECONDARY = Color3.fromRGB(29, 29, 29),   -- Dark Gray
        ACCENT = Color3.fromRGB(255, 128, 0),     -- Orange
        TEXT_PRIMARY = Color3.fromRGB(255, 255, 255),
        TEXT_SECONDARY = Color3.fromRGB(180, 180, 180),
        BACKGROUND = Color3.fromRGB(18, 18, 18),
        SUCCESS = Color3.fromRGB(76, 217, 100),
        ERROR = Color3.fromRGB(255, 59, 48)
    },
    -- Hard-coded key with 14-day expiration
     KEY_DATA = {
        ["NEXON-4D7F-9E2B-H8K3"] = {
            created = os.time(),
            expires = os.time() + (14 * 24 * 60 * 60) -- 14 days in seconds
        },
        ["NEXON-9A7C-8B2K-P4E1"] = {
            created = os.time(),
            expires = os.time() + (14 * 24 * 60 * 60) -- 14 days in seconds
        },
        ["NEXON-5R3T-7Y6P-J2Z8"] = {
            created = os.time(),
            expires = os.time() + (14 * 24 * 60 * 60) -- 14 days in seconds
        },
        ["NEXON-L8M1-K4N6-W9X3"] = {
            created = os.time(),
            expires = os.time() + (14 * 24 * 60 * 60) -- 14 days in seconds
        },
        ["NEXON-Q2Z5-G7H9-F3V6"] = {
            created = os.time(),
            expires = os.time() + (14 * 24 * 60 * 60) -- 14 days in seconds
        }
    },
    -- For demo purposes only
    VALID_KEYS = {"NEXON-4D7F-9E2B-H8K3"},{}
}

-- Utility Functions
local function CreateElement(class, properties)
    local element = Instance.new(class)
    for prop, value in pairs(properties or {}) do
        element[prop] = value
    end
    return element
end

local function FormatTime(seconds)
    if seconds <= 0 then
        return "Expired"
    end
    
    local days = math.floor(seconds / (24 * 60 * 60))
    seconds = seconds % (24 * 60 * 60)
    local hours = math.floor(seconds / (60 * 60))
    seconds = seconds % (60 * 60)
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    
    return string.format("%d days, %02d:%02d:%02d", days, hours, minutes, seconds)
end

local function CreateCorner(parent, radius)
    local corner = CreateElement("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent
    })
    return corner
end

local function CreateStroke(parent, color, thickness)
    local stroke = CreateElement("UIStroke", {
        Color = color or CONFIG.THEME.PRIMARY,
        Thickness = thickness or 1.5,
        Parent = parent
    })
    return stroke
end

local function CreateGradient(parent, colors)
    local gradient = CreateElement("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, colors[1] or CONFIG.THEME.PRIMARY),
            ColorSequenceKeypoint.new(1, colors[2] or CONFIG.THEME.SECONDARY)
        }),
        Parent = parent
    })
    return gradient
end

-- Key System Implementation
function KeySystem.new()
    local self = setmetatable({}, KeySystem)
    self.Authenticated = false
    self.TimeRemaining = 0
    self.CurrentKey = ""
    self.GUI = nil
    self.Timer = nil
    return self
end

function KeySystem:ValidateKey(keyInput)
    -- Check if key exists in our database
    local keyData = CONFIG.KEY_DATA[keyInput]
    if not keyData then
        return false, "Invalid key"
    end
    
    -- Check if key has expired
    local currentTime = os.time()
    if currentTime > keyData.expires then
        return false, "Key expired"
    end
    
    -- Key is valid and not expired
    self.TimeRemaining = keyData.expires - currentTime
    self.CurrentKey = keyInput
    return true, "Key validated successfully"
end

function KeySystem:StartTimer()
    if self.Timer then
        self.Timer:Disconnect()
    end
    
    -- Update every minute (60 seconds)
    self.Timer = game:GetService("RunService").Heartbeat:Connect(function()
        if self.TimeRemaining > 0 then
            self.TimeRemaining = self.TimeRemaining - 1
            
            -- Update the timer display if GUI exists
            if self.GUI and self.GUI.Parent and self.GUI.MainFrame.StatusFrame.TimeRemaining then
                self.GUI.MainFrame.StatusFrame.TimeRemaining.Text = "Time Remaining: " .. FormatTime(self.TimeRemaining)
                
                -- Update progress bar
                local totalTime = 14 * 24 * 60 * 60 -- 14 days in seconds
                local percentRemaining = self.TimeRemaining / totalTime
                self.GUI.MainFrame.StatusFrame.ProgressBar:TweenSize(
                    UDim2.new(percentRemaining, 0, 1, 0),
                    Enum.EasingDirection.Out,
                    Enum.EasingStyle.Quad,
                    0.5,
                    true
                )
                
                -- Change color based on time remaining
                if self.TimeRemaining < (3 * 24 * 60 * 60) then -- Less than 3 days
                    self.GUI.MainFrame.StatusFrame.ProgressBar.BackgroundColor3 = CONFIG.THEME.ERROR
                elseif self.TimeRemaining < (7 * 24 * 60 * 60) then -- Less than 7 days
                    self.GUI.MainFrame.StatusFrame.ProgressBar.BackgroundColor3 = CONFIG.THEME.ACCENT
                else
                    self.GUI.MainFrame.StatusFrame.ProgressBar.BackgroundColor3 = CONFIG.THEME.SUCCESS
                end
            end
            
            -- Check expiration every minute
            if self.TimeRemaining % 60 == 0 then
                -- Auto-save remaining time to keep track between sessions
                if self.CurrentKey ~= "" then
                    CONFIG.KEY_DATA[self.CurrentKey].expires = os.time() + self.TimeRemaining
                end
                
                -- If time is up, log out
                if self.TimeRemaining <= 0 then
                    self.Authenticated = false
                    self:ShowMessage("Your key has expired", CONFIG.THEME.ERROR)
                    self:ShowLoginScreen()
                end
            end
        end
    end)
end

function KeySystem:ShowMessage(message, color)
    if not self.GUI or not self.GUI.Parent then return end
    
    local messageFrame = self.GUI.MainFrame.MessageFrame
    messageFrame.Message.Text = message
    messageFrame.Message.TextColor3 = color or CONFIG.THEME.TEXT_PRIMARY
    
    -- Show message with animation
    messageFrame.Visible = true
    messageFrame.Position = UDim2.new(0.5, 0, -0.1, 0)
    messageFrame:TweenPosition(
        UDim2.new(0.5, 0, 0.1, 0),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Bounce,
        0.5,
        true
    )
    
    -- Hide after 3 seconds
    spawn(function()
        wait(3)
        messageFrame:TweenPosition(
            UDim2.new(0.5, 0, -0.1, 0),
            Enum.EasingDirection.In,
            Enum.EasingStyle.Quad,
            0.5,
            true,
            function()
                messageFrame.Visible = false
            end
        )
    end)
end

function KeySystem:ShowStatusScreen()
    if not self.GUI or not self.GUI.Parent then return end
    
    -- Hide login screen
    self.GUI.MainFrame.LoginFrame.Visible = false
    
    -- Show status screen
    local statusFrame = self.GUI.MainFrame.StatusFrame
    statusFrame.Visible = true
    statusFrame.KeyDisplay.Text = "Key: " .. string.sub(self.CurrentKey, 1, 6) .. "..." .. string.sub(self.CurrentKey, -4)
    statusFrame.TimeRemaining.Text = "Time Remaining: " .. FormatTime(self.TimeRemaining)
    
    -- Set initial progress bar
    local totalTime = 14 * 24 * 60 * 60 -- 14 days in seconds
    local percentRemaining = self.TimeRemaining / totalTime
    statusFrame.ProgressBar.Size = UDim2.new(percentRemaining, 0, 1, 0)
    
    -- Set color based on time remaining
    if self.TimeRemaining < (3 * 24 * 60 * 60) then -- Less than 3 days
        statusFrame.ProgressBar.BackgroundColor3 = CONFIG.THEME.ERROR
    elseif self.TimeRemaining < (7 * 24 * 60 * 60) then -- Less than 7 days
        statusFrame.ProgressBar.BackgroundColor3 = CONFIG.THEME.ACCENT
    else
        statusFrame.ProgressBar.BackgroundColor3 = CONFIG.THEME.SUCCESS
    end
    
    -- Start countdown timer
    self:StartTimer()
end

function KeySystem:ShowLoginScreen()
    if not self.GUI or not self.GUI.Parent then return end
    
    -- Hide status screen
    self.GUI.MainFrame.StatusFrame.Visible = false
    
    -- Show login screen
    self.GUI.MainFrame.LoginFrame.Visible = true
    self.GUI.MainFrame.LoginFrame.KeyInput.Text = ""
end

function KeySystem:CreateGUI()
    -- Create ScreenGui
    local screenGui = CreateElement("ScreenGui", {
        Name = "NEXONKeySystem",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game:GetService("CoreGui")
    })
    
    -- Create Main Frame
    local mainFrame = CreateElement("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 400, 0, 300),
        Position = UDim2.new(0.5, -200, 0.5, -150),
        BackgroundColor3 = CONFIG.THEME.BACKGROUND,
        BorderSizePixel = 0,
        Parent = screenGui
    })
    CreateCorner(mainFrame, 10)
    CreateStroke(mainFrame, CONFIG.THEME.PRIMARY, 2)
    
    -- Title Bar
    local titleBar = CreateElement("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = CONFIG.THEME.SECONDARY,
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    CreateCorner(titleBar, 10)
    
    -- Make bottom corners square
    local titleBarBottomFrame = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0.5, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = CONFIG.THEME.SECONDARY,
        BorderSizePixel = 0,
        Parent = titleBar
    })
    
    -- Title
    local title = CreateElement("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = CONFIG.THEME.TEXT_PRIMARY,
        Font = Enum.Font.GothamBold,
        Text = CONFIG.TITLE,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar
    })
    
    -- Close Button
    local closeButton = CreateElement("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(1, -40, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = CONFIG.THEME.TEXT_PRIMARY,
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextSize = 24,
        Parent = titleBar
    })
    
    -- Subtitle
    local subtitle = CreateElement("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(1, -30, 0, 20),
        Position = UDim2.new(0, 15, 0, 45),
        BackgroundTransparency = 1,
        TextColor3 = CONFIG.THEME.ACCENT,
        Font = Enum.Font.Gotham,
        Text = CONFIG.SUBTITLE,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = mainFrame
    })
    
    -- Login Frame
    local loginFrame = CreateElement("Frame", {
        Name = "LoginFrame",
        Size = UDim2.new(1, -40, 1, -100),
        Position = UDim2.new(0, 20, 0, 80),
        BackgroundTransparency = 1,
        Visible = true,
        Parent = mainFrame
    })
    
    -- Key Input Label
    local keyLabel = CreateElement("TextLabel", {
        Name = "KeyLabel",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 10),
        BackgroundTransparency = 1,
        TextColor3 = CONFIG.THEME.TEXT_PRIMARY,
        Font = Enum.Font.Gotham,
        Text = "Enter your activation key",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = loginFrame
    })
    
    -- Key Input Box
    local keyInput = CreateElement("TextBox", {
        Name = "KeyInput",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = CONFIG.THEME.SECONDARY,
        TextColor3 = CONFIG.THEME.TEXT_PRIMARY,
        PlaceholderText = "NEXON-XXXX-XXXX-XXXX",
        PlaceholderColor3 = CONFIG.THEME.TEXT_SECONDARY,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        Text = "",
        ClearTextOnFocus = false,
        Parent = loginFrame
    })
    CreateCorner(keyInput, 6)
    
    -- Login Button
    local loginButton = CreateElement("TextButton", {
        Name = "LoginButton",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 100),
        BackgroundColor3 = CONFIG.THEME.PRIMARY,
        TextColor3 = CONFIG.THEME.TEXT_PRIMARY,
        Font = Enum.Font.GothamBold,
        Text = "ACTIVATE",
        TextSize = 16,
        Parent = loginFrame
    })
    CreateCorner(loginButton, 6)
    CreateGradient(loginButton, {CONFIG.THEME.PRIMARY, Color3.fromRGB(0, 80, 175)})
    
    -- Note Label
    local noteLabel = CreateElement("TextLabel", {
        Name = "NoteLabel",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 160),
        BackgroundTransparency = 1,
        TextColor3 = CONFIG.THEME.TEXT_SECONDARY,
        Font = Enum.Font.Gotham,
        Text = "Your key will be active for 14 days from activation.\nTime countdown is active even when offline.",
        TextSize = 12,
        TextWrapped = true,
        Parent = loginFrame
    })
    
    -- Status Frame (initially hidden)
    local statusFrame = CreateElement("Frame", {
        Name = "StatusFrame",
        Size = UDim2.new(1, -40, 1, -100),
        Position = UDim2.new(0, 20, 0, 80),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = mainFrame
    })
    
    -- Status Title
    local statusTitle = CreateElement("TextLabel", {
        Name = "StatusTitle",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 10),
        BackgroundTransparency = 1,
        TextColor3 = CONFIG.THEME.TEXT_PRIMARY,
        Font = Enum.Font.GothamBold,
        Text = "Activated Successfully",
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = statusFrame
    })
    
    -- Key Display
    local keyDisplay = CreateElement("TextLabel", {
        Name = "KeyDisplay",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        TextColor3 = CONFIG.THEME.TEXT_SECONDARY,
        Font = Enum.Font.Gotham,
        Text = "Key: NEXON-****-****-****",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = statusFrame
    })
    
    -- Time Remaining
    local timeRemaining = CreateElement("TextLabel", {
        Name = "TimeRemaining",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 70),
        BackgroundTransparency = 1,
        TextColor3 = CONFIG.THEME.TEXT_PRIMARY,
        Font = Enum.Font.Gotham,
        Text = "Time Remaining: 14 days, 00:00:00",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = statusFrame
    })
    
    -- Progress Bar Background
    local progressBarBg = CreateElement("Frame", {
        Name = "ProgressBarBg",
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 0, 100),
        BackgroundColor3 = CONFIG.THEME.SECONDARY,
        BorderSizePixel = 0,
        Parent = statusFrame
    })
    CreateCorner(progressBarBg, 5)
    
    -- Progress Bar
    local progressBar = CreateElement("Frame", {
        Name = "ProgressBar",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = CONFIG.THEME.SUCCESS,
        BorderSizePixel = 0,
        Parent = progressBarBg
    })
    CreateCorner(progressBar, 5)
    
    -- Logout Button
    local logoutButton = CreateElement("TextButton", {
        Name = "LogoutButton",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 130),
        BackgroundColor3 = CONFIG.THEME.SECONDARY,
        TextColor3 = CONFIG.THEME.TEXT_PRIMARY,
        Font = Enum.Font.GothamBold,
        Text = "CONTINUE TO EXECUTOR",
        TextSize = 14,
        Parent = statusFrame
    })
    CreateCorner(logoutButton, 6)
    CreateGradient(logoutButton, {CONFIG.THEME.ACCENT, Color3.fromRGB(200, 80, 0)})
    
    -- Message Frame (for notifications)
    local messageFrame = CreateElement("Frame", {
        Name = "MessageFrame",
        Size = UDim2.new(0.8, 0, 0, 40),
        Position = UDim2.new(0.5, 0, -0.1, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = CONFIG.THEME.SECONDARY,
        BorderSizePixel = 0,
        Visible = false,
        Parent = mainFrame
    })
    CreateCorner(messageFrame, 6)
    
    -- Message Text
    local messageText = CreateElement("TextLabel", {
        Name = "Message",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = CONFIG.THEME.TEXT_PRIMARY,
        Font = Enum.Font.Gotham,
        Text = "Message goes here",
        TextSize =.14,
        TextWrapped = true,
        Parent = messageFrame
    })
    
    -- Make window draggable
    local isDragging = false
    local dragInput
    local dragStart
    local startPos
    
    local function updateDrag(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and isDragging then
            updateDrag(input)
        end
    end)
    
    -- Connect button events
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        if self.Timer then
            self.Timer:Disconnect()
        end
    end)
    
    loginButton.MouseButton1Click:Connect(function()
        local key = keyInput.Text
        local success, message = self:ValidateKey(key)
        
        if success then
            self.Authenticated = true
            self:ShowMessage("Successfully activated!", CONFIG.THEME.SUCCESS)
            self:ShowStatusScreen()
        else
            self:ShowMessage(message, CONFIG.THEME.ERROR)
        end
    end)
    
    logoutButton.MouseButton1Click:Connect(function()
        self:ShowMessage("Executor loading...", CONFIG.THEME.PRIMARY)
        -- Execute the loadstring to load your executor
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/NEXONHUB/HelloWord/refs/heads/main/script.lua"))() -- ใส่ URL ของ executor ของคุณที่นี่
        end)
        wait(1)
        screenGui:Destroy()
        if self.Timer then
            self.Timer:Disconnect()
        end
    end)
    
    -- Button hover effects
    local function addHoverEffect(button)
        button.MouseEnter:Connect(function()
            button:TweenSize(
                UDim2.new(button.Size.X.Scale, button.Size.X.Offset, button.Size.Y.Scale, button.Size.Y.Offset + 5),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.2,
                true
            )
        end)
        
        button.MouseLeave:Connect(function()
            button:TweenSize(
                UDim2.new(button.Size.X.Scale, button.Size.X.Offset, button.Size.Y.Scale, button.Size.Y.Offset - 5),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.2,
                true
            )
        end)
    end
    
    addHoverEffect(loginButton)
    addHoverEffect(logoutButton)
    
    -- Store GUI reference
    self.GUI = screenGui
    return screenGui
end

-- Initialize and show GUI
function KeySystem:Initialize()
    self:CreateGUI()
    self:ShowLoginScreen()
    return self
end

-- วิธีการใช้งาน
-- 1. อัปโหลดสคริปต์นี้ไปยังเว็บโฮสติ้ง เช่น GitHub หรือ Pastebin
-- 2. ใช้ loadstring เพื่อเรียกใช้งานระบบ key ด้วย:
-- loadstring(game:HttpGet("YOUR_SCRIPT_URL_HERE"))()

-- เรียกใช้งานระบบเมื่อสคริปต์นี้ถูกโหลดผ่าน loadstring
local keySystem = KeySystem.new():Initialize()

-- For testing purposes only - this would let you automatically validate with the test key
-- Uncomment this to test the status screen
--[[
wait(2)
keySystem.GUI.MainFrame.LoginFrame.KeyInput.Text = "NEXON-4D7F-9E2B-H8K3"
keySystem.GUI.MainFrame.LoginFrame.LoginButton.MouseButton1Click:Fire()
--]]

-- ไม่ต้อง return KeySystem เมื่อใช้ loadstring
-- return KeySystem
