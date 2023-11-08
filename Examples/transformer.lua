--[[
    OBS-TRANSFORMER
    v1.1
    A script for Open Broadcaster Software that lets you transform dimensions,
    rotation and position of a source (or group) while applying an easing
    function to the transformation.

    Copyright (C) 2019 Bernat Romagosa i Carrasquer and MunFilms
    bernat@romagosa.work
    info@munfilms.com

    https://github.com/bromagosa/obs-transformer

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]--

local obs = obslua
local active = false
local triggerOnRecord = false
local origin = {}
local destination = {}
local effect = {
    remaining_delay = 0,
    elapsed_time = 0 }
local source_name = ''
local sceneItem = nil
local hotkey_id = obs.OBS_INVALID_HOTKEY_ID

--
-- Utility functions based on @MacTartan's HotKeyRotate.lua
--

local function currentSceneName()
    local src = obs.obs_frontend_get_current_scene()
    local name = obs.obs_source_get_name(src)
    obs.obs_source_release(src)
    return name
end

local function findSceneItem()
    local src = obs.obs_get_source_by_name(currentSceneName())
    if src then
        local scene = obs.obs_scene_from_source(src)
        obs.obs_source_release(src)
        if scene then
            sceneItem = obs.obs_scene_find_source(scene, source_name)
            return true
        end
    end
end


--
-- OBS Script Overrides
--
function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_int(
        props, 'origin x', 'Origin x:', -100000, 100000, 1)
    obs.obs_properties_add_int(
        props, 'origin y', 'Origin y:', -100000, 100000, 1)

    obs.obs_properties_add_int(
        props, 'destination x', 'Destination x:', -100000, 100000, 1)
    obs.obs_properties_add_int(
        props, 'destination y', 'Destination y:', -100000, 100000, 1)

    obs.obs_properties_add_int(
        props, 'origin width', 'Origin width:', 0, 100000, 1)
    obs.obs_properties_add_int(
        props, 'origin height', 'Origin height:', 0, 100000, 1)

    obs.obs_properties_add_int(
        props, 'destination width', 'Destination width:', 0, 100000, 1)
    obs.obs_properties_add_int(
        props, 'destination height', 'Destination height:', 0, 100000, 1)

    obs.obs_properties_add_int(
        props, 'origin rotation', 'Origin rotation:', -360, 360, 1)
    obs.obs_properties_add_int(
        props, 'destination rotation', 'Destination rotation:',
            -100000, 100000, 1)

    obs.obs_properties_add_float(
        props, 'duration', 'Duration (seconds):', 0, 100000, 1)

    obs.obs_properties_add_float(
        props, 'delay', 'Start delay (seconds):', 0, 100000, 1)

    local effects =
        obs.obs_properties_add_list(
            props,
            'easing',
            'Easing function',
            obs.OBS_COMBO_TYPE_LIST,
            obs.OBS_COMBO_FORMAT_STRING)

    obs.obs_property_list_add_string(effects, '- Basic -', '---')
    obs.obs_property_list_item_disable(effects, 0, true)

    obs.obs_property_list_add_string(effects, 'Linear', 'linear')
    obs.obs_property_list_add_string(effects, 'Cut', 'cut')

    obs.obs_property_list_add_string(effects, '- Quadratic -', '---')
    obs.obs_property_list_item_disable(effects, 3, true)

    obs.obs_property_list_add_string(effects, 'Ease-in-quad', 'ease-in-quad')
    obs.obs_property_list_add_string(effects, 'Ease-out-quad', 'ease-out-quad')
    obs.obs_property_list_add_string(
        effects, 'Ease-in-out-quad', 'ease-in-out-quad')
    obs.obs_property_list_add_string(
        effects, 'Ease-out-in-quad', 'ease-out-in-quad')

    obs.obs_property_list_add_string(effects, '- Sine -', '---')
    obs.obs_property_list_item_disable(effects, 8, true)

    obs.obs_property_list_add_string(effects, 'Ease-in-sin', 'ease-in-sin')
    obs.obs_property_list_add_string(effects, 'Ease-out-sin', 'ease-out-sin')
    obs.obs_property_list_add_string(
        effects, 'Ease-in-out-sin', 'ease-in-out-sin')
    obs.obs_property_list_add_string(
        effects, 'Ease-out-in-sin', 'ease-out-in-sin')

    obs.obs_property_list_add_string(effects, '- Exponential -', '---')
    obs.obs_property_list_item_disable(effects, 13, true)

    obs.obs_property_list_add_string(effects, 'Ease-in-exp', 'ease-in-exp')
    obs.obs_property_list_add_string(effects, 'Ease-out-exp', 'ease-out-exp')
    obs.obs_property_list_add_string(
        effects, 'Ease-in-out-exp', 'ease-in-out-exp')
    obs.obs_property_list_add_string(
        effects, 'Ease-out-in-exp', 'ease-out-in-exp')

    obs.obs_property_list_add_string(effects, '- Bounce -', '---')
    obs.obs_property_list_item_disable(effects, 18, true)

    obs.obs_property_list_add_string(
        effects, 'Ease-in-bounce', 'ease-in-bounce')
    obs.obs_property_list_add_string(
        effects, 'Ease-out-bounce', 'ease-out-bounce')
    obs.obs_property_list_add_string(
        effects, 'Ease-in-out-bounce', 'ease-in-out-bounce')
    obs.obs_property_list_add_string(
        effects, 'Ease-out-in-bounce', 'ease-out-in-bounce')

    obs.obs_property_list_add_string(effects, '- Cubic -', '---')
    obs.obs_property_list_item_disable(effects, 23, true)

    obs.obs_property_list_add_string(
        effects, 'Ease-in-cubic', 'ease-in-cubic')
    obs.obs_property_list_add_string(
        effects, 'Ease-out-cubic', 'ease-out-cubic')
    obs.obs_property_list_add_string(
        effects, 'Ease-in-out-cubic', 'ease-in-out-cubic')
    obs.obs_property_list_add_string(
        effects, 'Ease-out-in-cubic', 'ease-out-in-cubic')

    local p =
        obs.obs_properties_add_list(
            props,
            'source',
            'Source',
            obs.OBS_COMBO_TYPE_EDITABLE,
            obs.OBS_COMBO_FORMAT_STRING)
    local sources = obs.obs_enum_sources()
    if sources then
        for _, source in ipairs(sources) do
            local name = obs.obs_source_get_name(source)
            obs.obs_property_list_add_string(p, name, name)
        end
    end
    obs.source_list_release(sources)

    obs.obs_properties_add_bool(props, 'trigger-on-record', 'Trigger on record')

    obs.obs_properties_add_button(props, 'button', 'Do it!', trigger)
    return props
end

function script_description()
    return 'Transform dimensions, rotation and position of a source ' ..
            '(or group) while applying an easing function to the ' ..
            'transformation. \n\n' ..
            'You can either assign a hotkey to trigger the transformation ' ..
            'or click on the "Do it!" button.\n\n' ..
            'By Bernat Romagosa & Mun Films 2019'
end

function script_update(settings)
    source_name = obs.obs_data_get_string(settings, 'source')

    origin.rot = obs.obs_data_get_int(settings, 'origin rotation')
    origin.pos = obs.vec2()
    obs.vec2_set(
        origin.pos,
        obs.obs_data_get_int(settings, 'origin x'),
        obs.obs_data_get_int(settings, 'origin y'))
    origin.bounds = obs.vec2()
    obs.vec2_set(
        origin.bounds,
        obs.obs_data_get_int(settings, 'origin width'),
        obs.obs_data_get_int(settings, 'origin height'))

    destination.pos = obs.vec2()
    destination.rot = obs.obs_data_get_int(settings, 'destination rotation')
    obs.vec2_set(
        destination.pos,
        obs.obs_data_get_int(settings, 'destination x'),
        obs.obs_data_get_int(settings, 'destination y'))
    destination.bounds = obs.vec2()
    obs.vec2_set(
        destination.bounds,
        obs.obs_data_get_int(settings, 'destination width'),
        obs.obs_data_get_int(settings, 'destination height'))

    effect.duration = obs.obs_data_get_double(settings, 'duration')
    effect.delay = obs.obs_data_get_double(settings, 'delay')
    effect.easing = obs.obs_data_get_string(settings, 'easing')

    triggerOnRecord = obs.obs_data_get_bool(settings, 'trigger-on-record')

    findSceneItem()
end

function script_save(settings)
    local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
    obs.obs_data_set_array(settings, 'trigger_hotkey', hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)
end

function script_load(settings)
    hotkey_id = obs.obs_hotkey_register_frontend(
        'trigger_transformer', 'Trigger Transformer', trigger)
    local hotkey_save_array = obs.obs_data_get_array(settings, 'trigger_hotkey')
    obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)
    obs.obs_frontend_add_event_callback(on_event)
