--[[
Open Broadcaster Software

OBS > Tools > Scripts

OBS Lua Script - DR2TVOverlay

Provides a number of OBS-Studio Text(GDI+) Sources which displays the event information from DiveRecorder (DR) onto the event video stream.  Uses the data provided by DR's 
DR2Video software.  Automatically checks for the *Update files and if detected displays the new information.   Has the capability to automatically hide the dive 
information banner and re-display it when DR file changes detected.  Works for both Individual events and Synchro events and a vairable number of judges.  May get updated someday to work for simultanious events (A & B) as DR2Video has this capability but never likley to be updated for a skills circuit! 

  V2.0.0  2022-04-08  Video overlay changed to be two seperate overlays, event info and dive data.   Event info on overlay and perminately displayed at the top and dive description or awards for the main overlay

*** Things of note ***
1. Need to select 'Synchro Event' in script setting for this to work correctly.  In theory as we have two Update files (Individual and Synchro) the script could select 
   appropoate way of working automatically (but too many courner cases to work reliabely so not implemented).
2. For those happy to modify this script, change the file location example to one related to your log-in ID.  Else need to be selected all four file location on each
   script update!
3. For initial configuration it is usefull to be able to generate the two Update text files so that their Windows location can be selected in the scripts user settings. There
   is a Windows .exe file to do this in the repository.
4. TVBanner = TVOverlay
5. Need to implement a few function keys (HotKeys) so as to provide user capability to remove overlay and to select 'Synchro event'.  May also use a few for message displays and
   perhaps a countdown timer to next event, etc.

  The position of data elements in the Dive/Synchro.txt file from DR2Video.
  In Dive/Synchro there are two lines of text in these DR files. First line of the DR file (which would be split_string1[n]) is headers and not generated or used by this script.
  The second line becomes split_string2[n] and get processed and displayed as the video overlay. 
  
      Name:            split_string2[1]
      Team:            split_string2[2]
      Dive:            split_string2[3]
      Position:        split_string2[4]
      Board:           split_string2[5]
      DD:              split_string2[6]
      DiveDescription: split_string2[7]
      J1:   E1:  E1:   split_string2[8]
      J2:   E2:  E2:   split_string2[9]
      J3:   E3:  E3:   split_string2[10]
      J4:   E4:  E4:   split_string2[11]
      J5:   E5:        split_string2[12]
      J6:   E6:        split_string2[13]
      J7:   S1:  S1:   split_string2[14]
      J8:   S2:  S2:   split_string2[15]
      J9:   S3:  S3:   split_string2[16]
      J10:  S4:  S4:   split_string2[17]
      J11:  S5:  S5:   split_string2[18]
      Score:           split_string2[19]
      Total:           split_string2[20]
      Rank:            split_string2[21]
      Flag File:       split_string2[22]
      Start No:        split_string2[23]
      Round:           split_string2[24]
      Event Title:     split_string2[25]
      Team Name:       split_string2[26]
      No Rounds:       split_string2[27]
      No Divers:       split_string2[28]
--]]

local obs = obslua
local textFile, textFileI, textFileS  -- textfile = the text file to be processed.  textFileI = the Individual event text file name (and file location) to be checked, then read into textFile.  Simmulary textFileS the Synchro event text file
local textFileDI  -- DR dummy text file to act as new data trigger for individual events
local textFileSI  -- DR dummy text file to act as new data trigger for synchro events
local eventComplete = false -- To help determine when ranking is to be displayed
local interval = 1000  -- interval(ms) = time between update file checks.
local dinterval, debug  -- dinterval = time to display the TV overlay after update. debug = turn debug information display in Log on or off
local activeId = 0 -- active file check id's
local current = {} -- current user values to compare with next user update.  Not used (I think!), left over from original 'textmonitor.lua' script

local source = obs.obs_get_source_by_name("TVBanner") -- disable TVBanner source group
-- Why just TVBanner, what about the other text sources? Is this needed?
if source ~= nil then
    obs.obs_source_set_enabled(source, false)
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("**Random Disable_source: " .. "TVBanner "))
    end
end
obs.obs_source_release(source)

