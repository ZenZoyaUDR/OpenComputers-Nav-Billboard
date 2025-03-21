-- Enhanced Railway System Display for OpenComputers
-- Displays a sleek interface showing your server's railway system

local component = require("component")
local computer = require("computer")
local term = require("term")
local unicode = require("unicode")
local colors = require("colors")
local gpu = component.gpu
local keyboard = require("keyboard")
local event = require("event")
local filesystem = require("filesystem")

-- Default configuration (will be overridden by config file if it exists)
local config = {
  updateInterval = 10,          -- Update interval in seconds
  screenWidth = 80,             -- Default screen width
  screenHeight = 30,            -- Default screen height
  defaultBackground = 0x000000, -- Black background
  defaultForeground = 0xFFFFFF, -- White text
  titleColor = 0x00FF00,        -- Green for title
  stationColor = 0xFFFF00,      -- Yellow for stations
  railColor = 0x808080,         -- Gray for railway lines
  mainStationColor = 0xFF0000,  -- Red for main stations/hubs
  borderColor = 0x555555,       -- Border color
  useColorsIfAvailable = true,  -- Use colors if the GPU supports it
  windowTitle = "Railway Network Display",
  animationChars = {"|", "/", "-", "\\"},
  
  -- Default railway map (will be overridden by config)
  railwayMap = {
    "                            RAILWAY NETWORK                            ",
    "                                                                       ",
    "                                                                       ",
  },
  
  -- Default stations (will be overridden by config)
  stations = {
    { name = "A", label = "EXAMPLE STATION", desc = "Example station description", x = 10, y = 5, isMain = true }
  }
}

-- Store original screen settings to restore later
local originalBackground, originalForeground
local originalWidth, originalHeight

