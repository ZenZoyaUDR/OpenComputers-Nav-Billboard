-- Nether Hub Navigation Billboard Display Program
-- This script loads configuration from GitHub and displays the billboard
-- Save this as "nether_hub_display.lua" in your GitHub repository

local component = require("component")
local gpu = component.gpu
local event = require("event")
local term = require("term")
local os = require("os")
local filesystem = require("filesystem")

-- Local configuration file path
local configPath = "/home/nether_hub_config.lua"

-- Default settings (will be overridden by config file if available)
local config = {
  rainbowColors = {
    0xFF0000,  -- Red
    0xFF7F00,  -- Orange
    0xFFFF00,  -- Yellow
    0x00FF00,  -- Green
    0x0000FF,  -- Blue
    0x4B0082,  -- Indigo
    0x9400D3,  -- Violet
  },
  backgroundColor = 0x000000,  -- Black
  titleColor = 0xFF0000,       -- Red
  arrowColor = 0xFFFF00,       -- Yellow
  nameColor = 0xFFFFFF,        -- White
  distanceColor = 0x00FF00,    -- Green
  pageInfoColor = 0xAAAAAA,    -- Light gray
  
  title = "NETHER HUB",
  borderWidth = 3,
  frameDelay = 0.1,            -- seconds between animation frames
  slideshowDelay = 5,          -- seconds between slideshow pages
  locationsPerPage = 1,        -- locations to show per page
  
  destinations = {
    {name = "Main Base", direction = "↑", distance = 125},
    {name = "Gold Farm", direction = "→", distance = 230},
    {name = "Blaze Farm", direction = "↓", distance = 180},
    {name = "Fortress", direction = "←", distance = 95},
    {name = "End Portal", direction = "↗", distance = 320},
    {name = "Witch Farm", direction = "↙", distance = 275},
  }
}

-- Animation state
local width, height = gpu.getResolution()
local borderOffset = 0
local currentPage = 1
local totalPages = 1
local lastSlideChange = os.time()

-- Extra large text characters (5x5 grid)
local bigChars = {
  ["↑"] = {
    "  █  ",
    " ███ ",
    "█████",
    "  █  ",
    "  █  "
  },
  ["→"] = {
    "     ",
    "  █  ",
    "█████",
    "  █  ",
    "     "
  },
  ["↓"] = {
    "  █  ",
    "  █  ",
    "█████",
    " ███ ",
    "  █  "
  },
  ["←"] = {
    "     ",
    "  █  ",
    "█████",
    "  █  ",
    "     "
  },
  ["↗"] = {
    "  ███",
    "   ██",
    "  █ █",
    " █  █",
    "█    "
  },
  ["↙"] = {
    "█    ",
    " █  █",
    "  █ █",
    "   ██",
    "  ███"
  }
}

