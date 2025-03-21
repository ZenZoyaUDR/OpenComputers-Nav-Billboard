-- Navigation Configuration File

{
  -- Title settings
  title = "NETHER HUB",
  
  -- Color settings (hexadecimal RGB values)
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
  
  -- Display settings
  borderWidth = 3,             -- Width of the rainbow border
  frameDelay = 0.1,            -- Seconds between animation frames
  slideshowDelay = 5,          -- Seconds between slideshow pages
  locationsPerPage = 1,        -- Number of locations to show per page
  
  -- List of nether hub destinations
  destinations = {
    {name = "Zenkku's Base", direction = "↑", distance = 1800},
    {name = "Khy's Base", direction = "→", distance = 27},
    {name = "hhhzzzsss's Base", direction = "↓", distance = 820},
    {name = "Mine", direction = "←", distance = 500},
    {name = "End Portal", direction = "↙", distance = 83},
  }
}
