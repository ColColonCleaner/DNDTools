className = "OneWorldGridSaver";
versionNumber = "2.1.0";
savedGridState = false;
gridStateData = nil;
finishedLoading = false;

function onload(saved_data)
    if saved_data ~= "" then
        local loaded_data = JSON.decode(saved_data);
        if loaded_data.saved_grid_state ~= nil then
            savedGridState = loaded_data.saved_grid_state;
            gridStateData = {
                type = loaded_data.type,
                show_lines = loaded_data.show_lines,
                color = loaded_data.color,
                opacity = loaded_data.opacity,
                thick_lines = loaded_data.thick_lines,
                snapping = loaded_data.snapping,
                offsetX = loaded_data.offsetX,
                offsetY = loaded_data.offsetY,
                sizeX = loaded_data.sizeX,
                sizeY = loaded_data.sizeY
            };
        end
    end
    self.setVar("className", "OneWorldGridSaver");
    self.setName("GridSaver " .. versionNumber);
    rebuildContextMenu();
    resetGridState();
    self.setVar("finishedLoading", true);
end

function rebuildContextMenu()
    self.clearContextMenu();
    if savedGridState then
        self.addContextMenuItem("[X] Save Grid State", saveGridState);
        self.addContextMenuItem("Reset Saver", resetSaver);
    else
        self.addContextMenuItem("[ ] Save Grid State", saveGridState);
    end
    self.addContextMenuItem("Toggle Grid", toggleGridVisibility)
    self.addContextMenuItem("Enable Grid Proj.", enableGridProjection);
end

function toggleGridVisibility()
    Grid.show_lines = not Grid.show_lines
end

function enableGridProjection()
    local oneWorldMap = nil;
    local allObjects = getAllObjects();
    for _, obj in ipairs(allObjects) do
        if obj ~= self and obj ~= nil and obj.getName() == "_OW_vBase" then
            oneWorldMap = obj;
        end
    end
    if oneWorldMap == nil then
        print("OneWorld is not available! Unable to enable grid projection.");
        return;
    end
    oneWorldMap.grid_projection = true;
    print("OneWorld grid projection enabled!");
end

function resetSaver()
    savedGridState = false;
    gridStateData = nil;
    self.script_state = "";
    rebuildContextMenu();
    print("Grid save data deleted!")
end

function saveGridState()
    savedGridState = true;
    gridStateData = Grid;
    self.script_state = JSON.encode({
        saved_grid_state = true,
        type = Grid.type,
        show_lines = Grid.show_lines,
        color = Grid.color,
        opacity = Grid.opacity,
        thick_lines = Grid.thick_lines,
        snapping = Grid.snapping,
        offsetX = Grid.offsetX,
        offsetY = Grid.offsetY,
        sizeX = Grid.sizeX,
        sizeY = Grid.sizeY
    });
    rebuildContextMenu();
    print("Grid state saved! Token can be packed now.")
end

function resetGridState()
    if savedGridState then
        Grid.type = gridStateData.type;
        Grid.show_lines = gridStateData.show_lines;
        Grid.color = gridStateData.color;
        Grid.opacity = gridStateData.opacity;
        Grid.thick_lines = gridStateData.thick_lines;
        Grid.snapping = gridStateData.snapping;
        Grid.offsetX = gridStateData.offsetX;
        Grid.offsetY = gridStateData.offsetY;
        Grid.sizeX = gridStateData.sizeX;
        Grid.sizeY = gridStateData.sizeY;

        -- Trigger applicable mini resizing
        local allObjects = getAllObjects()
        for _, obj in ipairs(allObjects) do
            if obj ~= self and obj ~= nil then
                local typeCheck = obj.getVar("className");
                if typeCheck == "MeasurementToken" then
                     obj.call("resetScale");
                end
            end
        end
    end
end