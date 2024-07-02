_CONFIG = {
    -- PURCHASE_SPRAY_PED = {
    --     Vec3 = vector3(-298.193, -1332.476, 30.297),
    --     Heading = 297.840
    -- },
    SPRAY_COST = 10000,
    CONTEST_MINUTES = 15,
    MIN_MEMBERS = 3
}

RegisterCallbacks = function()
    Callbacks:RegisterServerCallback('GangSystem:Server:FetchConfig', function(source, data, cb)
        cb(_CONFIG)
    end)
end