-- called when an update to the DR text file is detected.  Process DR data in the file then display and for a user determined period if Overlay hide option not disabled.
local function update(k, v)
    -- first line of data(k) in the DR text file not used --
    if v then -- Is second line of data(v) present? Just checking again!
        local result = {} -- empty array where we will store data from the DR2Video text files
        local delimiter = ("|") -- DR text string delimiter chr, likly be a "," if user has not changed DR2Video defaults
        for match in (line2 .. delimiter):gmatch("(.-)" .. delimiter) do -- fill the array
            table.insert(result, match)
        end
        split_string2 = result -- generates an array with 28 entries from line 2 of the DR text file (line 1 which is headers not used)
        split_string2[28] = string.sub(split_string2[28], 1, -2) -- CR present at end of each DR text line so remove from the last field [28] else Lua gets upset when displaying the last field
    end
    if split_string2[21] == ("") then 
      split_string2[21] = (" ")
      obs.script_log(obs.LOG_INFO, string.format("Nul detected in Rank "))
    end
    eventComplete = false
    
    local source = obs.obs_get_source_by_name("TVBanner2") -- enable text Source (TVBanner group) for display of dive/awards
    if source ~= nil then
        obs.obs_source_set_enabled(source, true)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Enable_source at start of update(): " .. "TVBanner2 "))
        end
    end
    obs.obs_source_release(source)
    local source = obs.obs_get_source_by_name("Event") -- enable text Source (Event group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, true)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Enable_source at start of update(): " .. "Event "))
        end
    end
    obs.obs_source_release(source)

    -- first generate empty text display lines
    lineOne = ("                                                  ") -- set overlay display text line 1 to 50 spaces
    lineTwo = ("                                                  ") -- set overlay display text line 2 to 50 spaces
    tvBanner_removed = false -- as we are about to display dive data or awards!

    -- now produce the event information display
    local event_info = (" " .. split_string2[25] .. " \n Diver " .. split_string2[23] .. "/" .. split_string2[28] .. "  Round " .. split_string2[24] .. "/" .. split_string2[27] .. " ")
    local source = obs.obs_get_source_by_name("EventData") -- Generate event data
    if source ~= nil then
    local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", event_info)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end

    -- now generate lineone of the overlay, the Divers information, preceded by rank
    display1a = (" " .. split_string2[21] .. " ")
    lineOne = string.insert(lineOne, display1a, 0)
    displayName = (split_string2[1] .. " -- " .. split_string2[2]) -- display divers rank, name and club
    lineOne = string.insert(lineOne, displayName, 5)
    display1b = (" ") 
    
    scores1 = split_string2[20]

    -- now generate the rest of the text displays
    --                  >>>> *** If a Synchro event then *** <<<<<
    if synchro then
        if split_string2[8] ~= (" ") then -- if awards in J1 field then display them
            sourcelineTwo = " " -- Empty string so nothing displayed and debug works correctly
            local source = obs.obs_get_source_by_name("JudgeAwards") -- Enable awards Text Source group (else 11 individual text boxes to enable!)
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "Synchro JudgeAwards "))
                end
            end
            obs.obs_source_release(source)
            if split_string2[12] ~= (" ") then -- if award in J5 then 11 synchro judges (labels are different to 9 judges!)
                local source = obs.obs_get_source_by_name("SynchroJLabels9")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, false)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels9 "))
                    end
                end
                obs.obs_source_release(source) 
                local source = obs.obs_get_source_by_name("SynchroJLabels11")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, true)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "SynchroJLabels11 "))
                    end
                end
                obs.obs_source_release(source)
          
                -- place awards into their respective text Sources
                local source = obs.obs_get_source_by_name("J1") -- Judge E1 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[8])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J2") -- Judge E2 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[9])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J3") -- Judge E3 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[10])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J4") -- Judge E4 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[11])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J5") -- Judge E5 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[12])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J6") -- Judge E6 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[13])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J7") -- Judge S1 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[14])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J8") -- Judge S2 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[15])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J9") -- Judge S3 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[16])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J10") -- Judge S4 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[17])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J11") -- Judge S5 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[18])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end

            else -- only 9 synchro judges  (labels are different to 11 judges!)
                local source = obs.obs_get_source_by_name("SynchroJLabels11")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, false)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels11 "))
                    end
                end
                obs.obs_source_release(source)                
                local source = obs.obs_get_source_by_name("SynchroJLabels9")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, true)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "SynchroJLabels9 "))
                    end
                end
                obs.obs_source_release(source) 

                -- place awards into their respective text Sources
                local source = obs.obs_get_source_by_name("J1") -- Judge E1 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[8])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J2") -- Judge E2 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[9])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J3") -- Judge E3 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[10])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J4") -- Judge E4 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[11])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J5") -- Judge S1 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[14])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J6") -- Judge S2 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[15])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J7") -- Judge S3 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[16])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J8") -- Judge S4 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[17])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J9") -- Judge S5 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[18])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J10") -- Judge 10 blank
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", " ")
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J11") -- Judge 11 blank
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", " ")
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
            end
            if split_string2[23] == split_string2[28] and split_string2[24] == split_string2[27] then
                eventComplete = true
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Synchro Event Complete!"))
                end
            end
            scores2 = split_string2[19]
         
        else -- Synchro before judge awards so display dive description and ranking, then
             -- disable synchro judge awards, judgeLabels9 and judgeLabels11. Finally enable and display sourcelineTwo

            local source = obs.obs_get_source_by_name("JudgeAwards") -- Disable awards Text Source group
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "Synchro JudgeAwards "))
                end
            end
            obs.obs_source_release(source)
            local source = obs.obs_get_source_by_name("SynchroJLabels9") -- Disable synchro judge labels
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels9 "))
                end
            end
            obs.obs_source_release(source)
            local source = obs.obs_get_source_by_name("SynchroJLabels11") -- Disable synchro judge labels
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels11 "))
                end
            end
            obs.obs_source_release(source)
            local source = obs.obs_get_source_by_name("Linetwo") -- Enable dive description
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "Linetwo "))
                end
            end
            obs.obs_source_release(source)
           
            scores2 = (" ")

            if     split_string2[4] == "A" then position = (", straight")
            elseif split_string2[4] == "B" then position = (", piked")
            elseif split_string2[4] == "C" then position = (", tucked")
            elseif split_string2[4] == "D" then position = (", free")
            end
            sourcelineTwo = (split_string2[7] .. position)          
            display2b = "!"
            display2a = "!"
            lineTwo = string.insert(lineTwo, sourcelineTwo, 0)

            obs.timer_add( function() remove_TVbanner() end,  dinterval )   -- hide overlay after timer period             
        end

