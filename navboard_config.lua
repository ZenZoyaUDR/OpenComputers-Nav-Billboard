-- Railway System Display Configuration
-- Save as "navboard_config.lua" for use with the bootstrap updater

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
  
  -- You can add custom settings below this line
  -- These will be available in the config table in the main program
}
