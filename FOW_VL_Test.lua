QuadTree = nil
GlobalBounds = nil
GlobalLowerLeft = nil
GlobalUpperRight = nil
GlobalFlight = nil
CoroutineYieldThreshold = 0.01
ConstBorder = 0.02
ConstMinSize = 0.25
FOWScriptingZone = nil
VectorHosts = {}
Initialized = false
UpdateReady = false
UpdateFrameCounter = 0
UpdateProcessingActive = false
ChangesMade = false
RevealerLocs = {}

function onLoad()
    startLuaCoroutine(self, "initialize")
end

function initialize()
    local startTime = os.clock()

    -- Figure out the fog bounds we need.
    local allObjects = getAllObjects()
    for _, obj in ipairs(allObjects) do
        if obj ~= self and obj ~= nil then
            local objName = obj.getName()
            if objName == "_OW_vBase" then
                GlobalBounds = obj.getBounds()
            elseif objName == "_OW_fows" then
                FOWScriptingZone = obj
            elseif string.match(objName, "_OW_fowvh") then
                --print("destroying " .. objName)
                obj.destruct()
            end
        end
    end

    if GlobalBounds == nil then
        print("OneWorld is not available! Unable to create fog.")
        return 1
    end

    if GlobalBounds.size.x < 10 then
        print("A OneWorld map is not deployed! Deploy a map first.")
        return 1
    end

    if FOWScriptingZone == nil then
        print("Spawning FOW scripting zone!")
        FOWScriptingZone = spawnObject({
            type = "ScriptingTrigger",
            position = {0, 10, 0},
            rotation = {0, 0, 0},
            scale = {GlobalBounds.size.x, 20, GlobalBounds.size.z},
            sound = false,
            callback_function = function(spawned_object)
                spawned_object.setName("_OW_fows")
                spawned_object.setTags({"FOWReveal"})
                spawned_object.setVar("Initialized", true)
            end
        })
    else
        FOWScriptingZone.setTags({"FOWReveal"})
        FOWScriptingZone.setVar("Initialized", true)
    end

    -- Calculate new bounds
    GlobalFlight = GlobalBounds.center.y + (GlobalBounds.size.y/2) + 0.05 + 20
    GlobalLowerLeft = vector(GlobalBounds.center.x - (GlobalBounds.size.x/2), GlobalFlight, GlobalBounds.center.z - (GlobalBounds.size.z/2))
    GlobalUpperRight = vector(GlobalBounds.center.x + (GlobalBounds.size.x/2), GlobalFlight, GlobalBounds.center.z + (GlobalBounds.size.z/2))

    local hostSizeX = GlobalBounds.size.x/4.0
    local hostSizeZ = GlobalBounds.size.z/4.0
    for x=0,3,1 do
        for z=0,3,1 do
            local hostName = "_OW_fowvh_"..x.."_"..z
            local hostName1 = "_OW_fowvh_"..x.."_"..z.."_1"
            local host1 = spawnObject({
                type = "BlockSquare",
                position = {0, -20, 0},
                rotation = {0, 0, 0},
                scale = {1,1,1},
                sound = false,
                callback_function = function(spawned_object)
                    spawned_object.setName(hostName1)
                    spawned_object.setLock(true);
                    spawned_object.setColorTint({0,0,0});
                    spawned_object.setVar("Initialized", true)
                end
            })
            local hostName2 = "_OW_fowvh_"..x.."_"..z.."_2"
            local host2 = spawnObject({
                type = "BlockSquare",
                position = {0, -20, 0},
                rotation = {0, 0, 0},
                scale = {1,1,1},
                sound = false,
                callback_function = function(spawned_object)
                    spawned_object.setName(hostName2)
                    spawned_object.setLock(true);
                    spawned_object.setColorTint({0,0,0});
                    spawned_object.setVar("Initialized", true)
                end
            })
            VectorHosts[hostName] = {
                hostName = hostName,
                activeHost = 1,
                host1 = host1,
                host2 = host2,
                left = GlobalLowerLeft.x + (x*hostSizeX),
                right = GlobalLowerLeft.x + (x*hostSizeX) + hostSizeX,
                bottom = GlobalLowerLeft.z + (z*hostSizeZ),
                top = GlobalLowerLeft.z + (z*hostSizeZ) + hostSizeZ,
                changed = false
            }
        end
    end

    QuadTree = newQuadTree(1, GlobalLowerLeft.x, GlobalLowerLeft.z, GlobalBounds.size.x, GlobalBounds.size.z)

    local endTime = os.clock()
    --print("Modify: " .. (endTime - startTime))
    Initialized = true
    return 1