--  >>>>> Individual event <<<<<<
    else
            --  >>>> *** As NOT a Synchro event assume only 5 or 7 judges for individual events, rest of J fields must be 'blank'.  Use awards line blank space for BannerLine2 data  *** <<<<
        if split_string2[16] ~= (" ") then -- then nothing in J9 award position so assume individual event and disable the 9 & 11 synchro judge role labels
                                           -- should not have got to this point if Synchro but no harm in checking again!
            local source = obs.obs_get_source_by_name("SynchroJLabels11") -- disable synchro11 judge role labels
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels11 "))
                end
            end
            obs.obs_source_release(source)
            local source = obs.obs_get_source_by_name("SynchroJLabels9") -- disable synchro9 judges role labels
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels9 "))
                end
            end
            obs.obs_source_release(source)
        end
        if split_string2[8] ~= (" ") then -- if award in J1 position then display judge awards
            sourcelineTwo = (" ") -- empty sourcelineTwo field so no awards displayed and debug works correctly
            local source = obs.obs_get_source_by_name("JudgeAwards") -- Enable awards Text Source group (else 11 individual text boxes to enable!)
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "Individual JudgeAwards "))
                end
            end
            obs.obs_source_release(source)
            -- place judge awards into their respective text Sources (yes could be a nested loop but this was a simple copy paste!!)
            local source = obs.obs_get_source_by_name("J1") -- Judge 1 awards insert
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[8])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J2") -- Judge 2 awards insert
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[9])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J3") -- Judge 3 awards insert
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[10])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J4") -- Judge 4 awards insert
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[11])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J5") -- Judge 5 awards insert
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[12])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J6") -- Judge 6 awards insert
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[13])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J7") -- Judge 7 awards insert
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[14])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J8") -- Judge 8 awards insert.  Should be a space!
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[15])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J9") -- Judge 9 awards insert.  Should be a space!
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[16])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J10") -- Judge 10 awards insert.  Should be a space!
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[17])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J11") -- Judge 11 awards insert.  Should be a space!
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[18])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            if split_string2[23] == split_string2[28] and split_string2[24] == split_string2[27] then
                eventComplete = true
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Individual Event Complete!"))
                end
            end
            
            scores2 = split_string2[19]
            display2a = (" ") -- should be nothing in here as this is the awards space!!
            display2b = (" ")
            if debug then 
                obs.script_log(obs.LOG_INFO, string.format("display2b length=" .. string.len(display2b)))
            end
            -- lineTwo = string.insert(lineTwo, display2b, 32) -- insert at the end of lineTwo, first part of lineTwo is the awards, but awards are not inserted into this Text Source!

        else  --    >>>>  *  Individual event before judge awards so display dive description and ranking on line two
            local source = obs.obs_get_source_by_name("JudgeAwards") -- Disable judge awards text Source Group
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "JudgeAwards "))
                end
            end
            obs.obs_source_release(source) -- disable 11 synchro judges role labels
            local source = obs.obs_get_source_by_name("SynchroJLabels11")
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels11 "))
                end
            end
            obs.obs_source_release(source) -- disable 9 synchro judges role labels
            local source = obs.obs_get_source_by_name("SynchroJLabels9")
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels9 "))
                end
            end
            obs.obs_source_release(source)
            
            scores2 = (" ")
            display1b = (" ") -- to keep debug happy!
            
            if     split_string2[4] == "A" then position = (", straight")
            elseif split_string2[4] == "B" then position = (", piked")
            elseif split_string2[4] == "C" then position = (", tucked")
            elseif split_string2[4] == "D" then position = (", free")
            end
            sourcelineTwo = (split_string2[7] .. position)
            lineTwo = string.insert(lineTwo, sourcelineTwo, 0) -- Insert dive description at the start of lineTwo
            obs.timer_add( function() remove_TVbanner() end,  dinterval )   -- hide overlay after timer period            
        end
    end

    if debug then -- show the overlay text strings in the log (not the awards though!) This needs sorting for V2.x.x as most of these strings now not used!
        obs.script_log(obs.LOG_INFO, string.format("display1a Length:" .. string.len(display1a) .. " =" .. display1a))
        obs.script_log(obs.LOG_INFO, string.format("display1b Length:" .. string.len(display1b) .. " =" .. display1b))
        obs.script_log(obs.LOG_INFO, string.format("lineOne Length:" .. string.len(lineOne) .. " =" .. lineOne))
        obs.script_log(obs.LOG_INFO, string.format("sourcelineTwo=" .. string.len(sourcelineTwo) .. " =" .. sourcelineTwo))
        obs.script_log(obs.LOG_INFO, string.format("display2a Length:" .. string.len(display2a) .. " =" .. display2a))
        obs.script_log(obs.LOG_INFO, string.format("display2b Length:" .. string.len(display2b) .. " =" .. display2b))
        obs.script_log(obs.LOG_INFO, string.format("lineTwo Length:" .. string.len(lineTwo) .. " =" .. lineTwo))
    end

    -- insert text into the Text(GDI+) OBS Sources
    local source = obs.obs_get_source_by_name("Lineone") -- Overlay LineOne text source insert
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", lineOne)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end

    local source = obs.obs_get_source_by_name("Linetwo") -- Overlay LineTwo text source insert
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", lineTwo)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
    
    scores = (scores1 .. "\n" .. scores2 )
    local source = obs.obs_get_source_by_name("Scores") -- Overlay LineTwo text source insert
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", scores)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
    
