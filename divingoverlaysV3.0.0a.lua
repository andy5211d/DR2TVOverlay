--[[
**        __     ______   ____    ______ _    __   ___   _    __   ______   ______   __      ______ _    __
**      /  |   / ___  / /__   \ /_  __/ | |  / / / __ \ | |  / / / _____/ /  __  /  / /    /  __  /| |  / /
**     / / |  / /__/ /   /  _/   / /    | | / / / / | | | | / / / /__    / /__/ / / /     / /__/ / | |_/ /
**    / /| | /  __  |  /  /__   / /     | |/ / | |_/ /  | |/ / / /___   /  __  | / /___  /  __  /  |_  _/
**   /____/ /_/   |_| |_____/  /_/      |__/   |____/   |__/  /______| /_/   |_|/_____/ /_/  /_/    /_/   TM
**
**
**  Open Broadcaster Software
**
**  OBS > Tools > Scripts
**
**  OBS Lua Script :- divingoverlaysVx.y.z.lua
**  matching OBS Source JSON File :- divingoverlays-sourceVx.y.z.json
**
**  Provides a number of OBS-Studio Text(GDI+) Sources which displays the event information from DiveRecorder (DR) onto the event video stream.  Uses the data provided by DR's 
**  DR2Video software.  Automatically checks for the *Update files and if detected displays the new information.   Has the capability to automatically hide the dive 
**  information banner and re-display it when DR file changes detected.  Works for both Individual events and Synchro events and a vairable number of judges.  May get updated someday
**  to work for simultanious events (A & B) as DR2Video has this capability but never likley to be updated for a skills circuit!  UDP script components by OBS Forum's John Hartman, with thanks. 
**
**    V3.0.0a  2022-07-05  A developement branch from V2.1.2 to implement UDP communications.  Don't use, unlikly to be working!!
**
**  The programmer should refere to Malcolm's spreadsheet listing all the components of the UDP data packets and the different UDP packet types.  (add file name here but it has not been released by Malcolm!)
**
**
**        Packet ID (REFEREE)       split_string2[1]            Packet ID (UPDATE)
**        a or b event              split_string2[2]
**        Sending Computer ID       split_string2[3]            Sending Computer ID
**        Event mode                split_string2[4]
**        New Event                 split_string2[5]            Sending Computer IP Address
**        Round                     split_string2[6]            Update file location on remote machine
**        Attempt by diver          split_string2[7]            EOF
**        Start No                  split_string2[8]
**        D1 Full Name + Team       split_string2[9]
**        D1 Family Name            split_string2[10]
**        D2 Full Name + Team       split_string2[11]
**        D2 Family Name            split_string2[12]
**        Dive No                   split_string2[13]
**        Position                  split_string2[14]
**        DD                        split_string2[15]
**        Board                     split_string2[16]
**        J1:  E1:  E1:             split_string2[17]
**        J2:  E2:  E2:             split_string2[18]
**        J3:  E3:  E3:             split_string2[19]
**        J4:  E4:  E4:             split_string2[20]
**        J5:  E5:  S1:             split_string2[21]
**        J6:  E6:  S2:             split_string2[22]
**        J7:  S1:  S3:             split_string2[23]
**        J8:  S2:  S4:             split_string2[24]
**        J9:  S3:  S5:             split_string2[25]
**        J10: S4:                  split_string2[26]
**        J11: S5:                  split_string2[27]
**        Judge Total               split_string2[28]
**        Points                    split_string2[29]
**        Total                     split_string2[30]
**        Scoreboard Display Mode   split_string2[31]
**        Rank                      split_string2[32]
**        Prediction                split_string2[33]
**        Likly rank                split_string2[34]
**        Background colour         split_string2[35]
**        AText colour              split_string2[36]
**        BText colour              split_string2[37]
**        Caption colour            split_string2[38]
**        Message 1 - Line 1 of 8   split_string2[39]
**        Message 2                 split_string2[40]
**        Message 3                 split_string2[41]
**        Message 4                 split_string2[42]
**        Message 5                 split_string2[43]
**        Message 6                 split_string2[44]
**        Message 7                 split_string2[45]
**        Message 8 - Line 8 of 8   split_string2[46]
**        Synchro event?            split_string2[47]
**        Show running total score  split_string2[48]
**        Show prediction           split_string2[49]
**        Number of Judges          split_string2[50]
**        Penalty code              split_string2[51]
**        Station no for cct events split_string2[52]
**        Number of stations        split_string2[53]
**        D1 First Name             split_string2[54]
**        D1 Team Name              split_string2[55]
**        D1 Team Code              split_string2[56]
**        D2 First Name             split_string2[57]
**        D2 Team Name              split_string2[58]
**        D2 Team Code              split_string2[59]
**        Long Event Name           split_string2[60]
**        Dive Description          split_string2[61]
**        Meet Title                split_string2[62]
**        No of Rounds in event     split_string2[63]
**        No of Divers in event     split_string2[64]
**        Short dive description    split_string2[65]
**        Conversion factor         split_string2[66]
**        Short Event Name          split_string2[67]
**        Team A2                   split_string2[68]
**        Team code A2              split_string2[69]
**        Team B2                   split_string2[70]
**        Team code B2              split_string2[71]
**        Seconds per dive          split_string2[72]
**        Do not Rank flag          split_string2[73]
**        Team event                split_string2[74]
**        eom  (^)                  split_string2[75]

]]

local obs = obslua
local socket = require("ljsocket")
--local bit = require("bit")   -- likly needed to decode the UDP stream?

local our_server1 = nil
--local our_server2 = nil
--local our_server3 = nil
--local our_server4 = nil
local portClient = 58091            -- the main port for DR broadcast data
--local portServer = 58092            --  server port for DR?
--local portWebUpdate = 58093         --  to send to LiveResults via DR2Web
--local portAwards = 58094            --  server port for awards and perhaps ranking
Address1 = socket.find_first_address("*", portClient)
--Address2 = socket.find_first_address("*", portServer)
--Address3 = socket.find_first_address("*", portWebUp)
--Address4 = socket.find_first_address("*", portAwards)

