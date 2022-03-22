className = "OneWorldLineSaver"
versionNumber = "2.0.0"
oneWorldLines = nil
linesSaved = false
finishedLoading = false

function onload(saved_data)
    if saved_data ~= "" then
        local loaded_data = JSON.decode(saved_data)
        if loaded_data.linesSaved ~= nil then
            linesSaved = loaded_data.linesSaved
        end
        if loaded_data.oneWorldLines ~= nil then
            oneWorldLines = loaded_data.oneWorldLines
        end
    end
    revertToSave()
    rebuildContextMenu()
    self.setVar("className", "OneWorldLineSaver")
    self.setVar("finishedLoading", true)
    self.setName("LineSaver " .. versionNumber);
end

function rebuildContextMenu()
    self.clearContextMenu()

    if (linesSaved) then
        self.addContextMenuItem("[X] Save Lines", saveLines)
    else
        self.addContextMenuItem("[ ] Save Lines", saveLines)
    end
    if (linesSaved and oneWorldLines ~= nil) then
        self.addContextMenuItem("Revert To Save", revertToSave)
        self.addContextMenuItem("Reset LineSaver", resetLineSaver)
    end
end

function saveLines()
    local validLines = getValidVectorLines(true)
    if validLines == nil or #validLines == 0 then
        print("No drawn lines to save! Only lines within the map area are saved.")
        return
    end
    oneWorldLines = validLines
    linesSaved = true
    self.script_state = JSON.encode({
        linesSaved = linesSaved,
        oneWorldLines = oneWorldLines
    });
    print("Drawn lines saved! Only lines within the map area are saved.")
    rebuildContextMenu()
end

function revertToSave()
    if (linesSaved and oneWorldLines ~= nil) then
        local newLines = getValidVectorLines(false)
        for _,v in ipairs(oneWorldLines) do
           table.insert(newLines, v)
        end
        Global.setVectorLines(newLines)
    end
end

function onObjectDestroy(destroy_obj)
    if destroy_obj == self and linesSaved and oneWorldLines ~= nil then
        Global.setVectorLines(getValidVectorLines(false))
    end
end

function getValidVectorLines(internal)
    local globalLines = Global.getVectorLines()
    -- Loop over the lines and find valid ones to save.
    -- Use OneWorld map bounds.
    local lineBounds = getMapBounds(true)
    local minX = lineBounds.x / -2.0
    local maxX = lineBounds.x / 2.0
    local minZ = lineBounds.z / -2.0
    local maxZ = lineBounds.z / 2.0
    local validLines = {}
    for i = 1, #globalLines do
        local currentLine = globalLines[i]
        -- Determine whether the line falls within bounds
        -- Save the line if a single point falls within the bounds
        local saveLine = false
        for li = 1, #currentLine.points do
            local currentPoint = currentLine.points[li]
            if currentPoint.x > minX and
               currentPoint.x < maxX and
               currentPoint.z > minZ and
               currentPoint.z < maxZ then
                saveLine = true
                break
            end
        end
        if internal == saveLine then
            table.insert(validLines, currentLine)
        end
    end
    return validLines
end

function resetLineSaver()
    if (linesSaved and oneWorldLines ~= nil) then
        oneWorldLines = nil
        linesSaved = false
        self.script_state = JSON.encode({
            linesSaved = linesSaved,
            oneWorldLines = oneWorldLines
        });
        print("LineSaver reset! Saved lines forgotten!")
        rebuildContextMenu()
    end
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
            if debuggingEnabled then
                print("Using OneWorld map bounds.")
            end
            return oneWorldBounds.size
        end
        if debug or debuggingEnabled then
            print("A OneWorld map is not deployed! Using default bounds.")
        end
        return defaultBounds
    end
    if debug or debuggingEnabled then
        print("OneWorld is not available! Using default bounds.")
    end
    return defaultBounds
end