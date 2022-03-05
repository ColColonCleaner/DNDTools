className = "OneWorldLineSaver"
versionNumber = "1.0"
oneWorldMap = nil
oneWorldLines = nil
drawingMode = false
linesSaved = false
finishedLoading = false
waitingForSave = false

function onSave()
    if waitingForSave == true then
        waitingForSave = false
        print("OneWorld lines saved!")
    end
    saved_data = JSON.encode({
        linesSaved = linesSaved,
        oneWorldLines = oneWorldLines
    });
    return saved_data
end

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
    self.setVar("className", "OneWorldLineSaver")
    self.setVar("finishedLoading", true)
    startLuaCoroutine(self, "initialize")
end

function initialize()
    local startTime = os.clock()

    local allObjects = getAllObjects()
    for _, obj in ipairs(allObjects) do
        if obj ~= self and obj ~= nil and obj.getName() == "_OW_vBase" then
            oneWorldMap = obj
        end
    end

    if oneWorldMap == nil then
        print("OneWorld is not available! Unable to load LineSaver.")
        self.clearContextMenu()
        self.addContextMenuItem("Reload LineSaver", initialize)
        return 1
    end

    if oneWorldMap.getBounds().size.x < 10 then
        print("A OneWorld map is not deployed! Deploy a map first.")
        self.clearContextMenu()
        self.addContextMenuItem("Reload LineSaver", initialize)
        return 1
    end

    revertToSave()

    rebuildContextMenu()
    Initialized = true
    return 1
end

function rebuildContextMenu()
    self.clearContextMenu()

    if (drawingMode) then
        self.addContextMenuItem("[X] Drawing Mode", toggleDrawingMode)
        if (linesSaved) then
            self.addContextMenuItem("[X] Save Lines", saveLines)
        else
            self.addContextMenuItem("[ ] Save Lines", saveLines)
        end
    else
        self.addContextMenuItem("[ ] Drawing Mode", toggleDrawingMode)
    end
    if (linesSaved and oneWorldLines ~= nil) then
        self.addContextMenuItem("Revert To Save", revertToSave)
        self.addContextMenuItem("Remove All Lines", removeAllLines)
    end
end

function toggleDrawingMode()
    if drawingMode == false then
        -- confirm that the map is currently non-interactable
        if oneWorldMap.interactable == true then
            -- if it's interactable, tell them to initialize oneWorldMap
            print("Initialize OneWorld first!")
            return
        end
        -- make the map interactable
        oneWorldMap.interactable = true
        drawingMode = true
        print("Drawing mode enabled!")
    else
        -- make the map non-interactable
        oneWorldMap.interactable = false
        drawingMode = false
        print("Drawing mode disabled!")
    end
    rebuildContextMenu()
end

function saveLines()
    if drawingMode == false then
        print("Enable drawing mode before drawing lines on the map. Otherwise they will not be saved.")
        return
    end
    local newLines = oneWorldMap.getVectorLines()
    if newLines == nil or #newLines == 0 then
        print("OneWorld map doesn't have any lines to save!")
        return
    end
    oneWorldLines = newLines
    linesSaved = true
    oneWorldMap.interactable = false
    drawingMode = false
    print("Waiting for save tick, please wait...")
    waitingForSave = true
    rebuildContextMenu()
end

function revertToSave()
    if (linesSaved and oneWorldLines ~= nil) then
        oneWorldMap.setVectorLines(oneWorldLines)
    end
end

function onDestroy()
    if (linesSaved and oneWorldLines ~= nil) then
        oneWorldMap.setVectorLines({})
    end
end

function removeAllLines()
    if (linesSaved and oneWorldLines ~= nil) then
        oneWorldMap.setVectorLines({})
        oneWorldLines = nil
        linesSaved = false
        print("OneWorld lines deleted!")
        rebuildContextMenu()
    end
end