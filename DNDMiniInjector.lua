-- DNDMiniInjector
-- Credit to HP Bar Writer by Kijan
--[[LUAStart
className = "MeasurementToken"
versionNumber = "4.5.52"
scaleMultiplierX = 1.0
scaleMultiplierY = 1.0
scaleMultiplierZ = 1.0
finishedLoading = false
calibratedOnce = false
debuggingEnabled = false
onUpdateTriggerCount = 0
onUpdateScale = 1.0
onUpdateGridSize = 1.0
loadTime = 1.0
saveVersion = 1
a = {}
triggerNames = {}
showing = false
savedAttachScales = {}

health = {value = 10, max = 10}
mana = {value = 10, max = 10}
extra = {value = 10, max = 10}

player = false
measureMove = false
alternateDiag = false
stabilizeOnDrop = false
miniHighlight = "highlightNone"
highlightToggle = true
hideFromPlayers = false
firstEdit = true

options = {
    HP2Desc = false,
    belowZero = false,
    aboveMax = false,
    heightModifier = 110,
    showBaseButtons = false,
    showBarButtons = false,
    hideHp = false,
    hideMana = true,
    hideExtra = true,
    incrementBy = 1,
    rotation = 90,
    initSettingsIncluded = true,
    initSettingsRolling = true,
    initSettingsMod = 0,
    initSettingsValue = 100,
    initRealActive = false,
    initRealValue = 0,
    initMockActive = false,
    initMockValue = 0
}

function resetInitiative()
    options.initSettingsValue = 100
    options.initRealActive = false
    options.initRealValue = 0
    options.initMockActive = false
    options.initMockValue = 0
    self.UI.setAttribute("InitValueInput", "text", options.initSettingsValue)
end

function getInitiative(inputActive)
    if options.initRealActive == true then
        if debuggingEnabled then
            print(self.getName() .. ' init real cache ' .. options.initRealValue)
        end
        return options.initRealValue
    end
    if inputActive == true then
        options.initRealActive = true
        if options.initMockActive == true then
            options.initRealValue = options.initMockValue
        else
            options.initRealValue = calculateInitiative()
        end
        if debuggingEnabled then
            print(self.getName() .. ' init real calc' .. options.initRealValue)
        end
        return options.initRealValue
    end
    if options.initMockActive == true then
        if debuggingEnabled then
            print(self.getName() .. ' init mock cache ' .. options.initMockValue)
        end
        return options.initMockValue
    end
    options.initMockActive = true
    options.initMockValue = calculateInitiative()
    if debuggingEnabled then
        print(self.getName() .. ' init mock calc ' .. options.initMockValue)
    end
    return options.initMockValue
end

function calculateInitiative()
    if options.initSettingsRolling == true then
        return math.random(1,20) + tonumber(options.initSettingsMod)
    else
        return tonumber(options.initSettingsValue)
    end
end

function onSave()
    saveVersion = saveVersion + 1
    if debuggingEnabled then
        print(self.getName() .. " saving, version " .. saveVersion .. ".")
    end
    local encodedAttachScales = {}
    if #savedAttachScales > 0 then
        for _, scaleVector in ipairs(savedAttachScales) do
            table.insert(encodedAttachScales, {x=scaleVector.x, y=scaleVector.y, z=scaleVector.z})
        end
    end
    local save_state = JSON.encode({
        scale_multiplier_x = scaleMultiplierX,
        scale_multiplier_y = scaleMultiplierY,
        scale_multiplier_z = scaleMultiplierZ,
        calibrated_once = calibratedOnce,
        health = health,
        mana = mana,
        extra = extra,
        options = options,
        encodedAttachScales = encodedAttachScales,
        statNames = statNames,
        player = player,
        measureMove = measureMove,
        alternateDiag = alternateDiag,
        stabilizeOnDrop = stabilizeOnDrop,
        miniHighlight = miniHighlight,
        highlightToggle = highlightToggle,
        hideFromPlayers = hideFromPlayers,
        saveVersion = saveVersion
    })
    return save_state
end

function onLoad(save_state)
    if stabilizeOnDrop == true and self.held_by_color == nil then
        Wait.frames(stabilize, 1)
    end

    local object = self
    local dropWatch = function()
        return object == nil or object.resting
    end
    local dropFunc = function()
        if object == nil then
            return
        end
        local saved_data = nil
        local my_saved_data = nil
        local bestVersion = 0
        if save_state ~= "" then
            saved_data = JSON.decode(save_state)
            my_saved_data = saved_data
            if saved_data.saveVersion ~= nil then
                bestVersion = saved_data.saveVersion
            end
        end
        -- ALRIGHTY, let's see which state data we need to use
        states = object.getStates()
        if states ~= nil then
            for _, s in pairs(states) do
                test_data = JSON.decode(s.lua_script_state)
                if test_data ~= nil and test_data.saveVersion ~= nil and test_data.saveVersion > bestVersion then
                    saved_data = test_data
                    bestVersion = test_data.saveVersion
                end
            end
        end
        if debuggingEnabled then
            print(object.getName() .. " best version: " .. bestVersion)
        end
        if saved_data ~= nil then
            if saved_data.health then
                for heal,_ in pairs(health) do
                    health[heal] = saved_data.health[heal]
                end
            end
            if saved_data.mana then
                for res,_ in pairs(mana) do
                    mana[res] = saved_data.mana[res]
                end
            end
            if saved_data.extra then
                for res,_ in pairs(extra) do
                    extra[res] = saved_data.extra[res]
                end
            end
            if saved_data.options then
                for opt,_ in pairs(options) do
                    if saved_data.options[opt] ~= nil then
                        options[opt] = saved_data.options[opt]
                    end
                end
            end
            if saved_data.encodedAttachScales then
                for _,encodedScale in pairs(saved_data.encodedAttachScales) do
                    if debuggingEnabled then
                        print("loaded vector: " .. encodedScale.x .. ", " .. encodedScale.y .. ", " .. encodedScale.z)
                    end
                    table.insert(savedAttachScales, vector(encodedScale.x, encodedScale.y, encodedScale.z))
                end
            end
            if saved_data.statNames then
                for stat,_ in pairs(statNames) do
                    statNames[stat] = saved_data.statNames[stat]
                end
            end
            -- Check if we need to override the scale calibration
            -- This state's calibration takes precedence over other states
            if my_saved_data ~= nil and my_saved_data.calibrated_once == true then
                saved_data.calibrated_once = my_saved_data.calibrated_once
                saved_data.scale_multiplier_x = my_saved_data.scale_multiplier_x
                saved_data.scale_multiplier_y = my_saved_data.scale_multiplier_y
                saved_data.scale_multiplier_z = my_saved_data.scale_multiplier_z
                options["heightModifier"] = my_saved_data.options["heightModifier"]
            end
            if saved_data.scale_multiplier_x ~= nil then
                scaleMultiplierX = saved_data.scale_multiplier_x
            end
            if saved_data.scale_multiplier_y ~= nil then
                scaleMultiplierY = saved_data.scale_multiplier_y
            end
            if saved_data.scale_multiplier_z ~= nil then
                scaleMultiplierZ = saved_data.scale_multiplier_z
            end
            if saved_data.calibrated_once ~= nil then
                calibratedOnce = saved_data.calibrated_once
            end
            if saved_data.player ~= nil then
                player = saved_data.player
            end
            if saved_data.measureMove ~= nil then
                measureMove = saved_data.measureMove
            end
            if saved_data.alternateDiag ~= nil then
                alternateDiag = saved_data.alternateDiag
            end
            if saved_data.stabilizeOnDrop ~= nil then
                stabilizeOnDrop = saved_data.stabilizeOnDrop
            end
            if saved_data.miniHighlight ~= nil then
                miniHighlight = saved_data.miniHighlight
            end
            if saved_data.highlightToggle ~= nil then
                highlightToggle = saved_data.highlightToggle
            end
            if saved_data.hideFromPlayers ~= nil then
                hideFromPlayers = saved_data.hideFromPlayers
                if player == true then
                    hideFromPlayers = false
                end
            end
            if saved_data.saveVersion ~= nil then
                saveVersion = saved_data.saveVersion
                if debuggingEnabled then
                    print(object.getName() .. " loading, version " .. saveVersion .. ".")
                end
            end
        end
        object.setVar("className", "MeasurementToken")
        object.setVar("player", player)
        object.setVar("measureMove", measureMove)
        object.setVar("alternateDiag", alternateDiag)
        object.setVar("stabilizeOnDrop", stabilizeOnDrop)
        object.setVar("miniHighlight", miniHighlight)
        object.setVar("highlightToggle", highlightToggle)
        object.setVar("hideFromPlayers", hideFromPlayers)

        Wait.frames(loadStageOne, 10)
    end
    Wait.condition(dropFunc, dropWatch)
end

function loadStageOne()
    local script = self.getLuaScript()
    local xml = script:sub(script:find("StartXML")+8, script:find("StopXML")-1)
    self.UI.setXml(xml)
    Wait.frames(loadStageTwo, 10)
end

function loadStageTwo()
    self.UI.setAttribute("panel", "position", "0 0 -" .. self.getBounds().size.y / self.getScale().y * options.heightModifier)
    self.UI.setAttribute("progressBar", "percentage", health.value / health.max * 100)
    self.UI.setAttribute("hpText", "text", health.value .. "/" .. health.max)
    self.UI.setAttribute("progressBarS", "percentage", mana.value / mana.max * 100)
    self.UI.setAttribute("manaText", "text", mana.value .. "/" .. mana.max)
    self.UI.setAttribute("extraProgress", "percentage", extra.value / extra.max * 100)
    self.UI.setAttribute("extraText", "text", extra.value .. "/" .. extra.max)
    self.UI.setAttribute("manaText", "textColor", "#FFFFFF")
    self.UI.setAttribute("increment", "text", options.incrementBy)
    self.UI.setAttribute("InitModInput", "text", options.initSettingsMod)
    self.UI.setAttribute("InitValueInput", "text", options.initSettingsValue)

    for i,j in pairs(statNames) do
        if j == true then
            self.UI.setAttribute(i, "active", true)
        end
    end
    Wait.frames(function() self.UI.setAttribute("statePanel", "width", getStatsCount()*300) end, 1)

    if options.showBarButtons == true then
        self.UI.setAttribute("addSub", "active", true)
        self.UI.setAttribute("addSubS", "active", true)
        self.UI.setAttribute("addSubE", "active", true)
    end

    if health.max == 0 then
        options.hideHp = true
    end
    if mana.max == 0 then
        options.hideMana = true
    end
    if extra.max == 0 then
        options.hideExtra = true
    end

    self.UI.setAttribute("hiddenButtonBar", "active", (options.hideHp == true and options.hideMana == true and options.hideExtra == true) and "True" or "False")

    self.UI.setAttribute("resourceBar", "active", options.hideHp == true and "False" or "True")
    self.UI.setAttribute("resourceBarS", "active", options.hideMana == true and "False" or "True")
    self.UI.setAttribute("extraBar", "active", options.hideExtra == true and "False" or "True")

    self.UI.setAttribute("addSub", "active", options.showBarButtons == true and "True" or "False")
    self.UI.setAttribute("addSubS", "active", options.showBarButtons == true and "True" or "False")
    self.UI.setAttribute("addSubE", "active", options.showBarButtons == true and "True" or "False")
    self.UI.setAttribute("panel", "rotation", options.rotation .. " 270 90")

    self.UI.setAttribute("PlayerCharToggle", "textColor", player == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("MeasureMoveToggle", "textColor", measureMove == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("AlternateDiagToggle", "textColor", alternateDiag == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("StabilizeToggle", "textColor", stabilizeOnDrop == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("HH", "textColor", options.hideHp == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("HM", "textColor", options.hideMana == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("HE", "textColor", options.hideExtra == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("HB", "textColor", options.showBarButtons == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("BZ", "textColor", options.belowZero == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("AM", "textColor", options.aboveMax == true and "#AA2222" or "#FFFFFF")

    self.UI.setAttribute("InitiativeIncludeToggle", "textColor", options.initSettingsIncluded == true and "#AA2222" or "#FFFFFF")
    self.UI.setAttribute("InitiativeRollingToggle", "textColor", options.initSettingsRolling == true and "#AA2222" or "#FFFFFF")

    -- Look for the mini injector, if available
    local allObjects = getAllObjects()
    for _, obj in ipairs(allObjects) do
        if obj ~= self and obj ~= nil then
            local typeCheck = obj.getVar("className")
            if typeCheck == "MiniInjector" then
                autoCalibrate = obj.getVar("autoCalibrateEnabled")
                if autoCalibrate == true then
                    calibrateScale()
                end
                -- grab ui settings
                local injOptions = obj.getTable("options")
                alternateDiag = injOptions.alternateDiag
                self.UI.setAttribute("AlternateDiagToggle", "textColor", alternateDiag == true and "#AA2222" or "#FFFFFF")
                if player == true then
                    self.UI.setAttribute("progressBar", "visibility", "")
                    self.UI.setAttribute("progressBarS", "visibility", "")
                    self.UI.setAttribute("extraProgress", "visibility", "")
                    self.UI.setAttribute("hpText", "visibility", "")
                    self.UI.setAttribute("manaText", "visibility", "")
                    self.UI.setAttribute("extraText", "visibility", "")
                    self.UI.setAttribute("addSub", "visibility", "")
                    self.UI.setAttribute("addSubS", "visibility", "")
                    self.UI.setAttribute("addSubE", "visibility", "")
                    self.UI.setAttribute("editPanel", "visibility", "")
                    self.UI.setAttribute("leftSide1", "visibility", "")
                    self.UI.setAttribute("editButton0", "visibility", "")
                    self.UI.setAttribute("editButton1", "visibility", "")
                    self.UI.setAttribute("editButtonS1", "visibility", "")
                    self.UI.setAttribute("leftSide2", "visibility", "")
                    self.UI.setAttribute("editButton2", "visibility", "")
                    self.UI.setAttribute("editButtonS2", "visibility", "")
                    self.UI.setAttribute("leftSide3", "visibility", "")
                    self.UI.setAttribute("editButton3", "visibility", "")
                    self.UI.setAttribute("editButtonS3", "visibility", "")
                else
                    if injOptions.hideBar == true then
                        self.UI.setAttribute("progressBar", "visibility", "Black")
                        self.UI.setAttribute("progressBarS", "visibility", "Black")
                        self.UI.setAttribute("extraProgress", "visibility", "Black")
                    else
                        self.UI.setAttribute("progressBar", "visibility", "")
                        self.UI.setAttribute("progressBarS", "visibility", "")
                        self.UI.setAttribute("extraProgress", "visibility", "")
                    end
                    if injOptions.hideText == true then
                        self.UI.setAttribute("hpText", "visibility", "Black")
                        self.UI.setAttribute("manaText", "visibility", "Black")
                        self.UI.setAttribute("extraText", "visibility", "Black")
                    else
                        self.UI.setAttribute("hpText", "visibility", "")
                        self.UI.setAttribute("manaText", "visibility", "")
                        self.UI.setAttribute("extraText", "visibility", "")
                    end
                    if injOptions.editText == true then
                        self.UI.setAttribute("addSub", "visibility", "Black")
                        self.UI.setAttribute("addSubS", "visibility", "Black")
                        self.UI.setAttribute("addSubE", "visibility", "Black")
                        self.UI.setAttribute("editPanel", "visibility", "Black")
                    else
                        self.UI.setAttribute("addSub", "visibility", "")
                        self.UI.setAttribute("addSubS", "visibility", "")
                        self.UI.setAttribute("addSubE", "visibility", "")
                        self.UI.setAttribute("editPanel", "visibility", "")
                    end
                    self.UI.setAttribute("editButton0", "visibility", "Black")
                    self.UI.setAttribute("leftSide1", "visibility", "Black")
                    self.UI.setAttribute("editButton1", "visibility", "Black")
                    self.UI.setAttribute("editButtonS1", "visibility", "Black")
                    self.UI.setAttribute("leftSide2", "visibility", "Black")
                    self.UI.setAttribute("editButton2", "visibility", "Black")
                    self.UI.setAttribute("editButtonS2", "visibility", "Black")
                    self.UI.setAttribute("leftSide3", "visibility", "Black")
                    self.UI.setAttribute("editButton3", "visibility", "Black")
                    self.UI.setAttribute("editButtonS3", "visibility", "Black")
                end
            end
        end
    end

    rebuildContextMenu()

    updateHighlight()

    self.ignore_fog_of_war = player
    self.auto_raise = true
    self.interactable = true

    onUpdateScale = 1.0
    onUpdateGridSize = 1.0
    loadTime = os.clock()

    instantiateTriggers()

    if hideFromPlayers then
        aColors = Player.getAvailableColors()
        for k, v in ipairs(aColors) do
            if v == "Black" or v == "Grey" or v == "White" then
                table.remove(aColors, k)
            end
        end
        table.insert(aColors, "Grey")
        table.insert(aColors, "White")
        if debuggingEnabled then
            print(self.getName() .. " gone.")
        end
        self.setInvisibleTo(aColors)
        -- In this case attachments are already shrunk, don't worry about them
    end

    finishedLoading = true
    self.setVar("finishedLoading", true)
end

function instantiateTriggers()
    for i = 0, 99 do
        triggerNames[i] = nil
        if self.AssetBundle ~= nil and self.AssetBundle.getTriggerEffects() ~= nil and self.AssetBundle.getTriggerEffects()[i] ~= nil then
            a[i] = false
            triggerNames[i] = self.AssetBundle.getTriggerEffects()[i].name
            -- create a new global function
            _G["TriggerFunction" .. i] = function()
                -- that simply calls our real target function
                self.AssetBundle.playTriggerEffect(i - 1)
            end
        end
    end
end

function onPlayerConnect(player)
    -- Wait 30 seconds for them to load fully.
    Wait.time(updateHighlight, 30)
end

function changeHighlight(player, value, id)
    miniHighlight = id
    highlightToggle = true
    updateHighlight(miniHighlight)
end

function toggleHighlight(player, value, id)
    highlightToggle = not highlightToggle
    updateHighlight()
end

function updateHighlight()
    if highlightToggle == false then
        self.highlightOff()
    elseif miniHighlight == "highlightNone" then
        self.highlightOff()
    elseif miniHighlight == "highlightWhite" then
        self.highlightOn(Color.White)
    elseif miniHighlight == "highlightBrown" then
        self.highlightOn(Color.Brown)
    elseif miniHighlight == "highlightRed" then
        self.highlightOn(Color.Red)
    elseif miniHighlight == "highlightOrange" then
        self.highlightOn(Color.Orange)
    elseif miniHighlight == "highlightYellow" then
        self.highlightOn(Color.Yellow)
    elseif miniHighlight == "highlightGreen" then
        self.highlightOn(Color.Green)
    elseif miniHighlight == "highlightTeal" then
        self.highlightOn(Color.Teal)
    elseif miniHighlight == "highlightBlue" then
        self.highlightOn(Color.Blue)
    elseif miniHighlight == "highlightPurple" then
        self.highlightOn(Color.Purple)
    elseif miniHighlight == "highlightPink" then
        self.highlightOn(Color.Pink)
    elseif miniHighlight == "highlightBlack" then
        self.highlightOn(Color.Black)
    end
end

function onUpdate()
    onUpdateTriggerCount = onUpdateTriggerCount + 1
    if onUpdateTriggerCount > 60 then
        onUpdateTriggerCount = 0
        if finishedLoading == true and onUpdateScale ~= self.getScale().y then
            local newScale = dec3(0.3 * (1.0 / self.getScale().y))
            self.UI.setAttribute("panel", "scale", newScale .. " " .. newScale)
            self.UI.setAttribute("panel", "position", "0 0 -" .. (options.heightModifier + 1))
            self.UI.setAttribute("panel", "position", "0 0 -" .. options.heightModifier)
            local vertical = 0
            vertical = vertical + (options.hideHp == true and 0 or 100)
            vertical = vertical + (options.hideMana == true and 0 or 100)
            vertical = vertical + (options.hideExtra == true and 0 or 100)
            self.UI.setAttribute("hiddenButtonBar", "active", (options.hideHp == true and options.hideMana == true and options.hideExtra == true) and "True" or "False")
            self.UI.setAttribute("resourceBar", "active", options.hideHp == true and "False" or "True")
            self.UI.setAttribute("resourceBarS", "active", options.hideMana == true and "False" or "True")
            self.UI.setAttribute("extraBar", "active", options.hideExtra == true and "False" or "True")
            self.UI.setAttribute("bars", "height", vertical)
            onUpdateScale = self.getScale().y
        end
        if finishedLoading == true and onUpdateGridSize ~= Grid.sizeX then
            resetScale()
        end
    end
end

function dec3(input)
    return math.floor(input * 1000.0) / 1000.0
end

function rebuildContextMenu()
    self.clearContextMenu()
    self.addContextMenuItem("UI Height UP", uiHeightUp, true)
    self.addContextMenuItem("UI Rotate 90", uiRotate90, true)
    if hideFromPlayers == true then
        self.addContextMenuItem("[X] Hide from players", toggleHideFromPlayers)
    else
        self.addContextMenuItem("[ ] Hide from players", toggleHideFromPlayers)
    end
    if calibratedOnce == true then
        self.addContextMenuItem("[X] Calibrate Scale", calibrateScale)
    else
        self.addContextMenuItem("[ ] Calibrate Scale", calibrateScale)
    end
    self.addContextMenuItem("Reset Scale", resetScale)
    self.addContextMenuItem("Reload Mini", reloadMini)
    if debuggingEnabled == true then
        self.addContextMenuItem("[X] Debugging", toggleDebug)
    else
        self.addContextMenuItem("[ ] Debugging", toggleDebug)
    end
end

function uiHeightUp()
    options.heightModifier = options.heightModifier + 50
    self.UI.setAttribute("panel", "position", "0 0 -" .. options.heightModifier)
end

function uiRotate90()
    options.rotation = options.rotation + 90
    self.UI.setAttribute("panel", "rotation", options.rotation .. " 270 90")
end

function toggleDebug()
    debuggingEnabled = not debuggingEnabled
    rebuildContextMenu()
end

function toggleHideFromPlayers()
    if player == true and hideFromPlayers == false then
        print(self.getName() .. " is a player character, cannot hide.")
        return
    end
    hideFromPlayers = not hideFromPlayers
    if hideFromPlayers then
        aColors = Player.getAvailableColors()
        for k, v in ipairs(aColors) do
            if v == "Black" or v == "Grey" or v == "White" then
                table.remove(aColors, k)
            end
        end
        table.insert(aColors, "Grey")
        table.insert(aColors, "White")
        if debuggingEnabled then
            print(self.getName() .. " gone.")
        end
        self.setInvisibleTo(aColors)
        -- If the object has attachments, make them invisible too
        myAttach = self.removeAttachments()
        if #myAttach > 0 then
            savedAttachScales = {}
            if debuggingEnabled then
                print(self.getName() .. " has attach.")
            end
            for _, attachObj in ipairs(myAttach) do
                if debuggingEnabled then
                    print(attachObj.getName() .. " gone.")
                end
                --attachObj.setInvisibleTo(aColors)
                table.insert(savedAttachScales, attachObj.getScale())
                attachObj.setScale(vector(0, 0, 0))
                self.addAttachment(attachObj)
            end
        end
    else
        if debuggingEnabled then
            print(self.getName() .. " back.")
        end
        self.setInvisibleTo({})
        -- If the object has attachments, make them visible too
        myAttach = self.removeAttachments()
        if #myAttach > 0 then
            if debuggingEnabled then
                print(self.getName() .. " has attach.")
            end
            for attachIndex, attachObj in ipairs(myAttach) do
                if debuggingEnabled then
                    print(attachObj.getName() .. " back.")
                end
                attachObj.setScale(savedAttachScales[attachIndex])
                self.addAttachment(attachObj)
            end
        end
        savedAttachScales = {}
    end
    rebuildContextMenu()
end

function togglePlayer()
    player = not player
    self.ignore_fog_of_war = player
    self.UI.setAttribute("PlayerCharToggle", "textColor", player == true and "#AA2222" or "#FFFFFF")
    if player == true then
        resetInitiative()
    end
    if player == true and hideFromPlayers == true then
        toggleHideFromPlayers()
    end
    Wait.frames(loadStageTwo, 1)
end

function toggleMeasure()
    measureMove = not measureMove
    self.UI.setAttribute("MeasureMoveToggle", "textColor", measureMove == true and "#AA2222" or "#FFFFFF")
end

function toggleAlternateDiag(thePlayer1)
    local myPlayer = thePlayer1
    local function tad_Helper(thePlayer2)
        -- Look for the mini injector, if available
        local allObjects = getAllObjects()
        for _, obj in ipairs(allObjects) do
            if obj ~= self and obj ~= nil then
                local typeCheck = obj.getVar("className")
                if typeCheck == "MiniInjector" then
                    local injOptions = obj.getTable("options")
                    alternateDiag = injOptions.alternateDiag
                    self.UI.setAttribute("AlternateDiagToggle", "textColor", alternateDiag == true and "#AA2222" or "#FFFFFF")
                    if thePlayer2 ~= nil then
                        broadcastToAll("Injector is present. Use the injector to toggle measurement style.", thePlayer2.color)
                    end
                    return
                end
            end
        end
        alternateDiag = not alternateDiag
        self.UI.setAttribute("AlternateDiagToggle", "textColor", alternateDiag == true and "#AA2222" or "#FFFFFF")
    end
    Wait.frames(function() tad_Helper(myPlayer) end, 30)
end


function toggleStabilizeOnDrop()
    stabilizeOnDrop = not stabilizeOnDrop
    self.UI.setAttribute("StabilizeToggle", "textColor", stabilizeOnDrop == true and "#AA2222" or "#FFFFFF")
end

function toggleInitiativeInclude()
    options.initSettingsIncluded = not options.initSettingsIncluded
    if options.initSettingsIncluded == false then
        options.initRealActive = false
        options.initRealValue = 0
        options.initMockActive = false
        options.initMockValue = 0
    end
    self.UI.setAttribute("InitiativeIncludeToggle", "textColor", options.initSettingsIncluded == true and "#AA2222" or "#FFFFFF")
end

function toggleInitiativeRolling()
    options.initSettingsRolling = not options.initSettingsRolling
    if options.initSettingsRolling == true then
        options.initRealActive = false
        options.initRealValue = 0
        options.initMockActive = false
        options.initMockValue = 0
    end
    self.UI.setAttribute("InitiativeRollingToggle", "textColor", options.initSettingsRolling == true and "#AA2222" or "#FFFFFF")
end

function calibrateScale()
    currentScale = self.getScale()
    scaleMultiplierX = currentScale.x / Grid.sizeX
    scaleMultiplierY = currentScale.y / Grid.sizeX
    scaleMultiplierZ = currentScale.z / Grid.sizeX
    calibratedOnce = true
    if debuggingEnabled then
        print(self.getName() .. ": Calibrated scale with reference to grid.")
    end
    rebuildContextMenu()
end

function reloadMini()
    self.reload()
end

function resetScale()
    if calibratedOnce == false then
        if debuggingEnabled == true then
            print(self.getName() .. ": Mini not calibrated to grid yet.")
        end
        return
    end
    newScaleX = Grid.sizeX * scaleMultiplierX
    newScaleY = Grid.sizeX * scaleMultiplierY
    newScaleZ = Grid.sizeX * scaleMultiplierZ
    if debuggingEnabled == true then
        print(self.getName() .. ": Reset scale with reference to grid.")
    end
    scaleVector = vector(newScaleX, newScaleY, newScaleZ)
    self.setScale(scaleVector)
    onUpdateGridSize = Grid.sizeX
end

function onRotate(spin, flip, player_color, old_spin, old_flip)
    if flip ~= old_flip then
        destabilize()
        if stabilizeOnDrop == true then
            local object = self
            local timeWaiting = os.clock() + 0.26
            local rotateWatch = function()
                if object == nil or object.resting then
                    return true
                end
                local currentRotation = object.getRotation()
                local rotationTarget = object.getRotationSmooth()
                return os.clock() > timeWaiting and (rotationTarget == nil or currentRotation:angle(rotationTarget) < 0.5)
            end
            local rotateFunc = function()
                if object == nil then
                    return
                end
                if stabilizeOnDrop == true then
                    if debuggingEnabled == true then
                        print(self.getName() .. ": Stabilizing after rotation.")
                    end
                    stabilize()
                end
            end
            Wait.condition(rotateFunc, rotateWatch)
        end
    end
end

function onPickUp(pcolor)
    destabilize()
    if measureMove == true and hideFromPlayers == false and finishedLoading == true then
        createMoveToken(pcolor, self)
    end
end

function onDrop(dcolor)
    if stabilizeOnDrop == true then
        stabilize()
    end
    if measureMove == true then
        destroyMoveToken()
    end
end

function stabilize()
    if debuggingEnabled == true then
        print(self.getName() .. ": stabilizing.")
    end
    local rb = self.getComponent("Rigidbody")
    rb.set("freezeRotation", true)
end

function destabilize()
    if debuggingEnabled == true then
        print(self.getName() .. ": de-stabilizing.")
    end
    local rb = self.getComponent("Rigidbody")
    rb.set("freezeRotation", false)
end

function destroyMoveToken()
    if string.match(tostring(myMoveToken),"Custom") then
        destroyObject(myMoveToken)
    end
end

function createMoveToken(mcolor, mtoken)
    destroyMoveToken()
    tokenRot = Player[mcolor].getPointerRotation()
    movetokenparams = {
        image = "http://cloud-3.steamusercontent.com/ugc/1021697601906583980/C63D67188FAD8B02F1B58E17C7B1DB304B7ECBE3/",
        thickness = 0.1,
        type = 2
    }
    startloc = mtoken.getPosition()
    local hitList = Physics.cast({
        origin       = mtoken.getBounds().center,
        direction    = {0,-1,0},
        type         = 1,
        max_distance = 10,
        debug        = false,
    })
    for _, hitTable in ipairs(hitList) do
        -- Find the first object directly below the mini
        if hitTable ~= nil and hitTable.point ~= nil and hitTable.hit_object ~= mtoken then
            startloc = hitTable.point
            break
        else
            if debuggingEnabled == true then
                print("Did not find object below mini.")
            end
        end
    end
    tokenScale = {
        x= Grid.sizeX / 2.2,
        y= 0.1,
        z= Grid.sizeX / 2.2
    }
    spawnparams = {
        type = "Custom_Tile",
        position = startloc,
        rotation = {x = 0, y = tokenRot, z = 0},
        scale = tokenScale,
        sound = false
    }
    local moveToken = spawnObject(spawnparams)
    moveToken.setLock(true)
    moveToken.setCustomObject(movetokenparams)
    mtoken.setVar("myMoveToken", moveToken)
    moveToken.setVar("measuredObject", mtoken)
    moveToken.setVar("myPlayer", mcolor)
    moveToken.setVar("alternateDiag", alternateDiag)
    moveToken.setVar("className", "MeasurementToken_Move")
    moveToken.ignore_fog_of_war = player
    moveToken.interactable = false
    moveButtonParams = {
        click_function = "onLoad",
        function_owner = self,
        label = "00",
        position = {x=0, y=0.1, z=0},
        width = 0,
        height = 0,
        font_size = 600
    }

    moveButton = moveToken.createButton(moveButtonParams)
    moveToken.setLuaScript("    function onUpdate() " ..
                           "        local finalDistance = 0 " ..
                           "        local mypos = self.getPosition() " ..
                           "        if measuredObject == nil or measuredObject.held_by_color == nil then " ..
                           "            destroyObject(self) " ..
                           "            return " ..
                           "        end " ..
                           "        local opos = measuredObject.getPosition() " ..
                           "        local oheld = measuredObject.held_by_color " ..
                           "        opos.y = opos.y-(Player[myPlayer].lift_height*5) " ..
                           "        mdiff = mypos - opos " ..
                           "        if oheld then " ..
                           "            if alternateDiag then " ..
                           "                mDistance = math.abs(mdiff.x) " ..
                           "                xDisGrid = math.floor(mDistance / Grid.sizeX + 0.5) " ..
                           "                zDistance = math.abs(mdiff.z) " ..
                           "                yDisGrid = math.floor(zDistance / Grid.sizeY + 0.5) " ..
                           "                if xDisGrid > yDisGrid then " ..
                           "                    finalDistance = math.floor(xDisGrid + yDisGrid/2.0) * 5.0 " ..
                           "                else" ..
                           "                    finalDistance = math.floor(yDisGrid + xDisGrid/2.0) * 5.0 " ..
                           "                end " ..
                           "            else " ..
                           "                mDistance = math.abs(mdiff.x) " ..
                           "                zDistance = math.abs(mdiff.z) " ..
                           "                if zDistance > mDistance then " ..
                           "                    mDistance = zDistance " ..
                           "                end " ..
                           "                mDistance = mDistance * (5.0 / Grid.sizeX) " ..
                           "                finalDistance = (math.floor((mDistance + 2.5) / 5.0) * 5) " ..
                           "            end " ..
                           "            self.editButton({index = 0, label = tostring(finalDistance)}) " ..
                           "        end " ..
                           "    end ")

end

function reduceHP()
    adjustHP(-1)
end

function increaseHP()
    adjustHP(1)
end

function adjustHP(difference)
    local intDiff = tonumber(difference)
    health.value = health.value + intDiff
    if health.value > health.max and not options.aboveMax then health.value = health.max end
    if health.value < 0 and not options.belowZero then health.value = 0 end
    if player == false and health.value <= 0 and options.initSettingsIncluded == true and options.initRealActive == true then
        options.initSettingsIncluded = false
        self.UI.setAttribute("InitiativeIncludeToggle", "textColor", options.initSettingsIncluded == true and "#AA2222" or "#FFFFFF")
        miniHighlight = "highlightNone"
        updateHighlight()
    end
    self.UI.setAttribute("hpText", "text", health.value .. "/" .. health.max)
    self.UI.setAttribute("progressBar", "percentage", health.value / health.max * 100)
    updateRollers()
end

function setHP(newHP)
    local intNewHP = tonumber(newHP)
    health.value = intNewHP
    if health.value > health.max and not options.aboveMax then health.value = health.max end
    if health.value < 0 and not options.belowZero then health.value = 0 end
    if player == false and health.value <= 0 and options.initSettingsIncluded == true and options.initRealActive == true then
        options.initSettingsIncluded = false
        self.UI.setAttribute("InitiativeIncludeToggle", "textColor", options.initSettingsIncluded == true and "#AA2222" or "#FFFFFF")
        miniHighlight = "highlightNone"
        updateHighlight()
    end
    self.UI.setAttribute("hpText", "text", health.value .. "/" .. health.max)
    self.UI.setAttribute("progressBar", "percentage", health.value / health.max * 100)
    updateRollers()
end

function setHPMax(newHPMax)
    local intNewHPMax = tonumber(newHPMax)
    if (intNewHPMax < 0) then
      intNewHPMax = 0
    end
    if (health.value > health.max) then
      health.value = health.max
    end
    health.max = intNewHPMax
    if health.value > health.max and not options.aboveMax then health.value = health.max end
    if health.value < 0 and not options.belowZero then health.value = 0 end
    if player == false and health.value <= 0 and options.initSettingsIncluded == true and options.initRealActive == true then
        options.initSettingsIncluded = false
        self.UI.setAttribute("InitiativeIncludeToggle", "textColor", options.initSettingsIncluded == true and "#AA2222" or "#FFFFFF")
    end
    self.UI.setAttribute("hpText", "text", health.value .. "/" .. health.max)
    self.UI.setAttribute("progressBar", "percentage", health.value / health.max * 100)
    updateRollers()
end

function updateRollers()
    local allObjects = getAllObjects()
    for _, obj in ipairs(allObjects) do
        local className = obj.getVar("className")
        if className == "MiniInjector" then
            obj.call("updateFromGuid", self.guid)
        end
    end
end

function onEndEdit(player, value, id)
    if id == "increment" then
        options.incrementBy = tonumber(value)
        self.UI.setAttribute("increment", "text", options.incrementBy)
    elseif id == "InitModInput" then
        options.initSettingsMod = tonumber(value)
        self.UI.setAttribute("InitModInput", "text", options.initSettingsMod)
    elseif id == "InitValueInput" then
        options.initSettingsValue = tonumber(value)
        options.initRealActive = false
        options.initRealValue = 0
        options.initMockActive = false
        options.initMockValue = 0
        self.UI.setAttribute("InitValueInput", "text", options.initSettingsValue)
        if self.getVar("player") == true then
            broadcastToAll(self.getName() .. " set initiative " .. options.initSettingsValue .. ".", player.color)
        end
    end
end

function onClickEx(params)
    onClick(params.player, params.value, params.id)
end

function add() onClick(-1, - 1, "add") end
function sub() onClick(-1, - 1, "sub") end

function onClick(player_in, value, id)
    if id == "leftSide1" or id == "leftSide2" or id == "leftSide3" then
        if showing ~= true then
            showAllButtons()
        else
            self.clearButtons()
            showing = false
        end
    elseif id == "editButton0" or id == "editButton1" or id == "editButton2" or id == "editButton3" then
        if firstEdit == true or self.UI.getAttribute("editPanel", "active") == "False" or self.UI.getAttribute("editPanel", "active") == nil then
            self.UI.setAttribute("editPanel", "active", true)
            self.UI.setAttribute("statePanel", "active", false)
            firstEdit = false
        else
            self.UI.setAttribute("editPanel", "active", false)
            self.UI.setAttribute("statePanel", "active", true)
        end
    elseif id == "subHeight" or id == "addHeight" then
        if id == "addHeight" then
            options.heightModifier = options.heightModifier + options.incrementBy
        else
            options.heightModifier = options.heightModifier - options.incrementBy
        end
        self.UI.setAttribute("panel", "position", "0 0 -" .. options.heightModifier)
    elseif id == "subRotation" or id == "addRotation" then
        if id == "addRotation" then
            options.rotation = options.rotation + options.incrementBy
        else
            options.rotation = options.rotation - options.incrementBy
        end
        self.UI.setAttribute("panel", "rotation", options.rotation .. " 270 90")
    elseif id == "HH" then
        options.hideHp = not options.hideHp
        local vertical = self.UI.getAttribute("bars", "height")
        Wait.frames(function()
            self.UI.setAttribute("HH", "textColor", options.hideHp == true and "#AA2222" or "#FFFFFF")
            self.UI.setAttribute("hiddenButtonBar", "active", (options.hideHp == true and options.hideMana == true and options.hideExtra == true) and "True" or "False")
            self.UI.setAttribute("resourceBar", "active", options.hideHp == true and "False" or "True")
            self.UI.setAttribute("bars", "height", vertical + (options.hideHp == true and -100 or 100))
        end, 1)
    elseif id == "HM" then
        options.hideMana = not options.hideMana
        local vertical = self.UI.getAttribute("bars", "height")
        Wait.frames(function()
            self.UI.setAttribute("HM", "textColor", options.hideMana == true and "#AA2222" or "#FFFFFF")
            self.UI.setAttribute("hiddenButtonBar", "active", (options.hideHp == true and options.hideMana == true and options.hideExtra == true) and "True" or "False")
            self.UI.setAttribute("resourceBarS", "active", options.hideMana == true and "False" or "True")
            self.UI.setAttribute("bars", "height", vertical + (options.hideMana == true and -100 or 100))
        end, 1)
    elseif id == "HE" then
        options.hideExtra = not options.hideExtra
        local vertical = self.UI.getAttribute("bars", "height")
        Wait.frames(function()
            self.UI.setAttribute("HE", "textColor", options.hideExtra == true and "#AA2222" or "#FFFFFF")
            self.UI.setAttribute("hiddenButtonBar", "active", (options.hideHp == true and options.hideMana == true and options.hideExtra == true) and "True" or "False")
            self.UI.setAttribute("extraBar", "active", options.hideExtra == true and "False" or "True")
            self.UI.setAttribute("bars", "height", vertical + (options.hideExtra == true and -100 or 100))
        end, 1)
    elseif id == "HB" or id == "editButtonS1" or id == "editButtonS2" or id == "editButtonS3" then
        if options.showBarButtons then
            self.UI.setAttribute("addSub", "active", false)
            self.UI.setAttribute("addSubS", "active", false)
            self.UI.setAttribute("addSubE", "active", false)
            options.showBarButtons = false
        else
            self.UI.setAttribute("addSub", "active", true)
            self.UI.setAttribute("addSubS", "active", true)
            self.UI.setAttribute("addSubE", "active", true)
            options.showBarButtons = true
        end
        self.UI.setAttribute("HB", "textColor", options.showBarButtons == true and "#AA2222" or "#FFFFFF")
    elseif id == "BZ" then
        options.belowZero = not options.belowZero
        self.UI.setAttribute("BZ", "textColor", options.belowZero == true and "#AA2222" or "#FFFFFF")
        if health.value > health.max and not options.aboveMax then health.value = health.max end
        if health.value < 0 and not options.belowZero then health.value = 0 end
        if mana.value > mana.max and not options.aboveMax then mana.value = mana.max end
        if mana.value < 0 and not options.belowZero then mana.value = 0 end
        if extra.value > extra.max and not options.aboveMax then extra.value = extra.max end
        if extra.value < 0 and not options.belowZero then extra.value = 0 end
        self.UI.setAttribute("progressBar", "percentage", health.value / health.max * 100)
        self.UI.setAttribute("progressBarS", "percentage", mana.value / mana.max * 100)
        self.UI.setAttribute("extraProgress", "percentage", extra.value / extra.max * 100)
        self.UI.setAttribute("hpText", "text", health.value .. "/" .. health.max)
        self.UI.setAttribute("manaText", "text", mana.value .. "/" .. mana.max)
        self.UI.setAttribute("extraText", "text", extra.value .. "/" .. extra.max)
        if options.HP2Desc then
            self.setDescription(health.value .. "/" .. health.max)
        end
        updateRollers()
    elseif id == "AM" then
        options.aboveMax = not options.aboveMax
        self.UI.setAttribute("AM", "textColor", options.aboveMax == true and "#AA2222" or "#FFFFFF")
        if health.value > health.max and not options.aboveMax then health.value = health.max end
        if health.value < 0 and not options.belowZero then health.value = 0 end
        if mana.value > mana.max and not options.aboveMax then mana.value = mana.max end
        if mana.value < 0 and not options.belowZero then mana.value = 0 end
        if extra.value > extra.max and not options.aboveMax then extra.value = extra.max end
        if extra.value < 0 and not options.belowZero then extra.value = 0 end
        self.UI.setAttribute("progressBar", "percentage", health.value / health.max * 100)
        self.UI.setAttribute("progressBarS", "percentage", mana.value / mana.max * 100)
        self.UI.setAttribute("extraProgress", "percentage", extra.value / extra.max * 100)
        self.UI.setAttribute("hpText", "text", health.value .. "/" .. health.max)
        self.UI.setAttribute("manaText", "text", mana.value .. "/" .. mana.max)
        self.UI.setAttribute("extraText", "text", extra.value .. "/" .. extra.max)
        if options.HP2Desc then
            self.setDescription(health.value .. "/" .. health.max)
        end
        updateRollers()
    elseif statNames[id] ~= nil then
        self.UI.setAttribute(id, "active", false)
        self.UI.setAttribute("statePanel", "width", tonumber(self.UI.getAttribute("statePanel", "width")-300))
        statNames[id] = false
    else
        if id == "add" then
            health.value = health.value + options.incrementBy
        elseif id == "addS" then
            mana.value = mana.value + options.incrementBy
        elseif id == "addE" then
            extra.value = extra.value + options.incrementBy
        elseif id == "sub" then
            health.value = health.value - options.incrementBy
        elseif id == "subS" then
            mana.value = mana.value - options.incrementBy
        elseif id == "subE" then
            extra.value = extra.value - options.incrementBy
        elseif id == "addMax" then
            health.value = health.value + options.incrementBy
            health.max = health.max + options.incrementBy
        elseif id == "addMaxS" then
            mana.value = mana.value + options.incrementBy
            mana.max = mana.max + options.incrementBy
        elseif id == "addMaxE" then
            extra.value = extra.value + options.incrementBy
            extra.max = extra.max + options.incrementBy
        elseif id == "subMax" then
            health.value = health.value - options.incrementBy
            health.max = health.max - options.incrementBy
        elseif id == "subMaxS" then
            mana.value = mana.value - options.incrementBy
            mana.max = mana.max - options.incrementBy
        elseif id == "subMaxE" then
            extra.value = extra.value - options.incrementBy
            extra.max = extra.max - options.incrementBy
        end
        if health.value > health.max and not options.aboveMax then health.value = health.max end
        if health.value < 0 and not options.belowZero then health.value = 0 end
        if mana.value > mana.max and not options.aboveMax then mana.value = mana.max end
        if mana.value < 0 and not options.belowZero then mana.value = 0 end
        if extra.value > extra.max and not options.aboveMax then extra.value = extra.max end
        if extra.value < 0 and not options.belowZero then extra.value = 0 end
        self.UI.setAttribute("progressBar", "percentage", health.value / health.max * 100)
        self.UI.setAttribute("progressBarS", "percentage", mana.value / mana.max * 100)
        self.UI.setAttribute("extraProgress", "percentage", extra.value / extra.max * 100)
        self.UI.setAttribute("hpText", "text", health.value .. "/" .. health.max)
        self.UI.setAttribute("manaText", "text", mana.value .. "/" .. mana.max)
        self.UI.setAttribute("extraText", "text", extra.value .. "/" .. extra.max)
        if options.HP2Desc then
            self.setDescription(health.value .. "/" .. health.max)
        end
        if player == false and health.value <= 0 and options.initSettingsIncluded == true and options.initRealActive == true then
            options.initSettingsIncluded = false
            self.UI.setAttribute("InitiativeIncludeToggle", "textColor", options.initSettingsIncluded == true and "#AA2222" or "#FFFFFF")
        end
        updateRollers()
    end
    self.UI.setAttribute("hpText", "textColor", "#FFFFFF")
    self.UI.setAttribute("manaText", "textColor", "#FFFFFF")
end

function showAllButtons()
    local foundTriggers = false
    posi = -16
    posiY = -2
    counter = 0
    for k = 0, 99 do
        if triggerNames[k] ~= nil and triggerNames[k] ~= "Reset" then
            foundTriggers = true
            -- typical button params
            local button_parameters1 = {}
            button_parameters1.click_function = "trigger"

            button_parameters1.function_owner = self
            button_parameters1.label = triggerNames[k]
            button_parameters1.position = {posi, 4, posiY}
            button_parameters1.rotation = {0, -90, 0}
            button_parameters1.width = 2000
            button_parameters1.height = 400
            button_parameters1.font_size = 150

            if a[k] == true then
                button_parameters1.color = {74 / 255, 186 / 255, 74 / 255}
                button_parameters1.hover_color = {74 / 255, 186 / 255, 74 / 255}
            end

            counter = counter + 1
            if counter < 16 then
                posi = posi + 1

                if counter == 11 then
                    if posiY == -21.5 then
                        posiY = posiY - 6
                        posi = -16
                        counter = 0
                    end
                end
            else
                posi = -16
                if posiY == -2 then
                    posiY = posiY - 6
                else
                    posiY = posiY - 4.5
                end
                counter = 0
            end

            -- create a new global function
            _G["ClickFunction" .. k] = function(obj, col)
                -- that simply calls our real target function
                RealClickFunction(obj, k)
            end

            button_parameters1.click_function = "ClickFunction" .. k

            self.createButton(button_parameters1)
        end
    end
    if triggerNames == false then
        print("No triggers found.")
        return
    end
    showing = true
end

function RealClickFunction(obj, index)
    if a[index] ~= true then
        a[index] = true
        self.editButton({index = index - 2, color = {74 / 255, 186 / 255, 74 / 255}})
        self.editButton({index = index - 2, hover_color = {120 / 255, 255 / 255, 120 / 255}})
    else
        a[index] = false
        self.editButton({index = index - 2, color = {255 / 255, 255 / 255, 255 / 255}})
        self.editButton({index = index - 2, hover_color = {180 / 255, 180 / 255, 180 / 255}})
    end
    self.AssetBundle.playTriggerEffect(0)
    Wait.frames(updateTriggerAgain, 10)
end

function updateTriggerAgain()
    timer = 1
    for i = 0, 99 do
        if a[i] ~= nil then
            if a[i] == true then
                Wait.frames(_G["TriggerFunction" .. i], timer)
                timer = timer + 10
            end
        end
    end
end

function onCollisionEnter(a) -- if colliding with a status token, destroy it and apply to UI
    local newState = a.collision_object.getName()
    if statNames[newState] ~= nil then
        statNames[newState] = true
        a.collision_object.destruct()
        self.UI.setAttribute(newState, "active", true)
        Wait.frames(function() self.UI.setAttribute("statePanel", "width", getStatsCount()*300) end, 1)
    end
end

function getStatsCount()
    local count = 0
    for i,j in pairs(statNames) do
        if self.UI.getAttribute(i, "active") == "True" or self.UI.getAttribute(i, "active") == "true" then
            count = count + 1
        end
    end
    return count
end
LUAStop--lua]]
--[[XMLStart
<Defaults>
    <Button onClick="onClick" fontSize="80" fontStyle="Bold" textColor="#FFFFFF" color="#000000FF"/>
    <Text fontSize="80" fontStyle="Bold" color="#FFFFFF"/>
    <InputField fontSize="70" color="#000000FF" textColor="#FFFFFF" characterValidation="Integer"/>
</Defaults>

<Panel id="panel" position="0 0 -220" rotation="90 270 90" scale="0.2 0.2">
    <VerticalLayout id="bars" height="300">
        <Panel id="hiddenButtonBar" active="false">
            <HorizontalLayout height="25" width="400">
                 <Button id="editButton0" color="#00000000"><Image image="UpArrow" preserveAspect="true"></Image></Button>
            </HorizontalLayout>
        </Panel>
        <Panel id="resourceBar" active="true">
            <ProgressBar id="progressBar" visibility="" height="100" width="600" showPercentageText="false" color="#000000FF" percentage="100" fillImageColor="#710000"></ProgressBar>
            <Text id="hpText" visibility="" height="100" width="600" text="10/10"></Text>
            <HorizontalLayout id="editButtonBar" height="100" width="600">
                 <Button id="leftSide1" text="" color="#00000000"></Button>
                 <Button id="editButton1" color="#00000000"></Button>
                 <Button id="editButtonS1" text="" color="#00000000"></Button>
            </HorizontalLayout>
            <Panel id="addSub" visibility="" height="100" width="825" active="false">
                <HorizontalLayout spacing="625">
                    <Button id="sub" text="-" color="#FFFFFF" textColor="#000000"></Button>
                    <Button id="add" text="+" color="#FFFFFF" textColor="#000000"></Button>
                </HorizontalLayout>
            </Panel>
        </Panel>
        <Panel id="resourceBarS" active="true">
            <ProgressBar id="progressBarS" visibility="" height="100" width="600" showPercentageText="false" color="#000000FF" percentage="100" fillImageColor="#000071"></ProgressBar>
            <Text id="manaText" visibility="" height="100" width="600" text="10/10"></Text>
            <HorizontalLayout id="editButtonBar" height="100" width="600">
                 <Button id="leftSide2" text="" color="#00000000"></Button>
                 <Button id="editButton2" color="#00000000"></Button>
                 <Button id="editButtonS2" text="" color="#00000000"></Button>
            </HorizontalLayout>
            <Panel id="addSubS" visibility="" height="100" width="825" active="false">
                <HorizontalLayout spacing="625">
                    <Button id="subS" text="-" color="#FFFFFF" textColor="#000000"></Button>
                    <Button id="addS" text="+" color="#FFFFFF" textColor="#000000"></Button>
                </HorizontalLayout>
            </Panel>
        </Panel>
        <Panel id="extraBar" active="true">
            <ProgressBar id="extraProgress" visibility="" height="100" width="600" showPercentageText="false" color="#000000FF" percentage="100" fillImageColor="#FFCF00"></ProgressBar>
            <Text id="extraText" visibility="" height="100" width="600" text="10/10"></Text>
            <HorizontalLayout id="editButtonBar" height="100" width="600">
                 <Button id="leftSide3" text="" color="#00000000"></Button>
                 <Button id="editButton3" color="#00000000"></Button>
                 <Button id="editButtonS3" text="" color="#00000000"></Button>
            </HorizontalLayout>
            <Panel id="addSubE" visibility="" height="100" width="825" active="false">
                <HorizontalLayout spacing="625">
                    <Button id="subE" text="-" color="#FFFFFF" textColor="#000000"></Button>
                    <Button id="addE" text="+" color="#FFFFFF" textColor="#000000"></Button>
                </HorizontalLayout>
            </Panel>
        </Panel>
    </VerticalLayout>
    <Panel id="editPanel" height="1520" width="800" color="#330000FF" position="0 1240 0" active="False">
        <ProgressBar id="blackBackground" visibility="" height="1520" width="800" showPercentageText="false" color="#330000FF" percentage="100" fillImageColor="#330000FF" position="0 -320 0"></ProgressBar>
        <HorizontalLayout>
            <VerticalLayout>
                <HorizontalLayout spacing="10" minheight="100">
                    <Button id="subHeight" text="◄"></Button>
                    <Text>Height</Text>
                    <Button id="addHeight" text="►"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="10" minheight="100">
                    <Button id="subRotation" text="◄" minwidth="90"></Button>
                    <Text>Rotation</Text>
                    <Button id="addRotation" text="►" minwidth="90"></Button>
                </HorizontalLayout>
                <HorizontalLayout minheight="100">
                    <Button id="PlayerCharToggle" onClick="togglePlayer" fontSize="70" text="Player Character" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout minheight="160">
                    <Button id="MeasureMoveToggle" onClick="toggleMeasure" fontSize="70" text="Measure Moves" color="#000000FF"></Button>
                    <Button id="AlternateDiagToggle" onClick="toggleAlternateDiag" fontSize="60" text="Alternate Diagonals" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout minheight="160">
                    <Button id="StabilizeToggle" onClick="toggleStabilizeOnDrop" fontSize="70" text="Stable Mini" color="#000000FF"></Button>
                    <Button id="HB" fontSize="70" text="Bar Edit Buttons" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout minheight="160">
                    <Button id="BZ" fontSize="70" text="Below Zero" color="#000000FF"></Button>
                    <Button id="AM" fontSize="70" text="Above Max" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout minheight="100">
                    <Button id="HH" fontSize="70" text="Hide Health Bar" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout minheight="100">
                    <Button id="HM" fontSize="70" text="Hide Bar 2" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout minheight="100">
                    <Button id="HE" fontSize="70" text="Hide Bar 3" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="55"  minheight="100">
                    <Button id="subMax" text="◄" minwidth="115"></Button>
                    <Text>Max HP</Text>
                    <Button id="addMax" text="►" minwidth="115"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="55"  minheight="100">
                    <Button id="subMaxS" text="◄" minwidth="90"></Button>
                    <Text>Max 2</Text>
                    <Button id="addMaxS" text="►" minwidth="90"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="55"  minheight="100">
                    <Button id="subMaxE" text="◄" minwidth="90"></Button>
                    <Text>Max 3</Text>
                    <Button id="addMaxE" text="►" minwidth="90"></Button>
                </HorizontalLayout>
                <HorizontalLayout minheight="160">
                    <Button id="InitiativeIncludeToggle" onClick="toggleInitiativeInclude" fontSize="70" text="Initiative Include" color="#000000FF"></Button>
                    <Button id="InitiativeRollingToggle" onClick="toggleInitiativeRolling" fontSize="70" text="Initiative Rolling" color="#000000FF"></Button>
                </HorizontalLayout>
                <HorizontalLayout spacing="10" minheight="100">
                    <Text fontSize="50">Initiative Mod:</Text>
                    <InputField id="InitModInput" onEndEdit="onEndEdit" minwidth="200" text="0"></InputField>
                </HorizontalLayout>
                <HorizontalLayout spacing="10" minheight="100">
                    <Text fontSize="50">Initiative Value:</Text>
                    <InputField id="InitValueInput" onEndEdit="onEndEdit" minwidth="200" text="0"></InputField>
                </HorizontalLayout>
                <HorizontalLayout spacing="10" minheight="100">
                    <Text fontSize="50">Increment by:</Text>
                    <InputField id="increment" onEndEdit="onEndEdit" minwidth="200" text="1"></InputField>
                </HorizontalLayout>
            </VerticalLayout>
            <VerticalLayout>
                <Button id="highlightNone" onClick="changeHighlight" minwidth="200" minheight="90" fontSize="70" text="None" color="Grey"></Button>
                <Button id="highlightWhite" onClick="changeHighlight" minwidth="200" minheight="90" fontSize="70" text="" color="White"></Button>
                <Button id="highlightBrown" onClick="changeHighlight" minwidth="200" minheight="90" fontSize="70" text="" color="Brown"></Button>
                <Button id="highlightRed" onClick="changeHighlight" minwidth="200" minheight="90" fontSize="70" text="" color="Red"></Button>
                <Button id="highlightOrange" onClick="changeHighlight" minwidth="200" minheight="90" fontSize="70" text="" color="Orange"></Button>
                <Button id="highlightYellow" onClick="changeHighlight" minwidth="200" minheight="90" fontSize="70" text="" color="Yellow"></Button>
                <Button id="highlightGreen" onClick="changeHighlight" minwidth="200" minheight="90" fontSize="70" text="" color="Green"></Button>
                <Button id="highlightTeal" onClick="changeHighlight" minwidth="200" minheight="90" fontSize="70" text="" color="Teal"></Button>
                <Button id="highlightBlue" onClick="changeHighlight" minwidth="200" minheight="90" fontSize="70" text="" color="Blue"></Button>
                <Button id="highlightPurple" onClick="changeHighlight" minwidth="200" minheight="90" fontSize="70" text="" color="Purple"></Button>
                <Button id="highlightPink" onClick="changeHighlight" minwidth="200" minheight="90" fontSize="70" text="" color="Pink"></Button>
                <Button id="highlightBlack" onClick="changeHighlight" minwidth="200" minheight="90" fontSize="70" text="" color="Black"></Button>
                <Button id="highlightToggle" onClick="toggleHighlight" minwidth="200" minheight="180" fontSize="50" text="Toggle" color="Grey"></Button>
            </VerticalLayout>
        </HorizontalLayout>
    </Panel>
    <Panel id="statePanel" height="300" width="-5" position="0 370 0">
        <VerticalLayout>
            <HorizontalLayout spacing="5">
                STATSIMAGE
            </HorizontalLayout>
        </VerticalLayout>
    </Panel>
</Panel>
XMLStop--xml]]

className = "MiniInjector"
versionNumber = "4.5.52"
finishedLoading = false
debuggingEnabled = false
pingInitMinis = true
hideUpsideDownMinis = true
autoCalibrateEnabled = false
injectEverythingAllowed = false
injectEverythingActive = false
injectEverythingFrameCount = 0
updateEverythingActive = false
updateEverythingFrameCount = 0
updateEverythingIndex = 1
injectedFrameLimiter = 0
collisionProcessing = {}

options = {
    hideText = false,
    editText = false,
    hideBar = false,
    hideAll = false,
    showAll = true,
    measureMove = false,
    alternateDiag = false,
    playerChar = false,
    HP2Desc = false,
    hp = 10,
    mana = 10,
    extra = 0,
    initActive = false,
    initCurrentValue = 0,
    initCurrentRound = 1,
    initCurrentGUID = ""
}

initFigures = {}

function onSave()
    local save_state = JSON.encode({
        debugging_enabled = debuggingEnabled,
        ping_init_minis = pingInitMinis,
        auto_calibrate_enabled = autoCalibrateEnabled,
        options = options,
    })
    return save_state
end

function onLoad(save_state)

    math.randomseed(os.time())
    math.random(1,20)
    math.random(1,20)
    math.random(1,20)
    math.random(1,20)
    math.random(1,20)
    math.random(1,20)
    math.random(1,20)
    math.random(1,20)
    math.random(1,999)
    math.random(1,999)
    math.random(1,999)
    math.random(1,999)
    math.random(1,999)
    math.random(1,999)
    math.random(1,999)
    math.random(1,999)

    if save_state ~= "" then
        saved_data = JSON.decode(save_state)
        if saved_data ~= nil then
            if saved_data.options ~= nil then
                for opt,_ in pairs(saved_data.options) do
                    if saved_data.options[opt] ~= nil then
                        options[opt] = saved_data.options[opt]
                    end
                end
            end
            if saved_data.debugging_enabled ~= nil then
                debuggingEnabled = saved_data.debugging_enabled
            end
            if saved_data.ping_init_minis ~= nil then
                pingInitMinis = saved_data.ping_init_minis
            end
            if saved_data.auto_calibrate_enabled ~= nil then
                autoCalibrateEnabled = saved_data.auto_calibrate_enabled
            end
        end
    end

    self.setVar("className", "MiniInjector")
    rebuildContextMenu()
    finishedLoading = true
    self.setVar("finishedLoading", true)
    self.setName("DND Mini Injector " .. versionNumber)

    addHotkey("Initiative Forward", forwardInitiative, false)
    addHotkey("Initiative Backward", backwardInitiative, false)
    addHotkey("Initiative Refresh", refreshInitiative, false)
    addHotkey("Initiative Roll", rollInitiative, false)

    Wait.frames(updateSettingUI, 10)

    Wait.frames(updateEverything, 120)
end

function updateSettingUI()
    self.UI.setAttribute("hp", "text", options.hp)
    self.UI.setAttribute("mana", "text", options.mana)
    self.UI.setAttribute("extra", "text", options.extra)

    for opt,_ in pairs(options) do
        if opt == "measureMove" or opt == "alternateDiag" or opt == "playerChar" or opt == "hideBar" or opt == "hideText" or opt == "editText" then
            if options[opt] then
                self.UI.setAttribute(opt, "value", "true")
                self.UI.setAttribute(opt, "text", "✘")
            else
                self.UI.setAttribute(opt, "value", "false")
                self.UI.setAttribute(opt, "text", "")
            end
            self.UI.setAttribute(opt, "textColor", "#FFFFFF")
        end
    end
end

function rebuildContextMenu()
    self.clearContextMenu()
    if (debuggingEnabled) then
        self.addContextMenuItem("[X] Debugging", toggleDebug)
    else
        self.addContextMenuItem("[ ] Debugging", toggleDebug)
    end
    if (pingInitMinis) then
        self.addContextMenuItem("[X] Ping Init Minis", togglePingInitMinis)
    else
        self.addContextMenuItem("[ ] Ping Init Minis", togglePingInitMinis)
    end
    if (autoCalibrateEnabled) then
        self.addContextMenuItem("[X] Auto-Calibrate", toggleAutoCalibrate)
    else
        self.addContextMenuItem("[ ] Auto-Calibrate", toggleAutoCalibrate)
    end
    self.addContextMenuItem("Update All Minis", updateEverything)
    self.addContextMenuItem("Inject EVERYTHING", injectEverything)
end

function toggleDebug()
    debuggingEnabled = not debuggingEnabled
    rebuildContextMenu()
end

function togglePingInitMinis()
    pingInitMinis = not pingInitMinis
    rebuildContextMenu()
end

function updateEverything()
    updateEverythingActive = true
end

function toggleAutoCalibrate()
    autoCalibrateEnabled = not autoCalibrateEnabled
    if autoCalibrateEnabled then
        print("Automatic calibration ENABLED. Injected minis will automatically be calibrated to the current grid.")
    else
        print("Automatic calibration DISABLED.")
    end
    rebuildContextMenu()
end

function injectEverything()
    if injectEverythingAllowed == false then
        print("INJECT EVERYTHING. This will inject movement tokens into literally every object in this save. Only use this in an empty save with only miniatures and measurement tools. Click it again to confirm.")
        injectEverythingAllowed = true
        return
    end
    injectEverythingActive = true
end

function onUpdate()
    if injectedFrameLimiter > 0 then
        injectedFrameLimiter = injectedFrameLimiter - 1
    end
    if injectedFrameLimiter == 0 and #collisionProcessing > 0 then
        local collision_info = table.remove(collisionProcessing)
        local object = collision_info.collision_object
        if object ~= nil then
            local hitList = Physics.cast({
                origin       = object.getBounds().center,
                direction    = {0,-1,0},
                type         = 1,
                max_distance = 10,
                debug        = false,
            })
            local attemptCount = 1
            for _, hitTable in ipairs(hitList) do
                -- This hit makes sure the injector is the first object directly below the mini
                if hitTable ~= nil and hitTable.hit_object == self then
                    if self.getRotationValue() == "[00ff00]INJECT[-]" then
                        objClassName = object.getVar("className")
                        if objClassName ~= "MiniInjector" and
                           objClassName ~= "MeasurementToken" and
                           objClassName ~= "MeasurementToken_Move" and
                           objClassName ~= "MeasurementTool" then
                            if debuggingEnabled == true then
                                print("[00ff00]Injecting[-] mini " .. object.getName() .. ".")
                            end
                            injectToken(object)
                            injectedFrameLimiter = 60
                            break
                        end
                    elseif self.getRotationValue() == "[ff0000]REMOVE[-]" then
                        if object.getVar("className") == "MeasurementToken" then
                            if debuggingEnabled == true then
                                print("[ff0000]Removing[-] injection from " .. object.getName() .. ".")
                            end
                            object.call("destroyMoveToken")
                            object.setLuaScript("")
                            object.reload()
                            break
                        end
                    else
                        error("Invalid rotation.")
                        break
                    end
                else
                    attemptCount = attemptCount + 1
                    if (debuggingEnabled) then
                        print("Did not find injector, index "..tostring(attemptCount)..".")
                    end
                end
            end
        end
    end
    if injectEverythingActive == true then
        injectEverythingFrameCount = injectEverythingFrameCount + 1
        if injectEverythingFrameCount >= 5 then
            injectEverythingFrameCount = 0
            local allObjects = getAllObjects()
            for _, obj in ipairs(allObjects) do
                if obj ~= self and obj ~= nil then
                    objClassName = obj.getVar("className")
                    if objClassName ~= "MeasurementToken" and
                       objClassName ~= "MeasurementToken_Move" and
                       objClassName ~= "MeasurementTool" then
                        print("[00ff00]Injecting[-] mini " .. obj.getName() .. ".")
                        injectToken(obj)
                        return
                    end
                end
            end
            injectEverythingActive = false
            print("[00ff00]Inject EVERYTHING complete.[-]")
        end
    end

    if updateEverythingActive == true then
        updateEverythingFrameCount = updateEverythingFrameCount + 1
        if updateEverythingFrameCount >= 5 then
            updateEverythingFrameCount = 0
            local allObjects = getAllObjects()
            for _, obj in ipairs(allObjects) do
                if obj ~= self and obj ~= nil then
                    objClassName = obj.getVar("className")
                    if objClassName == "MeasurementToken" then
                        tokenVersion = obj.getVar("versionNumber")
                        if versionNumber ~= tokenVersion then
                            print("[00ff00]Updating[-] mini " .. updateEverythingIndex .. ".")
                            updateEverythingIndex = updateEverythingIndex + 1
                            injectToken(obj)
                            return
                        end
                    end
                end
            end
            updateEverythingActive = false
            updateEverythingIndex = 1
            print("[00ff00]All minis updated.[-]")
            if options.initActive == true then
                Wait.frames(rollInitiative, 60)
            end
        end
    end
end

function onObjectSpawn(object)
    if finishedLoading == false then
        return
    end
    local dropWatch = function()
        return object == nil or object.resting
    end
    local dropFunc = function()
        if object == nil then
            return
        end
        if object.getVar("className") == "MeasurementToken" then
            tokenVersion = object.getVar("versionNumber")
            if versionNumber ~= tokenVersion then
                print("[00ff00]Updating[-] spawned mini.")
                injectToken(object)
                return
            else
                object.call('resetScale')
                object.call('toggleAlternateDiag')
            end
        end
    end
    Wait.condition(dropFunc, dropWatch)
end

function allOff()
    for i,j in pairs(getAllObjects()) do
        if j ~= self then
            if j.getLuaScript():find("StartXML") then
                j.UI.setAttribute("panel", "active", "false")
            end
        end
    end
end

function toggleCheckBox(player, value, id)
    if self.UI.getAttribute(id, "value") == "false" then
        self.UI.setAttribute(id, "value", "true")
        self.UI.setAttribute(id, "text", "✘")
        options[id] = true
    else
        self.UI.setAttribute(id, "value", "false")
        self.UI.setAttribute(id, "text", "")
        options[id] = false
    end
    self.UI.setAttribute(id, "textColor", "#FFFFFF")
    for i,j in pairs(getAllObjects()) do
        if j ~= self then
            if j.getLuaScript():find("StartXML") then
                if id == "alternateDiag" then
                    j.call('toggleAlternateDiag')
                end
                if j.getVar("player") then
                    if id == "hideBar" then
                        j.UI.setAttribute("progressBar", "visibility", "")
                        j.UI.setAttribute("progressBarS", "visibility", "")
                        j.UI.setAttribute("extraProgress", "visibility", "")
                    elseif id == "hideText" then
                        j.UI.setAttribute("hpText", "visibility", "")
                        j.UI.setAttribute("manaText", "visibility", "")
                        j.UI.setAttribute("extraText", "visibility", "")
                    elseif id == "editText" then
                        j.UI.setAttribute("addSub", "visibility", "")
                        j.UI.setAttribute("addSubS", "visibility", "")
                        j.UI.setAttribute("addSubE", "visibility", "")
                        j.UI.setAttribute("editPanel", "visibility", "")
                    end
                else
                    if id == "hideBar" then
                        j.UI.setAttribute("progressBar", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("progressBarS", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("extraProgress", "visibility", options[id] == true and "Black" or "")
                    elseif id == "hideText" then
                        j.UI.setAttribute("hpText", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("manaText", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("extraText", "visibility", options[id] == true and "Black" or "")
                    elseif id == "editText" then
                        j.UI.setAttribute("addSub", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("addSubS", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("addSubE", "visibility", options[id] == true and "Black" or "")
                        j.UI.setAttribute("editPanel", "visibility", options[id] == true and "Black" or "")
                    end
                end
            end
        end
    end
end

function toggleHideBars(player, value, id)
    for i,j in pairs(getAllObjects()) do
        if j ~= self and not j.getName():find("DND Mini Panel") then
            if j.getLuaScript():find("StartXML") then
                if not options.hideAll then
                    j.UI.setAttribute("resourceBar", "active", "false")
                    j.UI.setAttribute("resourceBarS", "active", "false")
                    j.UI.setAttribute("extraBar", "active", "false")
                else
                    j.UI.setAttribute("resourceBar", "active", "true")
                    local objTable = j.getTable("options")
                    if not objTable.hideMana then
                        j.UI.setAttribute("resourceBarS", "active", "true")
                    end
                    if not objTable.hideExtra then
                        j.UI.setAttribute("extraBar", "active", "true")
                    end
                end
            end
        end
    end
    options.hideAll = not options.hideAll
end


function toggleOnOff(player, value, id)
    if self.UI.getAttribute(id, "value") == "false" then
        self.UI.setAttribute(id, "value", "true")
        options[id] = true
    else
        self.UI.setAttribute(id, "value", "false")
        options[id] = false
    end
    for i,j in pairs(getAllObjects()) do
        if j ~= self then
            if j.getLuaScript():find("StartXML") then
                j.UI.setAttribute("panel", "active", options[id] == true and "true" or "false")
            end
        end
    end
end

function onEndEdit(player, value, id)
    if value ~= "" then
        options[id] = tonumber(value)
        self.UI.setAttribute(id, "text", value)
    end
end

function onCollisionEnter(collision_info)
    table.insert(collisionProcessing, collision_info)
end

function injectToken(object)
    local assets = self.UI.getCustomAssets()
    object.UI.setCustomAssets(assets)
    local script = self.getLuaScript()
    local xml = script:sub(script:find("XMLStart")+8, script:find("XMLStop")-1)
    local newScript = script:sub(script:find("LUAStart")+8, script:find("LUAStop")-1)
    local stats = "statNames = {"
    local xmlStats = ""
    for j,i in pairs(assets) do
        stats = stats .. i.name .. " = false, "
        xmlStats = xmlStats .. '<Button id="' .. i.name .. '" color="#FFFFFF00" active="false"><Image image="' .. i.name .. '" preserveAspect="true"></Image></Button>\n'
    end
    newScript = "--[[StartXML\n" .. xml:gsub("STATSIMAGE", xmlStats) .. "StopXML--xml]]" .. stats:sub(1, -3) .. "}\n" .. newScript
    xml = xml:gsub("STATSIMAGE", xmlStats)
    if not options.hideText and options.HP2Desc then
        object.setDescription(options.hp .. "/" .. options.hp)
    end
    newScript = newScript:gsub("health = {value = 10, max = 10}", "health = {value = " .. options.hp ..", max = " .. options.hp .. "}")
    newScript = newScript:gsub("mana = {value = 10, max = 10}", "mana = {value = " .. options.mana ..", max = " .. options.mana .. "}")
    newScript = newScript:gsub("extra = {value = 10, max = 10}", "extra = {value = " .. options.extra ..", max = " .. options.extra .. "}")

    if options.hp == 0 then
        newScript = newScript:gsub("hideHp = false,", "hideHp = true,")
    end
    if options.mana == 0 then
        newScript = newScript:gsub("hideMana = false,", "hideMana = true,")
    end
    if options.extra ~= 0 then
        newScript = newScript:gsub("hideExtra = true,", "hideExtra = false,")
    end
    newScript = newScript:gsub('<VerticalLayout id="bars" height="200">', '<VerticalLayout id="bars" height="' .. 200 + (options.mana == 0 and -100 or 0) + (options.extra ~= 0 and 100 or 0) .. '">')

    if options.measureMove == true then
        newScript = newScript:gsub("measureMove = false", "measureMove = true")
    end
    if options.alternateDiag == true then
        newScript = newScript:gsub("alternateDiag = false", "alternateDiag = true")
    end
    if options.playerChar == true then
        newScript = newScript:gsub("player = false", "player = true")
        if options.HP2Desc == true then
            newScript = newScript:gsub("HP2Desc = false,", "HP2Desc = true,")
        end
    else
        if options.hideText == true then
            newScript = newScript:gsub('id="hpText" visibility=""', 'id="hpText" visibility="Black"')
            newScript = newScript:gsub('id="manaText" visibility=""', 'id="manaText" visibility="Black"')
            newScript = newScript:gsub('id="extraText" visibility=""', 'id="extraText" visibility="Black"')
        end
        if options.hideBar == true then
            newScript = newScript:gsub('id="progressBar" visibility=""', 'id="progressBar" visibility="Black"')
            newScript = newScript:gsub('id="progressBarS" visibility=""', 'id="progressBarS" visibility="Black"')
            newScript = newScript:gsub('id="extraProgress" visibility=""', 'id="extraProgress" visibility="Black"')
        end
        if options.editText == true then
            newScript = newScript:gsub('id="addSub" visibility=""', 'id="addSub" visibility="Black"')
            newScript = newScript:gsub('id="addSubS" visibility=""', 'id="addSubS" visibility="Black"')
            newScript = newScript:gsub('id="addSubE" visibility=""', 'id="addSubE" visibility="Black"')
            newScript = newScript:gsub('id="editPanel" visibility=""', 'id="editPanel" visibility="Black"')
        end
    end
    newScript = newScript:gsub('<Panel id="panel" position="0 0 -220"', '<Panel id="panel" position="0 0 ' .. object.getBounds().size.y / object.getScale().y * 110 .. '"')
    object.setLuaScript(newScript)
    object.reload()
end

function getInitiativeFigures()
    figures = {}
    for k, v in pairs(getAllObjects()) do
        if v.getVar("className") == "MeasurementToken" then
            -- Grab miniature options
            local objTable = v.getTable("options")
            -- Only add minis that are initiative included
            if objTable.initSettingsIncluded == true then
                local player = v.getVar("player")
                local colorTint = v.getColorTint()
                if player == true then
                    local miniHighlight = v.getVar("miniHighlight")
                    if miniHighlight == "highlightWhite" then
                        colorTint = Color.White
                    elseif miniHighlight == "highlightBrown" then
                        colorTint = Color.Brown
                    elseif miniHighlight == "highlightRed" then
                        colorTint = Color.Red
                    elseif miniHighlight == "highlightOrange" then
                        colorTint = Color.Orange
                    elseif miniHighlight == "highlightYellow" then
                        colorTint = Color.Yellow
                    elseif miniHighlight == "highlightGreen" then
                        colorTint = Color.Green
                    elseif miniHighlight == "highlightTeal" then
                        colorTint = Color.Teal
                    elseif miniHighlight == "highlightBlue" then
                        colorTint = Color.Blue
                    elseif miniHighlight == "highlightPurple" then
                        colorTint = Color.Purple
                    elseif miniHighlight == "highlightPink" then
                        colorTint = Color.Pink
                    elseif miniHighlight == "highlightBlack" then
                        colorTint = Color.Black
                    end
                else
                    colorTint = Color.White
                end
                local figure = {
                    nameHealth = v.getName() .. " " .. v.UI.getAttribute("hpText", "Text"),
                    guidValue = v.getGUID(),
                    initValue = tonumber(v.call("getInitiative", options.initActive)),
                    initText = "",
                    initMod = tonumber(objTable.initSettingsMod),
                    initRolling = objTable.initSettingsRolling,
                    player = player,
                    name = v.getName(),
                    obj = v,
                    options = objTable,
                    health = v.getTable("health"),
                    colorTint = colorTint,
                    colorHex = tintToHex(colorTint)
                }
                local initText = tostring(figure.initValue) .. ' ['
                if figure.initMod == 0 then
                    initText = initText .. '0]'
                elseif figure.initMod > 0 then
                    initText = initText .. '+' .. figure.initMod .. ']'
                else
                    initText = initText .. figure.initMod .. ']'
                end
                figure.initText = initText
                table.insert(figures, figure)
            end
        end
    end
    local figureSorter = function(figA, figB)
        -- Sort by initiative value
        if figA.initValue ~= figB.initValue then
            return figA.initValue > figB.initValue
        end
        -- Then by initiative mod
        if figA.initMod ~= figB.initMod then
            return figA.initMod > figB.initMod
        end
        -- Then by name
        return figA.name < figB.name
    end
    table.sort(figures, figureSorter)
    initFigures = figures
    return figures
end

function resetInitiative()
    options.initActive = false
    options.initCurrentValue = 0
    options.initCurrentRound = 1
    options.initCurrentGUID = ""
    getInitiativeFigures()
    for i, figure in ipairs(initFigures) do
        figure.obj.call('resetInitiative')
    end
    initFigures = {}
    rebuildUI()
    setNotes("")
end

function refreshInitiative(player)
    if player ~= nil and player.team == nil and player ~= "Black" then
        return
    end
    getInitiativeFigures()
    if options.initActive == true then
        updateInitPlayer(player)
    end
    rebuildUI()
end

function rollInitiative(player)
    if player ~= nil and player.team == nil and player ~= "Black" then
        return
    end
    options.initActive = true
    getInitiativeFigures()
    if not checkPlayersSet() then
        rebuildUI()
        return
    end
    if options.initCurrentValue == 0 and options.initCurrentGUID == "" then
        for _, figure in ipairs(initFigures) do
            options.initCurrentValue = figure.initValue
            options.initCurrentGUID = figure.guidValue
            break
        end
        options.initCurrentRound = 1
    else
        updateInitPlayer(player)
    end
    rebuildUI()
    setInitiativeNotes()
end

function updateInitPlayer(player)
    local foundInitFigure = false
    local changedInitFigure = false
    --find the current player
    for _, figure in ipairs(initFigures) do
        if figure.guidValue == options.initCurrentGUID then
            if player ~= nil and pingInitMinis then
                figureObj = getObjectFromGUID(options.initCurrentGUID)
                if player.team == nil then
                    -- We're a color, not a player, assign the player object
                    for _, loopPlayer in ipairs(Player.getPlayers()) do
                        if loopPlayer.color == player then
                           player = loopPlayer
                           break
                        end
                    end
                end
                player.pingTable(figureObj.getBounds().center)
            end
            -- no need for update, they are still present
            return
        end
    end
    -- if we couldn't find them by guid, just use initiative value
    if changedInitFigure == false and foundInitFigure == false then
        for _, figure in ipairs(initFigures) do
            if figure.initValue <= options.initCurrentValue and figure.guidValue ~= options.initCurrentGUID then
                options.initCurrentValue = figure.initValue
                options.initCurrentGUID = figure.guidValue
                changedInitFigure = true
                break
            end
        end
    end
    --If we still couldn't find one, loop back around to the top of the list
    if changedInitFigure == false then
        for _, figure in ipairs(initFigures) do
            options.initCurrentValue = figure.initValue
            options.initCurrentGUID = figure.guidValue
            changedInitFigure = true
            break
        end
        options.initCurrentRound = options.initCurrentRound + 1
    end
    if changedInitFigure == true and pingInitMinis and player ~= nil then
        figureObj = getObjectFromGUID(options.initCurrentGUID)
        if player.team == nil then
            -- We're a color, not a player, assign the player object
            for _, loopPlayer in ipairs(Player.getPlayers()) do
                if loopPlayer.color == player then
                   player = loopPlayer
                   break
                end
            end
        end
        player.pingTable(figureObj.getBounds().center)
    end
end

function forwardInitiative(player)
    if player ~= nil and player.team == nil and player ~= "Black" then
        return
    end
    if not options.initActive then
        print("Initiative must be active before navigating.")
        return
    end
    getInitiativeFigures()
    if not checkPlayersSet() then
        rebuildUI()
        return
    end

    updateInitPlayerForward(player)

    rebuildUI()
    setInitiativeNotes()
end

function updateInitPlayerForward(player)
    local foundInitFigure = false
    local changedInitFigure = false
    --find the next player
    for _, figure in ipairs(initFigures) do
        if figure.guidValue == options.initCurrentGUID then
            foundInitFigure = true
        elseif foundInitFigure == true then
            options.initCurrentValue = figure.initValue
            options.initCurrentGUID = figure.guidValue
            changedInitFigure = true
            break
        end
    end
    -- if we couldn't find them by guid, just use initiative value
    if changedInitFigure == false and foundInitFigure == false then
        for _, figure in ipairs(initFigures) do
            if figure.initValue <= options.initCurrentValue and figure.guidValue ~= options.initCurrentGUID then
                options.initCurrentValue = figure.initValue
                options.initCurrentGUID = figure.guidValue
                changedInitFigure = true
                break
            end
        end
    end
    --If we still couldn't find one, loop back around to the top of the list
    if changedInitFigure == false then
        for _, figure in ipairs(initFigures) do
            options.initCurrentValue = figure.initValue
            options.initCurrentGUID = figure.guidValue
            changedInitFigure = true
            break
        end
        options.initCurrentRound = options.initCurrentRound + 1
    end
    if changedInitFigure == true and pingInitMinis and player ~= nil then
        figureObj = getObjectFromGUID(options.initCurrentGUID)
        if player.team == nil then
            -- We're a color, not a player, assign the player object
            for _, loopPlayer in ipairs(Player.getPlayers()) do
                if loopPlayer.color == player then
                   player = loopPlayer
                   break
                end
            end
        end
        player.pingTable(figureObj.getBounds().center)
    end
end

function backwardInitiative(player)
    if player ~= nil and player.team == nil and player ~= "Black" then
        return
    end
    if not options.initActive then
        print("Initiative must be active before navigating.")
        return
    end
    getInitiativeFigures()
    if not checkPlayersSet() then
        rebuildUI()
        return
    end

    updateInitPlayerBackward(player)

    rebuildUI()
    setInitiativeNotes()
end

function updateInitPlayerBackward(player)
    local previousFigure = nil
    local foundInitFigure = false
    local changedInitFigure = false
    --find the previous player
    for _, figure in ipairs(initFigures) do
        if figure.guidValue == options.initCurrentGUID then
            foundInitFigure = true
            if previousFigure ~= nil then
                options.initCurrentValue = previousFigure.initValue
                options.initCurrentGUID = previousFigure.guidValue
                changedInitFigure = true
                break
            end
        else
            previousFigure = figure
        end
    end
    -- if we couldn't find them by guid, just use initiative value
    if changedInitFigure == false and foundInitFigure == false then
        for _, figure in ipairs(initFigures) do
            if figure.initValue >= options.initCurrentValue and previousFigure ~= nil then
                foundInitFigure = true
                options.initCurrentValue = previousFigure.initValue
                options.initCurrentGUID = previousFigure.guidValue
                changedInitFigure = true
                break
            else
                previousFigure = figure
            end
        end
    end
    --If we still couldn't find one, loop back around to the bottom of the list
    if changedInitFigure == false then
        options.initCurrentValue = previousFigure.initValue
        options.initCurrentGUID = previousFigure.guidValue
        changedInitFigure = true
        options.initCurrentRound = options.initCurrentRound - 1
    end
    if changedInitFigure == true and pingInitMinis and player ~= nil then
        figureObj = getObjectFromGUID(options.initCurrentGUID)
        if player.team == nil then
            -- We're a color, not a player, assign the player object
            for _, loopPlayer in ipairs(Player.getPlayers()) do
                if loopPlayer.color == player then
                   player = loopPlayer
                   break
                end
            end
        end
        player.pingTable(figureObj.getBounds().center)
    end
end

function setInitiativeNotes()
    --Format each result into a string that goes into notes
    local noteString = "[CFCFCF]-------- INITIATIVE --------\n-------- ROUND " .. options.initCurrentRound .. " ---------\n-----------------------------\n[-]"
    for i, figure in ipairs(initFigures) do
        noteString = noteString .. getInitiativeString(figure)
    end
    noteString = noteString .. "[CFCFCF]-----------------------------[-]"
    --Put that string into notes
    setNotes(noteString)
end

--returns the rendered initiative string for this figure
function getInitiativeString(figure)
    local figureColorA = "[" .. figure.colorHex .. "]"
    local figureColorB = "[-]"
    local initiativeMarker = ""
    if figure.guidValue == options.initCurrentGUID then
        initiativeMarker = "---->"
    end
    if figure.player == false then
        return "[FFFFFF]" .. initiativeMarker .. figure.name .. "     " .. figure.initValue .. "[-]\n"
    else

        return "[b][i]" .. figureColorA .. initiativeMarker .. figure.name .. "     " .. figure.initValue .. "[/b][/i]" .. figureColorB .. "\n"
    end
end

function checkPlayersSet()
    local noteCheck = ""
    for _, figure in ipairs(initFigures) do
        if (figure.player == true or figure.initRolling == false) and figure.initValue == 100 then
            print(figure.name .. " has not set their initiative.")
            noteCheck = noteCheck .. figure.name .. " has not set their initiative.\n"
        end
    end
    if noteCheck ~= "" then
        setNotes(noteCheck)
        return false
    end
    return true
end

function rebuildUI()

    local xmlUI = self.UI.getXmlTable()
    -- clear out existing figures
    xmlUI[2].children = {}

    local allObjects = getAllObjects()
    local minilist = {
        tag='VerticalLayout',
        attributes={id='scroll', minHeight='100', width='600', inertia=false, scrollSensitivity=4, color='#00000000', visibility='Black', rectAlignment='UpperCenter'},
        children = {
            {tag='VerticalLayout', attributes={childForceExpandHeight=false, contentSizeFitter='vertical', spacing='5', padding='5 5 5 5', visibility='Black', rectAlignment='UpperCenter'}, children={}}
        }
    }

    local creatureCount = 0
    for i, figure in ipairs(initFigures) do
        creatureCount = creatureCount + 1
        local c = figure.colorTint
        local color = '#'..string.format('%02x', math.ceil(c.r * 255))..string.format('%02x', math.ceil(c.g * 255))..string.format('%02x', math.ceil(c.b * 255))

        local colorVar = '#202020'
        if options.initCurrentGUID == figure.guidValue then
            colorVar = '#505050'
        elseif figure.player == true then
            colorVar = '#401010'
        end

        local extraText = ''
        local currentHealth = figure.health.value
        local maxHealth = figure.health.max
        local perc = (maxHealth == 0) and 0 or (currentHealth * 1.0) / (maxHealth * 1.0)
        if (perc <= 0) then
            extraText = ' (Dead)'
        elseif (perc <= 0.05) then
            extraText = ' (Deaths Door)'
        elseif (perc <= 0.25) then
            extraText = ' (Spicy)'
        elseif (perc <= 0.5) then
            extraText = ' (Bloody)'
        elseif (perc <= 0.75) then
            extraText = ' (Feeling it now Mr. Krabs?)'
        elseif (perc < 1.0) then
            extraText = ' (Healthy)'
        else
            extraText = ' (Untouched)'
        end
        extraText = striptags(figure.name)..extraText
        local percMax = tonumber(perc * 100.0)
        local miniui = {
            tag='verticallayout',
            attributes={
                color=colorVar,
                childForceExpandHeight=false,
                padding=5,
                spacing=5,
                flexibleHeight=0
            },
            children={
                {
                    tag='horizontallayout',
                    attributes={
                        preferredHeight = 60,
                        childForceExpandHeight=false,
                        childForceExpandWidth=false,
                        spacing=5
                    },
                    children={
                        {
                            tag='text',
                            attributes={
                                id=figure.guidValue ..'_header_init',
                                alignment='MiddleLeft',
                                preferredHeight=60,
                                fontSize='32',
                                resizeTextForBestFit=true,
                                minWidth='113',
                                text=figure.initText
                            }
                        },
                        {
                            tag='panel',
                            attributes={
                                color=color,
                                preferredWidth = 10,
                                flexibleWidth = 0,
                                preferredHeight=60,
                                minWidth='10'
                            }
                        },
                        {
                            tag='text',
                            attributes={
                                id=figure.guidValue ..'_header_title',
                                alignment='MiddleLeft',
                                preferredHeight=60,
                                fontSize='32',
                                resizeTextForBestFit=true,
                                preferredWidth=10000,
                                text=extraText
                            }
                        },
                    }
                },
                {
                    tag='horizontallayout',
                    attributes={
                        preferredHeight=60,
                        childForceExpandHeight=false,
                        childForceExpandWidth=false,
                        spacing=5
                    },
                    children={
                        {
                            tag='InputField',
                            attributes={
                                id=figure.guidValue ..'_input_change',
                                preferredHeight='60',
                                preferredWidth='130',
                                flexibleWidth=0,
                                fontSize='38',
                                alignment='MiddleCenter',
                                offsetXY='150 0',
                                color='rgb(0.3,0.3,0.3)',
                                textColor='rgb(1,1,1)',
                                characterValidation='Integer',
                                onEndEdit='barChangeDiff',
                                fontStyle='Bold'
                            }
                        },
                        {
                            tag='InputField',
                            attributes={
                                id=figure.guidValue ..'_input_current',
                                preferredHeight='60',
                                preferredWidth='130',
                                flexibleWidth=0,
                                fontSize='38',
                                alignment='MiddleCenter',
                                offsetXY='150 0',
                                text=currentHealth,
                                characterValidation='Integer',
                                onEndEdit='barChangeCurrent',
                                fontStyle='Bold'
                            }
                        },
                        {
                            tag='Button',
                            attributes={
                                preferredWidth='30',
                                preferredHeight='60',
                                flexibleWidth=0,
                                image='ui_arrow_l2',
                                onClick='barReduce('..figure.guidValue ..')'
                            }
                        },
                        {
                            tag='panel',
                            attributes={
                                preferredHeight='60',
                                preferredWidth='300'
                            },
                            children={
                                {
                                    tag='progressbar',
                                    attributes={
                                        id=figure.guidValue ..'_bar',
                                        width='100%',
                                        percentage=percMax,
                                        fillImageColor='#FF0000',
                                        color='#00000080',
                                        textColor='transparent'
                                    }
                                }
                            }
                        },
                        {
                            tag='Button',
                            attributes={
                                preferredWidth='30',
                                preferredHeight='60',
                                image='ui_arrow_r2',
                                flexibleWidth=0,
                                onClick='barIncrease('..figure.guidValue ..')'
                            }
                        },
                        {
                            tag='InputField',
                            attributes={
                                id=figure.guidValue ..'_input_maximum',
                                preferredHeight='60',
                                preferredWidth='130',
                                fontSize='38',
                                text=maxHealth,
                                characterValidation='Integer',
                                onEndEdit='barChangeMaximum',
                                fontStyle='Bold'
                            }
                        }
                    }
                }
            }
        }

        table.insert(minilist.children[1].children, miniui)
    end

    local calcHeight = 93 * creatureCount
    minilist.attributes.height = calcHeight..''
    minilist.attributes.minHeight = calcHeight..''
    table.insert(xmlUI[2].children, {
        tag='Defaults', children={
            {tag='Text', attributes={color='#cccccc', fontSize='15', alignment='MiddleLeft', visibility='Black'}},
            {tag='InputField', attributes={fontSize='15', preferredHeight='60', visibility='Black'}},
            {tag='ToggleButton', attributes={fontSize='15', preferredHeight='60', colors='#ffcc33|#ffffff|#808080|#606060', selectedBackgroundColor='#dddddd', deselectedBackgroundColor='#999999', visibility='Black'}},
            {tag='Button', attributes={fontSize='15', preferredHeight='60', colors='#dddddd|#ffffff|#808080|#606060', visibility='Black'}},
            {tag='Toggle', attributes={textColor='#cccccc', visibility='Black'}},
        }
    })
    table.insert(xmlUI[2].children, {tag='Panel', attributes={ height=calcHeight..'', width='790', rectAlignment='UpperCenter'},
        children={
            {tag='VerticalLayout', attributes={childForceExpandHeight=false, minHeight='0', spacing=10, rectAlignment='UpperCenter'}, children={
                {tag='HorizontalLayout', attributes={preferredHeight=80, childForceExpandWidth=false, flexibleHeight=0, spacing=20, padding='10 10 10 10'}, children={}},
                minilist
            }}
        }
    })
    self.UI.setXmlTable(xmlUI)
end

function updateFromGuid(guid)
    local token = getObjectFromGUID(guid)
    if (token ~= nil) then
        local extraText = ''
        local healthTable = token.getTable("health")
        local currentHealth = healthTable.value
        local maxHealth = healthTable.max
        local perc = (maxHealth == 0) and 0 or (currentHealth * 1.0) / (maxHealth * 1.0)
        if (perc <= 0) then
            extraText = ' (Dead)'
            local player = token.getVar("player")
            if player == false and options.initActive then
                Wait.frames(rollInitiative, 5)
            end
        elseif (perc <= 0.05) then
            extraText = ' (Deaths Door)'
        elseif (perc <= 0.25) then
            extraText = ' (Spicy)'
        elseif (perc <= 0.5) then
            extraText = ' (Bloody)'
        elseif (perc <= 0.75) then
            extraText = ' (Feeling it now Mr. Krabs?)'
        elseif (perc < 1.0) then
            extraText = ' (Healthy)'
        else
            extraText = ' (Untouched)'
        end
        local percMax = tonumber(perc * 100.0)
        self.UI.setAttribute(guid..'_header_title', 'text', striptags(token.getName())..extraText)
        self.UI.setAttribute(guid..'_input_current', 'text', currentHealth)
        self.UI.setAttribute(guid..'_bar', 'percentage', percMax)
        self.UI.setAttribute(guid..'_input_maximum', 'text', maxHealth)
    end
end

function barChangeDiff(player, value, id)
    if value == "" then
        return
    end
    local args = {}
    for a in string.gmatch(id, '([^%_]+)') do
        table.insert(args,a)
    end
    local guid = args[1]
    local token = getObjectFromGUID(guid)
    if (token ~= nil) then
        token.call('adjustHP', value)
    end
    self.UI.setAttribute(id, 'text', '')
end

function barChangeCurrent(player, value, id)
    if value == "" then
        return
    end
    local args = {}
    for a in string.gmatch(id, '([^%_]+)') do
        table.insert(args,a)
    end
    local guid = args[1]
    local token = getObjectFromGUID(guid)
    if (token ~= nil) then
        token.call('setHP', value)
    end
end

function barChangeMaximum(player, value, id)
    if value == "" then
        return
    end
    local args = {}
    for a in string.gmatch(id, '([^%_]+)') do
        table.insert(args,a)
    end
    local guid = args[1]
    local token = getObjectFromGUID(guid)
    if (token ~= nil) then
        token.call('setHPMax', value)
    end
end

function barReduce(player, guid)
    local token = getObjectFromGUID(guid)
    if (token ~= nil) then
        token.call('reduceHP')
    end
end

function barIncrease(player, guid)
    local token = getObjectFromGUID(guid)
    if (token ~= nil) then
        token.call('increaseHP')
    end
end

function sanitize(str)
    return str:gsub('[<>]', '')
end

function striptags(str)
    str = sanitize(str)
    str = str:gsub('%[/?[iI]%]', '')
    str = str:gsub('%[/?[bB]%]', '')
    str = str:gsub('%[/?[uU]%]', '')
    str = str:gsub('%[/?[sS]%]', '')
    str = str:gsub('%[/?[sS][uU][bB]%]', '')
    str = str:gsub('%[/?[sS][uU][pP]%]', '')
    str = str:gsub('%[/?[sS][uU][pP]%]', '')
    str = str:gsub('%[/?%-%]', '')
    str = str:gsub('%[/?[a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9]%]', '')
    return str
end

--Converts a color tint to a hex code
function tintToHex(objColor)
    hexColor = ''
    for i=1,3 do
        hex = ''
        dec = objColor[i] * 255
        hex = string.format( "%2.2X",math.floor(dec+0.5))
        hexColor = hexColor..hex
    end
    return hexColor
end
