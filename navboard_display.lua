-- Navigation Billboard Display Program
-- This script loads configuration from GitHub and displays the billboard

local component = require("component")
local gpu = component.gpu
local event = require("event")
local term = require("term")
local os = require("os")
local filesystem = require("filesystem")

-- Local configuration file path
local configPath = "/home/navboard_config.lua"

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

-- Function to draw a location icon
local function drawLocationIcon(x, y, direction)
  gpu.setForeground(config.arrowColor)
  gpu.set(x, y, direction)
end

-- Function to display destinations
local function displayDestinations()
  term.clear()
  local startIndex = (currentPage - 1) * config.locationsPerPage + 1
  local endIndex = math.min(startIndex + config.locationsPerPage - 1, #config.destinations)
  for i = startIndex, endIndex do
    local dest = config.destinations[i]
    drawLocationIcon(10, i * 3, dest.direction)
    gpu.setForeground(config.nameColor)
    gpu.set(15, i * 3, dest.name)
    gpu.setForeground(config.distanceColor)
    gpu.set(30, i * 3, tostring(dest.distance) .. " BLOCKS")
  end
end

-- Main loop
local function main()
  loadConfig()
  while true do
    displayDestinations()
    os.sleep(config.slideshowDelay)
    currentPage = (currentPage % #config.destinations) + 1
  end
end

main()
