
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
    self.clearContextMenu()
    self.addContextMenuItem("Hide OW Minimaps", hideOWMinimaps, true)
    self.addContextMenuItem("Hide OW Hub", hideOWHub, true)
end

function hideOWMinimaps()
    print("Hiding OneWorld Minimaps!")
    spawnObjectData({
        data = {
            Name = "FogOfWarTrigger",
            Transform = {
                posX = 65.0,
                posY = 65.0,
                posZ = 65.0,
                rotX = 0.0,
                rotY = 0.0,
                rotZ = 0.0,
                scaleX = 3.0,
                scaleY = 0.13,
                scaleZ = 3.0
            },
            Nickname = "",
            Description = "",
            GMNotes = "",
            ColorDiffuse = {
                r = 0.25,
                g = 0.25,
                b = 0.25,
                a = 0.1025644
            },
            LayoutGroupSortIndex = 0,
            Value = 0,
            Locked = true,
            Grid = true,
            Snap = true,
            IgnoreFoW = false,
            MeasureMovement = false,
            DragSelectable = true,
            Autoraise = true,
            Sticky = true,
            Tooltip = true,
            GridProjection = false,
            HideWhenFaceDown = false,
            Hands = false,
            FogColor = "Black",
            FogHidePointers = true,
            FogReverseHiding = false,
            FogSeethrough = false,
            LuaScript = "",
            LuaScriptState = "",
            XmlUI = ""
        }
    })
end

function hideOWHub()
    local owHub = getOneWorldHub()
    if owHub == nil then
        print("OneWorld is not available! Unable to spawn hidden zone.")
        return
    end
    local pos = owHub.getPosition()
    local rot = owHub.getRotation()
    print("Hiding OneWorld Hub!")
    spawnObjectData({
        data = {
            Name = "FogOfWarTrigger",
            Transform = {
                posX = pos.x,
                posY = pos.y,
                posZ = pos.z,
                rotX = rot.x,
                rotY = rot.y,
                rotZ = rot.z,
                scaleX = 12.00,
                scaleY = 0.40,
                scaleZ = 10.20
            },
            Nickname = "",
            Description = "",
            GMNotes = "",
            ColorDiffuse = {
                r = 0.25,
                g = 0.25,
                b = 0.25,
                a = 0.1025644
            },
            LayoutGroupSortIndex = 0,
            Value = 0,
            Locked = true,
            Grid = true,
            Snap = true,
            IgnoreFoW = false,
            MeasureMovement = false,
            DragSelectable = true,
            Autoraise = true,
            Sticky = true,
            Tooltip = true,
            GridProjection = false,
            HideWhenFaceDown = false,
            Hands = false,
            FogColor = "Black",
            FogHidePointers = true,
            FogReverseHiding = false,
            FogSeethrough = false,
            LuaScript = "",
            LuaScriptState = "",
            XmlUI = ""
        }
    })
end

-- Handles clicks on the setup button
function buttonClick_spawnFOW()
    local bounds = getMapBounds(true)
    bounds.y = 20
    spawnObject({
        type = "FogOfWar",
        position = {0, 100, 0},
        rotation = {0, 0, 0},
        scale = bounds,
        sound = true,
        callback_function = function(spawned_object)
            spawned_object.setPositionSmooth({0, 10.85, 0})
        end
    });
end

function getOneWorldHub()
    for _, obj in ipairs(getAllObjects()) do
        if obj ~= self and obj ~= nil and obj.getName() == "OW_Hub" then
            return obj
        end
    end
    return nil
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