local textFile, flagLoc, textFileS, flagExt, textFileS_B  -- textfile = the text file to be processed.  flagLoc = the Individual event text file name (and file location) to be checked, then read into textFile.  Simmulary textFileS the Synchro event text file
local textFileD, textFileDI, textFileDS, textFileDI_B, textFileDS_B   -- DR dummy text file to act as new data trigger. Simmulary for B event.  Now not neded for UDP comms - to be deleted
local interval = 1000  -- (ms), time between update file checks   -- Again now not needed for UDP communications
local dinterval  -- the time to display the TV overlay after update
local debug  -- turn on or off debug information display in the Log
local synchro = false  -- default is Individual event
local event = "Event 1"  -- default location for Event source overlay
local eventB = false -- switch for using Event B data
local activeId = 0 -- active file check id's, incremented for each programme paramater change or script initiated re-start
local current = {} -- current data file values to compare with next file update
local togglevar1, togglevar3 = false, false  -- to aid Hotkey Toggle functions
local disableUpdate = false -- as it says!
local eventComplete = false -- as it says!
local tvBanner_removed = false -- is or is not the banner being displayed?
local fileContentsChanged = true  -- has the data file changed since the last update flag?   -- And again not needed for UDP comms
local hideDisable = false  -- default is to hide overlays after timeout

htk_1 = obs.OBS_INVALID_HOTKEY_ID  -- seems to work just as well without these declarations but all on-line inf says to do this so go for it!
htk_2 = obs.OBS_INVALID_HOTKEY_ID
htk_3 = obs.OBS_INVALID_HOTKEY_ID
htk_4 = obs.OBS_INVALID_HOTKEY_ID
htk_5 = obs.OBS_INVALID_HOTKEY_ID
htk_6 = obs.OBS_INVALID_HOTKEY_ID
htk_7 = obs.OBS_INVALID_HOTKEY_ID
htk_8 = obs.OBS_INVALID_HOTKEY_ID


local plugin_info = {
    name = "Diving Overlays",
    version = "3.0.0",
    url = "https://github.com/andy5211d/DR2TVOverlay",
    description = "Video stream overlay for springboard and highboard diving competitions",
    author = "andy5211d"
}

local plugin_def = {
    id = "DR2TVOverlay",
    type = obs.OBS_SOURCE_TYPE_INPUT,
    output_flags = bit.bor(obs.OBS_SOURCE_CUSTOM_DRAW),
}


-- called when an update to the DR text file is detected.  Process DR data in the file then display and for a user determined period if Overlay hide option not disabled.
local function update(k, v)
    -- first line in the DR text file [data(k)], not used by this script 
    obs.script_log(obs.LOG_INFO, string.format("start update(k, v)"))    -- show in log what is happening
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("Event Complete? %s", eventComplete))
        obs.script_log(obs.LOG_INFO, string.format("tvBanner Removed? %s", tvBanner_removed))
        obs.script_log(obs.LOG_INFO, string.format("File contents changed? %s", fileContentsChanged))      
        obs.script_log(obs.LOG_INFO, string.format("hideDisable: %s", hideDisable))
        obs.script_log(obs.LOG_INFO, string.format("synchro: %s", synchro))
        obs.script_log(obs.LOG_INFO, string.format("eventB: %s", eventB))
    end
    if eventComplete and tvBanner_removed and not fileContentsChanged then  -- try to stop the banner re-displaying when showing rankings.  Hmm, is this really doing what it says?
        return
    end

    if v then -- Is second line of data(v) present? Just checking again!
        local result = {} -- empty array where we will store data from the UDP data stream
        local delimiter = ("|") -- UDP data string delimiter chr
        for match in (v .. delimiter):gmatch("(.-)" .. delimiter) do -- fill the array
            table.insert(result, match)
        end
        split_string2 = result -- generates an array with entries from the UDP data packet
        if split_string2[1]  ~= "REFEREE" then return end   -- don't process other port 58091 UDP data packets at this time!!        
        if split_string2[74] ~= nil then -- check if empty field
            split_string2[74] = string.sub(split_string2[74], 1, -2) -- CR present at end of data packet so remove from the last field else Lua gets upset when trying to displaying the last field
        end  
    end
    if split_string2[32] == ("") then 
      split_string2[32] = (" ")
      obs.script_log(obs.LOG_INFO, string.format("Nil detected in Rank field "))
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
    local source = obs.obs_get_source_by_name(event) -- enable text Source (Event group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, true)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Enable_source at start of update(): " .. event))
        end
    end
    obs.obs_source_release(source)

    -- first generate empty text display lines
    lineOne = ("                                                  ") -- set overlay display text line 1 to 50 spaces
    lineTwo = ("                                                  ") -- set overlay display text line 2 to 50 spaces
    tvBanner_removed = false -- as we are about to display dive data or awards!

    -- generate country flag or club logo file info from udp data.  This is a local flag file not from a website as outlined above in notes
--    local index = flagExt:match'^.*().'  -- find last occurance of '.' file extension seperator'
  
