RegisterJob = function()
    -- Building to enter to gang boss. [vector4(4.567, 220.948, 107.795, 221.524)]
    -- No guns.
    -- Can register a gang.
    -- If in gang can interact with other npcs for daily missions.

    PedInteraction:Add("GangBossSecurity", `s_m_y_doorman_01`, vector3(4.567, 220.948, 106.795), 221.524, 25.0, {
        {
            icon = "person",
            text = "Interact",
            event = "GangSystem:Client:Security",
        }
    }, 'user-secret')
end

RegisterNetEvent('GangSystem:Client:Security', function(entity)
    NPCDialog.Open(entity.entity, {
        first_name = 'Aspect',
        last_name = 'Roleplay',
        Tag = '👿',
        description = 'No weapons allowed.',
        buttons = {
            {
                label = 'I want to enter !',
                data = { close = true, event = '' }
            },
            {
                label = 'See you later !',
                data = { close = true }
            }
        }
    })
end)