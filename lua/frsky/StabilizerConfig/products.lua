local FrSkyProducts = {
  -- {
  --   ID = 0,
  --   Name = "Test family (Rx)",
  --   Products = {
  --     {ID = 0, Name = "Test Device", SupportFields = {1, 2, 3, 4, 5}}
  --   }
  -- },
  {
    ID = 2,
    Name = "Receiver",
    Products = {
      { ID = 36, Name = "TD SR12",       SupportFields = { 1, 2, 3, 4 }, CaliPrefix = "ap_sr12p" },
      { ID = 37, Name = "TD SR18",       SupportFields = { 1, 2, 3, 4 }, CaliPrefix = "td_sr18" },
      { ID = 38, Name = "TD SR10",       SupportFields = { 1, 2, 3, 4 }, CaliPrefix = "ap_sr10p" },
      { ID = 39, Name = "TD SR6",        SupportFields = { 1, 2, 3, 4 }, CaliPrefix = "td_sr6" },
      { ID = 50, Name = "TW SR12",       SupportFields = { 1, 2, 3, 4 }, CaliPrefix = "ap_sr12p" },
      { ID = 58, Name = "TW SR8",        SupportFields = { 1, 2, 3, 4 }, CaliPrefix = "ap_sr8" },
      { ID = 59, Name = "TW SR10",       SupportFields = { 1, 2, 3, 4 }, CaliPrefix = "ap_sr8" },
      { ID = 64, Name = "Archer+ SR10+", SupportFields = { 2, 3, 4 },    CaliPrefix = "ap_sr10p" },
      { ID = 68, Name = "Archer+ SR8",   SupportFields = { 2, 3, 4 },    CaliPrefix = "ap_sr8" },
      { ID = 76, Name = "Archer+ SR12+", SupportFields = { 2, 3, 4 },    CaliPrefix = "ap_sr12p" },
      { ID = 79, Name = "SR6 Mini",      SupportFields = { 2, 3, 4 },    CaliPrefix = "ap_sr6_mini" },
      { ID = 80, Name = "SR6 Mini E",    SupportFields = { 2, 3, 4 },    CaliPrefix = "ap_sr6_mini" },
      { ID = 81, Name = "SR6BL15A",      SupportFields = { 2, 3, 4 },    CaliPrefix = "sr6bl15a" },
      { ID = 82, Name = "SR6Lite",       SupportFields = { 2, 3, 4 },    CaliPrefix = "sr6l" },
    }
  },
  {
    ID = 3,
    Name = "Sensor",
    Products = {
      -- {ID = 0, Name = "Test Device", SupportFields = {1, 2, 3, 4, 5}}
      { ID = 22, Name = "RB35(S)", SupportFields = { 1, 2, 3 }, CaliPrefix = "rb35s" }
    }
  },
}

return FrSkyProducts