--    local index = flagLoc:match'^.*()\\'  -- find last occurance of the Windows path seperator
--    flag_file = string.insert(flagLoc, split_string2[56] .. flagExt .. " ", index)  
--    flag_file = string.insert(flagLoc, "Default.png", index)  
--    local flag_file = flagLoc .. split_string2[56].. "." .. flagExt  -- an OBS user entered location and file extension.
    local flag_file = "C:\\Users\\The Trust\\Documents\\OBS\\flags\\" .. split_string2[56].. ".png"  -- temp solution
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("Flag File = " .. flag_file))
    end
    local ft, err = io.open(flag_file, "rb") -- try to open the flag file, if exists then use it else use Default.png
    if not ft then
        local index = flag_file:match'^.*()\\'  -- find last occurance of the Windows path seperator
        if index == "" then index = 0 end  -- fix error generated by networked DR instance sending scoreboard clear function  
        flag_file = string.insert(flag_file, "Default.png", index)  -- inset default logo if required flag file code not found (string.insert starts at 0. This will produce a sting.insert length error but acceptable as not for a formated text display)
    else
        ft:close()
    end

    -- Divers country flag or club logo insert into source overlay.
    local source = obs.obs_get_source_by_name("Flag") 
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "file", flag_file)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end

    -- now produce the event information display
    local event_info = (" " .. split_string2[60] .. " \n Diver " .. split_string2[8] .. "/" .. split_string2[64] .. "  Round " .. split_string2[6] .. "/" .. split_string2[63] .. " ")
    local source = obs.obs_get_source_by_name("EventData") -- Display event data
    if source ~= nil then
    local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", event_info)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end

    -- now generate lineone of the overlay, the Divers information, preceded by rank
    display1a = (" " .. split_string2[32] .. " ")
    lineOne = string.insert(lineOne, display1a, 0)
    displayName = (split_string2[9]) -- display name and club
    lineOne = string.insert(lineOne, displayName, 5)
    display1b = (" ")  
    scores1 = split_string2[29]

    -- now generate the rest of the text displays
    --                  >>>> *** If a Synchro event then *** <<<<<
    if synchro then
        if split_string2[17] ~= (" ") then -- if awards in J1 field then display them
            sourcelineTwo = " " -- Empty string so nothing displayed and debug works correctly
            local source = obs.obs_get_source_by_name("JudgeAwards") -- Enable awards Text Source group (else 11 individual text boxes to enable!)
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "Synchro JudgeAwards "))
                end
            end
            obs.obs_source_release(source)
            if split_string2[21] ~= (" ") then -- if award in J5 then 11 synchro judges (Judge role labels are in different positions for 9 judges!)
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
          
                -- place judge awards into their respective text Sources
                local source = obs.obs_get_source_by_name("J1") -- Judge E1 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[17])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J2") -- Judge E2 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[18])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J3") -- Judge E3 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[19])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J4") -- Judge E4 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[20])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J5") -- Judge E5 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[21])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J6") -- Judge E6 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[22])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J7") -- Judge S1 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[23])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J8") -- Judge S2 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[24])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J9") -- Judge S3 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[25])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J10") -- Judge S4 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[26])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J11") -- Judge S5 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[27])
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
                    obs.obs_data_set_string(settings, "text", split_string2[17])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J2") -- Judge E2 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string[18])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J3") -- Judge E3 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[19])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J4") -- Judge E4 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[20])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J5") -- Judge S1 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[21])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J6") -- Judge S2 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[22])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J7") -- Judge S3 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[23])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J8") -- Judge S4 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[24])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J9") -- Judge S5 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[25])
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
            if split_string2[8] == split_string2[65] and split_string2[6] == split_string2[64] then
                eventComplete = true
                local source = obs.obs_get_source_by_name("Event_Complete") -- show blue dot
                if source ~= nil then
                    obs.obs_source_set_enabled(source, true)
                end
                obs.obs_source_release(source) 
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Synchro Event Complete!"))
                end
            end
            scores2 = split_string2[30]  -- no data to put in this source as no awards
         
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

            if     split_string2[14] == "A" then position = (", straight")
            elseif split_string2[14] == "B" then position = (", piked")
            elseif split_string2[14] == "C" then position = (", tucked")
            elseif split_string2[14] == "D" then position = (", free position")
            end
            sourcelineTwo = (split_string2[62] .. position)          
            display2b = "!"
            display2a = "!"
            lineTwo = string.insert(lineTwo, sourcelineTwo, 0)

            obs.timer_add( function() remove_TVbanner() end,  dinterval )   -- hide overlay after timer period             
        end

--  >>>>> Individual event <<<<<<
    else            --  >>>> *** As NOT a Synchro event assume only 5 or 7 judges for individual events, rest of J fields must be 'blank'.  Use awards line blank space for BannerLine2 data  *** <<<<
        if split_string2[25] ~= (" ") then -- then nothing in J9 award position so assume individual event and disable the 9 & 11 synchro judge role labels
                                           -- should not have got to this point if Synchro but no harm in checking the awards to confirm!
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
        if split_string2[17] ~= (" ") then -- if award in J1 position then display judge awards
            sourcelineTwo = (" ") -- empty sourcelineTwo field to ensure debug works correctly
            local source = obs.obs_get_source_by_name("JudgeAwards") -- Enable awards Text Source group (else 11 individual text boxes sources to enable!)
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
                obs.obs_data_set_string(settings, "text", split_string2[17])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J2") -- Judge 2 awards insert
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[18])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J3") -- Judge 3 awards insert
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[19])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J4") -- Judge 4 awards insert
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[20])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J5") -- Judge 5 awards insert
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[21])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J6") -- Judge 6 awards insert
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[22])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J7") -- Judge 7 awards insert
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[23])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J8") -- Judge 8 awards insert.  Should be a space!
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[24])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J9") -- Judge 9 awards insert.  Should be a space!
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[25])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J10") -- Judge 10 awards insert.  Should be a space!
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[26])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            local source = obs.obs_get_source_by_name("J11") -- Judge 11 awards insert.  Should be a space!
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", split_string2[27])
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
            if split_string2[8] == split_string2[65] and split_string2[6] == split_string2[64] then
                eventComplete = true
                local source = obs.obs_get_source_by_name("Event_Complete") -- enable blue dot
                if source ~= nil then
                    obs.obs_source_set_enabled(source, true)
                end
                obs.obs_source_release(source) 
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Individual Event Complete!"))
                end
            end
            
            scores2 = split_string2[30]
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
            
            scores2 = (" ")  -- no data to put in this source as no awards
            display1b = (" ") -- to keep debug happy!
            
            if     split_string2[14] == "A" then position = (", straight")
            elseif split_string2[14] == "B" then position = (", piked")
            elseif split_string2[14] == "C" then position = (", tucked")
            elseif split_string2[14] == "D" then position = (", free position")
            end
            sourcelineTwo = (split_string2[62] .. position)
            lineTwo = string.insert(lineTwo, sourcelineTwo, 0) -- Insert dive description at the start of lineTwo
            obs.timer_add( function() remove_TVbanner() end,  dinterval )   -- hide overlay after timer period            
        end
    end

    if debug then -- show the overlay text strings in the log (not the awards though!) This needs sorting for V2.x.x as most of these strings now not used!
        obs.script_log(obs.LOG_INFO, string.format("display1a Length:" .. string.len(display1a) .. " =" .. display1a))
        obs.script_log(obs.LOG_INFO, string.format("display1b Length:" .. string.len(display1b) .. " =" .. display1b))
        obs.script_log(obs.LOG_INFO, string.format("lineOne Length:" .. string.len(lineOne) .. " =" .. lineOne))
        obs.script_log(obs.LOG_INFO, string.format("sourcelineTwo=" .. string.len(sourcelineTwo) .. " =" .. sourcelineTwo))
--        obs.script_log(obs.LOG_INFO, string.format("display2a Length:" .. string.len(display2a) .. " =" .. display2a))
--        obs.script_log(obs.LOG_INFO, string.format("display2b Length:" .. string.len(display2b) .. " =" .. display2b))
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


-- String insert function.  Keeps original string length; well almost! First position is 0, not 1 as per usual with Lua.  So use 0 for the position variable if 
-- insert required at beginning of str1.  If new string longer than original (because insert is towards the end and inserted string is longer than remaining length) 
-- error printed in log.  Function will not fail though, however all formatting bets for this OBS script are off as returned string will be longer than 
-- available display space!!!
function string.insert(str1, str2, pos)
    local lenstr1 = string.len(str1)
    local lenstr2 = string.len(str2)
    if (lenstr2 + pos) > lenstr1 then
        print("Function String.Insert length overrun by: " .. ((lenstr2+pos)-lenstr1) .. ", str1: " .. str1 .. " str2: " .. str2)
    end
    return str1:sub(1, pos) .. str2 .. str1:sub(pos + (1 + lenstr2))
