
function onload(saved_data)
    self.clearButtons()
    self.createButton({
        label = "FoW",
        click_function = "buttonClick_spawnFOW",
        function_owner = self,
        position = {0,0.3,0},
        rotation = {0,180,0},
        height = 350,
        width = 800,
        font_size = 250,
        color = {0,0,0},
        font_color = {1,1,1}
    })
end

-- Handles clicks on the setup button
function buttonClick_spawnFOW()
    local bounds = getMapBounds(true)
    bounds.y = 20
    spawnObject({
        type = "FogOfWar",
        position = {0, 10.85, 0},
        rotation = {0, 0, 0},
        scale = bounds,
        sound = true
    });
end

function getOneWorldMap()
    for _, obj in ipairs(getAllObjects()) do
        if obj ~= self and obj ~= nil and obj.getName() == "_OW_vBase" then
            return obj
        end
    end
    return nil
end

function getMapBounds(debug)
    local defaultBounds = {x = 88.07, y = 1, z = 52.02}
    local oneWorldMap = getOneWorldMap()
    if oneWorldMap ~= nil then
        local oneWorldBounds = oneWorldMap.getBounds();
        if oneWorldBounds.size.x > 10 then
            print("Using OneWorld map bounds.")
            return oneWorldBounds.size
        end
        if debug then
            print("A OneWorld map is not deployed! Using default bounds.")
        end
        return defaultBounds
    end
    if debug then
        print("OneWorld is not available! Using default bounds.")
    end
    return defaultBounds
end