end -- update(k, v)


local function checkFile(id)
    -- if the lua script has reloaded then stop any old timers and return
    if id < activeId then
        obs.remove_current_callback()
        return
    end
    obs.timer_remove(disable_source) -- remove the overlay display timer (is this the correct timer??)

    -- script not reloaded so check for DUpdate and SUpdate files
    -- now check if event ended and the display of the last dive is complete (display time ended)
    if eventComplete then
        obs.timer_add(remove_TVbanner, dinterval)
        eventComplete = false
    end

    local ft, err = io.open(textFileDI, "rb") --try to open the trigger text file, if exists then its an individual event, process the contents and update TVoverlay
    if ft then
        ft:close()
        os.remove(textFileDI) --  remove trigger file
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("\nIndividual Event 'DUpdate' File Detected"))
        end           
        local f, err = io.open(textFile, "rb")  -- open the DR2Video text file
        if f then
            line1 = f:read("*line") -- read the first line  Future version may remove line one.  Then need to change DR2Video options to remove headers as well!
            line2 = f:read("*line") -- read the second line
            if line2 then -- is there something in the file? Should be to get to here but check anyway!
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Yes, Individual File has contents"))
                    obs.script_log(obs.LOG_INFO, string.format(line2))
                end
                update(line1, line2) -- yes, process it using the "update(k,v)" function.  k=line1; v=line2
            end
            f:close()
        else
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Error reading Individual text file: ", err))
            end
        end
    end
    local fs, err = io.open(textFileDS, "rb") --try to open the trigger text file, if exists then its a synchro event, process the contents and update TVoverlay
    if fs then
        fs:close()
        os.remove(textFileDS) --  remove trigger file
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("\nSynchro Event 'SUpdate' File Detected"))
        end
        local f, err = io.open(textFile, "rb")  -- open the DR2Video text file
        if f then
            line1 = f:read("*line") -- read the first line  Future version may remove line 1.  Then need to change DR2Video options to remove headers as well!
            line2 = f:read("*line") -- read the second line
            if line2 then -- is there something in the file? Should be to get to here but check anyway!
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Yes, Synchro File has contents"))
                    obs.script_log(obs.LOG_INFO, string.format(line2))
                end
                update(line1, line2) -- yes, process it using the "update(k,v)" function.  k=line1; v=line2
            end
            f:close()
        else
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Error reading Synchro text file: ", err))
            end
        end
    end