end -- string.insert()


function toggle_event_position(pressed)  -- F12 Hotkey to toggle Event overlay position 
    -- Hotkey to toggle between the two event overlay positions
    if not pressed then
     return
    end
    if togglevar1 then
       togglevar1 = false
       event = "Event 2"
       local source = obs.obs_get_source_by_name("Event 2") -- enable text Source (Event group)
       if source ~= nil then
           obs.obs_source_set_enabled(source, true)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "Event 2"))
           end
       end
       obs.obs_source_release(source)
       local source = obs.obs_get_source_by_name("Event 1") -- disable text Source (Event group)
       if source ~= nil then
           obs.obs_source_set_enabled(source, false)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Event 1"))
           end
       end
       obs.obs_source_release(source)
       local source = obs.obs_get_source_by_name("Position1") -- disable event icon Source
       if source ~= nil then
           obs.obs_source_set_enabled(source, false)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Disable_source ): " .. "Position1"))
           end
       end
       obs.obs_source_release(source)  
       local source = obs.obs_get_source_by_name("Position2") -- enable event icon Source
       if source ~= nil then
           obs.obs_source_set_enabled(source, true)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Enable_source ): " .. "Position2"))
           end
       end
       obs.obs_source_release(source) 

    else  -- the initial position when script first run
       togglevar1 = true 
       event = "Event 1"
       local source = obs.obs_get_source_by_name("Event 1") -- enable text Source (Event group)
       if source ~= nil then
           obs.obs_source_set_enabled(source, true)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "Event 1"))
           end
       end
       obs.obs_source_release(source)
       local source = obs.obs_get_source_by_name("Event 2") -- disable text Source (Event group)
       if source ~= nil then
           obs.obs_source_set_enabled(source, false)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Disable_source ): " .. "Event 2"))
           end
       end
       obs.obs_source_release(source)  
       local source = obs.obs_get_source_by_name("Position2") -- disable event icon Source
       if source ~= nil then
           obs.obs_source_set_enabled(source, false)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Disable_source ): " .. "Position2"))
           end
       end
       obs.obs_source_release(source)  
       local source = obs.obs_get_source_by_name("Position1") -- enable event icon Source
       if source ~= nil then
           obs.obs_source_set_enabled(source, true)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Enable_source ): " .. "Position1"))
           end
       end
       obs.obs_source_release(source)  
    end
end -- toggle_event_position()


function remove_overlays(pressed)  -- F1 Hotkey to hide the two overlays
    if not pressed then
     return
    end
    local source = obs.obs_get_source_by_name("Event 1") -- disable text Source (Event 1 group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Event 1"))
        end
    end
    obs.obs_source_release(source)
    local source = obs.obs_get_source_by_name("Event 2") -- disable text Source (Event 2 group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Event 2"))
        end
    end
    obs.obs_source_release(source)
    local source = obs.obs_get_source_by_name("TVBanner2") -- disable text Source (JudgeAwards group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "TVBanner2"))
        end
    end
    obs.obs_source_release(source)
    local source = obs.obs_get_source_by_name("JudgeAwards") -- disable text Source (JudgeAwards group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "JudgeAwards"))
        end
    end
    obs.obs_source_release(source)
    local source = obs.obs_get_source_by_name("SynchroJLabels11") -- disable text Source (SynchroJLabels11 group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "SynchroJLabels11"))
        end
    end
    obs.obs_source_release(source)
    local source = obs.obs_get_source_by_name("SynchroJLabels9") -- disable text Source (TVBanner group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "SynchroJLabels9"))
        end
    end
    obs.obs_source_release(source)    
end  -- remove_overlays()


function display_overlays(pressed)  -- F2 HotKey to show the two overlays; but not the Synchro Judge Labels
    if not pressed then
     return
    end
    -- tvBanner_remove()
    local source = obs.obs_get_source_by_name("Event 1") -- enable text Source (Event 1 group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, true)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Event 1"))
        end
    end
    obs.obs_source_release(source)
    local source = obs.obs_get_source_by_name("Event 2") -- enable text Source (Event 2 group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, true)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Event 2"))
        end
    end
    obs.obs_source_release(source)
    local source = obs.obs_get_source_by_name("TVBanner2") -- enable text Source (JudgeAwards group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, true)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "TVBanner2"))
        end
    end
    obs.obs_source_release(source)
    local source = obs.obs_get_source_by_name("JudgeAwards") -- enable text Source (JudgeAwards group, which may just be dive description dependent upon last update)
    if source ~= nil then
        obs.obs_source_set_enabled(source, true)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "JudgeAwards"))
        end
    end
    obs.obs_source_release(source)
end  -- display_overlays()


function disableUpdate_overlays(pressed)  --  F3 Hotkey to disable overlays update (halt the script)
    if not pressed then
     return
    end
    if disableUpdate then
        disableUpdate = false
        local source = obs.obs_get_source_by_name("Screen_Update") 
        if source ~= nil then
          local settings = obs.obs_data_create()
          obs.obs_data_set_string(settings, "text", "Overlays Updated")
          obs.obs_source_update(source, settings)
          obs.obs_data_release(settings)
          obs.obs_source_release(source)
        end  
        local source = obs.obs_get_source_by_name("F3_Function_Background_False") -- disable background
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source ): " .. "F3_Function_Background_False"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("F3_Function_Background_True") -- enable background
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source ): " .. "F3_Function_Background_True"))
            end
        end
        obs.obs_source_release(source)   
    else
        disableUpdate = true
        local source = obs.obs_get_source_by_name("Screen_Update") 
        if source ~= nil then
          local settings = obs.obs_data_create()
          obs.obs_data_set_string(settings, "text", "Overlays NOT Updated")
          obs.obs_source_update(source, settings)
          obs.obs_data_release(settings)
          obs.obs_source_release(source)
        end   
        local source = obs.obs_get_source_by_name("F3_Function_Background_True") -- disable background
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source ): " .. "F3_Function_Background_True"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("F3_Function_Background_False") -- enable background
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source ): " .. "F3_Function_Background_False"))
            end
        end
        obs.obs_source_release(source)   
    end
    obs.script_log(obs.LOG_INFO, string.format("Disable Overlay Update: %s", disableUpdate))    
end  -- disableUpdate_overlays()


