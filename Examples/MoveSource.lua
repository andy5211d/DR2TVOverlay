-- An example from Bing AI !!


obs = obslua

function move_source(source_name, x, y)
    local source = obs.obs_get_source_by_name(source_name)
    if source ~= nil then
        local position = obs.vec2()
        position.x = x
        position.y = y
        obs.obs_source_set_pos(source, position)
        obs.obs_source_release(source)
    end
end

-- Called when the hotkey is pressed
function move_source_hotkey(pressed)
    if not pressed then
        return
    end

    -- Modify these values to suit your needs
    local source_name = "My Source"
    local x = 100
    local y = 200

    move_source(source_name, x, y)
end

-- Register the hotkey
hotkey_id = obs.obs_hotkey_register_frontend("move_source_hotkey", "Move Source", move_source_hotkey)

-- Bind the hotkey to a key combination (modify this to suit your needs)
obs.obs_hotkey_bind(hotkey_id, "shift+ctrl", false)


--[[

obs           = obslua
team1_score   = 0
instant_hotkey_id = obs.OBS_INVALID_HOTKEY_ID

function instant_replay()
    if not pressed then
      return
    end
    team1_score = team1_score + 1
    write_to_file("team1", team1_score)
end

function  write_to_file(file_name, value)
	local f = assert(io.open(script_path() .. file_name .. ".txt", "w"))
	f.write(f, value)
	f:close()
end

function script_save(settings)
	local instant_hotkey_save_array = obs.obs_hotkey_save(instant_hotkey_id)
	obs.obs_data_set_array(settings, "instant_replay.trigger", instant_hotkey_save_array)
	obs.obs_data_array_release(instant_hotkey_save_array)
end

function script_load(settings)
	instant_hotkey_id = obs.obs_hotkey_register_frontend("instant_replay.trigger", "Instant Replay", instant_replay)
	local instant_hotkey_save_array = obs.obs_data_get_array(settings, "instant_replay.trigger")
	obs.obs_hotkey_load(instant_hotkey_id, instant_hotkey_save_array)
	obs.obs_data_array_release(instant_hotkey_save_array)
end

function script_description()
	return "Write to a file on operation of a HotKey"
end





]]