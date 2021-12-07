local className = "WallSpawner";
versionNumber = "1.7";
local wallHeight = 1.0;
local wallOffset = 0;
local enabled = 0;
local firstPoint = nil;
local secondPoint = nil;
local thirdPoint = nil;
local debuggingEnabled = true;

function onSave()
    saved_data = JSON.encode({
        wall_height = wallHeight,
        wall_offset = wallOffset
    });
    return saved_data;
end

function onload(saved_data)
    if saved_data ~= "" then
        local loaded_data = JSON.decode(saved_data);
        if loaded_data.wall_height ~= nil then
            wallHeight = loaded_data.wall_height;
        end
        if loaded_data.wall_offset ~= nil then
            wallOffset = loaded_data.wall_offset;
        end
    end
    self.setVar("className", "WallSpawner");
    self.setVar("finishedLoading", true);
    self.setName("Wall Spawner " .. versionNumber);
    rebuildContextMenu();
    refreshButtons();
    Wait.frames(stabilize, 1);
end

function onPickUp(player_color)
    destabilize();
end

function onDrop(player_color)
    stabilize();
end

function stabilize()
    local rb = self.getComponent("Rigidbody");
    rb.set("freezeRotation", true);
end

function destabilize()
    local rb = self.getComponent("Rigidbody");
    rb.set("freezeRotation", false);
end

function wallHeightUp()
    wallHeight = wallHeight + 0.25;
    if wallHeight > 5.0 then
        wallHeight = 5.0;
    end
    Wait.frames(refreshButtons, 1);
    print("Wall Height: " .. wallHeight .. " squares.");
end

function wallHeightDown()
    wallHeight = wallHeight - 0.25;
    if wallHeight < 0.25 then
        wallHeight = 0.25;
    end
    Wait.frames(refreshButtons, 1);
    print("Wall Height: " .. wallHeight .. " squares.");
end

function wallOffsetUp()
    wallOffset = wallOffset + 0.25;
    if wallOffset > 5.0 then
        wallOffset = 5.0;
    end
    Wait.frames(refreshButtons, 1);
    print("Wall Offset: " .. wallOffset);
end

function wallOffsetDown()
    wallOffset = wallOffset - 0.25;
    if wallOffset < 0.0 then
        wallOffset = 0.0;
    end
    Wait.frames(refreshButtons, 1);
    print("Wall Offset: " .. wallOffset);
end

function rebuildContextMenu()
    self.clearContextMenu();
    self.addContextMenuItem("Wall Height UP", wallHeightUp);
    self.addContextMenuItem("Wall Height DOWN", wallHeightDown);
    self.addContextMenuItem("Wall Offset UP", wallOffsetUp);
    self.addContextMenuItem("Wall Offset DOWN", wallOffsetDown);
end

function refreshButtons()
    self.clearButtons();
    self.clearInputs();
    if enabled == 1 then
        self.createButton({
            label = "NORMAL",
            click_function = "buttonClick_toggleEnabled",
            function_owner = self,
            position = {0,0.2,-0.8},
            rotation = {0,180,0},
            height = 350,
            width = 1000,
            font_size = 250,
            color = {0,0,0},
            font_color = {1,1,1}
        });
    elseif enabled == 2 then
        self.createButton({
            label = "CHAIN",
            click_function = "buttonClick_toggleEnabled",
            function_owner = self,
            position = {0,0.2,-0.8},
            rotation = {0,180,0},
            height = 350,
            width = 800,
            font_size = 250,
            color = {0,0,0},
            font_color = {1,1,1}
        });
    elseif enabled == 3 then
        self.createButton({
            label = "SQUARE",
            click_function = "buttonClick_toggleEnabled",
            function_owner = self,
            position = {0,0.2,-0.8},
            rotation = {0,180,0},
            height = 350,
            width = 950,
            font_size = 250,
            color = {0,0,0},
            font_color = {1,1,1}
        });
    elseif enabled == 4 then
        self.createButton({
            label = "BLOCK",
            click_function = "buttonClick_toggleEnabled",
            function_owner = self,
            position = {0,0.2,-0.8},
            rotation = {0,180,0},
            height = 350,
            width = 800,
            font_size = 250,
            color = {0,0,0},
            font_color = {1,1,1}
        });
    else
        self.createButton({
            label = "OFF",
            click_function = "buttonClick_toggleEnabled",
            function_owner = self,
            position = {0,0.2,-0.8},
            rotation = {0,180,0},
            height = 350,
            width = 500,
            font_size = 250,
            color = {0,0,0},
            font_color = {1,1,1}
        });
    end
    self.createInput({
        label = "H",
        input_function = "inputChange_height",
        function_owner = self,
        position = {0.6,0.2,-1.5},
        rotation = {0,180,0},
        height = 300,
        width = 500,
        font_size = 250,
        color = {0,0,0},
        font_color = {1,1,1},
        alignment = 3,
        value = wallHeight,
        validation = 3,
        tab = 2,
        tooltip = "Wall Height"
    });
    self.createInput({
        label = "O",
        input_function = "inputChange_offset",
        function_owner = self,
        position = {-0.6,0.2,-1.5},
        rotation = {0,180,0},
        height = 300,
        width = 500,
        font_size = 250,
        color = {0,0,0},
        font_color = {1,1,1},
        alignment = 3,
        value = wallOffset,
        validation = 3,
        tab = 2,
        tooltip = "Wall Vertical Offset"
    });