function toggle_event_type(pressed)  -- F9 Hotkey to toggle Event type and re-start script
    -- Hotkey to toggle between the two event types
    if not pressed then
     return
    end
    if synchro then
       synchro = false
       local source = obs.obs_get_source_by_name("Event_Type") -- Event type: Individual
       if source ~= nil then
           local settings = obs.obs_data_create()
           obs.obs_data_set_string(settings, "text", "Individual Event")
           obs.obs_source_update(source, settings)
           obs.obs_data_release(settings)
           obs.obs_source_release(source)
       end
       local source = obs.obs_get_source_by_name("F9_Function_Background_False") -- disable background
       if source ~= nil then
           obs.obs_source_set_enabled(source, false)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Disable_source ): " .. "F9_Function_Background_False"))
           end
       end
       obs.obs_source_release(source)  
       local source = obs.obs_get_source_by_name("F9_Function_Background_True") -- enable background
       if source ~= nil then
           obs.obs_source_set_enabled(source, true)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Enable_source ): " .. "F9_Function_Background_True"))
           end
       end
       obs.obs_source_release(source)          
    else 
       synchro = true
       toggle_event_a_or_b(true)  -- Event B for Synchro not possible
       local source = obs.obs_get_source_by_name("Event_Type") -- Event type: Synchro
       if source ~= nil then
           local settings = obs.obs_data_create()
           obs.obs_data_set_string(settings, "text", "Synchro Event")
           obs.obs_source_update(source, settings)
           obs.obs_data_release(settings)
           obs.obs_source_release(source)
       end   
       local source = obs.obs_get_source_by_name("F9_Function_Background_True") -- disable background
       if source ~= nil then
           obs.obs_source_set_enabled(source, false)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Disable_source ): " .. "F9_Function_Background_True"))
           end
       end
       obs.obs_source_release(source)  
       local source = obs.obs_get_source_by_name("F9_Function_Background_False") -- enable background
       if source ~= nil then
           obs.obs_source_set_enabled(source, true)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Enable_source ): " .. "F9_Function_Background_False"))
           end
       end
       obs.obs_source_release(source)       
    end
    init()  -- re-start the script
end -- toggle_event_type()


function toggle_display_disable(pressed)  -- F5 Hotkey to permanently remove overlays
    if not pressed then
        return
       end
       if togglevar3 then
          togglevar3 = false
          disableUpdate = false  -- flip it back again
          local source = obs.obs_get_source_by_name("Remove_Overlays") 
          if source ~= nil then
            local settings = obs.obs_data_create()
            obs.obs_data_set_string(settings, "text", "Overlays Visable")
            obs.obs_source_update(source, settings)
            obs.obs_data_release(settings)
            obs.obs_source_release(source)
          end 
          local source = obs.obs_get_source_by_name("F5_Function_Background_False") -- disable background
          if source ~= nil then
              obs.obs_source_set_enabled(source, false)
              if debug then
                  obs.script_log(obs.LOG_INFO, string.format("Disable_source ): " .. "F5_Function_Background_False"))
              end
          end
          obs.obs_source_release(source)  
          local source = obs.obs_get_source_by_name("F5_Function_Background_True") -- enable background
          if source ~= nil then
              obs.obs_source_set_enabled(source, true)
              if debug then
                  obs.script_log(obs.LOG_INFO, string.format("Enable_source ): " .. "F5_Function_Background_True"))
              end
          end
          obs.obs_source_release(source)     
       else 
          togglevar3 = true
          remove_overlays(true)
          disableUpdate = true  -- toggle to disable
          local source = obs.obs_get_source_by_name("Remove_Overlays") 
          if source ~= nil then
            local settings = obs.obs_data_create()
            obs.obs_data_set_string(settings, "text", "Overlays NOT Visable")
            obs.obs_source_update(source, settings)
            obs.obs_data_release(settings)
            obs.obs_source_release(source)
          end  
          local source = obs.obs_get_source_by_name("F5_Function_Background_True") -- disable background
          if source ~= nil then
              obs.obs_source_set_enabled(source, false)
              if debug then
                  obs.script_log(obs.LOG_INFO, string.format("Disable_source ): " .. "F5_Function_Background_True"))
              end
          end
          obs.obs_source_release(source)  
          local source = obs.obs_get_source_by_name("F5_Function_Background_False") -- enable background
          if source ~= nil then
              obs.obs_source_set_enabled(source, true)
              if debug then
                  obs.script_log(obs.LOG_INFO, string.format("Enable_source ): " .. "F5_Function_Background_False"))
              end
          end
          obs.obs_source_release(source)    
       end
end -- toggle_display_disable()  


function toggle_disable_of_autohide(pressed)  -- F8 Hotkey to toggle autohide disable
    if not pressed then
        return
       end
       if hideDisable then
          hideDisable = false
          local source = obs.obs_get_source_by_name("AutoHide") 
          if source ~= nil then
            local settings = obs.obs_data_create()
            obs.obs_data_set_string(settings, "text", "Auto-hide Enabled")
            obs.obs_source_update(source, settings)
            obs.obs_data_release(settings)
            obs.obs_source_release(source)
          end   
          local source = obs.obs_get_source_by_name("F8_Function_Background_False") -- disable background
          if source ~= nil then
              obs.obs_source_set_enabled(source, false)
              if debug then
                  obs.script_log(obs.LOG_INFO, string.format("Disable_source ): " .. "F8_Function_Background_False"))
              end
          end
          obs.obs_source_release(source)  
          local source = obs.obs_get_source_by_name("F8_Function_Background_True") -- enable background
          if source ~= nil then
              obs.obs_source_set_enabled(source, true)
              if debug then
                  obs.script_log(obs.LOG_INFO, string.format("Enable_source ): " .. "F8_Function_Background_True"))
              end
          end
          obs.obs_source_release(source)   
       else 
          hideDisable = true
          local source = obs.obs_get_source_by_name("AutoHide") 
          if source ~= nil then
            local settings = obs.obs_data_create()
            obs.obs_data_set_string(settings, "text", "Auto-hide Disabled")
            obs.obs_source_update(source, settings)
            obs.obs_data_release(settings)
            obs.obs_source_release(source)
          end  
          local source = obs.obs_get_source_by_name("F8_Function_Background_True") -- disable background
          if source ~= nil then
              obs.obs_source_set_enabled(source, false)
              if debug then
                  obs.script_log(obs.LOG_INFO, string.format("Disable_source ): " .. "F8_Function_Background_True"))
              end
          end
          obs.obs_source_release(source)  
          local source = obs.obs_get_source_by_name("F8_Function_Background_False") -- enable background
          if source ~= nil then
              obs.obs_source_set_enabled(source, true)
              if debug then
                  obs.script_log(obs.LOG_INFO, string.format("Enable_source ): " .. "F8_Function_Background_False"))
              end
          end
          obs.obs_source_release(source)    
       end
end -- toggle_disable_of_autohide()  


