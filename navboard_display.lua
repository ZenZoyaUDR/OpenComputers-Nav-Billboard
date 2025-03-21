-- Navigation Display for OpenComputers

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
  defaultBackground = 0x000000, -- Black background
  defaultForeground = 0xFFFFFF, -- White text
  titleColor = 0x0088FF,        -- Blue for title
  hubColor = 0xFFFF00,          -- Yellow for hubs
  pathColor = 0x808080,         -- Gray for paths lines
  mainHubColor = 0xFF0000,      -- Red for main hubs
  borderColor = 0x555555,       -- Border color
  legendBackgroundColor = 0x222222, -- Darker background for legend
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
  },
  
  -- Font scaling for better visibility
  stationFontScale = 1.5,      -- Scale station labels for better visibility
  legendFontScale = 1.2,       -- Scale legend text for better visibility
}

-- Store original screen settings to restore later
local originalBackground, originalForeground
local originalWidth, originalHeight

-- Function to draw a window box with proper Unicode box drawing characters
local function drawWindow(title, width, height, x, y, bgColor, fgColor, borderColor)
  -- Save current settings
  local oldBg, oldFg = gpu.getBackground(), gpu.getForeground()
  
  -- Set colors
  gpu.setBackground(bgColor)
  gpu.setForeground(borderColor)
  
  -- Draw the background
  gpu.fill(x, y, width, height, " ")
  
  -- Draw top border
  gpu.fill(x, y, width, 1, "═")
  gpu.set(x, y, "╔")
  gpu.set(x + width - 1, y, "╗")
  
  -- Draw sides
  for i = 1, height - 2 do
    gpu.set(x, y + i, "║")
    gpu.set(x + width - 1, y + i, "║")
  end
  
  -- Draw bottom border
  gpu.fill(x, y + height - 1, width, 1, "═")
  gpu.set(x, y + height - 1, "╚")
  gpu.set(x + width - 1, y + height - 1, "╝")
  
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

