Config = {}

Config.EarlzBench = vector3(-225.36386108398, -1182.9503173828, 23.054676055908) -- New UI crafting spot

-- Crafting locations
Config.MetalLocation = vector3(-235.69961547852, -1181.3897705078, 23.054697036743)
Config.SteelLocation = vector4(-240.38273620605, -1178.7924804688, 23.054693222046, 93.600769042969)

-- Rim crafting requirements
Config.RequiredMetal = 12
Config.RequiredSteel = 12

-- Rims and sale price range
Config.Rims = {
    "forgi_rims",
    "bb_rims",
    "steel_rims"
}
Config.PriceRange = { min = 403, max = 855 }

-- Ped spawn distance & delay
Config.PedSpawnDist = 10.0
Config.NextPedDelay = 8000 -- ms