function toggle_event_a_or_b(pressed)  -- F10 Hotkey to toggle Event A or Event B and re-start
    if not pressed then
        return
    end
    if eventB then
        eventB = false
        local source = obs.obs_get_source_by_name("A_B") -- Event type: Individual
        if source ~= nil then
            local settings = obs.obs_data_create()
            obs.obs_data_set_string(settings, "text", "Event A Shown")
            obs.obs_source_update(source, settings)
            obs.obs_data_release(settings)
            obs.obs_source_release(source)
        end 
        local source = obs.obs_get_source_by_name("F10_Function_Background_False") -- disable background
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source ): " .. "F10_Function_Background_False"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("F10_Function_Background_True") -- enable background
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source ): " .. "F10_Function_Background_True"))
            end
        end
        obs.obs_source_release(source)     
    else 
        eventB = true
        if synchro then               
            return   -- Event B for Synchro not possible
        end
        local source = obs.obs_get_source_by_name("A_B") -- Event type: Individual
        if source ~= nil then
            local settings = obs.obs_data_create()
            obs.obs_data_set_string(settings, "text", "Event B Shown")
            obs.obs_source_update(source, settings)
            obs.obs_data_release(settings)
            obs.obs_source_release(source)
        end   
        local source = obs.obs_get_source_by_name("F10_Function_Background_True") -- disable background
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source ): " .. "F10_Function_Background_True"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("F10_Function_Background_False") -- enable background
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source ): " .. "F10_Function_Background_False"))
            end
        end
        obs.obs_source_release(source)   
    end
    init()  -- re-start the script
end -- toggle_event_a_or_b()  


function remove_TVbanner()
    obs.script_log(obs.LOG_INFO, string.format("start removeTVBanner()"))  
    -- remove the TV Banner from the screen if not hideDisable and after a user configurable period of time.  If last dive then remove
    -- banner after time period anyway even if hideDisable set.
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("tvBanner_removed: %s", tvBanner_removed))    
        obs.script_log(obs.LOG_INFO, string.format("hideDisable: %s", hideDisable))
        obs.script_log(obs.LOG_INFO, string.format("eventComplete: %s", eventComplete))
    end
    if hideDisable then
        tvBanner_removed = true
        obs.remove_current_callback()
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("hideDisable so do not run remove_TVbanner (unless eventComplete is true)"))
        end
        return
    end
    --[[
    else  -- leftover from auto banner remove at the end of the event.  Not reliable and when Recorders display Results banner re-displays!!
        if tvBanner_removed then
            obs.remove_current_callback()
            return
        end
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("remove_TVbanner()"))
        end

        if eventComplete then         
            local source = obs.obs_get_source_by_name(event) -- disable text Source (Event group)
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable event source (remove_TVbanner()): " .. event .. ' position'))
                end
            else 
                obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. event .. " source not available!"))
            end
            obs.obs_source_release(source)
        end
        ]]
    tvBanner_remove() 
    obs.remove_current_callback()  -- stops remove_TVBanner running endlesly
    
    tvBanner_removed = true
--    eventComplete = false
    
end --remove_TVbanner()


function tvBanner_remove()
    obs.script_log(obs.LOG_INFO, string.format("start tvBanner_remove()"))  

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

    obs.timer_remove(remove_TVbanner) 
end  -- tvBanner_remove()


local function checkFile(id)  -- *** possibly not needed for udp operation ***
    -- if the lua script has reloaded then stop any old timers and return
    if id < activeId then
        obs.remove_current_callback()
        return
    end
    -- script not reloaded so check for Update files (DUpdate, SUpdate and Event B versions)     
     
    local source = obs.obs_get_source_by_name("Update_File_Detected") -- disable text Source (UpdateFileDetected)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
    end
    obs.obs_source_release(source)

    local fs, err = io.open(textFileD, "rb") --try to open the Update text file, if it exists then the data file has been updated, process the contents and update TV overlays
    if fs then
        fs:close()
        os.remove(textFileD) --  remove trigger file
        local source = obs.obs_get_source_by_name("Update_File_Detected") -- enable text Source (UpdateFileDetected)
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
        end
        obs.obs_source_release(source)
        if disableUpdate then  -- if disable_Update Hotkey pressed then ignore file update
            return
        end
        obs.script_log(obs.LOG_INFO, string.format("\nValid 'Update' File Detected"))
        local f, err = io.open(textFile, "rb")  -- open the DR2Video text file
        if f then
            line1 = f:read("*line") -- read the first line.  Future version may remove line 1, (then need to change DR2Video options to remove headers as well)!
            line2 = f:read("*line") -- read the second line
            if line2 then -- is there something in the file? Must be data in the file to get to here but check anyway!
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format(line2))
                end
                if current[line2] ~= line2 then  -- check for changed contents
                    current[line2] = line2
                    fileContentsChanged = true
                    eventComplete = false
                    local source = obs.obs_get_source_by_name("Event_Complete") -- disable blue status rectangle on 'Status' source dock
                    if source ~= nil then
                        obs.obs_source_set_enabled(source, false)
                    end
                    obs.obs_source_release(source) 
                else 
                    fileContentsChanged = false                    
                end
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("File contents changed? %s", fileContentsChanged))
                    obs.script_log(obs.LOG_INFO, string.format("Synchro selected: %s", synchro))
                    obs.script_log(obs.LOG_INFO, string.format("B Event selected: %s", eventB))
                    obs.script_log(obs.LOG_INFO, string.format("Event Complete: %s", eventComplete))
                    obs.script_log(obs.LOG_INFO, string.format("Disable Updates: %s", disableUpdate))
                    obs.script_log(obs.LOG_INFO, string.format("TVBanner removed: %s", tvBanner_removed))
                end                
                update(line1, line2) -- yes there is data, process the file contents using the "update(k,v)" function.  k=line1; v=line2
            end
            f:close()
        else
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Error reading Synchro text file: ", err))
            end
        end
    end
end -- checkFile(id)


function UDPtimer_callback() 
        -- Get UDP data until there is no more, or an error occurs
        -- if the lua script has reloaded then stop any old timers and return
    if id < activeId then
        obs.remove_current_callback()
        return
    end   


    local source = obs.obs_get_source_by_name("Update_File_Detected") -- disable text Source (UpdateFileDetected)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
    end
    obs.obs_source_release(source)
    repeat
        local dataClient, status = our_server1:receive_from()
        if dataClient then

            if current[dataClient] ~= dataClient then
                current[dataClient] = dataClient
                fileContentsChanged = true
                eventComplete = false                
                local source = obs.obs_get_source_by_name("Update_File_Detected") -- enable text Source (UpdateFileDetected)
                if source ~= nil then
                    obs.obs_source_set_enabled(source, true)
                end
                obs.obs_source_release(source)         
                print("dataClient: " .. dataClient)
                update(' ', dataClient) 
                local source = obs.obs_get_source_by_name("Event_Complete") -- disable blue status rectangle on 'Status' source dock
                    if source ~= nil then
                        obs.obs_source_set_enabled(source, false)
                    end
                    obs.obs_source_release(source) 
            else 
                fileContentsChanged = false                    
            end         
        elseif status ~= "timeout" then
            error(status)
        end
    until dataClient == nil