end

function onUpdate()
    if UpdateReady == false then
        if Initialized ~= true or
           FOWScriptingZone.getVar("Initialized") ~= true then
            return
        end
        -- Check all the vector line hosts
        for hostName,vHost in ipairs(VectorHosts) do
            if vHost.host1.getVar("Initialized") ~= true or
               vHost.host2.getVar("Initialized") ~= true then
                return
            end
        end
        UpdateReady = true
        ChangesMade = true
        --print("changes true onUpdate")
        print("READY!")
    end
    UpdateFrameCounter = UpdateFrameCounter + 1
    if UpdateFrameCounter > 0 then
        UpdateFrameCounter = 0
        if UpdateProcessingActive == false then
            -- Check if objects have moved
            local moved = false
            for _, obj in pairs(FOWScriptingZone.getObjects()) do
                local pLoc = RevealerLocs[obj.getGUID()]
                local cLoc = obj.getPosition()
                if (pLoc == nil or pLoc.x ~= cLoc.x or pLoc.z ~= cLoc.z) then --obj.held_by_color == nil and
                    moved = true
                    --prinlt("processing " .. obj.getName())
                    RevealerLocs[obj.getGUID()] = cLoc
                end
            end
            if moved == true or ChangesMade == true then
                startLuaCoroutine(self, "onUpdateProcessing")
            end
        end
    end
end

function onUpdateProcessing()
    --if 1==1 then return 1 end
    UpdateProcessingActive = true
    for _, obj in pairs(FOWScriptingZone.getObjects()) do
        revealQuadTree(QuadTree, obj.getPosition(), 5)
    end
    if ChangesMade == false then
        UpdateProcessingActive = false
        return 1
    end
    refreshGrid()
    --print("Size: " .. getTreeSize())
    ChangesMade = false
    --print("changes false onUpdateProcessing")
    UpdateProcessingActive = false
    return 1
end

function revealQuadTree(qt, position, distance)
    --print("revealing " .. qt.depth)
    conditionalYield()

    if qt.revealed == true then
        return
    end

    -- Search quads in a depth-first fashion finding ones either partially or fully contained in the reveal distance
    local p_left = position.x - distance
    local p_right = position.x + distance
    local p_bottom = position.z - distance
    local p_top = position.z + distance

    -- If quad is fully contained by the bounding box, free all quads inside
    if qt.left > p_left and
       qt.right < p_right and
       qt.bottom > p_bottom and
       qt.top < p_top then
        freeQuadTreeNode(qt)
        return
    end
    -- If quad is partially contained by the bounding box, check its children, subdividing if necessary
    if qt.right < p_left or
       qt.left > p_right or
       qt.top < p_bottom or
       qt.bottom > p_top then
        -- The two boxes do not overlap
        return
    end
    if subdivideQuadTree(qt) == true then
        revealQuadTree(qt.children[1], position, distance)
        revealQuadTree(qt.children[2], position, distance)
        revealQuadTree(qt.children[3], position, distance)
        revealQuadTree(qt.children[4], position, distance)
    end
end

-- Doesn't do any extra calculations, just frees the nodes contained
function freeQuadTreeNode(qt)
    --print("Freeing Depth: " .. qt.depth)
    if qt ~= nil and qt.children ~= nil then
        freeQuadTreeNode(qt.children[1])
        freeQuadTreeNode(qt.children[2])
        freeQuadTreeNode(qt.children[3])
        freeQuadTreeNode(qt.children[4])
        qt.children = nil
    end
    qt.revealed = true
    qt.host.changed = true
    ChangesMade = true
    --print("changes true freeQuadTreeNode")
end

function getTreeSize()
    local currentSize = 0
    return sizeHelper(QuadTree, currentSize)
