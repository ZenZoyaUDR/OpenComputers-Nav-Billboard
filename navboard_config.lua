-- Configuration for Railway Network Display
-- Save this file as "/home/navboard_config.lua"

return {
  -- Display settings
  updateInterval = 1,           -- Update interval in seconds
  defaultBackground = 0x000000,  -- Black background
  defaultForeground = 0xFFFFFF,  -- White text
  titleColor = 0x0088FF,         -- Blue for title
  hubColor = 0xFFFF00,           -- Yellow for hubs
  pathColor = 0x808080,          -- Gray for paths lines
  mainHubColor = 0xFF0000,       -- Red for main hubs
  borderColor = 0x555555,        -- Border color
  legendBackgroundColor = 0x222222, -- Darker background for legend
  useColorsIfAvailable = true,   -- Use colors if the GPU supports it
  windowTitle = "Railway Network",
  animationChars = {"|", "/", "-", "\\"},
  stationFontScale = 1,        -- Scale station labels for better visibility
  legendFontScale = 2,         -- Scale legend text for better visibility
  
  -- Railway map
  railwayMap = {
    "                                                                                 ",
    "                                             Zenkku                              ",
    "                                    [B]+-----BASE                                ",
    "                                     |                                           ",
    "                                     |                                           ",
    "                                     |                                           ",
    "                                     |                                           ",
    "                                     |                                           ",
    "         MINES                       |                Khy's                      ",
    "           |                         |       +--------BASE                       ",
    "           |                         |------[B]                                  ",
    "           +                         |                                           ",
    "          [M]-----------------------[A]+-----MAIN HUB                            ",
    "                                   / | \\                                        ",
    "                    END           /  |  \\         Opt & Amy                     ",
    "                    PORTAL----+[A]   |   [B]+-----BASE                           ",
    "                                     |                                           ",
    "                                 [F]-|-[B]       hhhzzzsss'                      ",
    "                  GOLD FARM-------+     +--------BASE                            ",
    "                                                                                 ",
  },
  
  -- Station definitions - coordinates are based on map layout
  stations = {
    { 
      name = "A", 
      label = "MAIN STATION",
      desc = "Central hub connecting all major railway lines",
      x = 37, 
      y = 13, 
      isMain = true 
    },
    { 
      name = "B", 
      label = "ZENKKU BASE",
      desc = "Connection to Zenkku's Base",
      x = 37, 
      y = 3, 
      isMain = false 
    },
    { 
      name = "B", 
      label = "KHY'S BASE",
      desc = "Connection to Khy's Base",
      x = 45, 
      y = 11, 
      isMain = false 
    },
    { 
      name = "M", 
      label = "MINES",
      desc = "Access to the mining areas",
      x = 12, 
      y = 12, 
      isMain = false 
    },
    { 
      name = "A", 
      label = "END PORTAL",
      desc = "Direct access to the End Portal",
      x = 32, 
      y = 16, 
      isMain = false 
    },
    { 
      name = "B", 
      label = "OPT & AMY'S BASE",
      desc = "Connection to Opt and Amy's Base",
      x = 42, 
      y = 16, 
      isMain = false 
    },
    { 
      name = "F", 
      label = "GOLD FARM",
      desc = "Connection to the Gold Farm",
      x = 34, 
      y = 18, 
      isMain = false 
    },
    { 
      name = "B", 
      label = "HHHZZZSSS' BASE",
      desc = "Connection to hhhzzzsss' Base",
      x = 40, 
      y = 18, 
      isMain = false 
    }
  },
  
  -- Advanced display settings
  railColor = 0x666666,        -- Color for the railway lines
  stationColor = 0xFFAA00,     -- Color for regular stations
  mainStationColor = 0xFF0000, -- Color for main stations/hubs
  
  -- Custom button settings
  buttonActiveBg = 0x444444,   -- Background for active buttons
  buttonHoverColor = 0xAAAAAA, -- Hover color for buttons
}