--[[    
    repeat
        local dataServer, status = our_server2:receive_from()
        if dataServer then
            print("dataServer: " .. dataServer)
            print('dataServer IP: ' .. status:get_ip() .. ',  dataServer port: ' .. status:get_port())
            
        elseif status ~= "timeout" then
            error(status)
        end
    until dataServer == nil
    repeat
        local dataWebUp, status = our_server3:receive_from()
        if dataWebUp then
            print("dataWebUp: " .. dataWebUp)
            print('dataWebUp IP: ' .. status:get_ip() .. ',  dataWebUp port: ' .. status:get_port())
                
        elseif status ~= "timeout" then
            error(status)
        end
    until dataWebUp == nil
    repeat
        local dataAwards, status = our_server4:receive_from()
        if dataAwards then
            print("dataAwards: " .. dataAwards)
            print('dataAwards IP: ' .. status:get_ip() .. ',  dataAwards port: ' .. status:get_port())
                
        elseif status ~= "timeout" then
            error(status)
        end
    until dataAwards == nil
--]]    
end


function init()
    -- initilise the various start-up paramaters and clears screen (TV overlay)
    -- increase the timer id - old timers will be cancelled

    if debug then
        obs.script_log(obs.LOG_INFO, string.format("init()"))
    end    
    
    activeId = activeId + 1

     -- start the timer id to check changed data
    id = activeId

    -- start the timer loop for udp port scanning, in ms
    obs.timer_add(UDPtimer_callback, 200)  
    obs.script_log(obs.LOG_INFO, string.format('Listening on UDP ports. Re-start ID: ' .. id))

    -- ensure nothing displayed on startup or function change
    tvBanner_remove()

    -- select the text files to be displayed in the overlays and the associated update trigger file  -- Not needed for UDP comms
    --[[ synchro then      
            textFile = textFileS       -- Event A data file.  No B Event possible!
            textFileD = textFileDS     -- Event A trigger file.  No B Event possible!
    else  -- individual event
        if eventB then
            textFile = flagExt     -- Event B data file
            textFileD = textFileDI_B   -- Event B trigger file
        else
            textFile = textFileI       -- Event A data file
            textFileD = textFileDI     -- Event A trigger file
        end
    end
    ]]
end -- init()


------------------------------------------------------------------------------------
--    ***        OBS Set-up functions for user configurable items          ***    --
------------------------------------------------------------------------------------
-- Hotkey definitions and default settings, (not realy OBS Set-up functions).  Don't use F11 as it is a predefined 'Full Screen' trigger
hk = {}
key_1 = '{ "htk_1": [ { "key": "OBS_KEY_F1" } ], '   -- HK to temp remove_overlays
key_2 = '  "htk_2": [ { "key": "OBS_KEY_F2" } ], '   -- HK to temp display_overlays (all)
key_3 = '  "htk_3": [ { "key": "OBS_KEY_F3" } ], '   -- HK to disableUpdate_overlays
key_4 = '  "htk_4": [ { "key": "OBS_KEY_F12" } ], '   -- HK to toggle_event_position
key_5 = '  "htk_5": [ { "key": "OBS_KEY_F9" } ], '   -- HK to toggle_event_type (synchro or individual)
key_6 = '  "htk_6": [ { "key": "OBS_KEY_F5" } ], '   -- HK to permanently remove overlays
key_7 = '  "htk_7": [ { "key": "OBS_KEY_F8" } ], '   -- HK to disable auto-hide of overlays
key_8 = '  "htk_8": [ { "key": "OBS_KEY_F10" } ] }'   -- HK to toggle Event A or Event B
json_s = key_1 .. key_2 .. key_3 .. key_4 .. key_5 .. key_6 .. key_7 .. key_8
default_hotkeys =
    {
    {id='htk_1', des='Temporary Remove DR2TVOverlays ',   callback=remove_overlays},
    {id='htk_2', des='Temporary Display All DR2TVOverlays ',  callback=display_overlays},
    {id='htk_3', des='Disable Update of Overlays ',  callback=disableUpdate_overlays},
    {id='htk_4', des='Toggle Event Overlay Position ',   callback=toggle_event_position},
    {id='htk_5', des='Toggle Event Type (Synchro or Individual) ',   callback=toggle_event_type},   
    {id='htk_6', des='Permanently Remove All Overlays ', callback=toggle_display_disable},   
    {id='htk_7', des='Disable Auto-hide of Overlays ', callback=toggle_disable_of_autohide},   
    {id='htk_8', des='Toggle to Display Event A or Event B ', callback=toggle_event_a_or_b},      
    }

-- A function named "script_load" will be called on startup
function script_load(settings) 
    s = obs.obs_data_create_from_json(json_s)
    for _,v in pairs(default_hotkeys) do 
      a = obs.obs_data_get_array(s,v.id)
      h = obs.obs_hotkey_register_frontend(v.id,v.des,v.callback)
      obs.obs_hotkey_load(h,a)
      obs.obs_data_array_release(a)
    end
    obs.obs_data_release(s)

    our_server1 = assert(socket.create("inet", "dgram", "udp"))
    obs.script_log(obs.LOG_INFO, string.format("\nHostingClient udp at: " .. Address1:get_ip() .. ":" .. Address1:get_port()))
--    our_server2 = assert(socket.create("inet", "dgram", "udp"))
--    obs.script_log(obs.LOG_INFO, string.format("HostingServer udp at: " .. Address2:get_ip() .. ":" .. Address2:get_port()))
--    our_server3 = assert(socket.create("inet", "dgram", "udp"))
--    obs.script_log(obs.LOG_INFO, string.format("HostingWebUp udp at: " .. Address3:get_ip() .. ":" .. Address3:get_port()))
--    our_server4 = assert(socket.create("inet", "dgram", "udp"))
--    obs.script_log(obs.LOG_INFO, string.format("HostingAwards udp at: " .. Address4:get_ip() .. ":" .. Address4:get_port()))

    -- Must set "reuseaddr" or bind will fail when you reload the script
    assert(our_server1:set_option("reuseaddr", 1))
