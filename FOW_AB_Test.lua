AvailableQuads = nil
QuadTree = nil
GlobalLowerLeft = nil
GlobalUpperRight = nil
GlobalFlight = nil
ConstBorder = 0.02
ConstMinSize = 0.25
FOWScriptingZone = nil
Initialized = false
UpdateReady = false
UpdateFrameCounter = 0
UpdateProcessingActive = false

CoroutineTime = os.clock()
function conditionalYield()
    local clockCheck = os.clock()
    if clockCheck - CoroutineTime > 0.1 then
        coroutine.yield(0)
        CoroutineTime = clockCheck
    end
end

function onLoad()
    startLuaCoroutine(self, "initialize")
end

function onUpdate()
    if UpdateReady == false then
        if Initialized ~= true or FOWScriptingZone.getVar("Initialized") ~= true then
            return
        end
        UpdateReady = true
    end
    UpdateFrameCounter = UpdateFrameCounter + 1
    if UpdateFrameCounter > 5 then
        UpdateFrameCounter = 0
        if UpdateProcessingActive == false then
            startLuaCoroutine(self, "onUpdateProcessing")
        end
    end
end

function onUpdateProcessing()
    UpdateProcessingActive = true
    for _, obj in pairs(FOWScriptingZone.getObjects()) do
        revealQuadTree(QuadTree, obj.getPosition(), 5)
    end
    UpdateProcessingActive = false
    return 1
end

function revealQuadTree(qt, position, distance)
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
    if qt.quadObj ~= nil then
        pushAvailableQuad(qt.quadObj)
        qt.quadObj = nil
    end
    if qt ~= nil and qt.children ~= nil then
        freeQuadTreeNode(qt.children[1])
        freeQuadTreeNode(qt.children[2])
        freeQuadTreeNode(qt.children[3])
        freeQuadTreeNode(qt.children[4])
        qt.children = nil
    end
    qt.revealed = true
end

function initialize()
    local startTime = os.clock()

    initializeQuadList()

    local fogBounds = nil
    -- Figure out the fog bounds we need.
    local allObjects = getAllObjects()
    for _, obj in ipairs(allObjects) do
        if obj ~= self and obj ~= nil then
            if obj.getName() == "_OW_vBase" then
                fogBounds = obj.getBounds()
            elseif obj.getName() == "_OW_fows" then
                FOWScriptingZone = obj
            end
        end
    end
    if FOWScriptingZone == nil then
        print("Spawning FOW scripting zone!")
        FOWScriptingZone = spawnObject({
            type = "ScriptingTrigger",
            position = {0, 10, 0},
            rotation = {0, 0, 0},
            scale = {fogBounds.size.x, 20, fogBounds.size.z},
            sound = true,
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

    if fogBounds == nil then
        print("Can't find OneWorld panel!")
        return 1
    end
    -- Calculate new bounds
    GlobalFlight = fogBounds.center.y + (fogBounds.size.y/2) + 0.05
    GlobalLowerLeft = vector(fogBounds.center.x - (fogBounds.size.x/2), GlobalFlight, fogBounds.center.z - (fogBounds.size.z/2))
    GlobalUpperRight = vector(fogBounds.center.x + (fogBounds.size.x/2), GlobalFlight, fogBounds.center.z + (fogBounds.size.z/2))

    QuadTree = newQuadTree(1, GlobalLowerLeft.x, GlobalLowerLeft.z, fogBounds.size.x, fogBounds.size.z)

    local endTime = os.clock()
    --print("Modify: " .. (endTime - startTime))
    Initialized = true
    return 1
end

function initializeQuadList()
    -- Initialize available quads as a linked list
    -- The quads we want are inside the first child
    for _, inQuad in pairs(self.getChildren()[1].getChildren()) do
        local renderer = inQuad.getComponent("MeshRenderer")
        local transform = inQuad.getComponent("Transform")
        local newVal = {
            next = AvailableQuads,
            value = inQuad,
            show = function() renderer.set("enabled", true) end,
            hide = function() renderer.set("enabled", false) end,
            setPosition = function(position) transform.set("position", position) end,
            setScale = function(coverage) transform.set("localScale", coverage) end,
            renderer = renderer,
            transform = transform
        }
        AvailableQuads = newVal
        conditionalYield()
    end
end

function popAvailableQuad()
    local myQuad = AvailableQuads
    -- Move the list forward
    AvailableQuads = AvailableQuads.next
    return myQuad
end

function pushAvailableQuad(quad)
    quad.hide()
    quad.next = AvailableQuads
    AvailableQuads = quad
end

function newQuadTree(depth, left, bottom, width, height)
    local data = {
        depth = depth,
        left = left,
        right = left + width,
        bottom = bottom,
        top = bottom + height,
        width = width,
        height = height,
        quadObj = popAvailableQuad(),
        children = nil,
        revealed = false
    }
    data.quadObj.setPosition(vector(left+(width/2.0), GlobalFlight, bottom+(height/2.0)))
    data.quadObj.setScale(vector(width-ConstBorder, height-ConstBorder, 1))
    data.quadObj.show()
    conditionalYield()
    return data
end

function subdivideQuadTree(qt)
    if qt.children ~= nil then
        return true
    end
    if qt.quadObj == nil then
        -- This node has already been revealed
        return false
    end
    local w = qt.width/2.0
    local h = qt.height/2.0
    -- Don't allow subdividing below 0.05 size
    if w < ConstMinSize or h < ConstMinSize then
        return false
    end
    qt.children = {
        newQuadTree(qt.depth + 1, qt.left, qt.bottom, w, h),
        newQuadTree(qt.depth + 1, qt.left, qt.bottom+h, w, h),
        newQuadTree(qt.depth + 1, qt.left+w, qt.bottom, w, h),
        newQuadTree(qt.depth + 1, qt.left+w, qt.bottom+h, w, h)
    }
    pushAvailableQuad(qt.quadObj)
    qt.quadObj = nil
    conditionalYield()
    return true;
end