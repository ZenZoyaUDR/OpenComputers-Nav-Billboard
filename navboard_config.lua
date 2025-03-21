-- Railway System Display Configuration

return {
    -- Display settings
    updateInterval = 10,          -- Update interval in seconds
    screenWidth = 80,             -- Screen width
    screenHeight = 30,            -- Screen height
    
    -- Color settings (in hex)
    defaultBackground = 0x000000, -- Black background
    defaultForeground = 0xFFFFFF, -- White text
    titleColor = 0x00FF00,        -- Green for title
    stationColor = 0xFFFF00,      -- Yellow for stations
    railColor = 0x808080,         -- Gray for railway lines
    mainStationColor = 0xFF0000,  -- Red for main stations/hubs
    useColorsIfAvailable = true,  -- Set to false for monochrome displays
    
    -- Railway map - ASCII art representation of your railway system
    -- Modify this to match your server's railway layout
    railwayMap = {
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
    },
    
    -- Station information
    -- Each station has: 
    -- - name: The label shown on the map
    -- - label: Full name of the station
    -- - desc: Description or notes about the station
    -- - x, y: Coordinates on the map (relative to top-left)
    -- - isMain: true for main hubs, false for regular stations
    stations = {
      { name = "A", label = "NORTH HUB", desc = "Connection to Northern Mines and Western Forest", x = 19, y = 7, isMain = true },
      { name = "B", label = "CENTRAL JUNCTION", desc = "Major transit hub with storage facilities", x = 28, y = 7, isMain = true },
      { name = "C", label = "EAST STATION", desc = "Gateway to Eastern Village", x = 60, y = 7, isMain = true },
      { name = "D", label = "SOUTH JUNCTION", desc = "Industrial area transit point", x = 29, y = 15, isMain = false },
      { name = "E", label = "FARM STATION", desc = "Access to Southern Farms", x = 54, y = 15, isMain = false },
    },
  }
