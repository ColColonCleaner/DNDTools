local finishedLoading = false
function onSave()
    saved_data = JSON.encode({ssl=savedStatsList})
    return saved_data
end

function onload(saved_data)
    if saved_data ~= "" then
        local loaded_data = JSON.decode(saved_data)
        savedStatsList = loaded_data.ssl
        updateUI()
    else
        savedStatsList = {}
        updateText(player, 0, "xml_if_dex_mod")
        updateText(player, 0, "xml_if_ac_bonus")
    end

    finishedLoading = true
    calculateArmor()
end

function updateUI()
    for statKey, statValue in pairs(savedStatsList) do
        if (statKey:find("xml_tb_") == 1) then
            updateIsOn(nil, statValue, statKey)
        end
        if (statKey:find("xml_if_") == 1 or statKey:find("xml_dd_") == 1) then
            updateText(nil, statValue, statKey)
        end
    end
    calculateArmor()
end

function updateIsOn(player, value, id)
    self.UI.setAttribute(id, "isOn", value)
    savedStatsList[id] = value
    calculateArmor()
end

function updateText(player, value, id)
    self.UI.setAttribute(id, "text", value)
    --print("Setting text " .. id .. ": " .. value)
    savedStatsList[id] = value
    calculateArmor()
end

function calculateArmor()
    if (not finishedLoading) then
        return
    end
    -- Pull info from the UI to set save values
    local currentAC = 10
    local armorWeight = 0.0
    local mobilityImpairLimit = 999
    local mobilityImpairCount = 0
    local strengthRequirement = 0
    local heavyArmorCount = 0
    local statIncrease_stealth = 0
    local statIncrease_carry = 0
    local damageIncrease_unarmed = 0
    local damageReduction_falling = 0
    local damageReduction_melee = 0
    local damageReduction_blud = 0
    local damageReduction_cold = 0
    local damageReduction_chemical = 0
    local damageReduction_fire = 0
    local damageReduction_electric = 0
    local damageReduction_energy = 0
    local damageReduction_pierce = 0
    local damageReduction_poison = 0
    local damageReduction_radiation = 0
    local damageReduction_slash = 0
    local damageReduction_sonic = 0
    local damageReduction_explosion = 0
    local extraString = ""

    -- DEX Mod
    local dexMod = tonumber(savedStatsList["xml_if_dex_mod"])
    local dexACBonus = 0.0
    if (dexMod > 0) then
        dexACBonus = dexMod
    else
        currentAC = 10 - dexMod
    end
    -- AC Bonus
    local acBonus = tonumber(savedStatsList["xml_if_ac_bonus"])
    currentAC = currentAC + acBonus

    -- HELMET
    local helmetLight = savedStatsList["xml_tb_helmet_l"]
    local helmetHeavy = savedStatsList["xml_tb_helmet_h"]
    if (helmetLight == "True") then
        currentAC = currentAC + 1
        armorWeight = armorWeight + 4
    end
    if (helmetHeavy == "True") then
        currentAC = currentAC + 2
        heavyArmorCount = heavyArmorCount + 1
        armorWeight = armorWeight + 6
    end

    -- CHEST
    local curLight = savedStatsList["xml_tb_chest_l"]
    local curMedium = savedStatsList["xml_tb_chest_m"]
    local curHeavy = savedStatsList["xml_tb_chest_h"]
    local anyChest = false
    if (curLight == "True") then
        anyChest = true
        currentAC = currentAC + 1
        armorWeight = armorWeight + 3
    end
    if (curMedium == "True") then
        anyChest = true
        currentAC = currentAC + 3
        dexACBonus = dexACBonus - 1
        if (mobilityImpairLimit > 2) then
            mobilityImpairLimit = 2
        end
        mobilityImpairCount = mobilityImpairCount + 1
        armorWeight = armorWeight + 8
    end
    if (curHeavy == "True") then
        anyChest = true
        currentAC = currentAC + 4
        dexACBonus = dexACBonus - 2
        if (mobilityImpairLimit > 1) then
            mobilityImpairLimit = 1
        end
        mobilityImpairCount = mobilityImpairCount + 1
        if (strengthRequirement < 15) then
            strengthRequirement = 15
        end
        heavyArmorCount = heavyArmorCount + 1
        armorWeight = armorWeight + 16
    end
    if (anyChest) then
        -- MATERIAL
        local material = savedStatsList["xml_dd_chest_material"];
        if (material == "Asbestos Lined") then
            damageReduction_fire = damageReduction_fire + 1
            damageReduction_energy = damageReduction_energy + 1
        end
        if (material == "Heavy Build") then
            currentAC = currentAC + 1
            if (curLight == "True") then
                armorWeight = armorWeight + 0.5
            end
            if (curMedium == "True") then
                armorWeight = armorWeight + 1
            end
            if (curHeavy == "True") then
                armorWeight = armorWeight + 2
            end
        end
        if (material == "Lead Lined") then
            damageReduction_radiation = damageReduction_radiation + 1
        end
        if (material == "Light Build") then
            if (curLight == "True") then
                armorWeight = armorWeight - 0.5
            end
            if (curMedium == "True") then
                armorWeight = armorWeight - 1
            end
            if (curHeavy == "True") then
                armorWeight = armorWeight - 2
            end
        end
        if (material == "Non-Conducting") then
            damageReduction_electric = damageReduction_electric + 1
        end
        if (material == "Thermal Lined") then
            damageReduction_cold = damageReduction_cold + 1
        end
        if (material == "Toughened") then
            damageReduction_blud = damageReduction_blud + 1
        end

        -- MODIFICATIONS
        local modification = savedStatsList["xml_dd_chest_mod"];
        if (modification == "Dense") then
            damageReduction_explosion = damageReduction_explosion + 5
        end
        if (modification == "Spiked") then
            extraString = extraString .. "Grappled/Grappling creatures take 1d4 damage at the start of their turn. "
        end
        if (modification == "Hacking module (Robot)") then
            extraString = extraString .. "You are proficient in Hacking. "
        end
        if (modification == "Radiation Coils (Robot)") then
            extraString = extraString .. "You can activate/deactivate radiation coils as a bonus action, making adjacent creatures take 1d4 radiation damage at the start of their turns. "
        end
        if (modification == "Resistance Field (Robot)") then
            extraString = extraString .. "Allies within 15 feet of you reduce damage taken from attacks by 3. "
        end
        if (modification == "Sensor Array (Robot)") then
            extraString = extraString .. "You have advantage on Wisdom (Perception) checks. "
        end
        if (modification == "Stealth Assist Field (Robot)") then
            extraString = extraString .. "Allies within 15 feet of you increase their Dexterity (Stealth) check results by +2. "
        end
        if (modification == "Tesla Coils (Robot)") then
            extraString = extraString .. "You can activate/deactivate tesla coils as a bonus action, making adjacent creatures take 1d4 electrical damage at the start of their turns. "
        end
    end

    -- LEFT ARM
    local curLight = savedStatsList["xml_tb_leftarm_l"]
    local curMedium = savedStatsList["xml_tb_leftarm_m"]
    local curHeavy = savedStatsList["xml_tb_leftarm_h"]
    local anyLeftArm = false
    if (curLight == "True") then
        anyLeftArm = true
        currentAC = currentAC + 0.25
        armorWeight = armorWeight + 1.5
    end
    if (curMedium == "True") then
        anyLeftArm = true
        currentAC = currentAC + 0.5
        dexACBonus = dexACBonus - 0.5
        armorWeight = armorWeight + 4
    end
    if (curHeavy == "True") then
        anyLeftArm = true
        currentAC = currentAC + 1
        dexACBonus = dexACBonus - 1
        if (mobilityImpairLimit > 2) then
            mobilityImpairLimit = 2
        end
        mobilityImpairCount = mobilityImpairCount + 1
        if (strengthRequirement < 13) then
            strengthRequirement = 13
        end
        heavyArmorCount = heavyArmorCount + 1
        armorWeight = armorWeight + 8
    end
    if (anyLeftArm) then
        -- MATERIAL
        local material = savedStatsList["xml_dd_leftarm_material"];
        if (material == "Asbestos Lined") then
            damageReduction_fire = damageReduction_fire + 1
            damageReduction_energy = damageReduction_energy + 1
        end
        if (material == "Heavy Build") then
            if (curLight == "True") then
                currentAC = currentAC + 0.25
                armorWeight = armorWeight + 0.5
            end
            if (curMedium == "True") then
                currentAC = currentAC + 0.5
                armorWeight = armorWeight + 1
            end
            if (curHeavy == "True") then
                currentAC = currentAC + 0.5
                armorWeight = armorWeight + 2
            end
        end
        if (material == "Lead Lined") then
            damageReduction_radiation = damageReduction_radiation + 1
        end
        if (material == "Light Build") then
            if (curLight == "True") then
                armorWeight = armorWeight - 0.5
            end
            if (curMedium == "True") then
                armorWeight = armorWeight - 1
            end
            if (curHeavy == "True") then
                armorWeight = armorWeight - 2
            end
        end
        if (material == "Non-Conducting") then
            damageReduction_electric = damageReduction_electric + 1
        end
        if (material == "Thermal Lined") then
            damageReduction_cold = damageReduction_cold + 1
        end
        if (material == "Toughened") then
            damageReduction_blud = damageReduction_blud + 1
        end

        -- MODIFICATIONS
        local modification = savedStatsList["xml_dd_leftarm_mod"];
        if (modification == "Braced") then
            damageReduction_melee = damageReduction_melee + 3
        end
        if (modification == "Brawling") then
            damageIncrease_unarmed = damageIncrease_unarmed + 3
        end
        if (modification == "Grappling Hook" and not extraString:find("You can launch a grappling hook")) then
            extraString = extraString .. "You can launch a grappling hook as an action with 50ft of rope attached. "
        end
        if (modification == "Larceny Module" and not extraString:find("You are proficient in Lockpicking")) then
            extraString = extraString .. "You are proficient in Lockpicking, and always have a lockpick available. "
        end
    end

    -- RIGHT ARM
    local curLight = savedStatsList["xml_tb_rightarm_l"]
    local curMedium = savedStatsList["xml_tb_rightarm_m"]
    local curHeavy = savedStatsList["xml_tb_rightarm_h"]
    local anyLeftArm = false
    if (curLight == "True") then
        anyLeftArm = true
        currentAC = currentAC + 0.25
        armorWeight = armorWeight + 1.5
    end
    if (curMedium == "True") then
        anyLeftArm = true
        currentAC = currentAC + 0.5
        dexACBonus = dexACBonus - 0.5
        armorWeight = armorWeight + 4
    end
    if (curHeavy == "True") then
        anyLeftArm = true
        currentAC = currentAC + 1
        dexACBonus = dexACBonus - 1
        if (mobilityImpairLimit > 2) then
            mobilityImpairLimit = 2
        end
        mobilityImpairCount = mobilityImpairCount + 1
        if (strengthRequirement < 13) then
            strengthRequirement = 13
        end
        heavyArmorCount = heavyArmorCount + 1
        armorWeight = armorWeight + 8
    end
    if (anyLeftArm) then
        -- MATERIAL
        local material = savedStatsList["xml_dd_rightarm_material"];
        if (material == "Asbestos Lined") then
            damageReduction_fire = damageReduction_fire + 1
            damageReduction_energy = damageReduction_energy + 1
        end
        if (material == "Heavy Build") then
            if (curLight == "True") then
                currentAC = currentAC + 0.25
                armorWeight = armorWeight + 0.5
            end
            if (curMedium == "True") then
                currentAC = currentAC + 0.5
                armorWeight = armorWeight + 1
            end
            if (curHeavy == "True") then
                currentAC = currentAC + 0.5
                armorWeight = armorWeight + 2
            end
        end
        if (material == "Lead Lined") then
            damageReduction_radiation = damageReduction_radiation + 1
        end
        if (material == "Light Build") then
            if (curLight == "True") then
                armorWeight = armorWeight - 0.5
            end
            if (curMedium == "True") then
                armorWeight = armorWeight - 1
            end
            if (curHeavy == "True") then
                armorWeight = armorWeight - 2
            end
        end
        if (material == "Non-Conducting") then
            damageReduction_electric = damageReduction_electric + 1
        end
        if (material == "Thermal Lined") then
            damageReduction_cold = damageReduction_cold + 1
        end
        if (material == "Toughened") then
            damageReduction_blud = damageReduction_blud + 1
        end

        -- MODIFICATIONS
        local modification = savedStatsList["xml_dd_rightarm_mod"];
        if (modification == "Braced") then
            damageReduction_melee = damageReduction_melee + 3
        end
        if (modification == "Brawling") then
            damageIncrease_unarmed = damageIncrease_unarmed + 3
        end
        if (modification == "Grappling Hook" and not extraString:find("You can launch a grappling hook")) then
            extraString = extraString .. "You can launch a grappling hook as an action with 50ft of rope attached. "
        end
        if (modification == "Larceny Module" and not extraString:find("You are proficient in Lockpicking")) then
            extraString = extraString .. "You are proficient in Lockpicking, and always have a lockpick available. "
        end
    end

    -- LEFT LEG
    local curLight = savedStatsList["xml_tb_leftleg_l"]
    local curMedium = savedStatsList["xml_tb_leftleg_m"]
    local curHeavy = savedStatsList["xml_tb_leftleg_h"]
    local anyLeftArm = false
    if (curLight == "True") then
        anyLeftArm = true
        currentAC = currentAC + 0.25
        armorWeight = armorWeight + 1.5
    end
    if (curMedium == "True") then
        anyLeftArm = true
        currentAC = currentAC + 0.5
        dexACBonus = dexACBonus - 0.5
        armorWeight = armorWeight + 4
    end
    if (curHeavy == "True") then
        anyLeftArm = true
        currentAC = currentAC + 1
        dexACBonus = dexACBonus - 1
        if (mobilityImpairLimit > 2) then
            mobilityImpairLimit = 2
        end
        mobilityImpairCount = mobilityImpairCount + 1
        if (strengthRequirement < 13) then
            strengthRequirement = 13
        end
        heavyArmorCount = heavyArmorCount + 1
        armorWeight = armorWeight + 8
    end
    if (anyLeftArm) then
        -- MATERIAL
        local material = savedStatsList["xml_dd_leftleg_material"];
        if (material == "Asbestos Lined") then
            damageReduction_fire = damageReduction_fire + 1
            damageReduction_energy = damageReduction_energy + 1
        end
        if (material == "Heavy Build") then
            if (curLight == "True") then
                currentAC = currentAC + 0.25
                armorWeight = armorWeight + 0.5
            end
            if (curMedium == "True") then
                currentAC = currentAC + 0.5
                armorWeight = armorWeight + 1
            end
            if (curHeavy == "True") then
                currentAC = currentAC + 0.5
                armorWeight = armorWeight + 2
            end
        end
        if (material == "Lead Lined") then
            damageReduction_radiation = damageReduction_radiation + 1
        end
        if (material == "Light Build") then
            if (curLight == "True") then
                armorWeight = armorWeight - 0.5
            end
            if (curMedium == "True") then
                armorWeight = armorWeight - 1
            end
            if (curHeavy == "True") then
                armorWeight = armorWeight - 2
            end
        end
        if (material == "Non-Conducting") then
            damageReduction_electric = damageReduction_electric + 1
        end
        if (material == "Thermal Lined") then
            damageReduction_cold = damageReduction_cold + 1
        end
        if (material == "Toughened") then
            damageReduction_blud = damageReduction_blud + 1
        end

        -- MODIFICATIONS
        local modification = savedStatsList["xml_dd_leftleg_mod"];
        if (modification == "Cushioned") then
            damageReduction_falling = damageReduction_falling + 3
        end
        if (modification == "Muffled") then
            statIncrease_stealth = statIncrease_stealth + 2
        end
        if (modification == "Hydraulic Frame (Robot)") then
            statIncrease_carry = statIncrease_carry + 100
        end
        if (modification == "Robotic Legs (Robot)" and not extraString:find("You have Robotic Legs, see details on wiki.")) then
            extraString = extraString .. "You have Robotic Legs, see details on wiki. "
        end
        if (modification == "Thrusters (Robot)" and not extraString:find("You have Thrusters, see details on wiki.")) then
            extraString = extraString .. "You have Thrusters, see details on wiki. "
        end
        if (modification == "Treads (Robot)" and not extraString:find("You have Treads, see details on wiki.")) then
            extraString = extraString .. "You have Treads, see details on wiki. "
        end
    end

    -- RIGHT LEG
    local curLight = savedStatsList["xml_tb_rightleg_l"]
    local curMedium = savedStatsList["xml_tb_rightleg_m"]
    local curHeavy = savedStatsList["xml_tb_rightleg_h"]
    local anyLeftArm = false
    if (curLight == "True") then
        anyLeftArm = true
        currentAC = currentAC + 0.25
        armorWeight = armorWeight + 1.5
    end
    if (curMedium == "True") then
        anyLeftArm = true
        currentAC = currentAC + 0.5
        dexACBonus = dexACBonus - 0.5
        armorWeight = armorWeight + 4
    end
    if (curHeavy == "True") then
        anyLeftArm = true
        currentAC = currentAC + 1
        dexACBonus = dexACBonus - 1
        if (mobilityImpairLimit > 2) then
            mobilityImpairLimit = 2
        end
        mobilityImpairCount = mobilityImpairCount + 1
        if (strengthRequirement < 13) then
            strengthRequirement = 13
        end
        heavyArmorCount = heavyArmorCount + 1
        armorWeight = armorWeight + 8
    end
    if (anyLeftArm) then
        -- MATERIAL
        local material = savedStatsList["xml_dd_rightleg_material"];
        if (material == "Asbestos Lined") then
            damageReduction_fire = damageReduction_fire + 1
            damageReduction_energy = damageReduction_energy + 1
        end
        if (material == "Heavy Build") then
            if (curLight == "True") then
                currentAC = currentAC + 0.25
                armorWeight = armorWeight + 0.5
            end
            if (curMedium == "True") then
                currentAC = currentAC + 0.5
                armorWeight = armorWeight + 1
            end
            if (curHeavy == "True") then
                currentAC = currentAC + 0.5
                armorWeight = armorWeight + 2
            end
        end
        if (material == "Lead Lined") then
            damageReduction_radiation = damageReduction_radiation + 1
        end
        if (material == "Light Build") then
            if (curLight == "True") then
                armorWeight = armorWeight - 0.5
            end
            if (curMedium == "True") then
                armorWeight = armorWeight - 1
            end
            if (curHeavy == "True") then
                armorWeight = armorWeight - 2
            end
        end
        if (material == "Non-Conducting") then
            damageReduction_electric = damageReduction_electric + 1
        end
        if (material == "Thermal Lined") then
            damageReduction_cold = damageReduction_cold + 1
        end
        if (material == "Toughened") then
            damageReduction_blud = damageReduction_blud + 1
        end

        -- MODIFICATIONS
        local modification = savedStatsList["xml_dd_rightleg_mod"];
        if (modification == "Cushioned") then
            damageReduction_falling = damageReduction_falling + 3
        end
        if (modification == "Muffled") then
            statIncrease_stealth = statIncrease_stealth + 2
        end
        if (modification == "Hydraulic Frame (Robot)") then
            statIncrease_carry = statIncrease_carry + 100
        end
        if (modification == "Robotic Legs (Robot)" and not extraString:find("You have Robotic Legs, see details on wiki.")) then
            extraString = extraString .. "You have Robotic Legs, see details on wiki. "
        end
        if (modification == "Thrusters (Robot)" and not extraString:find("You have Thrusters, see details on wiki.")) then
            extraString = extraString .. "You have Thrusters, see details on wiki. "
        end
        if (modification == "Treads (Robot)" and not extraString:find("You have Treads, see details on wiki.")) then
            extraString = extraString .. "You have Treads, see details on wiki. "
        end
    end

    -- SHIELD
    local curShield = savedStatsList["xml_tb_shield"]
    if (curShield == "True") then
        armorWeight = armorWeight + 6
        currentAC = currentAC + 2
    end

    if (dexACBonus < 0) then
        dexACBonus = 0
    end
    -- Dex bonus gets REDUCED in whole numbers, so take the ceiling
    dexACBonus = math.ceil(dexACBonus)
    currentAC = currentAC + dexACBonus
    -- AC gets gets ADDED in whole numbers, so take the floor
    currentAC = math.floor(currentAC)
    self.UI.setAttribute("xml_text_armor_class", "text", "AC: " .. currentAC .. " Weight: " .. armorWeight)
    local extraStuff = ""
    if (statIncrease_carry > 0) then
        extraStuff = extraStuff .. "You have +" .. statIncrease_carry .. "lbs carry weight limit. "
    end
    if (statIncrease_stealth > 0) then
        extraStuff = extraStuff .. "You have +" .. statIncrease_stealth .. " on Dexterity (Stealth) checks. "
    end
    if (damageIncrease_unarmed > 0) then
        extraStuff = extraStuff .. "Your unarmed strikes deal +" .. damageIncrease_unarmed .. " damage. "
    end
    if (damageReduction_falling > 0) then
        extraStuff = extraStuff .. "Falling damage -" .. damageReduction_falling .. ". "
    end
    if (damageReduction_melee > 0) then
        extraStuff = extraStuff .. "Melee damage -" .. damageReduction_melee .. ". "
    end
    if (damageReduction_blud > 0) then
        extraStuff = extraStuff .. "Bludgeoning/Piercing/Slashing damage -" .. damageReduction_blud .. ". "
    end
    if (damageReduction_cold > 0) then
        extraStuff = extraStuff .. "Cold damage -" .. damageReduction_cold .. ". "
    end
    if (damageReduction_chemical > 0) then
        extraStuff = extraStuff .. "Chemical/Acid damage -" .. damageReduction_chemical .. ". "
    end
    if (damageReduction_fire > 0) then
        extraStuff = extraStuff .. "Fire damage -" .. damageReduction_fire .. ". "
    end
    if (damageReduction_electric > 0) then
        extraStuff = extraStuff .. "Electrical/Lightning damage -" .. damageReduction_electric .. ". "
    end
    if (damageReduction_energy > 0) then
        extraStuff = extraStuff .. "Energy/Radiant damage -" .. damageReduction_energy .. ". "
    end
    if (damageReduction_poison > 0) then
        extraStuff = extraStuff .. "Poison damage -" .. damageReduction_poison .. ". "
    end
    if (damageReduction_radiation > 0) then
        extraStuff = extraStuff .. "Radiation damage -" .. damageReduction_radiation .. ". "
    end
    if (damageReduction_sonic > 0) then
        extraStuff = extraStuff .. "Sonic/Thunder damage -" .. damageReduction_sonic .. ". "
    end
    if (damageReduction_explosion > 0) then
        extraStuff = extraStuff .. "Explosion damage -" .. damageReduction_explosion .. ". "
    end
    if (mobilityImpairCount >= mobilityImpairLimit) then
        extraStuff = extraStuff .. "Disadvantage on Dexterity checks, and Strength (Athletics) checks. "
    end
    extraStuff = extraStuff .. extraString
    self.UI.setAttribute("xml_text_extra_stuff", "text", extraStuff)
end