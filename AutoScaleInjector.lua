--[[LUAStart
className = "AutoScaledObject"
versionNumber = "1.0.0"
scaleMultiplierX = 1.0
scaleMultiplierY = 1.0
scaleMultiplierZ = 1.0
finishedLoading = false
debuggingEnabled = false
onUpdateTriggerCount = 0
onUpdateGridSize = 1.0

function onLoad(save_state)
    finishedLoading = true
end

function onUpdate()
    onUpdateTriggerCount = onUpdateTriggerCount + 1
    if onUpdateTriggerCount > 60 then
        onUpdateTriggerCount = 0
        if finishedLoading == true and onUpdateGridSize ~= Grid.sizeX then
            resetScale()
        end
    end
end

function reloadMini()
    self.reload()
end

function resetScale()
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
            if debuggingEnabled == true then
                print(self.getName() .. ": Stabilizing after rotation.")
            end
            stabilize()
        end
        Wait.condition(rotateFunc, rotateWatch)
    end
end

function onPickUp(pcolor)
    destabilize()
end

function onDrop(dcolor)
    stabilize()
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
LUAStop--lua]]

className = "AutoScaleInjector"
versionNumber = "1.0.0"
finishedLoading = false
debuggingEnabled = false
onUpdateTriggerCount = 0
onUpdateGridSize = 1.0
injectedFrameLimiter = 0
collisionProcessing = {}

function onLoad(script_state)

    finishedLoading = true
    self.setVar("finishedLoading", true)
    self.setName("Auto-Scale Injector " .. versionNumber)
end

function onCollisionEnter(collision_info)
    table.insert(collisionProcessing, collision_info)
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
                           objClassName ~= "MeasurementTool" and
                           objClassName ~= "AutoScaledObject" and
                           objClassName ~= "AutoScaleInjector" then
                               print("[00ff00]Locking scale[-] for " .. object.getName() .. ".")
                            injectToken(object)
                            injectedFrameLimiter = 60
                            break
                        end
                    elseif self.getRotationValue() == "[ff0000]REMOVE[-]" then
                        if object.getVar("className") == "AutoScaledObject" then
                            print("[ff0000]Removing[-] scale lock for " .. object.getName() .. ".")
                            object.script_state = ""
                            object.script_code = ""
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
end

function injectToken(object)
    local script = self.getLuaScript()
    local newScript = script:sub(script:find("LUAStart")+8, script:find("LUAStop")-1)
    currentScale = object.getScale()
    newScript = newScript:gsub("scaleMultiplierX = 1.0", "scaleMultiplierX = " .. (currentScale.x / Grid.sizeX))
    newScript = newScript:gsub("scaleMultiplierY = 1.0", "scaleMultiplierY = " .. (currentScale.y / Grid.sizeX))
    newScript = newScript:gsub("scaleMultiplierZ = 1.0", "scaleMultiplierZ = " .. (currentScale.z / Grid.sizeX))
    object.setLuaScript(newScript)
    object.reload()
end