end -- checkFile(id)

-- String insert function.  Keeps original string length; almost! First position is 0 not as per usual with Lua of 1.  So use 0 for the pos vairable if 
-- insert required at beginning of str1.  If new string longer than original (because insert is towards the end and inserted string is longer than available length) 
-- error printed in log.  Function will not fail though, however all formatting bets for this OBS script are off as returned string will be longer than 
-- available space!!!
function string.insert(str1, str2, pos)
    local lenstr1 = string.len(str1)
    local lenstr2 = string.len(str2)
    if (lenstr2 + pos) > string.len(str1) then
        print("Function String.Insert length error, str1: " .. str1 .. " str2: " .. str2)
    end
    return str1:sub(1, pos) .. str2 .. str1:sub(pos + (1 + lenstr2))
end -- string.insert()


function remove_TVbanner()
    -- remove the TV Banner from the screen after a user configurable period of time.  But only if not final dive.  If last dive then remove banner after time period anyway.
    -- need to add something here to determine if dive description or awards.
    if hideDisable and not(eventComplete) then
        tvBanner_removed = true
        obs.remove_current_callback()
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("hideDisable so do not run remove_TVbanner (unless eventComplete is true)"))
        end
        return
    else
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("remove_TVbanner()"))
        end
        local source = obs.obs_get_source_by_name("Event") -- disable text Source (Event group)
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source (remove_TVbanner): " .. "Event "))
            end
        else 
            obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "TVBanner2 source not available!"))
        end
        obs.obs_source_release(source)
        tvBanner_remove()
        obs.remove_current_callback() -- stops remove_TVBanner running endlesly
    end
    tvBanner_removed = true
end --remove_TVbanner()


function tvBanner_remove()
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("tvBanner_remove()"))
    end
    local source = obs.obs_get_source_by_name("TVBanner2") -- disable text Source (TVBanner group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "TVBanner2 "))
        end
    else 
        obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "TVBanner2 source not available!"))
    end
    obs.obs_source_release(source)
    local source = obs.obs_get_source_by_name("JudgeAwards") -- disable text Source (JudgeAwards)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "JudgeAwards "))
        end
    end
    obs.obs_source_release(source)
    local source = obs.obs_get_source_by_name("SynchroJLabels11") -- disable text Source (SynchroJLabels11)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "SynchroJLabels11 "))
        end
    end
    obs.obs_source_release(source)
    local source = obs.obs_get_source_by_name("SynchroJLabels9") -- disable text Source (SynchroJLabels9)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "SynchroJLabels9 "))
        end
    end
    obs.obs_source_release(source)
    obs.timer_remove(removeTVbanner)
end  -- TVBanner_remove()


local function init()
    -- initilise the various start-up paramaters and clear screen (TV overlay)
    -- increase the timer id - old timers will be cancelled
    activeId = activeId + 1
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("init()"))
    end
    -- ensure nothing displayed on startup or function change
    tvBanner_remove()

    -- only proceed if there is a text file selected
    if not textFile then
        return nil
    end -- this may not work as textFile is allocated to either textFileI or textFileS dependent upon synchro settings.  Thus one file chack should allways be true!

    -- start the timer id to check the text file
    local id = activeId

    -- start timer loop to check for DUpdate or SUpdate file
    obs.timer_add(
        function()
            checkFile(id)
        end,
        interval
    )

    obs.script_log(obs.LOG_INFO, string.format("DR file monitor started.  ID: ".. id))
end -- init()


