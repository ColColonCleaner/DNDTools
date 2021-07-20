className = "MeasurementTool";
versionNumber = "2.30";
finishedLoading = false;
toggleMeasure = 0;
pickedUp = 0;
lastPickedUpObjects = {};
pickedUpColor = nil;
firstUpdate = 0;
rotationVector = vector(0, 0, 0);
positionVector = vector(0, 0, 0);
distance_label = self.createButton({
    label="", click_function="none", position = pointLabel, rotation={-58,0,0}, height=0, width=0, font_size=500,
    font_color={1, 1, 1},
    alignment=2
});
cm_label = self.createButton({
    label="feet", click_function="none", position = {0, 7.7, 0.8}, rotation={-58,0,0}, height=0, width=0, font_size=200,
    font_color={1, 1, 1},
    alignment=2
});

function onSave()
    return saved_data
end

function onload(saved_data)
    self.setVar("className", "MeasurementTool");
    self.setVar("finishedLoading", true);
    self.setName("DND Measurement Tool " .. versionNumber);
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

function getTrimmedVectorLines()
    currentLines = Global.getVectorLines();
    trimmedVectorLines = {};
    if currentLines ~= nil then
        for _, curVect in ipairs(currentLines) do
            if curVect ~= nil and math.abs(curVect.thickness - 0.1023) >= 0.0001 then
                table.insert(trimmedVectorLines, curVect);
            end
        end
    end
    return trimmedVectorLines;
end

function onObjectPickUp(player_color, targetObj)
    if targetObj == self then
        pickedUpColor = player_color;
        toggleMeasure = 1;
        pickedUp = 1;
    end

    if targetObj != nil and targetObj != self then
        -- if the last player to touch the stick picked up something else, remove measurements
        if player_color == pickedUpColor then
            toggleMeasure = 0;
            Global.setVectorLines(getTrimmedVectorLines());
        end
        colorName = player_color .. "";
        lastPickedUpObjects[colorName] = targetObj;
    end

end

function onObjectDrop(player_color, dropped_object)
    -- Every time the stick is dropped, grab that position/rotation.
    -- if you don't save the position when dropped then the stick drifts slowly
    if dropped_object == self then
        rotationVector = self.getRotation();
        positionVector = self.getPosition();
        pickedUp = 0;
    end
end

function resetScales()
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

function onUpdate()
    if finishedLoading == false then
        return;
    end

    -- first time through, grab the current position of the stick
    if firstUpdate == 0 then
        firstUpdate = 1;
        rotationVector = self.getRotation();
        positionVector = self.getPosition();
    end

    -- grab the current position of the stick
    -- if it's not being held, use the saved stick position
    pointA = self.getPosition();
    if pickedUp == 0 then
        pointA = positionVector;
    end

    if toggleMeasure == 0 then
        self.editButton({index=0,label=""});
        return;
    end

    if pickedUpColor == nil then
        return;
    end
    playerLastObject = lastPickedUpObjects[pickedUpColor .. ""];
    if playerLastObject == nil then
        return;
    end

    -- make sure the stick stays still and upright when not held
    if pickedUp == 0 then
        self.setVelocity({0, 0, 0});
        self.setAngularVelocity({0, 0, 0});
        self.setPosition({positionVector.x, positionVector.y + 0.1, positionVector.z});
    end
    -- If measuring, face the player
    if pickedUpColor ~= nil then
        self.setRotation({x = 0, y = Player[pickedUpColor].getPointerRotation(), z = 0});
    end

    pointB = playerLastObject.getPosition();

    pointR = pointA - pointB;
    -- ACTUAL distance calculations
    --pointR[1] = math.abs(pointR[1]);
    --pointR[3] = math.abs(pointR[3]);
    --distResult = math.sqrt((pointR[1]^2) + (pointR[3]^2));
    -- DND distance calculations
    distResult = math.abs(pointR[1]);
    zResult = math.abs(pointR[3]);
    if zResult > distResult then
        distResult = zResult;
    end

    descriptionText = self.getDescription();
    -- Check if the description starts with 'c' to call a calibration
    if string.sub(descriptionText, 1, 1) == "c" then
        -- Calibrate using the remaining text after 'c'
        descriptionText = string.sub(descriptionText, 2, string.len(descriptionText));
        calibrationDistance = tonumber(descriptionText);
        gridSize = (5.0 / (calibrationDistance / distResult));
        Grid.sizeX = gridSize;
        Grid.sizeY = gridSize;
        Grid.offsetX = pointA[1] - (gridSize / 2.0);
        Grid.offsetY = pointA[3] - (gridSize / 2.0);
        resetScales();
        self.setDescription("To calibrate use a 'c' prefix in this description. i.e. c50 calibrates the current distance as 50 feet.");
    end

    distValue = distResult * (5.0 / Grid.sizeX);
    distanceText = (math.floor((distValue + 2.5) / 5.0) * 5) .. "";

    --editing the button position to match pole
    self.editButton({index=0,label=distanceText, position = {0,8.2,0.5}});

    --Drawing the line between pole and selected object
    if pickedUp == 1 then
        newVectorLines = getTrimmedVectorLines();
        table.insert(newVectorLines, {
            points    = { {pointA[1],pointA[2],pointA[3]}, {pointB[1],pointB[2],pointB[3]} },
            color     = self.getColorTint(),
            thickness = 0.1023,
            rotation  = {0,0,0},
        });
        Global.setVectorLines(newVectorLines);
    end
end