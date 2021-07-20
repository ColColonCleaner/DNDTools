
function onload(saved_data)
    self.clearButtons()
    self.createButton({
        label = "FoW",
        click_function = "buttonClick_spawnFOW",
        function_owner = self,
        position = {0,0.3,0},
        rotation = {0,180,0},
        height = 350,
        width = 800,
        font_size = 250,
        color = {0,0,0},
        font_color = {1,1,1}
    })
end

-- Handles clicks on the setup button
function buttonClick_spawnFOW()
    spawnObject({
        type = "FogOfWar",
        position = {0, 5.9, 0},
        rotation = {0, 90, 0},
        scale = {59, 10, 88.07},
        sound = true,
        callback_function = function(spawned_object)
            log(spawned_object.getBounds())
        end
    });
end