------------------------------------------------------------------------------------
--    ***        OBS Set-up functions for user configurable items          ***    --
------------------------------------------------------------------------------------
-- A function named "script_load" will be called on startup
function script_load(settings) 
end

-- A function named "script_unload" will be called on removal of script
function script_unload()
end

-- A function named "script_update" will be called when settings are changed by the user
function script_update(settings)
    textFileI = obs.obs_data_get_string(settings, "textFileI") -- Individual data file, usually Diver.txt
    textFileS = obs.obs_data_get_string(settings, "textFileS") -- Synchro data file, usually Synchro.txt
    textFileDI = obs.obs_data_get_string(settings, "textFileDI") -- Dummy file to act as Individual event new data trigger
    textFileDS = obs.obs_data_get_string(settings, "textFileDS") -- Dummy file to act as Synchro event new data trigger
    dinterval = obs.obs_data_get_int(settings, "dinterval") -- Overlay display period
    debug = obs.obs_data_get_bool(settings, "debug") -- Set debug on or off
    synchro = obs.obs_data_get_bool(settings, "synchro") -- Select for a Synchro event
    hideDisable = obs.obs_data_get_bool(settings, "hideDisable") -- Turn off oberlay hide
    if synchro then
        textFile = textFileS
    else
        textFile = textFileI
    end
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("(OBS defaults updated) Script_update()"))
    end    
    obs.script_log(obs.LOG_INFO, string.format("\nSynchro selected: %s", synchro))
    init()  -- set-up done, now start the main work of this script!
end

-- A function named "script_description" returns the description shown to the user
function script_description()
    return [[<center><h2>Display DiveRecorder Data</h></center>
             <p>Display diver and scores from DiveRecorder for individual and synchro events.  DR2Video text file & path must be entered for individual events (Dive.txt) and for synchro events (Synchro.txt).  Trigger file locations (DUpdate.txt & SUpdate.txt) need to be entered to trigger an update of the DR data .txt files.  The approporate OBS Source .json file must be imported into OBS for this video overlay to function correctly.  </p><p>Andy - V2.0.0 2022Apr08</p>]]
end

-- A function named script_properties defines the properties that the user can change for the entire script module itself
function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_path(props, "textFileI", "Individual DR2Video File", obs.OBS_PATH_FILE, "", nil)
    obs.obs_properties_add_bool(props, "synchro", "Select if Synchro Event") --** may not be needed in the new regime of update files **
    obs.obs_properties_add_path(props, "textFileS", "Synchro DR2Video File", obs.OBS_PATH_FILE, "", nil)
    obs.obs_properties_add_path(props, "textFileDI", "DR2Video Individual Update Trigger File", obs.OBS_PATH_FILE, "", nil)
    obs.obs_properties_add_path(props, "textFileDS", "DR2Video Synchro Update Trigger File", obs.OBS_PATH_FILE, "", nil)
    obs.obs_properties_add_int(props,  "dinterval", "TVBanner display period (ms)", 4000, 15000, 2000)
    obs.obs_properties_add_bool(props, "hideDisable", "Disable TV Banner Auto Hide")
    obs.obs_properties_add_bool(props, "debug", "Show debug data in Log file")

    return props
end

-- A function named "script_defaults" will be called to set the default settings
function script_defaults(settings)

    obs.obs_data_set_default_string(settings, "textFileI", "C:/Users/<your UserID>/Documents/OBS/mdt/temp/Dive.txt")
    obs.obs_data_set_default_string(settings, "textFileS", "C:/Users/<your UserID>/Documents/OBS/mdt/temp/Synchro.txt")
    obs.obs_data_set_default_string(settings, "textFileDI", "C:/Users/<your UserID>/Documents/OBS/mdt/temp/DUpdate.txt")
    obs.obs_data_set_default_string(settings, "textFileDS", "C:/Users/<your UserID>/Documents/OBS/mdt/temp/SUpdate.txt")
    obs.obs_data_set_default_int(settings,  "dinterval", 5000)
    obs.obs_data_set_default_bool(settings, "debug", false)
    obs.obs_data_set_default_bool(settings, "synchro", false) --** may not be needed in the new regime of update files  **
    obs.obs_data_set_default_bool(settings, "hideDisable", true)
end

-- A function named "script_save" will be called when the script is saved
-- NOTE: This function is usually used for saving extra data (such as a hotkey's settings).  Settings set via the 'properties' function are saved automatically.
function script_save(settings)
end