--    assert(our_server2:set_option("reuseaddr", 1))
--    assert(our_server3:set_option("reuseaddr", 1))
--    assert(our_server4:set_option("reuseaddr", 1))
    
    -- Must set non-blocking to prevent the locking the OBS UI thread
    assert(our_server1:set_blocking(false))
--    assert(our_server2:set_blocking(false))  
--    assert(our_server3:set_blocking(false))      
--    assert(our_server4:set_blocking(false))

    -- Bind our_port on all local interfaces
    assert(our_server1:bind(Address1, portClient))
--    assert(our_server2:bind(Address2, portServer))
--    assert(our_server3:bind(Address3, portWebUp))
--    assert(our_server4:bind(Address4, portAwards))

end

-- A function named "script_unload" will be called on removal of script
function script_unload()
    if our_server1 ~= nil then
        print('Shutting down our server')
        assert(our_server1:close())
        our_server1 = nil
    end
--[[    
    if our_server2 ~= nil then
        print('Shutting down our server')
        assert(our_server2:close())
        our_server2 = nil
    end
    if our_server3 ~= nil then
        print('Shutting down our server')
        assert(our_server3:close())
        our_server3 = nil
    end
    if our_server4 ~= nil then
        print('Shutting down our server')
        assert(our_server4:close())
        our_server4 = nil
    end
--]]    
end

-- A function named "script_update" will be called when settings are changed by the user
function script_update(settings)
    flagLoc = obs.obs_data_get_string(settings, "flagLoc") -- Flag file path
    textFileS = obs.obs_data_get_string(settings, "textFileS") -- Synchro data file, usually Synchro.txt
    flagExt = obs.obs_data_get_string(settings, "flagExt") -- Flag file extension
    textFileDI = obs.obs_data_get_string(settings, "textFileDI") -- Dummy file to act as Individual event new data trigger, usualy DUpdate.txt
    textFileDS = obs.obs_data_get_string(settings, "textFileDS") -- Dummy file to act as Synchro event new data trigger, usualy SUpdate.txt
    textFileDI_B = obs.obs_data_get_string(settings, "textFileDI_B") -- Dummy file to act as Individual B event new data trigger, usualy DUpdateB.txt
    dinterval = obs.obs_data_get_int(settings, "dinterval") -- Overlay display period
    debug = obs.obs_data_get_bool(settings, "debug") -- Set debug on or off

    obs.script_log(obs.LOG_INFO, string.format("\nOBS defaults updated, by Script_update()"))   
    obs.script_log(obs.LOG_INFO, string.format("Synchro selected: %s", synchro))
    obs.script_log(obs.LOG_INFO, string.format("B Event selected: %s", eventB))
    obs.script_log(obs.LOG_INFO, string.format("Event Complete: %s", eventComplete))
    obs.script_log(obs.LOG_INFO, string.format("Disable Updates: %s", disableUpdate))
    obs.script_log(obs.LOG_INFO, string.format("File Contents Changed: %s", fileContentsChanged))
    obs.script_log(obs.LOG_INFO, string.format("TVBanner removed: %s", tvBanner_removed))
    init()  -- set-up done, now start the main work of this script!
end

-- A function named "script_description" returns the description shown to the user
function script_description()
    return [[<center><h2>Display DiveRecorder Data as a Video Overlay</h></center>
             <p>Display diver and scores from DiveRecorder for individual and synchro diving events.  The approporate OBS Source .json file must be imported into OBS for this video overlay to function correctly. ***** THIS IS A UDP DEVELOPMENT VERSION!!  DO NOT USE UNLESS YOU WANT A LOT OF UNEXPLAINED GREEF!! ***** </p><p>Andy - V3.0.0 2022Jul05</p>]]
end
--[[
function script_description()   -- wonder if this construct works better for maintaining version ?
    return "<b>" .. plugin_info.description .. "</b><br>" ..
        "Version: " .. plugin_info.version .. "<br>" ..
        "<a href=\"" .. plugin_info.url .. "\">" .. plugin_info.url .. "</a><br><br>" ..

end
]]


-- A function named script_properties defines the properties that the user can change for the entire script module itself
function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_path(props, "flagLoc", "Path to flags folder (select any file)", obs.OBS_PATH_FILE, "", nil)
    obs.obs_properties_add_path(props, "flagExt", "Select file with required extension", obs.OBS_PATH_FILE, "", nil)
    obs.obs_properties_add_path(props, "textFileS", "Synchro DR2Video File", obs.OBS_PATH_FILE, "", nil)
    obs.obs_properties_add_path(props, "textFileDI", "DR2Video Individual Update Trigger File", obs.OBS_PATH_FILE, "", nil)
    obs.obs_properties_add_path(props, "textFileDI_B", "DR2Video Individual B Event Update Trigger File", obs.OBS_PATH_FILE, "", nil)
    obs.obs_properties_add_path(props, "textFileDS", "DR2Video Synchro Event Update Trigger File", obs.OBS_PATH_FILE, "", nil)
    obs.obs_properties_add_int(props,  "dinterval", "TVBanner display period (ms)", 4000, 15000, 2000)
    obs.obs_properties_add_bool(props, "debug", "Show debug data in Log file")
    return props
end

-- A function named "script_defaults" will be called to set the default settings and file locations
function script_defaults(settings)
    obs.obs_data_set_default_string(settings, "flagLoc", "C:/Users/<your UserID>/Documents/OBS/mdt/flags/anyfile.png")
    obs.obs_data_set_default_string(settings, "flagExt", "something.png")
    obs.obs_data_set_default_string(settings, "textFileS", "C:/Users/<your UserID>/Documents/OBS/mdt/temp/Synchro.txt")
    obs.obs_data_set_default_string(settings, "textFileDI", "C:/Users/<your UserID>/Documents/OBS/mdt/temp/DUpdate.txt")
    obs.obs_data_set_default_string(settings, "textFileDS", "C:/Users/<your UserID>/Documents/OBS/mdt/temp/SUpdate.txt")
    obs.obs_data_set_default_string(settings, "textFileDI_B", "C:/Users/<your UserID>/Documents/OBS/mdt/temp/DUpdateB.txt")
    obs.obs_data_set_default_int(settings,  "dinterval", 5000)
    obs.obs_data_set_default_bool(settings, "debug", false)
end

-- A function named "script_save" will be called when the script is saved
-- NOTE: This function is usually used for saving extra data (such as a hotkey's settings).  Settings set via the 'properties' function are saved automatically.
function script_save(settings)
  for k, v in pairs(hk) do
    a = obs.obs_hotkey_save(hk[k])
    obs.obs_data_set_array(settings, k, a)
    obs.obs_data_array_release(a)
  end
end