end

function buttonClick_toggleEnabled()
    enabled = enabled + 1;
    if enabled > 4 then
        enabled = 0;
        firstPoint = nil;
        secondPoint = nil;
        thirdPoint = nil;
    end
    refreshButtons();
end

function inputChange_height(obj, color, input, stillEditing)
    if not stillEditing then
        if input == "" then
            input = "1"
        end
        wallHeight = tonumber(input)
        if wallHeight < 0.25 then
            wallHeight = 0.25
        end
        if wallHeight > 5.0 then
            wallHeight = 5.0
        end
        Wait.frames(refreshButtons, 1);
        print("Wall Height: " .. wallHeight .. " grid squares.");
    end
end

function inputChange_offset(obj, color, input, stillEditing)
    if not stillEditing then
        if input == "" then
            input = "0"
        end
        wallOffset = tonumber(input)
        if wallOffset < 0.0 then
            wallOffset = 0.0
        end
        if wallOffset > 5.0 then
            wallOffset = 5.0
        end
        Wait.frames(refreshButtons, 1);
        print("Wall Vertical Offset: " .. wallOffset .. " grid squares.");
    end
end

function onPlayerPing(player, position)
    --print(player.color .. " pinged " .. position:string())
    if enabled == 3 then
        -- Figure out which square the player pinged
        local gridX = math.ceil((position.x - Grid.offsetX) / Grid.sizeX) - 0.5;
        local gridY = math.ceil((position.z - Grid.offsetY) / Grid.sizeY) - 0.5;

        --print("Grid: " .. gridX .. " -/- " .. gridY)

        local startLoc = self.getPosition();
        local hitList = Physics.cast({
            origin       = self.getBounds().center,
            direction    = {0,-1,0},
            type         = 1,
            max_distance = 10,
            debug        = true,
        });
        for _, hitTable in ipairs(hitList) do
            -- Find the first object directly below the mini
            if hitTable ~= nil and hitTable.point ~= nil and hitTable.hit_object ~= self then
                startLoc = hitTable.point;
                break;
            else
                if (debuggingEnabled) then
                    print("Did not find object below ping.");
                end
            end
        end
        local startY = startLoc.y;
        -- Account for offset. Raise Y by that offset multiplied by the grid size.
        startY = startY + (wallOffset * Grid.sizeX);
        local startX = Grid.offsetX + (gridX * Grid.sizeX);
        local startZ = Grid.offsetY + (gridY * Grid.sizeY);
        local floorHeight = 0.1
        local newWall = spawnObject({
            type = "BlockSquare",
            position = {startX, startY + (floorHeight/2.0), startZ},
            rotation = {0, 0, 0},
            scale = {Grid.sizeX, floorHeight, Grid.sizeY},
            sound = false,
            snap_to_grid = false
        });
        newWall.setLock(true);
        newWall.setColorTint(self.getColorTint());
        firstPoint = nil;
        secondPoint = nil;
        thirdPoint = nil;
    elseif enabled == 4 then
        if firstPoint == nil then
            firstPoint = vector(position.x, 0, position.z);
            return
        end
        if secondPoint == nil then
            secondPoint = vector(position.x, 0, position.z);
            return
        end
        thirdPoint = vector(position.x, 0, position.z);
        local avgX = (firstPoint.x + secondPoint.x) / 2.0;
        local avgZ = (firstPoint.z + secondPoint.z) / 2.0;
        local startloc = self.getPosition();
        local hitList = Physics.cast({
            origin       = self.getBounds().center,
            direction    = {0,-1,0},
            type         = 1,
            max_distance = 10,
            debug        = false,
        });
        for _, hitTable in ipairs(hitList) do
            -- Find the first object directly below the mini
            if hitTable ~= nil and hitTable.point ~= nil and hitTable.hit_object ~= self then
                startloc = hitTable.point;
                break;
            else
                if (debuggingEnabled) then
                    print("Did not find object below spawner.");
                end
            end
        end
        local avgY = startloc.y;
        -- Account for offset. Raise Y by that offset multiplied by the grid size.
        avgY = avgY + (wallOffset * Grid.sizeX);
        local difX = secondPoint.x - firstPoint.x;
        local difZ = secondPoint.z - firstPoint.z;

        -- Length of the rectangle is the distance between first two points
        local length = firstPoint:distance(secondPoint);
        print("length: " .. length);
        -- Width of the rectangle is the distance of third point from the line between first two points.
        local widthDenominator = math.sqrt(math.pow(secondPoint.x - firstPoint.x, 2) + math.pow(secondPoint.z - firstPoint.z, 2));
        local width =  math.abs(((secondPoint.x - firstPoint.x)*(firstPoint.z - thirdPoint.z)) - ((firstPoint.x - thirdPoint.x)*(secondPoint.z - firstPoint.z))) / widthDenominator;
        print("width: " .. width);
        local directionWidth = (((secondPoint.x - firstPoint.x)*(firstPoint.z - thirdPoint.z)) - ((firstPoint.x - thirdPoint.x)*(secondPoint.z - firstPoint.z))) / widthDenominator;
        --print("directionWidth: " .. directionWidth);
        local vect = Vector.between(firstPoint, secondPoint):normalized();
        local angle = vect:heading('y');
        vect = vect:rotateOver('y', 90 * (directionWidth / math.abs(directionWidth))):scale(width);
        print("new_vectx: " .. vect.x);
        print("new_vectz: " .. vect.z);
        print("new_vecty: " .. vect.y);
        print("new_angle: " .. vect:heading('y'));
        local boundryPoint = firstPoint:add(vect);
        print("boundry_x: " .. boundryPoint.x);
        print("boundry_z: " .. boundryPoint.z);
        print("boundry_y: " .. boundryPoint.y);
        local midPoint = Vector.between(boundryPoint, secondPoint):scale(0.5):add(boundryPoint);
        print("midPoint_x: " .. midPoint.x);
        print("midPoint_z: " .. midPoint.z);
        print("midPoint_y: " .. midPoint.y);
        local newWall = spawnObject({
            type = "BlockSquare",
            position = {midPoint.x, avgY + (wallHeight * Grid.sizeX / 2.0), midPoint.z},
            rotation = {0, angle, 0},
            scale = {width, wallHeight * Grid.sizeX, length},
            sound = false,
            snap_to_grid = false
        });
        newWall.setLock(true);
        newWall.setColorTint(self.getColorTint());
        firstPoint = nil;
        secondPoint = nil;
        thirdPoint = nil;
    elseif enabled ~= 0 then
        if firstPoint == nil then
            firstPoint = vector(position.x, 0, position.z);
            return
        end
        secondPoint = vector(position.x, 0, position.z);
        local avgX = (firstPoint.x + secondPoint.x) / 2.0;
        local avgZ = (firstPoint.z + secondPoint.z) / 2.0;
        local startloc = self.getPosition();
        local hitList = Physics.cast({
            origin       = self.getBounds().center,
            direction    = {0,-1,0},
            type         = 1,
            max_distance = 10,
            debug        = false,
        });
        for _, hitTable in ipairs(hitList) do
            -- Find the first object directly below the mini
            if hitTable ~= nil and hitTable.point ~= nil and hitTable.hit_object ~= self then
                startloc = hitTable.point;
                break;
            else
                if (debuggingEnabled) then
                    print("Did not find object below spawner.");
                end
            end
        end
        local avgY = startloc.y;
        -- Account for offset. Raise Y by that offset multiplied by the grid size.
        avgY = avgY + (wallOffset * Grid.sizeX);
        local difX = secondPoint.x - firstPoint.x;
        local difZ = secondPoint.z - firstPoint.z;
        local dist = math.sqrt(math.pow(math.abs(difX), 2) + math.pow(math.abs(difZ), 2)) + 0.02;
        local angle = math.atan(difX / difZ) * 180.0 / math.pi;
        local newWall = spawnObject({
            type = "BlockSquare",
            position = {avgX, avgY + (wallHeight * Grid.sizeX / 2.0), avgZ},
            rotation = {0, angle, 0},
            scale = {0.1, wallHeight * Grid.sizeX, dist},
            sound = false,
            snap_to_grid = false
        });
        newWall.setLock(true);
        newWall.setColorTint(self.getColorTint());
        if enabled == 2 then
            firstPoint = secondPoint;
            secondPoint = nil;
            thirdPoint = nil;
        else
            firstPoint = nil;
            secondPoint = nil;
            thirdPoint = nil;
        end
    end
end