end
function sizeHelper(qt, currentSize)
    currentSize = currentSize + 1
    if qt.children ~= nil then
        currentSize = sizeHelper(qt.children[1], currentSize)
        currentSize = sizeHelper(qt.children[2], currentSize)
        currentSize = sizeHelper(qt.children[3], currentSize)
        currentSize = sizeHelper(qt.children[4], currentSize)
    end
    return currentSize
end

function refreshGrid()
    local hostsObjectsToClear = {}
    -- Get vector hosts which have changed and update them
    for hostName, vHost in pairs(VectorHosts) do
        if vHost.changed == true then
            -- Get all lines which belong to this host
            local newVectorLines = {}
            newVectorLines = getLinesForHost(QuadTree, vHost, newVectorLines)
            if vHost.activeHost == 1 then
                vHost.host2.setVectorLines(newVectorLines)
                table.insert(hostsObjectsToClear, vHost.host1)
                vHost.activeHost = 2
            else
                vHost.host1.setVectorLines(newVectorLines)
                table.insert(hostsObjectsToClear, vHost.host2)
                vHost.activeHost = 1
            end
            --print(hostName .. " changed. " .. #newVectorLines .. " lines, obj " .. vHost.activeHost)
            vHost.changed = false
            conditionalYield()
        end
    end
    -- process hosts which need to be cleared
    -- this has to be done at the end to avoid flickering
    for _, hostObj in pairs(hostsObjectsToClear) do
        hostObj.setVectorLines({})
        conditionalYield()
    end
end

function getLinesForHost(qt, host, resultList)
    if qt.revealed == true then
        return resultList
    end
    if qt.children ~= nil then
        resultList = getLinesForHost(qt.children[1], host, resultList)
        resultList = getLinesForHost(qt.children[2], host, resultList)
        resultList = getLinesForHost(qt.children[3], host, resultList)
        resultList = getLinesForHost(qt.children[4], host, resultList)
        conditionalYield()
    elseif qt.host == host then
        table.insert(resultList, qt.lineData)
    end
    return resultList
end

function newQuadTree(depth, left, bottom, width, height)
    -- Find the vector host that will contain this quad
    local myHost = nil
    for hostName, vHost in pairs(VectorHosts) do
        if vHost.left <= left and vHost.right > left and vHost.bottom <= bottom and vHost.top > bottom then
            myHost = vHost
            --print("Picked host " .. vHost.hostName)
            break
        end
    end
    if myHost == nil then
        print("Could not find valid host for quad!")
        return
    end
    myHost.changed = true
    ChangesMade = true
    --print("changes true newQuadTree")
    local data = {
        depth = depth,
        left = left,
        right = left + width,
        bottom = bottom,
        top = bottom + height,
        width = width,
        height = height,
        children = nil,
        lineData = {
            points    = { {left + ConstBorder, GlobalFlight, bottom + (height/2.0)}, {left + width - ConstBorder, GlobalFlight, bottom + (height/2.0)}},
            color     = {0,0,0},
            thickness = height - (ConstBorder*2),
            rotation  = {0,0,0},
            square=true
        },
        revealed = false,
        host = myHost
    }
    return data
end

function subdivideQuadTree(qt)
    if qt.children ~= nil then
        return true
    end
    if qt.revealed == true then
        return false
    end
    local w = qt.width/2.0
    local h = qt.height/2.0
    -- Don't allow subdividing below 0.05 size
    if w < ConstMinSize or h < ConstMinSize then
        return false
    end
    --print("subdividing " .. qt.depth)
    qt.children = {
        newQuadTree(qt.depth + 1, qt.left, qt.bottom, w, h),
        newQuadTree(qt.depth + 1, qt.left, qt.bottom+h, w, h),
        newQuadTree(qt.depth + 1, qt.left+w, qt.bottom, w, h),
        newQuadTree(qt.depth + 1, qt.left+w, qt.bottom+h, w, h)
    }
    conditionalYield()
    return true;
end

CoroutineTime = os.clock()
function conditionalYield()
    local clockCheck = os.clock()
    if clockCheck - CoroutineTime > CoroutineYieldThreshold then
        coroutine.yield(0)
        CoroutineTime = clockCheck
    end
end