-- Function to create a sleek, modern button
local function drawButton(text, x, y, color, isSelected)
  local oldBg, oldFg = gpu.getBackground(), gpu.getForeground()
  local buttonWidth = #text + 4
  
  if isSelected then
    -- Selected button - highlight with background
    gpu.setBackground(color)
    gpu.setForeground(0x000000)
    gpu.fill(x, y, buttonWidth, 1, " ")
    gpu.set(x + 2, y, text)
  else
    -- Normal button - clean modern style
    gpu.setBackground(config.defaultBackground)
    gpu.setForeground(color)
    gpu.set(x + 2, y, text)
    -- Draw subtle underline
    gpu.fill(x + 1, y + 1, #text + 2, 1, "▁")
  end
  
  gpu.setBackground(oldBg)
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

-- Function to setup the UI with maximum resolution
local function setupUI()
  -- Store original settings
  originalBackground = gpu.getBackground()
  originalForeground = gpu.getForeground()
  originalWidth, originalHeight = gpu.getResolution()
  
  -- Set to maximum available resolution
  local maxWidth, maxHeight = gpu.maxResolution()
  gpu.setResolution(maxWidth, maxHeight)
  
  -- Clear screen with new colors
  gpu.setBackground(config.defaultBackground)
  gpu.setForeground(config.defaultForeground)
  term.clear()
  
  -- Draw main window - full screen
  drawWindow(config.windowTitle, maxWidth, maxHeight, 1, 1, 
             config.defaultBackground, config.titleColor, config.borderColor)
  
  return maxWidth, maxHeight
end

-- Function to restore original UI settings
local function restoreUI()
  gpu.setBackground(originalBackground)
  gpu.setForeground(originalForeground)
  gpu.setResolution(originalWidth, originalHeight)
  term.clear()
end

-- Function to draw a bold character for better visibility
local function drawBoldChar(x, y, char, color)
  local oldFg = gpu.getForeground()
  gpu.setForeground(color)
  
  -- Draw the character
  gpu.set(x, y, char)
  
  -- For better visibility from afar, draw the same character with slight offsets
  -- This creates a "bold" effect that's more visible
  if config.stationFontScale > 1 then
    gpu.set(x + 1, y, char)
  end
  
  gpu.setForeground(oldFg)
end

-- Draw the railway map using maximum screen real estate
local function drawMap()
  local screenWidth, screenHeight = gpu.getResolution()
  
  -- Calculate map dimensions
  local mapWidth = 0
  for _, line in ipairs(config.railwayMap) do
    mapWidth = math.max(mapWidth, #line)
  end
  local mapHeight = #config.railwayMap
  
  -- Maximum available space for the map view (accounting for borders and controls)
  local maxAvailableWidth = screenWidth - 4  -- 2 for borders, 2 for padding
  local maxAvailableHeight = screenHeight - 6 -- Account for title, borders, legend, buttons
  
  -- Window dimensions - maximize space usage
  local viewWidth = math.min(mapWidth, maxAvailableWidth)
  local viewHeight = math.min(mapHeight, maxAvailableHeight)
  
  -- Center the map
  local windowWidth = viewWidth + 4  -- Add space for borders
  local windowHeight = viewHeight + 6 -- Add space for title, borders, and status
  local windowX = math.max(1, math.floor((screenWidth - windowWidth) / 2))
  local windowY = math.max(1, math.floor((screenHeight - windowHeight) / 2))
  
  -- Clear screen and draw the map window
  term.clear()
  drawWindow("Railway Network Map", screenWidth, screenHeight, 1, 1, 
             config.defaultBackground, config.titleColor, config.borderColor)
  
  -- Draw railway map - with better contrast for visibility
  gpu.setForeground(config.railColor or config.pathColor)
  for i = 1, viewHeight do
    if i <= mapHeight then
      local line = config.railwayMap[i] or ""
      -- Center the map horizontally if it's smaller than the view
      local xOffset = 0
      if #line < viewWidth then
        xOffset = math.floor((viewWidth - #line) / 2)
      end
      local displayLine = line:sub(1, viewWidth)
      gpu.set(windowX + 2 + xOffset, windowY + 1 + i, displayLine)
    end
  end
  
  -- Highlight stations with enhanced visibility
  for _, station in ipairs(config.stations) do
    if station.x >= 0 and station.x < viewWidth and station.y >= 0 and station.y < viewHeight then
      local color
      if station.isMain then
        color = config.mainStationColor or config.mainHubColor
      else
        color = config.stationColor or config.hubColor
      end
      
      -- Draw station name with bold effect for better visibility
      drawBoldChar(windowX + 2 + station.x, windowY + 1 + station.y, station.name, color)
    end
  end
  
  -- Draw sleek modern legend panel at the bottom
  local legendHeight = 3
  local legendY = screenHeight - legendHeight - 2
  
  -- Draw legend background panel
  gpu.setBackground(config.legendBackgroundColor)
  gpu.fill(3, legendY, screenWidth - 4, legendHeight, " ")
  
  -- Draw legend title
  gpu.setForeground(config.titleColor)
  gpu.set(5, legendY, "« LEGEND »")
  
  -- Draw legend items - more compact and modern layout
  local itemX = 20
  
  -- Main stations legend
  gpu.setForeground(config.mainStationColor or config.mainHubColor)
  gpu.set(itemX, legendY, "●")
  gpu.setForeground(config.defaultForeground)
  gpu.set(itemX + 2, legendY, "Main Stations")
  
  -- Regular stations legend
  itemX = itemX + 20
  gpu.setForeground(config.stationColor or config.hubColor)
  gpu.set(itemX, legendY, "●")
  gpu.setForeground(config.defaultForeground)
  gpu.set(itemX + 2, legendY, "Regular Stations")
  
  -- Railway lines legend
  itemX = itemX + 20
  gpu.setForeground(config.railColor or config.pathColor)
  gpu.set(itemX, legendY, "───")
  gpu.setForeground(config.defaultForeground)
  gpu.set(itemX + 4, legendY, "Railway Lines")
  
  -- Reset background color
  gpu.setBackground(config.defaultBackground)
  
  -- Draw buttons in a centered row with modern styling
  local buttonY = screenHeight - 3
  
  -- Calculate total width of all buttons to center them
  local totalButtonWidth = 18 + 6 + 14 + 6 + 11  -- Width of all buttons plus spacing
  local buttonX = math.floor((screenWidth - totalButtonWidth) / 2)
  
  local infoWidth = drawButton("Station Info [I]", buttonX, buttonY, config.titleColor, false)
  buttonX = buttonX + infoWidth + 6
  
  local refreshWidth = drawButton("Refresh [R]", buttonX, buttonY, config.stationColor or config.hubColor, false)
  buttonX = buttonX + refreshWidth + 6
  
  local quitWidth = drawButton("Quit [Q]", buttonX, buttonY, 0xFF0000, false)
  
  -- Draw current status
  local timeStr = os.date("%H:%M:%S")
  gpu.setForeground(config.defaultForeground)
  gpu.set(screenWidth - #timeStr - 4, screenHeight - 2, timeStr)
  
  return windowX, windowY, viewWidth, viewHeight
end

-- Display station information with enhanced readability
local function showStationInfo()
  local screenWidth, screenHeight = gpu.getResolution()
  
  -- Calculate window dimensions
  local windowWidth = math.min(math.floor(screenWidth * 0.8), screenWidth - 4)
  local windowHeight = math.min(#config.stations * 3 + 6, screenHeight - 4)
  local windowX = math.floor((screenWidth - windowWidth) / 2)
  local windowY = math.floor((screenHeight - windowHeight) / 2)
  
  -- Draw the station info window with enhanced styling
  drawWindow("STATION INFORMATION", windowWidth, windowHeight, windowX, windowY, 
             config.defaultBackground, config.titleColor, config.borderColor)
  
  -- Draw station details with improved visibility
  for i, station in ipairs(config.stations) do
    local yPos = windowY + i * 3
    
    -- Highlight station name based on type
    local color
    if station.isMain then
      color = config.mainStationColor or config.mainHubColor
    else
      color = config.stationColor or config.hubColor
    end
    
    -- Draw station name with enhanced visibility
    gpu.setForeground(color)
    gpu.set(windowX + 3, yPos, station.name .. ":")
    
    -- Draw station label with slight offset for visual separation
    gpu.setForeground(config.defaultForeground)
    gpu.set(windowX + 6, yPos, station.label)
    
    -- Draw station description with slight indent
    gpu.setForeground(config.defaultForeground)
    gpu.set(windowX + 5, yPos + 1, station.desc)
  end
  
  -- Draw sleek close button
  local buttonText = "Close"
  local buttonX = windowX + math.floor((windowWidth - #buttonText - 4) / 2)
  local buttonY = windowY + windowHeight - 2
  drawButton(buttonText, buttonX, buttonY, config.titleColor, false)
  
  -- Wait for key press or click
  while true do
    local eventData = {event.pull()}
    local eventType = eventData[1]
    
    if eventType == "key_down" then
      break
    elseif eventType == "touch" then
      local _, eX, eY = table.unpack(eventData)
      if eX >= buttonX and eX < buttonX + #buttonText + 4 and eY == buttonY then
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
  
  -- Progressive loading animation
  gpu.setForeground(config.titleColor)
  gpu.set(x, y, message)
  
  -- Draw loading bar
  local barWidth = 30
  local barX = math.floor((screenWidth - barWidth) / 2)
  local barY = y + 2
  
  -- Draw bar outline
  gpu.setForeground(config.borderColor)
  gpu.set(barX, barY, "┌" .. string.rep("─", barWidth) .. "┐")
  gpu.set(barX, barY + 1, "│" .. string.rep(" ", barWidth) .. "│")
  gpu.set(barX, barY + 2, "└" .. string.rep("─", barWidth) .. "┘")
  
  -- Animate loading bar
  gpu.setForeground(config.titleColor)
  for i = 1, barWidth do
    gpu.set(barX + i, barY + 1, "█")
    os.sleep(0.05)
  end
  
  -- Show completion message
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
    local windowX, windowY, viewWidth, viewHeight = drawMap()
    
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
      local buttonY = screenHeight - 3
      
      -- Check if a button was clicked
      if eY == buttonY then
        -- Calculate button positions same as in drawMap
        local totalButtonWidth = 18 + 6 + 14 + 6 + 11
        local buttonX = math.floor((screenWidth - totalButtonWidth) / 2)
        
        if isInButton(eX, eY, buttonX, buttonY, 18) then
          -- Station Info button
          showStationInfo()
        elseif isInButton(eX, eY, buttonX + 18 + 6, buttonY, 14) then
          -- Refresh button
          lastUpdateTime = computer.uptime()
        elseif isInButton(eX, eY, buttonX + 18 + 6 + 14 + 6, buttonY, 11) then
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
