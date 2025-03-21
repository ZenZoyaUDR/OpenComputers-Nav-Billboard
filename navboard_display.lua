-- Railway System Display for OpenComputers
-- Displays ASCII art representation of your server's railway system
-- Save as "navboard_display.lua" for use with the bootstrap updater

local component = require("component")
local computer = require("computer")
local term = require("term")
local unicode = require("unicode")
local colors = require("colors")
local gpu = component.gpu
local keyboard = require("keyboard")
local event = require("event")
local filesystem = require("filesystem")

-- Configuration
local config = {
  updateInterval = 10,          -- Update interval in seconds
  screenWidth = 80,             -- Default screen width
  screenHeight = 25,            -- Default screen height
  defaultBackground = 0x000000, -- Black background
  defaultForeground = 0xFFFFFF, -- White text
  titleColor = 0x00FF00,        -- Green for title
  stationColor = 0xFFFF00,      -- Yellow for stations
  railColor = 0x808080,         -- Gray for railway lines
  mainStationColor = 0xFF0000,  -- Red for main stations/hubs
  useColorsIfAvailable = true   -- Use colors if the GPU supports it
}

-- Try to load custom configuration if it exists
local function loadConfig()
  if filesystem.exists("/home/navboard_config.lua") then
    local success, result = pcall(dofile, "/home/navboard_config.lua")
    if success and type(result) == "table" then
      for k, v in pairs(result) do
        config[k] = v
      end
      print("Custom configuration loaded!")
    else
      print("Warning: Could not load custom configuration")
    end
  end
end

-- Initialize the screen
local function initializeScreen()
  local maxWidth, maxHeight = gpu.maxResolution()
  local width = math.min(config.screenWidth, maxWidth)
  local height = math.min(config.screenHeight, maxHeight)
  gpu.setResolution(width, height)
  gpu.setBackground(config.defaultBackground)
  gpu.setForeground(config.defaultForeground)
  term.clear()
  return width, height
end

-- Railway system ASCII art
local railwayMap = {
  "                            MINECRAFT RAILWAY NETWORK                            ",
  "                                                                                 ",
  "              NORTHERN MINES                                                     ",
  "                   |                                                             ",
  "                   |                                  EASTERN VILLAGE            ",
  "                   |                                         |                   ",
  "                   |                                         |                   ",
  "    WESTERN      [A]--------[B]------------------------------[C]                 ",
  "    FOREST--------+          \\                               |                   ",
  "                              \\                              |                   ",
  "                               \\                             |                   ",
  "                                \\                            |                   ",
  "                                 \\                           |                   ",
  "                                  \\                          |                   ",
  "                                   \\                         |                   ",
  "                                    [D]--------------------[E]                   ",
  "                                     |                      |                    ",
  "                                     |                      |                    ",
  "                                     |                      |                    ",
  "                                  CENTRAL                   |                    ",
  "                                  STATION                   |                    ",
  "                                                            |                    ",
  "                                                         SOUTHERN                ",
  "                                                          FARMS                  ",
  "                                                                                 ",
}

-- Station descriptions and coordinates for the map
local stations = {
  { name = "A", label = "NORTH HUB", desc = "Connection to Northern Mines and Western Forest", x = 19, y = 7, isMain = true },
  { name = "B", label = "CENTRAL JUNCTION", desc = "Major transit hub with storage facilities", x = 28, y = 7, isMain = true },
  { name = "C", label = "EAST STATION", desc = "Gateway to Eastern Village", x = 60, y = 7, isMain = true },
  { name = "D", label = "SOUTH JUNCTION", desc = "Industrial area transit point", x = 29, y = 15, isMain = false },
  { name = "E", label = "FARM STATION", desc = "Access to Southern Farms", x = 54, y = 15, isMain = false },
}

-- Draw the railway map
local function drawMap()
  term.clear()
  
  -- Draw title
  if config.useColorsIfAvailable then
    gpu.setForeground(config.titleColor)
  end
  
  local width, height = gpu.getResolution()
  local title = "MINECRAFT RAILWAY SYSTEM"
  local xPos = math.floor((width - unicode.len(title)) / 2)
  gpu.set(xPos, 1, title)
  
  -- Draw railway map
  gpu.setForeground(config.railColor)
  for i, line in ipairs(railwayMap) do
    gpu.set(1, i + 2, line)
  end
  
  -- Highlight stations
  for _, station in ipairs(stations) do
    if config.useColorsIfAvailable then
      if station.isMain then
        gpu.setForeground(config.mainStationColor)
      else
        gpu.setForeground(config.stationColor)
      end
    end
    gpu.set(station.x, station.y + 2, station.name)
  end
  
  -- Draw legend at the bottom
  gpu.setForeground(config.defaultForeground)
  local legendY = height - 5
  gpu.set(2, legendY, "LEGEND:")
  
  if config.useColorsIfAvailable then
    gpu.setForeground(config.mainStationColor)
  end
  gpu.set(2, legendY + 1, "● Main Stations")
  
  if config.useColorsIfAvailable then
    gpu.setForeground(config.stationColor)
  end
  gpu.set(2, legendY + 2, "● Regular Stations")
  
  if config.useColorsIfAvailable then
    gpu.setForeground(config.railColor)
  end
  gpu.set(2, legendY + 3, "─── Railway Lines")
  
  -- Status line
  gpu.setForeground(config.defaultForeground)
  gpu.set(2, height, "Press 'Q' to quit, 'I' for station info, 'R' to refresh")
end

-- Display station information
local function showStationInfo()
  term.clear()
  gpu.setForeground(config.titleColor)
  gpu.set(2, 1, "STATION INFORMATION")
  gpu.setForeground(config.defaultForeground)
  
  for i, station in ipairs(stations) do
    local yPos = i * 3 + 1
    if config.useColorsIfAvailable and station.isMain then
      gpu.setForeground(config.mainStationColor)
    elseif config.useColorsIfAvailable then
      gpu.setForeground(config.stationColor)
    end
    
    gpu.set(2, yPos, station.name .. ": " .. station.label)
    gpu.setForeground(config.defaultForeground)
    gpu.set(4, yPos + 1, station.desc)
  end
  
  gpu.set(2, #stations * 3 + 4, "Press any key to return to the map")
  event.pull("key_down")
end

-- Main program loop
local function main()
  loadConfig()
  local width, height = initializeScreen()
  
  -- Main loop
  local running = true
  local lastUpdateTime = 0
  
  while running do
    drawMap()
    
    -- Event handling
    local eventType, _, _, code = event.pull(1)
    
    if eventType == "key_down" then
      -- Q to quit
      if code == keyboard.keys.q then
        running = false
      -- I for station info
      elseif code == keyboard.keys.i then
        showStationInfo()
      -- R to refresh/redraw
      elseif code == keyboard.keys.r then
        -- Just redraw on next loop
      end
    end
    
    -- Automatic refresh based on interval
    local currentTime = computer.uptime()
    if currentTime - lastUpdateTime > config.updateInterval then
      lastUpdateTime = currentTime
    end
  end
  
  -- Cleanup
  term.clear()
  print("Railway display closed")
end

-- Start the program
main()