-- Function to draw a window box
local function drawWindow(title, width, height, x, y, bgColor, fgColor, borderColor)
  -- Save current settings
  local oldBg, oldFg = gpu.getBackground(), gpu.getForeground()
  
  -- Set colors
  gpu.setBackground(bgColor)
  gpu.setForeground(borderColor)
  
  -- Draw the background
  gpu.fill(x, y, width, height, " ")
  
  -- Draw top border
  gpu.fill(x, y, width, 1, "─")
  gpu.set(x, y, "┌")
  gpu.set(x + width - 1, y, "┐")
  
  -- Draw sides
  for i = 1, height - 2 do
    gpu.set(x, y + i, "│")
    gpu.set(x + width - 1, y + i, "│")
  end
  
  -- Draw bottom border
  gpu.fill(x, y + height - 1, width, 1, "─")
  gpu.set(x, y + height - 1, "└")
  gpu.set(x + width - 1, y + height - 1, "┘")
  
  -- Draw title
  gpu.setForeground(fgColor)
  local titleX = x + math.floor((width - #title) / 2)
  gpu.set(titleX, y, title)
  
  -- Restore original colors
  gpu.setBackground(oldBg)
  gpu.setForeground(oldFg)
end

-- Function to display a message box with a close button
local function messageBox(title, message, type)
  -- Save old settings
  local oldBg, oldFg = gpu.getBackground(), gpu.getForeground()
  
  local screenWidth, screenHeight = gpu.getResolution()
  local boxWidth = math.min(60, screenWidth - 4)
  local lines = {}
  
  -- Split message into lines that fit in the box
  local maxLineWidth = boxWidth - 6
  local words = {}
  for word in message:gmatch("%S+") do
    table.insert(words, word)
  end
  
  local currentLine = ""
  for _, word in ipairs(words) do
    if #currentLine + #word + 1 <= maxLineWidth then
      if #currentLine > 0 then
        currentLine = currentLine .. " " .. word
      else
        currentLine = word
      end
    else
      table.insert(lines, currentLine)
      currentLine = word
    end
  end
  
  if #currentLine > 0 then
    table.insert(lines, currentLine)
  end
  
  -- If no words were found, add message as a single line
  if #lines == 0 then
    table.insert(lines, message)
  end
  
  -- Calculate box height based on message lines
  local boxHeight = #lines + 6
  local x = math.floor((screenWidth - boxWidth) / 2)
  local y = math.floor((screenHeight - boxHeight) / 2)
  
  -- Select color based on message type
  local color
  if type == "error" then
    color = 0xFF0000
  elseif type == "success" then
    color = 0x00FF00
  elseif type == "warning" then
    color = 0xFFFF00
  else
    color = config.defaultForeground
  end
  
  -- Draw window
  gpu.setBackground(config.defaultBackground)
  drawWindow(title, boxWidth, boxHeight, x, y, config.defaultBackground, color, config.borderColor)
  
  -- Draw message
  gpu.setBackground(config.defaultBackground)
  gpu.setForeground(config.defaultForeground)
  for i, line in ipairs(lines) do
    gpu.set(x + 3, y + 2 + i, line)
  end
  
  -- Draw button
  local buttonText = "[ OK ]"
  local buttonX = x + math.floor((boxWidth - #buttonText) / 2)
  local buttonY = y + boxHeight - 2
  
  gpu.setForeground(color)
  gpu.set(buttonX, buttonY, buttonText)
  
  -- Wait for key press or click
  while true do
    local eventData = {event.pull()}
    local eventType = eventData[1]
    
    if eventType == "key_down" then
      local _, _, _, button = table.unpack(eventData)
      if button == keyboard.keys.enter or button == keyboard.keys.space then
        break
      end
    elseif eventType == "touch" then
      local _, eX, eY = table.unpack(eventData)
      if eX >= buttonX and eX < buttonX + #buttonText and eY == buttonY then
        break
      end
    end
  end
  
  -- Restore colors
  gpu.setBackground(oldBg)
  gpu.setForeground(oldFg)
end

-- Function to create a button
local function drawButton(text, x, y, color, isSelected)
  local oldFg = gpu.getForeground()
  local buttonWidth = #text + 4
  
  if isSelected then
    gpu.setForeground(0xFFFFFF)
    gpu.set(x, y, "[ " .. text .. " ]")
  else
    gpu.setForeground(color)
    gpu.set(x, y, "  " .. text .. "  ")
  end
  
  gpu.setForeground(oldFg)
  return buttonWidth
end

-- Function to check if a position is within a button
local function isInButton(x, y, buttonX, buttonY, buttonWidth)
  return x >= buttonX and x < buttonX + buttonWidth and y == buttonY
end

-- Try to load custom configuration if it exists
local function loadConfig()
  if filesystem.exists("/home/navboard_config.lua") then
    local success, result = pcall(dofile, "/home/navboard_config.lua")
    if success and type(result) == "table" then
      for k, v in pairs(result) do
        config[k] = v
      end
      return true, "Custom configuration loaded!"
    else
      return false, "Warning: Could not load custom configuration"
    end
  else
    return false, "Warning: Configuration file not found, using defaults"
  end
end

-- Function to setup the UI
local function setupUI()
  -- Store original settings
  originalBackground = gpu.getBackground()
  originalForeground = gpu.getForeground()
  originalWidth, originalHeight = gpu.getResolution()
  
  -- Set new resolution if needed
  local maxWidth, maxHeight = gpu.maxResolution()
  local screenWidth = math.min(maxWidth, config.screenWidth)
  local screenHeight = math.min(maxHeight, config.screenHeight)
  gpu.setResolution(screenWidth, screenHeight)
  
  -- Clear screen with new colors
  gpu.setBackground(config.defaultBackground)
  gpu.setForeground(config.defaultForeground)
  term.clear()
  
  -- Draw main window
  drawWindow(config.windowTitle, screenWidth, screenHeight, 1, 1, 
             config.defaultBackground, config.titleColor, config.borderColor)
  
  return screenWidth, screenHeight
end

-- Function to restore original UI settings
local function restoreUI()
  gpu.setBackground(originalBackground)
  gpu.setForeground(originalForeground)
  gpu.setResolution(originalWidth, originalHeight)
  term.clear()
end

-- Draw the railway map within a window
local function drawMap()
  local screenWidth, screenHeight = gpu.getResolution()
  local mapWidth = 0
  
  -- Calculate map dimensions
  for _, line in ipairs(config.railwayMap) do
    mapWidth = math.max(mapWidth, #line)
  end
  
  local mapHeight = #config.railwayMap
  local windowWidth = math.min(mapWidth + 4, screenWidth - 2)
  local windowHeight = math.min(mapHeight + 6, screenHeight - 4)
  local windowX = math.floor((screenWidth - windowWidth) / 2)
  local windowY = 2
  
  -- Draw the map window
  drawWindow("RAILWAY MAP", windowWidth, windowHeight, windowX, windowY, 
             config.defaultBackground, config.titleColor, config.borderColor)
  
  -- Draw railway map
  gpu.setForeground(config.railColor)
  for i, line in ipairs(config.railwayMap) do
    gpu.set(windowX + 2, windowY + 2 + i, line)
  end
  
  -- Highlight stations
  for _, station in ipairs(config.stations) do
    if config.useColorsIfAvailable then
      if station.isMain then
        gpu.setForeground(config.mainStationColor)
      else
        gpu.setForeground(config.stationColor)
      end
    end
    gpu.set(windowX + 2 + station.x, windowY + 2 + station.y, station.name)
  end
  
  -- Draw legend
  local legendX = windowX + 2
  local legendY = windowY + windowHeight - 4
  gpu.setForeground(config.defaultForeground)
  gpu.set(legendX, legendY, "LEGEND:")
  
  if config.useColorsIfAvailable then
    gpu.setForeground(config.mainStationColor)
  end
  gpu.set(legendX, legendY + 1, "● Main Stations")
  
  if config.useColorsIfAvailable then
    gpu.setForeground(config.stationColor)
  end
  gpu.set(legendX + 20, legendY + 1, "● Regular Stations")
  
  if config.useColorsIfAvailable then
    gpu.setForeground(config.railColor)
  end
  gpu.set(legendX + 40, legendY + 1, "─── Railway Lines")
  
  -- Draw buttons
  gpu.setForeground(config.defaultForeground)
  local buttonY = screenHeight - 2
  local buttonX = 5
  
  local infoWidth = drawButton("Station Info [I]", buttonX, buttonY, config.titleColor, false)
  buttonX = buttonX + infoWidth + 2
  
  local refreshWidth = drawButton("Refresh [R]", buttonX, buttonY, config.stationColor, false)
  buttonX = buttonX + refreshWidth + 2
  
  local quitWidth = drawButton("Quit [Q]", buttonX, buttonY, 0xFF0000, false)
  
  return windowX, windowY, windowWidth, windowHeight
end

-- Display station information
local function showStationInfo()
  local screenWidth, screenHeight = gpu.getResolution()
  
  -- Calculate window dimensions
  local windowWidth = math.min(60, screenWidth - 4)
  local windowHeight = math.min(#config.stations * 3 + 6, screenHeight - 4)
  local windowX = math.floor((screenWidth - windowWidth) / 2)
  local windowY = math.floor((screenHeight - windowHeight) / 2)
  
  -- Draw the station info window
  drawWindow("STATION INFORMATION", windowWidth, windowHeight, windowX, windowY, 
             config.defaultBackground, config.titleColor, config.borderColor)
  
  -- Draw station details
  for i, station in ipairs(config.stations) do
    local yPos = windowY + i * 3
    
    if config.useColorsIfAvailable and station.isMain then
      gpu.setForeground(config.mainStationColor)
    elseif config.useColorsIfAvailable then
      gpu.setForeground(config.stationColor)
    end
    
    gpu.set(windowX + 3, yPos, station.name .. ": " .. station.label)
    gpu.setForeground(config.defaultForeground)
    gpu.set(windowX + 5, yPos + 1, station.desc)
  end
  
  -- Draw close button
  local buttonText = "[ Close ]"
  local buttonX = windowX + math.floor((windowWidth - #buttonText) / 2)
  local buttonY = windowY + windowHeight - 2
  gpu.setForeground(config.titleColor)
  gpu.set(buttonX, buttonY, buttonText)
  
  -- Wait for key press or click
  while true do
    local eventData = {event.pull()}
    local eventType = eventData[1]
    
    if eventType == "key_down" then
      break
    elseif eventType == "touch" then
      local _, eX, eY = table.unpack(eventData)
      if eX >= buttonX and eX < buttonX + #buttonText and eY == buttonY then
        break
      end
    end
  end
end

-- Show a startup animation
local function showStartupAnimation()
  local screenWidth, screenHeight = gpu.getResolution()
  local message = "Loading Railway Network Display..."
  local x = math.floor((screenWidth - #message) / 2)
  local y = math.floor(screenHeight / 2)
  
  local animationIndex = 1
  for i = 1, 10 do
    local char = config.animationChars[animationIndex]
    gpu.set(x, y, message .. " " .. char)
    os.sleep(0.1)
    animationIndex = animationIndex % #config.animationChars + 1
  end
  
  gpu.set(x, y, message .. " ✓")
  os.sleep(0.5)
end

-- Main program loop
local function main()
  local success, message = loadConfig()
  local screenWidth, screenHeight = setupUI()
  
  showStartupAnimation()
  
  if not success then
    messageBox("Configuration Notice", message, "warning")
  end
  
  -- Main loop
  local running = true
  local lastUpdateTime = 0
  
  while running do
    local windowX, windowY, windowWidth, windowHeight = drawMap()
    
    -- Wait for event with timeout for auto-refresh
    local remainingTime = config.updateInterval - (computer.uptime() - lastUpdateTime)
    remainingTime = math.max(0.1, remainingTime)
    
    local eventData = {event.pull(remainingTime)}
    local eventType = eventData[1]
    
    if eventType == "key_down" then
      local _, _, _, code = table.unpack(eventData)
      -- Q to quit
      if code == keyboard.keys.q then
        running = false
      -- I for station info
      elseif code == keyboard.keys.i then
        showStationInfo()
      -- R to refresh/redraw
      elseif code == keyboard.keys.r then
        lastUpdateTime = computer.uptime()
      end
    elseif eventType == "touch" then
      local _, eX, eY = table.unpack(eventData)
      local buttonY = screenHeight - 2
      
      -- Check if a button was clicked
      if eY == buttonY then
        if isInButton(eX, eY, 5, buttonY, 18) then
          -- Station Info button
          showStationInfo()
        elseif isInButton(eX, eY, 25, buttonY, 14) then
          -- Refresh button
          lastUpdateTime = computer.uptime()
        elseif isInButton(eX, eY, 41, buttonY, 11) then
          -- Quit button
          running = false
        end
      end
    end
    
    -- Automatic refresh based on interval
    local currentTime = computer.uptime()
    if currentTime - lastUpdateTime > config.updateInterval then
      lastUpdateTime = currentTime
    end
  end
  
  -- Cleanup
  restoreUI()
  messageBox("Goodbye", "Railway display closed", "success")
end

-- Error handling for the entire program
local function safeMain()
  local success, error = pcall(main)
  if not success then
    -- Try to show error in UI mode, fall back to text mode if UI fails
    local msgBoxSuccess = pcall(function()
      messageBox("Critical Error", "The display encountered an unexpected error:\n\n" .. tostring(error), "error")
      restoreUI()
    end)
    
    if not msgBoxSuccess then
      -- Print error to console as backup
      term.clear()
      print("Critical Error: " .. tostring(error))
      print("\nPress any key to exit")
    end
  end
end

-- Run the program
safeMain()