end

function on_event(event)
    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
        if triggerOnRecord then
            trigger(true)
        end
    end
end

function script_tick(seconds)
    if (active) then
        effect.remaining_delay = effect.remaining_delay - seconds
        if (effect.remaining_delay <= 0) then
            effect.elapsed_time = effect.elapsed_time + seconds
            obs.obs_sceneitem_set_rot(sceneItem, get_new_scalar('rot', seconds))
            obs.obs_sceneitem_set_pos(sceneItem, get_new_vector('pos', seconds))
            obs.obs_sceneitem_set_bounds(
            sceneItem,
            get_new_vector('bounds', seconds))
            if (effect.elapsed_time >= effect.duration) then
                active = false
                effect.elapsed_time = 0
                obs.obs_sceneitem_set_rot(sceneItem, destination.rot)
                obs.obs_sceneitem_set_pos(sceneItem, destination.pos)
                obs.obs_sceneitem_set_bounds(sceneItem, destination.bounds)
            end
        end
    end
end


--
-- Transformer Code
--

function trigger(pressed)
    if not pressed then return end
    if not sceneItem then findSceneItem() end
    if sceneItem then
        obs.obs_sceneitem_set_rot(sceneItem, origin.rot)
        obs.obs_sceneitem_set_pos(sceneItem, origin.pos)
        obs.obs_sceneitem_set_bounds_type(sceneItem, obs.OBS_BOUNDS_STRETCH)
        obs.obs_sceneitem_set_bounds(sceneItem, origin.bounds)
        effect.elapsed_time = 0
        effect.remaining_delay = effect.delay
        active = true
    end