-- Function to load configuration from file
local function loadConfig()
  if not filesystem.exists(configPath) then
    print("Config file not found, using defaults")
    return
  end
  
  print("Loading configuration...")
  
  local file = io.open(configPath, "r")
  if not file then
    print("Could not open config file")
    return
  end
  
  local content = file:read("*all")
  file:close()
  
  -- The config file should be a Lua table, so we need to wrap it in return statement if it's not already
  if not content:match("^%s*return%s") then
    content = "return " .. content
  end
  
  local success, loadedConfig = pcall(load(content))
  
  if success and type(loadedConfig) == "table" then
    -- Update config with loaded values
    for k, v in pairs(loadedConfig) do
      config[k] = v
    end
    print("Configuration loaded successfully!")
  else
    print("Error parsing configuration file: " .. tostring(loadedConfig))
  end
  
  -- Calculate total pages
  totalPages = math.ceil(#config.destinations / config.locationsPerPage)
end

-- Function to clear screen
local function clearScreen()
  gpu.setBackground(config.backgroundColor)
  term.clear()
end

-- Function to draw rainbow border
local function drawRainbowBorder(offset)
  local borderWidth = config.borderWidth
  
  -- Draw top and bottom borders
  for x = 1, width do
    local colorIndex = ((x + offset) % #config.rainbowColors) + 1
    gpu.setBackground(config.rainbowColors[colorIndex])
    
    -- Top border
    for by = 1, borderWidth do
      gpu.set(x, by, " ")
    end
    
    -- Bottom border
    for by = height - borderWidth + 1, height do
      gpu.set(x, by, " ")
    end
  end
  
  -- Draw left and right borders
  for y = borderWidth + 1, height - borderWidth do
    -- Left border
    local leftColorIndex = ((y + offset) % #config.rainbowColors) + 1
    gpu.setBackground(config.rainbowColors[leftColorIndex])
    for bx = 1, borderWidth do
      gpu.set(bx, y, " ")
    end
    
    -- Right border
    local rightColorIndex = ((y + offset) % #config.rainbowColors) + 1
    gpu.setBackground(config.rainbowColors[rightColorIndex])
    for bx = width - borderWidth + 1, width do
      gpu.set(bx, y, " ")
    end
  end
end

-- Function to draw the nether hub title
local function drawTitle()
  local title = config.title
  
  -- Center the title
  local titleX = math.floor((width - #title) / 2)
  local titleY = config.borderWidth + 3
  
  -- Draw title in normal text
  gpu.setBackground(config.backgroundColor)
  gpu.setForeground(config.titleColor)
  gpu.set(titleX, titleY, title)
  
  -- Draw page indicator
  local pageInfo = string.format("Page %d/%d", currentPage, totalPages)
  local pageX = width - #pageInfo - 5
  local pageY = height - 5
  gpu.setForeground(config.pageInfoColor)
  gpu.set(pageX, pageY, pageInfo)
end

-- Function to draw destinations for current page
local function drawCurrentDestinations()
  local startIndex = (currentPage - 1) * config.locationsPerPage + 1
  local endIndex = math.min(startIndex + config.locationsPerPage - 1, #config.destinations)
  
  gpu.setBackground(config.backgroundColor)
  
  for i = startIndex, endIndex do
    local dest = config.destinations[i]
    
    -- Calculate vertical positions
    local centerY = math.floor(height / 2)
    
    -- Draw direction arrow (still using the big character function)
    local arrowY = centerY - 7
    local arrowX = math.floor(width / 2) - 2
    drawBigChar(arrowX, arrowY, dest.direction, config.arrowColor)
    
    -- Draw destination name (normal text)
    local nameY = centerY
    local name = dest.name
    local nameX = math.floor((width - #name) / 2)
    
    gpu.setForeground(config.nameColor)
    gpu.set(nameX, nameY, name)
    
    -- Draw distance (normal text)
    local distanceText = tostring(dest.distance) .. " BLOCKS"
    local distX = math.floor((width - #distanceText) / 2)
    local distY = centerY + 5
    
    gpu.setForeground(config.distanceColor)
    gpu.set(distX, distY, distanceText)
  end
end

-- Function to handle animation and slideshow
local function runAnimation()
  clearScreen()
  
  print("Press Ctrl+C to exit or R to reload configuration")
  
  while true do
    -- Draw animated rainbow border
    drawRainbowBorder(borderOffset)
    
    -- Draw title and current destinations
    drawTitle()
    drawCurrentDestinations()
    
    -- Update animation
    borderOffset = (borderOffset + 1) % 100
    
    -- Check if it's time to change slides
    local currentTime = os.time()
    if currentTime - lastSlideChange >= config.slideshowDelay then
      currentPage = currentPage % totalPages + 1
      lastSlideChange = currentTime
    end
    
    -- Wait before next frame
    os.sleep(config.frameDelay)
    
    -- Check for key presses
    local eventType, _, _, code = event.pull(0)
    if eventType == "key_down" then
      if code == 3 then  -- Ctrl+C
        break
      elseif code == 19 then  -- R key
        loadConfig()
        clearScreen()
      end
    end
  end
  
  -- Restore default colors and clear screen
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  term.clear()
end

-- Main program
local function main()
  print("Starting Nether Hub Navigation Billboard...")
  
  -- Load configuration
  loadConfig()
  
  -- Start the animation
  os.sleep(1)
  runAnimation()
end

-- Run the program
main()
