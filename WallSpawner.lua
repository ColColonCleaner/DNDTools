local className = "WallSpawner";
local wallHeight = 1.75;
local enabled = 0;
local firstPoint = nil;
local secondPoint = nil;

function onSave()
    saved_data = JSON.encode({
        wall_height = wallHeight
    });
    return saved_data;
end

function onload(saved_data)
    if saved_data ~= "" then
        local loaded_data = JSON.decode(saved_data);
        if loaded_data.wall_height ~= nil then
            wallHeight = loaded_data.wall_height;
        end
    end
    self.setVar("className", "WallSpawner");
    self.setVar("finishedLoading", true);
    rebuildContextMenu();
    refreshButtons();
end

function wallHeightUp()
    wallHeight = wallHeight + 0.25;
    if wallHeight > 5.0 then
        wallHeight = 5.0;
    end
    print("Wall Height: " .. wallHeight);
end

function wallHeightDown()
    wallHeight = wallHeight - 0.25;
    if wallHeight < 0.5 then
        wallHeight = 0.5;
    end
    print("Wall Height: " .. wallHeight);
end

function rebuildContextMenu()
    self.clearContextMenu();
    self.addContextMenuItem("Wall Height UP", wallHeightUp);
    self.addContextMenuItem("Wall Height DOWN", wallHeightDown);
end

function refreshButtons()
    self.clearButtons();
    if enabled == 1 then
        self.createButton({
            label = "ON",
            click_function = "buttonClick_toggleEnabled",
            function_owner = self,
            position = {0,0.3,0},
            rotation = {0,180,0},
            height = 350,
            width = 400,
            font_size = 250,
            color = {0,0,0},
            font_color = {1,1,1}
        });
    elseif enabled == 2 then
        self.createButton({
            label = "CHAIN",
            click_function = "buttonClick_toggleEnabled",
            function_owner = self,
            position = {0,0.3,0},
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
            position = {0,0.3,0},
            rotation = {0,180,0},
            height = 350,
            width = 500,
            font_size = 250,
            color = {0,0,0},
            font_color = {1,1,1}
        });
    end
end

function buttonClick_toggleEnabled()
    enabled = enabled + 1;
    if enabled > 2 then
        enabled = 0;
        firstPoint = nil;
        secondPoint = nil;
    end
    refreshButtons();
end

function onPlayerPing(player, position)
    --print(player.color .. " pinged " .. position:string())
    if enabled ~= 0 then
        if firstPoint == nil then
            firstPoint = position;
            return
        end
        secondPoint = position;
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
            if hitTable ~= nil and hitTable.point ~= nil and hitTable.hit_object ~= mtoken then
                startloc = hitTable.point;
                break;
            else
                if (debuggingEnabled) then
                    print("Did not find object below spawner.");
                end
            end
        end
        local avgY = startloc.y;
        local difX = secondPoint.x - firstPoint.x;
        local difZ = secondPoint.z - firstPoint.z;
        local dist = math.sqrt(math.pow(math.abs(difX), 2) + math.pow(math.abs(difZ), 2)) + 0.02;
        local angle = math.atan(difX / difZ) * 180.0 / math.pi;
        local newWall = spawnObject({
            type = "BlockSquare",
            position = {avgX, avgY + (wallHeight/2.0), avgZ},
            rotation = {0, angle, 0},
            scale = {0.1, wallHeight, dist},
            sound = false,
            snap_to_grid = false
        });
        newWall.setLock(true);
        newWall.setColorTint(self.getColorTint());
        if enabled == 2 then
            firstPoint = secondPoint;
            secondPoint = nil;
        else
            firstPoint = nil;
            secondPoint = nil;
        end
    end
end