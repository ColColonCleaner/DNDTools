className = "MeasurementTool"
versionNumber = "2.7.0"
finishedLoading = false
toggleMeasure = 0
pickedUp = 0
lastPickedUpObjects = {}
pickedUpColor = nil
firstUpdate = 0
rotationVector = vector(0, 0, 0)
positionVector = vector(0, 0, 0)
inputsActive = false
enableCalibration = false
vertexMode = false
alternateDiag = false
finalDistance = 1

savedStartPoint = nil
savedEndPoint = nil

function onSave()
    local save_state = JSON.encode({
        enableCalibration = enableCalibration,
        vertexMode = vertexMode,
        alternateDiag = alternateDiag
    })
    return save_state
end

function onload(save_state)

    if save_state ~= "" then
        -- ALRIGHTY, let's see which state data we need to use
        local saved_data = JSON.decode(save_state)
        if saved_data.alternateDiag ~= nil then
            alternateDiag = saved_data.alternateDiag
        end
        if saved_data.enableCalibration ~= nil then
            enableCalibration = saved_data.enableCalibration
        end
        if saved_data.vertexMode ~= nil then
            vertexMode = saved_data.vertexMode
        end
    end

    self.setVar("className", "MeasurementTool")
    self.setVar("finishedLoading", true)
    self.setName("DND Measurement Tool " .. versionNumber)

    distance_label = self.createButton({
        label="",
        click_function="none",
        position = {0, 8.2, 0.5},
        --position = {0,0.30,-0.1},
        rotation={-58,0,0},
        height=0,
        width=0,
        font_size=500,
        font_color={1, 1, 1},
        alignment=2
    })
    cm_label = self.createButton({
        label="feet",
        click_function="none",
        position = {0, 7.7, 0.8},
        --position = {0, 0.30, 0.55},
        rotation={-58,0,0},
        height=0,
        width=0,
        font_size=200,
        font_color={1, 1, 1},
        alignment=2
    })

    destroyActiveInputs()
    rebuildContextMenu()
    self.setVectorLines({})

    Wait.frames(stabilize, 1)
end

function rebuildContextMenu()
    self.clearContextMenu()
    if enableCalibration == true then
        self.addContextMenuItem("[X] Calibration", toggleEnableCalibration)
        if vertexMode == true then
            self.addContextMenuItem("[X] Vertex Mode", toggleEnableVertexMode)
        else
            self.addContextMenuItem("[ ] Vertex Mode", toggleEnableVertexMode)
        end
    else
        self.addContextMenuItem("[ ] Calibration", toggleEnableCalibration)
    end
    if alternateDiag == true then
        self.addContextMenuItem("[X] Alt. Diagonals", toggleAlternateDiag)
    else
        self.addContextMenuItem("[ ] Alt. Diagonals", toggleAlternateDiag)
    end
    self.addContextMenuItem("Toggle Grid", toggleGridVisibility)
end

function toggleGridVisibility()
    Grid.show_lines = not Grid.show_lines
end

function toggleEnableVertexMode()
    vertexMode = not vertexMode
    rebuildContextMenu()
end

function toggleEnableCalibration()
    enableCalibration = not enableCalibration
    rebuildContextMenu()
    if enableCalibration == false then
        destroyActiveInputs()
    end
end

function toggleAlternateDiag()
    alternateDiag = not alternateDiag
    rebuildContextMenu()
end

function createActiveInputs()
    if pickedUpColor == nil or inputsActive == true or enableCalibration == false then
        return
    end
    inputsActive = true
    cm_label = self.createInput({
        label="Cal.",
        input_function="calibrationFunction",
        function_owner=self,
        position = {0, 9.0, 0},
        rotation={-58,0,0},
        height=350,
        width=700,
        font_size=300,
        font_color={0, 0, 0},
        alignment=2,
        validation=2,
        tab=2
    })
end

function destroyActiveInputs()
    if inputsActive == true then
        inputsActive = false
        self.clearInputs()
    end
end

function onPickUp(player_color)
    destabilize()
end

function onDrop(player_color)
    stabilize()
    rotationVector = self.getRotation()
    positionVector = self.getPosition()
    pickedUp = 0
end

function stabilize()
    local rb = self.getComponent("Rigidbody")
    rb.set("freezeRotation", true)
end

function destabilize()
    local rb = self.getComponent("Rigidbody")
    rb.set("freezeRotation", false)
end

function onObjectPickUp(player_color, targetObj)
    if targetObj == self then
        pickedUpColor = player_color
        toggleMeasure = 1
        pickedUp = 1
    end

    if targetObj != nil and targetObj != self then
        -- if the last player to touch the stick picked up something else, remove measurements
        if player_color == pickedUpColor then
            toggleMeasure = 0
            self.setVectorLines({})
        end
        colorName = player_color .. ""
        lastPickedUpObjects[colorName] = targetObj
        destroyActiveInputs()
    end