end

function easing(function_name, time, change, initial_value)
    if function_name == 'linear' then
        return change * time / effect.duration + initial_value
    elseif function_name == 'cut' then
        return 0

    -- Easing functions based on @EmmanuelOga's easing.lua
    -- https://github.com/EmmanuelOga/easing/blob/master/lib/easing.lua

    -- QUADRATIC --
    elseif function_name == 'ease-in-quad' then
        time = time / effect.duration
        return change * math.pow(time, 2) + initial_value
    elseif function_name == 'ease-out-quad' then
        time = time / effect.duration
        return - change * time * (time - 2) + initial_value
    elseif function_name == 'ease-in-out-quad' then
        time = time / effect.duration * 2
        if time < 1 then
            return change / 2 * math.pow(time, 2) + initial_value
        else
            return -change / 2 * ((time - 1) * (time - 3) - 1) + initial_value
        end
    elseif function_name == 'ease-out-in-quad' then
        if time < effect.duration / 2 then
            return easing('ease-out-quad', time * 2, change / 2, initial_value)
        else
            return easing(
                'ease-in-quad',
                (time * 2) - effect.duration,
                change / 2,
                initial_value + change / 2)
        end

    -- SINE --
    elseif function_name == 'ease-in-sin' then
        return -change * math.cos(time / effect.duration * (math.pi / 2)) +
                change + initial_value
    elseif function_name == 'ease-out-sin' then
        return change * math.sin(time / effect.duration * (math.pi / 2)) +
            initial_value
    elseif function_name == 'ease-in-out-sin' then
        return -change / 2 * (math.cos(math.pi * time / effect.duration) - 1) +
            initial_value
    elseif function_name == 'ease-out-in-sin' then
        if time < effect.duration / 2 then
            return easing('ease-out-sin', time * 2, change / 2, initial_value)
        else
            return easing(
                'ease-in-sin',
                (time * 2) - effect.duration,
                change / 2,
                initial_value + change / 2)
        end

    -- CUBIC --
    elseif function_name == 'ease-in-cubic' then
        time = time / effect.duration
        return change * math.pow(time, 3) + initial_value
    elseif function_name == 'ease-out-cubic' then
        time = time / effect.duration - 1
        return change * (math.pow(time, 3) + 1) + initial_value
    elseif function_name == 'ease-in-out-cubic' then
        time = time / effect.duration * 2
        if time < 1 then
            return change / 2 * time * time * time + initial_value
        else
            time = time - 2
            return change / 2 * (time * time * time + 2) + initial_value
        end
    elseif function_name == 'ease-out-in-cubic' then
        if time < effect.duration / 2 then
            return easing('ease-out-cubic', time * 2, change / 2, initial_value)
        else
            return easing(
                'ease-in-cubic',
                (time * 2) - effect.duration,
                change / 2,
                initial_value + change / 2)
        end

    -- EXPONENTIAL --
    elseif function_name == 'ease-in-exp' then
        if time == 0 then
            return initial_value
        else
            return change * math.pow(2, 10 * (time / effect.duration - 1)) +
                initial_value - change * 0.001
        end
    elseif function_name == 'ease-out-exp' then
        if time == effect.duration then
            return initial_value + change
        else
            return change * 1.001 *
                (-math.pow(2, -10 * time / effect.duration) + 1) + initial_value
        end
    elseif function_name == 'ease-in-out-exp' then
        if time == 0 then return initial_value end
        if time == effect.duration then return initial_value + change end
        time = time / effect.duration * 2
        if time < 1 then
            return change / 2 * math.pow(2, 10 * (time - 1)) +
                initial_value - change * 0.0005
        else
            time = time - 1
            return change / 2 * 1.0005 * (-math.pow(2, -10 * time) + 2) +
                initial_value
        end
    elseif function_name == 'ease-out-in-exp' then
        if time < effect.duration / 2 then
            return easing('ease-out-exp', time * 2, change / 2, initial_value)
        else
            return easing(
                'ease-in-exp',
                (time * 2) - effect.duration,
                change / 2,
                initial_value + change / 2)
        end

    -- BOUNCE --
    elseif function_name == 'ease-out-bounce' then
        time = time / effect.duration
        if time < 1 / 2.75 then
            return change * (7.5625 * time * time) + initial_value
        elseif time < 2 / 2.75 then
            time = time - (1.5 / 2.75)
            return change * (7.5625 * time * time + 0.75) + initial_value
        elseif time < 2.5 / 2.75 then
            time = time - (2.25 / 2.75)
            return change * (7.5625 * time * time + 0.9375) + initial_value
        else
            time = time - (2.625 / 2.75)
            return change * (7.5625 * time * time + 0.984375) + initial_value
        end
    elseif function_name == 'ease-in-bounce' then
        return change -
            easing('ease-out-bounce', effect.duration - time, change, 0) +
            initial_value
    elseif function_name == 'ease-in-out-bounce' then
        if time < effect.duration / 2 then
            return easing('ease-in-bounce', time * 2, change, 0) * 0.5 +
                initial_value
        else
            return easing(
                'ease-out-bounce',
                time * 2 - effect.duration,
                change,
                0) * 0.5 + change * .5 + initial_value
        end
    elseif function_name == 'ease-out-in-bounce' then
        if time < effect.duration / 2 then
            return easing(
                'ease-out-bounce',
                time * 2,
                change / 2,
                initial_value)
        else
            return easing(
                'ease-in-bounce',
                (time * 2) - effect.duration,
                change / 2,
                initial_value + change / 2)
        end
    end
end

function get_new_scalar(scalar_name)
    return easing(
        effect.easing,
        effect.elapsed_time,
        destination[scalar_name] - origin[scalar_name],
        origin[scalar_name])
end

function get_new_vector(vector_name)
    local delta = obs.vec2()

    obs.vec2_set(
        delta,
        easing(
            effect.easing,
            effect.elapsed_time,
            destination[vector_name].x - origin[vector_name].x,
            origin[vector_name].x),
        easing(
            effect.easing,
            effect.elapsed_time,
            destination[vector_name].y - origin[vector_name].y,
            origin[vector_name].y))

    return delta
end