end

function resetScales()
    local allObjects = getAllObjects()
    for _, obj in ipairs(allObjects) do
        if obj ~= self and obj ~= nil then
            local typeCheck = obj.getVar("className")
            if typeCheck == "MeasurementToken" then
                 obj.call("resetScale")
            end
        end
    end
end

function onUpdate()
    if finishedLoading == false then
        return
    end

    -- first time through, grab the current position of the stick
    if firstUpdate == 0 then
        firstUpdate = 1
        rotationVector = self.getRotation()
        positionVector = self.getPosition()
    end

    if toggleMeasure == 0 then
        self.editButton({index=0,label=""})
        return
    end

    if pickedUpColor == nil then
        return
    end
    playerLastObject = lastPickedUpObjects[pickedUpColor .. ""]
    if playerLastObject == nil then
        return
    end

    -- grab the current position of the stick
    -- if it's not being held, use the saved stick position
    pointA = self.getPosition()
    if pickedUp == 0 then
        pointA = positionVector
        -- make sure the stick stays still and upright when not held
        self.setVelocity({0, 0, 0})
        self.setAngularVelocity({0, 0, 0})
        self.setPosition({positionVector.x, positionVector.y, positionVector.z})
    end

    pointB = playerLastObject.getPosition()
    local objBounds = playerLastObject.getBounds()
    pointB.y = objBounds.center.y - (objBounds.size.y/2.0)

    mdiff = pointA - pointB
    finalDistance = 0
    minDistance = 10000
    if alternateDiag then
        xDistance = math.abs(mdiff.x)
        if xDistance < minDistance then
            minDistance = xDistance
        end
        xDisGrid = math.floor(xDistance / Grid.sizeX + 0.5)
        zDistance = math.abs(mdiff.z)
        if zDistance < minDistance then
            minDistance = zDistance
        end
        yDisGrid = math.floor(zDistance / Grid.sizeY + 0.5)
        if xDisGrid > yDisGrid then
            finalDistance = math.floor(xDisGrid + yDisGrid/2.0) * 5.0
        else
            finalDistance = math.floor(yDisGrid + xDisGrid/2.0) * 5.0
        end
    else
        xDistance = math.abs(mdiff.x)
        if xDistance < minDistance then
            minDistance = xDistance
        end
        zDistance = math.abs(mdiff.z)
        if zDistance < minDistance then
            minDistance = zDistance
        end
        if zDistance > xDistance then
            xDistance = zDistance
        end
        xDistance = xDistance * (5.0 / Grid.sizeX)
        finalDistance = (math.floor((xDistance + 2.5) / 5.0) * 5)
    end
    self.editButton({index = 0, label = tostring(finalDistance)})

    if pickedUpColor ~= nil then
        -- If measuring, face the player
        self.setRotation({x = 0, y = Player[pickedUpColor].getPointerRotation(), z = 0})

        if minDistance < 1.0 or alternateDiag == false then
            createActiveInputs()
        else
            destroyActiveInputs()
        end

        -- Drawing the line between pole and selected object
        newStartPoint = self.positionToLocal({pointA[1],pointA[2],pointA[3]})
        newEndPoint = self.positionToLocal({pointB[1],pointB[2]+0.1,pointB[3]})

        if savedStartPoint ~= nil and
            savedEndPoint ~= nil and
            savedStartPoint[1] == newStartPoint[1] and
            savedStartPoint[2] == newStartPoint[2] and
            savedStartPoint[3] == newStartPoint[3] and
            savedEndPoint[1] == newEndPoint[1] and
            savedEndPoint[2] == newEndPoint[2] and
            savedEndPoint[3] == newEndPoint[3] then
            return
        end

        savedStartPoint = newStartPoint
        savedEndPoint = newEndPoint

        newVectorLines = {}
        table.insert(newVectorLines, {
            points    = { newStartPoint, newEndPoint },
            color     = self.getColorTint(),
            thickness = 0.1023,
            rotation  = {0,0,0},
        })
        self.setVectorLines(newVectorLines)
    end
end

function calibrationFunction(obj, player_clicker_color, input_value, selected)
    if selected == false and input_value ~= "" then
        pointA = self.getPosition()
        pointB = playerLastObject.getPosition()
        mdiff = pointA - pointB

        calibrationDistance = tonumber(input_value)
        mDistance = math.abs(mdiff.x)
        zDistance = math.abs(mdiff.z)
        if zDistance > mDistance then
            mDistance = zDistance
        end
        gridSize = (5.0 / (calibrationDistance / mDistance));

        Grid.sizeX = gridSize
        Grid.sizeY = gridSize
        displacement = (gridSize / 2.0)
        if vertexMode then
            displacement = 0
        end
        Grid.offsetX = pointA[1] - displacement
        Grid.offsetY = pointA[3] - displacement
        resetScales()
    end
end