--[[
**        __     ______   ____    ______ _    __   ___   _    __   ______   ______   __      ______ _    __
**      /  |   / ___  / /__   \ /_  __/ | |  / / / __ \ | |  / / / _____/ /  __  /  / /    /  __  /| |  / /
**     / / |  / /__/ /   /  _/   / /    | | / / / / | | | | / / / /__    / /__/ / / /     / /__/ / | |_/ /
**    / /| | /  __  |  /  /__   / /     | |/ / | |_/ /  | |/ / / /___   /  __  | / /___  /  __  /  |_  _/
**   /____/ /_/   |_| /_____/  /_/      |__/   |____/   |__/  /______| /_/   |_|/_____/ /_/  /_/    /_/   TM
**
**
**  Open Broadcaster Software
**
**  OBS > Tools > Scripts
**
**  OBS Lua Script :- divingoverlaysVx.y.z.lua
**  matching OBS Source JSON File :- divingoverlays-sourceVx.y.z.json
**
**  Provides a number of OBS-Studio Text(GDI+) Sources which displays the event information from DiveRecorder (DR) onto the event video stream.  Uses the UDP data provided by DR on the local network
**  and after checking displays the new information.   Has the capability to automatically hide the dive information banner and re-display it when DR data changes.  Works for both Individual events
**  and Synchro events and a vairable number of judges.  Will work for simultaneous events but only display the data for one of the simultaneous events (Event A or B).  Does not work for a skills
**  circuit and should be disabled else random info show!  Most UDP script components by OBS Forum's John Hartman, with thanks. 
**
**    V3.0.0a  2022-07-05  A developement branch from V2.1.2 to implement UDP communications.  Don't use, unlikly to be working!!
**    V3.0.0b  2022-10-25  Further deveopement on the use of UDP for communications.  Mainly rationalisation of the code and removal of file monitoring code.  Don't use, unlikly to be fully working!!
**    V3.0.0c  2022-10-28  Working version using UDP communications from DR.  Penalty description now included in awards overlay as approporate.  Auto selection between Individual or Synchro events.
**    V3.0.1   2022-11-02  Working version. However still issues with initilisation of the HotKeys. Best if user cycles each function key after the start of OBS.  Test of using two UDP ports.
**    V3.1.0a  2022-11-05  Using UDP to determine how many judges are being used (and displayed in Status).  Synchro 5 judge and 7 judge option now included.  Source JSON file updated for 5 and 7
**                         synchro judges.
**    V3.1.0b  2022-11-12  A test version to investigate the anomilies when running a skills circuit.
**    V3.1.0c  2022-11-22  Update to fix minor issues with layout and the non display of end of event status indicator.  For Plaform events, board height added after dive description. Source JSON 
**                         updated for new concept of Total and Marks Source rather then just one called Scores
**    V3.1.0d  2022-12-14  Connecting to all four UDP ports but only processing messages from two and using messages from one (at this time)! 
**    V3.1.0e  2023-01-11  Windows path capture and use now correct.   Only two UDP ports needed at present, 58091 and 58093.  The other two not used. 
**    V3.1.0   2023-01-28  Version for National Cup testing.  No further changes or updates anticipated.   
**    V3.1.1   2023-04-20  Minor bug fix for F5 hotkey, which did not do anything usefull anyway! Re-purpose F3 to be 'Re-display Overlay' hotkey.   
**    V3.1.2   2023-04-24  Clean-up.  No functional changes.  
**    V3.1.3   2023-mm-nn  Work in progress so use V3.1.2 for events. Preperatery changes to provide a dual display for simultaneous events. Should be no functional change from V3.1.2 though and may even work!                    
**             2023-05-08  No changes just a few code clean-ups to start with
**             2023-09-29  More clean-ups
**    V3.2.1   2023-10-01  Added code for Ctrl+F12 (or Shft+F12) hotkey but does not do anything useful yet as can't get key modifier (Ctrl or Shft) to work.
**    V3.2.2   2023-10-29  Re-factored for single_update and simultaneous_update screen update functions (functions names may change).  Simultaneous or Single mode change uses 'S' as hotkey to move between modes, likly to change though!
**    V3.3.0   2023-11-08  single_update re-factored to match simultaneous_update format and also both simplified.  Few wrinkles in the display formating but working for both single event and simultaneous events modes.
**
**  
**        Packet ID (58091 REFEREE) split_string2[1]          Packet ID (58091 AVIDEO)
**        a or b event              split_string2[2]          a or b event
**        Sending Computer ID       split_string2[3]          Sending Computer ID
**        Event mode                split_string2[4]          Event mode
**        New Event                 split_string2[5]          Event Status
**        Round                     split_string2[6]          eom (^, 94 dec, 5E hex)
**        Attempt by diver          split_string2[7]
**        Start No                  split_string2[8]
**        D1 Full Name + Team       split_string2[9]
**        D1 Family Name            split_string2[10]
**        D2 Full Name + Team       split_string2[11]
**        D2 Family Name            split_string2[12]
**        Dive No                   split_string2[13]
**        Position                  split_string2[14]
**        DD                        split_string2[15]
**        Board                     split_string2[16]
**        J1:  E1:  E1:  E1:  E1:   split_string2[17]
**        J2:  E2:  E2:  E2:  E2:   split_string2[18]
**        J3:  E3:  E3:  E3:        split_string2[19]
**        J4:  E4:  E4:  E4:        split_string2[20]
**        J5:  E5:                  split_string2[21]
**        J6:  E6:                  split_string2[22]
**        J7:  S1:  S1:  S1:  S1:   split_string2[23]
**        J8:  S2:  S2:  S2:  S2:   split_string2[24]
**        J9:  S3:  S3:  S3:  S3:   split_string2[25]
**        J10: S4:  S4:             split_string2[26]
**        J11: S5:  S5:             split_string2[27]
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
**        Message 4 ( ½  a store)   split_string2[42]
**        Message 5                 split_string2[43]
**        Message 6                 split_string2[44]
**        Message 7                 split_string2[45]
**        Message 8 - Line 8 of 8   split_string2[46]
**        Synchro event?            split_string2[47]
**        Show running total score  split_string2[48]
**        Show prediction           split_string2[49]
**        Number of Judges          split_string2[50]
**        Penalty code              split_string2[51]
**        Station No for cct events split_string2[52]
**        Number of stations        split_string2[53]
**        D1 First Name             split_string2[54]
**        D1 Team Name              split_string2[55]
**        D1 Team Code              split_string2[56]
**        D2 First Name             split_string2[57]
**        D2 Team Name              split_string2[58]
**        D2 Team Code              split_string2[59]
**        Long event name           split_string2[60]
**        Dive Description          split_string2[61]
**        Meet Title                split_string2[62]
**        No of Rounds in event     split_string2[63]
**        No of Divers in event     split_string2[64]
**        Short dive description    split_string2[65]
**        Conversion factor         split_string2[66]
**        Short event name          split_string2[67]
**        Team A2                   split_string2[68]
**        Team code A2              split_string2[69]
**        Team B2                   split_string2[70]
**        Team code B2              split_string2[71]
**        Seconds per dive          split_string2[72]
**        Do Not Rank flag          split_string2[73]
**        Team event                split_string2[74]
**        eom (^, 94 dec , 5E hex)  split_string2[75]
]]

local obs = obslua
local socket = require("ljsocket")

local our_server1 = nil
local our_server2 = nil
local our_server3 = nil
local our_server4 = nil
local portClient = 58091            --  the main port for DR broadcast data
local portServer = 58092            --  port for DR Server locate and identification
local portWebUp  = 58093            --  to send to LiveResults via DR2Web
local portAwards = 58094            --  server port for awards and perhaps ranking
Address1 = socket.find_first_address("*", portClient)
Address2 = socket.find_first_address("*", portServer)
Address3 = socket.find_first_address("*", portWebUp)
Address4 = socket.find_first_address("*", portAwards)

local currentDataClient  -- to check if latest received data has changed
local interval = 1000  -- (ms), time between update file checks   -- Again now not needed for UDP communications
local dinterval  -- the time to display the TV overlay after update
local debug  -- turn on or off debug information display in the Log
local synchro = false  -- default is Individual event
local simultaneousEvents = false  -- default is Single event
local event = "Event 1"  -- default location for Event source overlay
local eventB = false -- switch for using Event B data
local activeId = 0 -- active file check id's, incremented for each programme parameter change or script initiated re-start
local current = {} -- current data file values to compare with next file update
local resultK = {} -- empty array where we will store data from the first UDP port data stream
local resultL = {} -- empty array where we will store data from the second UDP port data stream
local resultM = {} -- empty array where we will store data from the third UDP port data stream
local resultN = {} -- empty array where we will store data from the fouth UDP port data stream
local togglevar1, togglevar2, togglevar3 = false, false, false  -- to aid Hotkey Toggle functions
local disableUpdate, eventComplete = false, false -- as it says!
local tvBanner_removed = false -- is or is not the banner being displayed?
local fileContentsChanged = true  -- has the data file changed since the last update flag?   -- And again not needed for UDP comms
local hideDisable = false  -- default is to hide overlays after timeout

-- Hotkey definitions and default settings, (not realy OBS Set-up functions).  Don't use F11 as it is a predefined 'Full Screen' trigger
htk_1 = obs.OBS_INVALID_HOTKEY_ID  -- seems to work just as well without these declarations but all on-line info says to do this so here we go!
htk_2 = obs.OBS_INVALID_HOTKEY_ID
htk_3 = obs.OBS_INVALID_HOTKEY_ID
htk_4 = obs.OBS_INVALID_HOTKEY_ID
htk_5 = obs.OBS_INVALID_HOTKEY_ID
htk_6 = obs.OBS_INVALID_HOTKEY_ID
htk_7 = obs.OBS_INVALID_HOTKEY_ID
htk_8 = obs.OBS_INVALID_HOTKEY_ID
htk_9 = obs.OBS_INVALID_HOTKEY_ID

positionText = {   -- not used in V3.3.0 yet
    A  = ", straight",
    B  = ", piked",
    C  = ", tucked",
    D  = ", free position"
}

penaltyText = {    -- not used in V3.3.0 yet
    " ",
    "   Failed Dive ",
    "    Restarted \n    -2 points ",
    "Flight or Danger\n Max 2 points ",
    "  Arm position \n  Max 4½ points "
}

local plugin_info = {
    name = "Diving Overlays",
    version = "3.3.0",
    url = "https://github.com/andy5211d/DR2TVOverlay",
    description = "Video stream overlay of Diverecorder data for springboard and highboard diving competitions",
    author = "andy5211d"
}

local plugin_def = {
    id = "DR2TVOverlay",
    type = obs.OBS_SOURCE_TYPE_INPUT,
    output_flags = bit.bor(obs.OBS_SOURCE_CUSTOM_DRAW),
}

function getPath(str)   -- Sorts out the Windows file path seperator character 
    return str:match("(.*[/\\])")
end

-- Single Mode.  Called when a valid UDP message is detected.  Process DR data in the message then display and for a user determined period if Overlay hide option not disabled.
local function single_update(v)

    obs.script_log(obs.LOG_INFO, string.format("start single_update(), Message Headder: " .. v[1]) .. " received")    -- show in log what is happening (message header)
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

    if v[1] ~= ("REFEREE") then return end

    split_string2 = v    -- now we are processing a UDP message 

    -- update the OBS Status display (old F9) with current settings.
    if synchro then   -- message processing for status update
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
            obs.obs_source_release(source)            
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F9_Function_Background_True"))
            end
        end 
        local source = obs.obs_get_source_by_name("F9_Function_Background_False") -- enable background
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            obs.obs_source_release(source)            
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F9_Function_Background_False"))
            end
        end
    else 
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
            obs.obs_source_release(source)           
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F9_Function_Background_False"))
            end
        end
        local source = obs.obs_get_source_by_name("F9_Function_Background_True") -- enable background
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            obs.obs_source_release(source)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F9_Function_Background_True"))
            end
        end    
    end    -- end status single_update

    local source = obs.obs_get_source_by_name("NoJudges") -- Display number of judges in corner of F9 Status box
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", ("No Judges: " .. split_string2[50]))
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
    if split_string2[32] == ("") then      -- sort out a Nul in array as strings can't contain a Nul
       split_string2[32] = (" ")
       obs.script_log(obs.LOG_INFO, string.format("Nul detected in Rank field (so first round)"))
    end

    eventComplete = false
    tvBanner_removed = false -- as we are about to display dive data or awards!  

    -- produce the event information display
    local event_info = (" " .. split_string2[60] .. " \n Diver " .. split_string2[8] .. "/" .. split_string2[64] .. "  Round " .. split_string2[6] .. "/" .. split_string2[63] .. " ")
    local source = obs.obs_get_source_by_name("EventData") -- Display event data
    if source ~= nil then
    local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", event_info)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end

    local source = obs.obs_get_source_by_name(event) -- enable text Source (Event group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, true)
        obs.obs_source_release(source)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Enable_source at start of single_update(): " .. event))
        end
    end
    -- end of Status display single_update

    -- first generate empty text display lines
    lineOne = ("                                                  ") -- set overlay display text line 1 to 50 spaces
    lineTwo = ("                                                  ") -- set overlay display text line 2 to 50 spaces
  
    -- generate country flag or club logo file info from udp data.
    local flag_file = getPath(flagLoc) .. split_string2[56].. ".png" 
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("Flag File = " .. flag_file))
    end
    local ft, err = io.open(flag_file, "rb") -- try to open the flag file and if it exists then use it, else use Default.png
    if not ft then
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Flag file not found, using default flag file"))
        end
        local index = flag_file:match'^.*()/'  -- find last occurance of the path seperator        
        if index == "" then index = 0 end      -- fix error generated by networked DR instance sending scoreboard clear function  
        flag_file = string_insert(flag_file, "Default.png", index) -- inset default logo if required flag file code not found (string_insert starts at 0. This will produce a sting.insert length error but acceptable as not for a formated text display)
    else
        ft:close()
    end

    local source = obs.obs_get_source_by_name("Flag")     -- Divers country flag or club logo insert into source.
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "file", flag_file)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
    -- end of flag display process

    -- now generate lineOne of the overlay text, the Divers, preceded by rank
    display1a = (" " .. split_string2[32] .. " ")   -- rank
    lineOne = string_insert(lineOne, display1a, 0)
    display1b = (" ") 
    if synchro then
        displayName = (split_string2[54] .. ' ' .. split_string2[10] .. ' + ' .. split_string2[57] .. ' ' .. split_string2[12] .. '  ' .. split_string2[56] .. '/' .. split_string2[59]) -- display names + clubs
        lineOne = string_insert(lineOne, displayName, 5)  -- where is the Total text generated??
    else
        displayName = (split_string2[9]) -- display name and club
        lineOne = string_insert(lineOne, displayName, 5)
        scores1 = split_string2[29]  -- points  *** why here? part of lineTwo end of J awards.
    end

    if split_string2[17] ~= (" ") then -- if awards in J1 field then display them

        -- generate the Penalty text, if there is one                 ***** make this a table look-up *****
        if     split_string2[51] == "0" then penalty = (" ")
        elseif split_string2[51] == "1" then penalty = ("   Failed Dive ")
        elseif split_string2[51] == "2" then penalty = ("    Restarted \n    -2 points ")
        elseif split_string2[51] == "3" then penalty = ("Flight or Danger\n Max 2 points ")
        elseif split_string2[51] == "4" then penalty = ("  Arm position \n  Max 4½ points ")
        end 

        sourcelineTwo = (" ") -- empty sourcelineTwo field to ensure dive description removed

        if synchro then  -- display synchro judge awards

            if split_string2[50]  == "11" then  -- 11 synchro judges (Judge role labels are in different positions for other number of judges!)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Synchro 11 Judge display selected"))
                end
                local source = obs.obs_get_source_by_name("SynchroJLabels5")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, false)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels5"))
                    end
                end

                local source = obs.obs_get_source_by_name("SynchroJLabels7")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, false)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels7"))
                    end
                end

                local source = obs.obs_get_source_by_name("SynchroJLabels9")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, false)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels9"))
                    end
                end
 
                local source = obs.obs_get_source_by_name("SynchroJLabels11")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, true)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "SynchroJLabels11"))
                    end
                end
       
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

            elseif split_string2[50] == "9" then  -- 9 synchro judges (Judge role labels are in different positions for other no of judges!)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Synchro 9 Judge display selected"))
                end
                local source = obs.obs_get_source_by_name("SynchroJLabels5")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, false)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels5"))
                    end
                end

                local source = obs.obs_get_source_by_name("SynchroJLabels7")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, false)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels7"))
                    end
                end
                 
                local source = obs.obs_get_source_by_name("SynchroJLabels11")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, false)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels11"))
                    end
                end
              
                local source = obs.obs_get_source_by_name("SynchroJLabels9")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, true)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "SynchroJLabels9"))
                    end
                end

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
                local source = obs.obs_get_source_by_name("J5") -- Judge S1 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[23])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J6") -- Judge S2 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[24])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J7") -- Judge S3 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[25])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J8") -- Judge S4 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[26])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J9") -- Judge S5 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[27])
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
            
            elseif split_string2[50] == "7" then  -- 7 synchro judges (Judge role labels are in different positions for other no of judges!)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Synchro 7 Judge display selected"))
                end
                local source = obs.obs_get_source_by_name("SynchroJLabels5")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, false)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels5"))
                    end
                end

                local source = obs.obs_get_source_by_name("SynchroJLabels9")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, false)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels9"))
                    end
                end

                local source = obs.obs_get_source_by_name("SynchroJLabels11")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, false)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels11"))
                    end
                end

                local source = obs.obs_get_source_by_name("SynchroJLabels7")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, true)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "SynchroJLabels7"))
                    end
                end

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
                local source = obs.obs_get_source_by_name("J5") -- Judge S1 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[23])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J6") -- Judge S2 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[24])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J7") -- Judge S3 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[25])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J8") -- Judge 8 blank
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", " ")
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J9") -- Judge 9 blank
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", " ")
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

            elseif split_string2[50] == "5" then  -- 5 synchro judges (Judge role labels are in different positions for other no of judges!)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Synchro 5 Judge display selected"))
                end
                local source = obs.obs_get_source_by_name("SynchroJLabels11")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, false)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels11"))
                    end
                end
  
                local source = obs.obs_get_source_by_name("SynchroJLabels9")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, false)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels9"))
                    end
                end
      
                local source = obs.obs_get_source_by_name("SynchroJLabels7")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, false)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels7"))
                    end
                end
                                      
                local source = obs.obs_get_source_by_name("SynchroJLabels5")
                if source ~= nil then
                    obs.obs_source_set_enabled(source, true)
                    obs.obs_source_release(source)
                    if debug then
                        obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "SynchroJLabels5"))
                    end
                end

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
                    obs.obs_data_set_string(settings, "text", split_string2[18])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J3") -- Judge S1 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[23])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J4") -- Judge S2 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[24])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J5") -- Judge S3 awards insert
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", split_string2[25])
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J6") -- Judge 6 blank
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", " ")
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J7") -- Judge 7 blank
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", " ")
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J8") -- Judge 8 blank
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", " ")
                    obs.obs_source_update(source, settings)
                    obs.obs_data_release(settings)
                    obs.obs_source_release(source)
                end
                local source = obs.obs_get_source_by_name("J9") -- Judge 9 blank
                if source ~= nil then
                    local settings = obs.obs_data_create()
                    obs.obs_data_set_string(settings, "text", " ")
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
            else 
                error("Invalid number of synchro judges")
            end

        else  -- display individual judge awards
            local source = obs.obs_get_source_by_name("SynchroJLabels11") -- disable synchro11 judge role labels
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                obs.obs_source_release(source)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels11"))
                end
            end

            local source = obs.obs_get_source_by_name("SynchroJLabels9") -- disable synchro9 judges role labels
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                obs.obs_source_release(source)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels9"))
                end
            end

            local source = obs.obs_get_source_by_name("SynchroJLabels7") -- Disable synchro judge labels
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                obs.obs_source_release(source)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels7"))
                end
            end

            local source = obs.obs_get_source_by_name("SynchroJLabels5") -- Disable synchro judge labels
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                obs.obs_source_release(source)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels5"))
                end
            end

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

        end

        local source = obs.obs_get_source_by_name("JudgeAwards") -- Enable awards Text Source group
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            obs.obs_source_release(source)            
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "Synchro JudgeAwards "))
            end
        end

    --  Event Complete?
        if split_string2[8] == split_string2[64] and split_string2[6] == split_string2[63] then
            eventComplete = true
            local source = obs.obs_get_source_by_name("Event_Complete") -- show blue status rectangle in 'Status' source dock
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                obs.obs_source_release(source)
            end
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Synchro Event Complete!"))
            end
        else
            eventComplete = false
            local source = obs.obs_get_source_by_name("Event_Complete") -- disable blue status rectangle in 'Status' source dock
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                obs.obs_source_release(source)
            end
 
        end

    else  -- no awards so show dive info

        local source = obs.obs_get_source_by_name("JudgeAwards") -- Disable awards Text Source group
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            obs.obs_source_release(source)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "Synchro JudgeAwards"))
            end
        end
        local source = obs.obs_get_source_by_name("SynchroJLabels5") -- Disable synchro judge labels
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            obs.obs_source_release(source)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels5"))
            end
        end
        local source = obs.obs_get_source_by_name("SynchroJLabels7") -- Disable synchro judge labels
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            obs.obs_source_release(source)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels7"))
            end
        end
        local source = obs.obs_get_source_by_name("SynchroJLabels9") -- Disable synchro judge labels
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            obs.obs_source_release(source)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels9"))
            end
        end
        local source = obs.obs_get_source_by_name("SynchroJLabels11") -- Disable synchro judge labels
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            obs.obs_source_release(source)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source: " .. "SynchroJLabels11"))
            end
        end
        local source = obs.obs_get_source_by_name("Linetwo") -- Enable dive description
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            obs.obs_source_release(source)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "Linetwo "))
            end
        end

        if     split_string2[14] == "A" then position = (", straight")
        elseif split_string2[14] == "B" then position = (", piked")
        elseif split_string2[14] == "C" then position = (", tucked")
        elseif split_string2[14] == "D" then position = (", free position")
        end

        if split_string2[16] == "1" or split_string2[16] == "3" or split_string2[16] == "5" or split_string2[16] == "7½" or split_string2[16] == "10" then 
            board = (" " .. split_string2[16] .. "m")
        else
            board = (" ")
        end

        sourcelineTwo = (split_string2[61] .. position .. board)      -- generate dive description + position    
        lineTwo = string_insert(lineTwo, sourcelineTwo, 0)            -- insert at the start of lineTwo

        obs.timer_add( function() remove_TVbanner() end,  dinterval )   -- hide overlay after timer period 
    
    end

    if debug then -- show the overlay text strings in the log (not the awards though!)
        obs.script_log(obs.LOG_INFO, string.format("display1a Length:" .. string.len(display1a) .. " =" .. display1a))
        obs.script_log(obs.LOG_INFO, string.format("display1b Length:" .. string.len(display1b) .. " =" .. display1b))
        obs.script_log(obs.LOG_INFO, string.format("lineOne Length:" .. string.len(lineOne) .. " =" .. lineOne))
        obs.script_log(obs.LOG_INFO, string.format("sourcelineTwo=" .. string.len(sourcelineTwo) .. " =" .. sourcelineTwo))
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
    local source = obs.obs_get_source_by_name("Total") -- Overlay Total text source insert
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", split_string2[30])
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end 
    local source = obs.obs_get_source_by_name("Points") -- Overlay points text source insert
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", split_string2[29])
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
    local source = obs.obs_get_source_by_name("Penalty") -- Overlay Penalty text source insert
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", penalty)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end

    local source = obs.obs_get_source_by_name("TVBanner2") -- enable Source (TVBanner group) for display of dive/awards
    if source ~= nil then
        obs.obs_source_set_enabled(source, true)
        obs.obs_source_release(source)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Enable_source at start of single_update(): " .. "TVBanner2 "))
        end
    end

end -- single_update(v)

-- Simultaneous Mode.  Called when a valid UDP message is detected.  Process DR data in the messages then display.  No display timeout for simultaneous events displays.
local function simultaneous_update(v)
  
    obs.script_log(obs.LOG_INFO, string.format("start simultaneous_update(), Message Headder: " .. v[1]) .. " received")  -- show in log what is happening (message header)
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("Event Complete? %s", eventComplete))        -- which one!  now needs to be changed
        obs.script_log(obs.LOG_INFO, string.format("tvBanner Removed? %s", tvBanner_removed))   -- again, which one?
        obs.script_log(obs.LOG_INFO, string.format("File contents changed? %s", fileContentsChanged))      
        obs.script_log(obs.LOG_INFO, string.format("hideDisable: %s", hideDisable))
        obs.script_log(obs.LOG_INFO, string.format("synchro: %s", synchro))                     -- leave this in to catch an error if there is synchro data received
        obs.script_log(obs.LOG_INFO, string.format("eventB: %s", eventB))
        obs.script_log(obs.LOG_INFO, string.format("simultaneous events: %s", simultaneousEvents))
    end
    if eventComplete and tvBanner_removed and not fileContentsChanged then  -- try to stop the banner re-displaying when showing rankings.  Hmm, is this really doing what it says?
        return
    end
    if synchro then 
        -- trap any Synchro event and remove display for the associated event
        obs.script_log(obs.LOG_INFO, string.format(">>>***** ERROR  -  Can't display a Synchro event when running in simultaneous mode!  *****<<<"))
        displayText = (" ")
        if eventB then
            local source = obs.obs_get_source_by_name("EventData_B") -- Display data for B
            if source ~= nil then
            local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", displayText)
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
        else
            local source = obs.obs_get_source_by_name("EventData_A") -- Display data for A
            if source ~= nil then
            local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", displayText)
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
        end  
        return
    end  

    split_string2 = v   
    tvBanner_removed = false  -- as we are about to display dive data or awards! 
    eventComplete = false 

    local source = obs.obs_get_source_by_name("Event A") -- enable Event A Source group for display of dive/awards on the left
    if source ~= nil then
        obs.obs_source_set_enabled(source, true)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Enable_source at start of simultaneous_update(): " .. "Event A "))
        end
        obs.obs_source_release(source)
    end

    local source = obs.obs_get_source_by_name("Event B") -- enable Event B Source group for display of dive/awards on the right
    if source ~= nil then
        obs.obs_source_set_enabled(source, true)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Enable_source at start of simultaneous_update(): " .. "Event B"))
        end
        obs.obs_source_release(source)            
    end

    if split_string2[32] == ("") then   -- replace the nul as Lua can't handle them in stings
        split_string2[32] = (" ")
        obs.script_log(obs.LOG_INFO, string.format("Nil detected in Rank field (first round?)"))
    end

    -- first generate empty text lines to display
    lineOne  =  ("                                        ") -- set overlay display text line 1 to 40 spaces
    lineTwo  =  ("                                        ") -- set overlay display text line 2 to 40 spaces
    lineThree = ("                                        ") -- set overlay display text line 2 to 40 spaces  
    
    if split_string2[17] ~= (" ") then -- if award in J1 position then display judge awards  -- is there a better way of doing this now we have UDP data?
        -- awards branch

        -- generate the first line of the display.   Event, then alternativy the round number or the diver number.   (Don't know how to do this yet!!)
        display1a = (" " .. split_string2[60] .. "  ")                                -- first line: Event info
        display1b = (" Dvr " .. split_string2[8] .. "/" .. split_string2[64] .. " ")    -- first line: diver number of total divers option
        display1c = (" Rnd " .. split_string2[6] .. "/" .. split_string2[63] .. " ")    -- first line: round number of total rounds option

        -- insert display1's into lineOne)
        lineOne = string_insert(lineOne, display1a, 0)        -- insert into line One
        lineOne = string_insert(lineOne, display1c, 33)       -- insert into line One.

        -- generate the Penalty text, if there is one
        if     split_string2[51] == "0" then penalty = (" ")
        elseif split_string2[51] == "1" then penalty = ("   Failed Dive ")
        elseif split_string2[51] == "2" then penalty = ("    Restarted \n    -2 points ")
        elseif split_string2[51] == "3" then penalty = ("Flight or Danger\n Max 2 points ")
        elseif split_string2[51] == "4" then penalty = ("  Arm position \n  Max 4½ points ")
        end 

        -- generate the awards string and points
        awards = (split_string2[17] .. "  " .. split_string2[18] .. "  " .. split_string2[19] .. "  " .. split_string2[20] .. "  " .. split_string2[21] .. "  " .. split_string2[22] .. "  " .. split_string2[23])
        display3a = (split_string2[29]) 
        lineThree = string_insert(lineThree, awards, 0)
        lineThree = string_insert(lineThree, display3a, 34)

        -- Event Complete ??
        if split_string2[8] == split_string2[64] and split_string2[6] == split_string2[63] then
            eventComplete = true
            local source = obs.obs_get_source_by_name("Event_Complete") -- enable blue status rectangle
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                obs.obs_source_release(source)                         
            end
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Individual Event Complete!"))
            end
        else
            eventComplete = false
            local source = obs.obs_get_source_by_name("Event_Complete") -- disable blue status rectangle in 'Status' source dock
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                obs.obs_source_release(source)                        
            end
        end
    else  -- before awards so display dive data

        -- generate the first line of the display.   Event, then alternativy the round number or the diver number.   (Don't know how to do this yet!!)
        display1a = (" " .. split_string2[60] .. "  ")                                -- first line: Event info
        display1b = (" Dvr " .. split_string2[8] .. "/" .. split_string2[64] .. " ")    -- first line: diver number of total divers option
        display1c = (" Rnd " .. split_string2[6] .. "/" .. split_string2[63] .. " ")    -- first line: round number of total rounds option
    
        -- insert display1's into lineOne)
        lineOne = string_insert(lineOne, display1a, 0)        -- insert into line One
        lineOne = string_insert(lineOne, display1b, 33)       -- insert into line One

        -- generate dive position (and board?)
        if     split_string2[14] == "A" then position = (", straight")
        elseif split_string2[14] == "B" then position = (", piked")
        elseif split_string2[14] == "C" then position = (", tucked")
        elseif split_string2[14] == "D" then position = (", free position")
        end
 
        -- generate board
        if split_string2[16] == "1" or split_string2[16] == "3" or split_string2[16] == "5" or split_string2[16] == "7.5" or split_string2[16] == "10" then board = (" " .. split_string2[16] .. "m")
        else board = (" ")
        end

        display3a = (split_string2[61] .. position .. board)
        lineThree = string_insert(lineThree, display3a, 0) -- Insert dive description at the start of lineThree


    end

    -- generate linetwo of the overlay, the Diver and club, preceded by rank and ending in total points
    display2a = (split_string2[32] .. " ")  -- second line: rank
    display2b = (split_string2[9])                 -- second line: display name and club          
    display2c = (" " .. split_string2[30])                -- second line: total points
        
    lineTwo = string_insert(lineTwo, display2a, 0)       -- insert into line Two
    lineTwo = string_insert(lineTwo, display2b, 4)       -- insert into line Two
    lineTwo = string_insert(lineTwo, display2c, 34)      -- insert into line Two

    displayText = (lineOne .. "\n" .. lineTwo .. "\n" .. lineThree)

    -- now inset in the Text Source, either into Event A or Event B 
    -- however this does not swap A & B around under the command of Hotkey F12 yet!
    if eventB then
        local source = obs.obs_get_source_by_name("EventData_B") -- Display data for B
        if source ~= nil then
        local settings = obs.obs_data_create()
            obs.obs_data_set_string(settings, "text", displayText)
            obs.obs_source_update(source, settings)
            obs.obs_data_release(settings)
            obs.obs_source_release(source)
        end
    else
        local source = obs.obs_get_source_by_name("EventData_A") -- Display data for A
        if source ~= nil then
        local settings = obs.obs_data_create()
            obs.obs_data_set_string(settings, "text", displayText)
            obs.obs_source_update(source, settings)
            obs.obs_data_release(settings)
            obs.obs_source_release(source)
        end
    end

    if debug then -- show the overlay text strings in the log (not the awards though!) This needs sorting for V3.x.x as most of these strings now not used!
        obs.script_log(obs.LOG_INFO, string.format("display1a Length:" .. string.len(display1a) .. " =" .. display1a))
        obs.script_log(obs.LOG_INFO, string.format("display1b Length:" .. string.len(display1b) .. " =" .. display1b))
        obs.script_log(obs.LOG_INFO, string.format("display1c Length:" .. string.len(display1c) .. " =" .. display1c))
        obs.script_log(obs.LOG_INFO, string.format("display2a Length:" .. string.len(display2a) .. " =" .. display2a))
        obs.script_log(obs.LOG_INFO, string.format("display2b Length:" .. string.len(display2b) .. " =" .. display2b))
        obs.script_log(obs.LOG_INFO, string.format("display2c Length:" .. string.len(display2c) .. " =" .. display2c))
        obs.script_log(obs.LOG_INFO, string.format("lineOne Length:" .. string.len(lineOne) .. " =" .. lineOne))
        obs.script_log(obs.LOG_INFO, string.format("lineTwo Length:" .. string.len(lineTwo) .. " =" .. lineTwo))
        obs.script_log(obs.LOG_INFO, string.format("lineThree Length:" .. string.len(lineThree) .. " =" .. lineThree))
    end
    obs.timer_add( function() remove_TVbanner() end,  dinterval )   -- hide overlay after timer period   

end -- simultaneous_update(v)

function string_insert(str1, str2, pos)
-- String insert function.  Keeps original string length; well almost! First position is 0, not 1 as per usual with Lua.  So use 0 for the position variable if 
-- insert required at beginning of str1.  If new string longer than original (because insert is towards the end and inserted string is longer than remaining length) 
-- error printed in log.  Function will not fail though, however all screen formatting bets for this OBS script are off as returned string will be longer than 
-- available on screen display space!!!  Function now also used for Flag file location string generation and often does return an error; but thats OK in this instance.    
    local lenstr1 = string.len(str1)
    local lenstr2 = string.len(str2)
    if (lenstr2 + pos) > lenstr1 then
        print("string_insert length overrun by: " .. ((lenstr2+pos)-lenstr1) .. ", str1: " .. str1 .. "  str2: " .. str2)
    end
    return str1:sub(1, pos) .. str2 .. str1:sub(pos + (1 + lenstr2))
end -- string_insert()


function toggle_event_position(pressed)  -- F12 Hotkey to toggle Event overlay or Event A or B positions
    if not pressed then
     return
    end
    if simultaneousEvents then --F12 for simultaneous events to swap event A and B positions (but actually does nothing at present other than change status area)
        local source = obs.obs_get_source_by_name("Event 1") -- disable single event banner overlay Source
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            obs.obs_source_release(source)            
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Event 1"))
            end
        end
        local source = obs.obs_get_source_by_name("Event 2") -- disable single event banner overlay Source
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            obs.obs_source_release(source)            
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Event 2"))
            end
        end
        if togglevar2 then
            togglevar2 = false
--[[
            local source = obs.obs_get_source_by_name("Position1 A") -- disable status icon for Position1 A Source
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                obs.obs_source_release(source)                
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Position1 A"))
                end
            end
            local source = obs.obs_get_source_by_name("Position2 B") -- disable status icon for Position2 B Source
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                obs.obs_source_release(source)                
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Position2 B"))
                end
            end
       
            local source = obs.obs_get_source_by_name("Position1 B") -- enable status icon for Position1 B Source
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                obs.obs_source_release(source)                
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Position1 B"))
                end
            end
            local source = obs.obs_get_source_by_name("Position2 A") -- enable status icon for Position2 A Source
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                obs.obs_source_release(source)                
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Position2 A"))
                end
            end
]]            
        else
            togglevar2 = true           
            local source = obs.obs_get_source_by_name("Position1 B") -- disable status icon for Position1 A Source
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                obs.obs_source_release(source)                
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Position1 B"))
                end
            end
            local source = obs.obs_get_source_by_name("Position2 A") -- disable status icon for Position2 B Source
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                obs.obs_source_release(source)               
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Position2 A"))
                end
            end
            local source = obs.obs_get_source_by_name("Position1 A") -- enable status icon for Position1 B Source
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                obs.obs_source_release(source)                
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Position1 A"))
                end
            end
            local source = obs.obs_get_source_by_name("Position2 B") -- enable status icon for Position2 A Source
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                obs.obs_source_release(source)                
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Position2 B"))
                end
            end
        end
    else  -- F12 for single event text overlay position
        obs.obs_source_release(source)
        local source = obs.obs_get_source_by_name("EventData_A") -- disable simultanous event icon Source
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            obs.obs_source_release(source)            
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "EventData_A"))
            end
        end
        local source = obs.obs_get_source_by_name("EventData_B") -- disable simultanous event icon Source
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            obs.obs_source_release(source)            
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("disable_source : " .. "EventData_B"))
            end
        end
        if togglevar1 then
            togglevar1 = false
            event = "Event 2"   --  is this still needed??
            local source = obs.obs_get_source_by_name("Event 2") -- enable text Source (Event group)
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                obs.obs_source_release(source)                
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "Event 2"))
                end
            end
            local source = obs.obs_get_source_by_name("Event 1") -- disable text Source (Event group)
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                obs.obs_source_release(source)                
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Event 1"))
                end
            end
            local source = obs.obs_get_source_by_name("Position1") -- disable event icon Source  *** don't need to do this but just in case!
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                obs.obs_source_release(source)                  
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Position1"))
                end
            end
            local source = obs.obs_get_source_by_name("Position2") -- enable event icon Source  *** don't need to do this but just in case!
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                obs.obs_source_release(source)             
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Position2"))
                end
            end


        else  -- the initial position when script first run
            togglevar1 = true 
            event = "Event 1"  -- is this still needed?
            local source = obs.obs_get_source_by_name("Event 1") -- enable text Source (Event group)
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                obs.obs_source_release(source)                
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "Event 1"))
                end
            end
            local source = obs.obs_get_source_by_name("Event 2") -- disable text Source (Event group)
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                obs.obs_source_release(source)                
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Event 2"))
                end
            end
            local source = obs.obs_get_source_by_name("Position2") -- disable event icon Source
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                obs.obs_source_release(source)               
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Position2"))
                end
            end
            local source = obs.obs_get_source_by_name("Position1") -- enable event icon Source
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                obs.obs_source_release(source)                
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Position1"))
                end
            end
        end
    end
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("End of F12 functions"))
    end 
end -- toggle_event_position()


function toggle_simultaneous_events(pressed)  -- S Hotkey to toggle Simultaneous Events                                         
    if not pressed then
        return
    end
    if simultaneousEvents then  -- change to single event operation
        local source = obs.obs_get_source_by_name("FS Simultaneous Events") -- disable Simultaneous Event status banner
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "FS Simultaneous Events"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("FS Single Event") -- enable Single Event status banner
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "FS Single Event"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("AutoHide") -- enable F8 description
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F8 AutoHide"))
            end
        end
        obs.obs_source_release(source) 
        local source = obs.obs_get_source_by_name("A_B") -- enable F10 description
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            obs.obs_source_release(source)        
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F10 Description"))
            end
        end
        local source = obs.obs_get_source_by_name("NoJudges") -- enable F9 description-NoJudges
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            obs.obs_source_release(source)        
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F9 Descriptiom-NoJudges"))
            end
        end
        local source = obs.obs_get_source_by_name("Event_Type") -- enable F9 description
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            obs.obs_source_release(source)        
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F9 Description"))
            end
        end
        local source = obs.obs_get_source_by_name("Screen_Update") -- enable F3 description
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            obs.obs_source_release(source)        
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F3 Description"))
            end
        end
        local source = obs.obs_get_source_by_name("Event A") -- disable Simultaneous Event A source group
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Event A"))
            end
        end
        obs.obs_source_release(source)
        local source = obs.obs_get_source_by_name("Event B") -- disable Simultaneous Event B source group
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Event B"))
            end
        end
        obs.obs_source_release(source)        
        local source = obs.obs_get_source_by_name("Position1 A") -- disable F12 Simultaneous event status location indicator
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("disable_source : " .. "Position1 A"))
            end
        end
        obs.obs_source_release(source)          
        local source = obs.obs_get_source_by_name("Position1 B") -- disable F12 Simultaneous event status location indicator
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("disable_source : " .. "Position1 b"))
            end
        end
        obs.obs_source_release(source)          
        local source = obs.obs_get_source_by_name("Position2 A") -- disable F12 Simultaneous event status location indicator
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("disable_source : " .. "Position2 a"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("Position2 B") -- disable F12 Simultaneous event status location indicator
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("disable_source : " .. "Position2 B"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("TVBanner2") -- enable single event overlay
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Single Event Overlay"))
            end
        end
        obs.obs_source_release(source)   
        hideDisable = true
        toggle_disable_of_autohide(true) 
        simultaneousEvents = false
        toggle_event_position(true)      
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Single Event Selected"))
        end        
    else                        -- change to simultaneous event operation
        simultaneousEvents = true
        hideDisable = true   -- disable auto hide of TVBanner
        local source = obs.obs_get_source_by_name("AutoHide") -- disable F8 description as not used in Sumultaneous events mode
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F8 Function description (AutoHide)"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("A_B") -- disable F10 description as not used in Sumultaneous events mode
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            obs.obs_source_release(source)            
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F10 Function description (A or B Event?)"))
            end
        end     
        local source = obs.obs_get_source_by_name("Screen_Update") -- disable F3 description as not used in Sumultaneous events mode
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            obs.obs_source_release(source)            
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F3 Function description (Screen_Update)"))
            end
        end           
        local source = obs.obs_get_source_by_name("Event_Type") -- disable old F9 description as not used in Sumultaneous events mode
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            obs.obs_source_release(source)            
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F9 Function description (Event_Type)"))
            end
        end 
        local source = obs.obs_get_source_by_name("NoJudges") -- disable old F9 description-judges as not used in Sumultaneous events mode
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            obs.obs_source_release(source)            
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F9 Function description (NoJudges)"))
            end
        end 
        local source = obs.obs_get_source_by_name("TVBanner2") -- disable single event overlay
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Single Event Overlay"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("JudgeAwards") -- disable single event overlay
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Single Event JudgeAwards"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("SynchroJLabels11") -- disable single Judge labels
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Synchro11 lables"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("SynchroJLabels9") -- disable single judge labels
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Synchro9 Labels"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("SynchroJLabels7") -- disable single judge labels
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Synchro7 Labels"))
            end
        end
        obs.obs_source_release(source)
        local source = obs.obs_get_source_by_name("SynchroJLabels5") -- disable single judge labels
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Synchro5 Labels"))
            end
        end
        obs.obs_source_release(source)
        local source = obs.obs_get_source_by_name("FS Single Event") -- disable single event status banner
        if source ~= nil then
            obs.obs_source_set_enabled(source, false)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "FS Single Event"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("FS Simultaneous Events") -- enable simultaneous event status banner
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "FS Simultaneous Events"))
            end
        end
        obs.obs_source_release(source)  
        local source = obs.obs_get_source_by_name("Event A") -- enable simultaneous Event A source (left)
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Event A"))
            end
        end
        obs.obs_source_release(source)     
        local source = obs.obs_get_source_by_name("Event B") -- enable simultaneous Event B source (right)
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Event B"))
            end
        end
        obs.obs_source_release(source)    
        local source = obs.obs_get_source_by_name("EventData_A") -- enable simultaneous Event A source (left)
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            obs.obs_source_release(source)            
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "EventData_A"))
            end
        end
        local source = obs.obs_get_source_by_name("EventData_B") -- enable simultaneous Event B source (right)
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            obs.obs_source_release(source)            
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "EventData_B"))
            end
        end
        local source = obs.obs_get_source_by_name("Position1") -- enable simultaneous Event A status source (left)
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Position1"))
            end
        end
        obs.obs_source_release(source)     
        local source = obs.obs_get_source_by_name("Position2") -- enable simultaneous Event B status source (right)
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Position2"))
            end
        end
        obs.obs_source_release(source)  
        toggle_event_position(true)        
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Simultaneous Events Selected"))
        end        
    end
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("End of FS functions"))
    end 
end  -- toggle_sumultanious_events


function remove_overlays(pressed)  -- F1 Hotkey to hide the two overlays
    if not pressed then
     return
    end
    local source = obs.obs_get_source_by_name("Event A") -- disable text Source (Event A group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        obs.obs_source_release(source)        
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Event A"))
        end
    end
    local source = obs.obs_get_source_by_name("Event B") -- disable text Source (Event B group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        obs.obs_source_release(source)        
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "Event B"))
        end
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
    local source = obs.obs_get_source_by_name("TVBanner2") -- disable text Source (TVBanner2 group)
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
    local source = obs.obs_get_source_by_name("SynchroJLabels9") -- disable text Source (SynchroJLabels9 group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "SynchroJLabels9"))
        end
    end
    obs.obs_source_release(source)    
    local source = obs.obs_get_source_by_name("SynchroJLabels7") -- disable text Source (SynchroJLabels7 group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "SynchroJLabels7"))
        end
    end
    obs.obs_source_release(source)       
    local source = obs.obs_get_source_by_name("SynchroJLabels5") -- disable text Source (SynchroJLabels5 group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "SynchroJLabels5"))
        end
    end
    obs.obs_source_release(source)       
end  -- remove_overlays()


function display_overlays(pressed)  -- F2 HotKey to show the two overlays; but not the Synchro Judge Labels
    if not pressed then
     return
    end
    -- tvBanner_remove()
    if simultaneousEvents then
        local source = obs.obs_get_source_by_name("Event A") -- enable source Event A
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Event_A"))
            end
        end
        obs.obs_source_release(source)
        local source = obs.obs_get_source_by_name("EventData_A") -- enable text source Event A
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "EventData_A"))
            end
        end
        obs.obs_source_release(source)   
        local source = obs.obs_get_source_by_name("Event B") -- enable Source Event B
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "Event_B"))
            end
        end
        obs.obs_source_release(source)
        local source = obs.obs_get_source_by_name("EventData_B") -- enable text Source Event B
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "EventData_B"))
            end
        end
        obs.obs_source_release(source)     
    else
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

    end
end  -- display_overlays()


function redisplay_overlays(pressed)  --  F3 Hotkey to re display last update
    if not pressed then
     return
    end
    if simultaneousEvents then 
        return
    else
        if resultK[1] == "REFEREE" then
            single_update(resultK)
        end
    end
    obs.script_log(obs.LOG_INFO, string.format("F3 Re-display Overlay"))    
end  -- redisplay_overlays()


function toggle_event_type(pressed)  -- F9 Hotkey to toggle Event type and re-start script ***NOW NOT NEEDED BUT LEFT IN SCRIPT WITH SLIGHT SOURCE MODIFICATION TO REMOVE THE 'F9' LABEL**
    -- Hotkey to toggle between the two event types  *No of judges displayed in the F9 status source is not generated here*
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
       local source = obs.obs_get_source_by_name("F9_Function_Background_False") -- disable F9 background
       if source ~= nil then
           obs.obs_source_set_enabled(source, false)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F9_Function_Background_False"))
           end
       end
       obs.obs_source_release(source)  
       local source = obs.obs_get_source_by_name("F9_Function_Background_True") -- enable F9 background
       if source ~= nil then
           obs.obs_source_set_enabled(source, true)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F9_Function_Background_True"))
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
       local source = obs.obs_get_source_by_name("F9_Function_Background_True") -- disable F9 background
       if source ~= nil then
           obs.obs_source_set_enabled(source, false)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F9_Function_Background_True"))
           end
       end
       obs.obs_source_release(source)  
       local source = obs.obs_get_source_by_name("F9_Function_Background_False") -- enable F9 background
       if source ~= nil then
           obs.obs_source_set_enabled(source, true)
           if debug then
               obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F9_Function_Background_False"))
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
          local source = obs.obs_get_source_by_name("F5_Function_Background_False") -- disable F5 background
          if source ~= nil then
              obs.obs_source_set_enabled(source, false)
              if debug then
                  obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F5_Function_Background_False"))
              end
          end
          obs.obs_source_release(source)  
          local source = obs.obs_get_source_by_name("F5_Function_Background_True") -- enable F5 background
          if source ~= nil then
              obs.obs_source_set_enabled(source, true)
              if debug then
                  obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F5_Function_Background_True"))
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
          local source = obs.obs_get_source_by_name("F5_Function_Background_True") -- disable F5 background
          if source ~= nil then
              obs.obs_source_set_enabled(source, false)
              if debug then
                  obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F5_Function_Background_True"))
              end
          end
          obs.obs_source_release(source)  
          local source = obs.obs_get_source_by_name("F5_Function_Background_False") -- enable F5 background
          if source ~= nil then
              obs.obs_source_set_enabled(source, true)
              if debug then
                  obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F5_Function_Background_False"))
              end
          end
          obs.obs_source_release(source)    
       end
end -- toggle_display_disable()  


function toggle_disable_of_autohide(pressed)  -- F8 Hotkey to toggle autohide disable
    if not pressed then
        return
       end
    if simultaneousEvents then -- F8 does nothing if simultaneous events 
        hideDisable = true
        return
    else
        local source = obs.obs_get_source_by_name("AutoHide") -- enable F8 function description
        if source ~= nil then
            obs.obs_source_set_enabled(source, true)
            if debug then
                obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F8 Function description (AutoHide)"))
            end
        end
        obs.obs_source_release(source) 
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
            local source = obs.obs_get_source_by_name("F8_Function_Background_False") -- disable F8 background
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F8_Function_Background_False"))
                end
            end
            obs.obs_source_release(source)  
            local source = obs.obs_get_source_by_name("F8_Function_Background_True") -- enable F8 background
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F8_Function_Background_True"))
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
            local source = obs.obs_get_source_by_name("F8_Function_Background_True") -- disable F8 background
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F8_Function_Background_True"))
                end
            end
            obs.obs_source_release(source)  
            local source = obs.obs_get_source_by_name("F8_Function_Background_False") -- enable F8 background
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F8_Function_Background_False"))
                end
            end
            obs.obs_source_release(source)    
        end
    end
end -- toggle_disable_of_autohide()  


function toggle_event_a_or_b(pressed)  -- F10 Hotkey to toggle Event A or Event B and re-start  *** this Function needs to be changed to change positions of A & B overlays for simul events.
    if not pressed then
        return
    end
    if not simultaneousEvents then -- single event
        if eventB then
            eventB = false   -- is this still needed?
            local source = obs.obs_get_source_by_name("A_B")  -- Event A
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", "Event A Shown")
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end 
            local source = obs.obs_get_source_by_name("F10_Function_Background_False") -- disable F10 background
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F10_Function_Background_False"))
                end
            end
            obs.obs_source_release(source)  
            local source = obs.obs_get_source_by_name("F10_Function_Background_True") -- enable F10 background
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F10_Function_Background_True"))
                end
            end
            obs.obs_source_release(source)     
        else 
            eventB = true
            if synchro then               
                return   -- Event B for Synchro not possible
            end
            local source = obs.obs_get_source_by_name("A_B") -- Event B
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", "Event B Shown")
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end   
            local source = obs.obs_get_source_by_name("F10_Function_Background_True") -- disable F10 background
            if source ~= nil then
                obs.obs_source_set_enabled(source, false)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Disable_source : " .. "F10_Function_Background_True"))
                end
            end
            obs.obs_source_release(source)  
            local source = obs.obs_get_source_by_name("F10_Function_Background_False") -- enable F10 background
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source : " .. "F10_Function_Background_False"))
                end
            end
            obs.obs_source_release(source)   
        end
        init()  -- re-start the script
    else  -- so simultaneous events
        -- do something here for simultaneous events 
    end
end -- toggle_event_a_or_b()  


function remove_TVbanner()  -- this removes the overlay under timer control
    obs.script_log(obs.LOG_INFO, string.format("start removeTVBanner()"))  
    -- remove the TV Overlay from the screen if not 'hideDisable' and after a user configurable period of time.  
    -- If last dive then remove banner after time period anyway even if 'hideDisable' set.  ***Does not work***
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
    else  -- leftover from auto overlay remove at the end of the event.  Not reliable and when the Recorders display Results or Rankings the banner re-displays!!  What UDP data can drive this?
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
    tvBanner_remove()   -- this is the line that actually removes the overlay!!
    obs.remove_current_callback()  -- stops remove_TVBanner running endlesly
    
    tvBanner_removed = true
    
end --remove_TVbanner()


function tvBanner_remove()  -- this calls the timer, timer_remove, to remove the banner using function remove_TVbanner()
    obs.script_log(obs.LOG_INFO, string.format("start tvBanner_remove()"))  

    local source = obs.obs_get_source_by_name("TVBanner2") -- disable text Source (TVBanner group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        obs.obs_source_release(source)       
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "TVBanner2 "))
        end
    else 
        obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "TVBanner2 source not available!"))
    end

    local source = obs.obs_get_source_by_name("JudgeAwards") -- disable text Source (JudgeAwards)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        obs.obs_source_release(source)        
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "JudgeAwards"))
        end
    end

    local source = obs.obs_get_source_by_name("SynchroJLabels11") -- disable text Source (SynchroJLabels11)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        obs.obs_source_release(source)        
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "SynchroJLabels11"))
        end
    end

    local source = obs.obs_get_source_by_name("SynchroJLabels9") -- disable text Source (SynchroJLabels9)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        obs.obs_source_release(source)        
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "SynchroJLabels9"))
        end
    end

    local source = obs.obs_get_source_by_name("SynchroJLabels7") -- disable text Source (SynchroJLabels7)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        obs.obs_source_release(source)        
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "SynchroJLabels7"))
        end
    end

    local source = obs.obs_get_source_by_name("SynchroJLabels5") -- disable text Source (SynchroJLabels5)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        obs.obs_source_release(source)         
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "SynchroJLabels5"))
        end
    end
   
    obs.timer_remove(remove_TVbanner) 
end  -- tvBanner_remove()


-- process the UDP messages
local function processMessage(k, v, x, y)
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("processMessage()"))
        obs.script_log(obs.LOG_INFO, string.format("simultaneousEvents: %s", simultaneousEvents))
    end    
    if k then -- Is there a first UDP port message present (k)?
--        local resultK = {} -- empty array where we will store data from the first UDP port data stream
        local count = #resultK
        for i=0, count do resultK[i] = nil end  -- clear the array
        local delimiter = ("|") -- UDP data string delimiter chr
        for match in (k .. delimiter):gmatch("(.-)" .. delimiter) do -- fill the array
            table.insert(resultK, match)
        end
        if debug then
           print ('UDP(1) message: "' .. resultK[1] .. '" received, length is ' .. #resultK .. ' fields. Last field is: ' .. resultK[#resultK]) 
        end 
        --  resultK is a sorted array with entries from the UDP data packet             
        if resultK[#resultK] ~= nil then -- not empty so check if empty field at end
            resultK[#resultK] = string.sub(resultK[#resultK], 1, -2) -- CR present at end of data packet so remove from the last field else Lua gets upset when trying to display the last field
        end 

        if simultaneousEvents then
            if resultK[1] == "REFEREE" then
                if resultK[47] == "True" then 
                    synchro = true 
                else 
                    synchro = false
                 end   -- set this so as to be able to display an error message in simultaneous_update() if there is a synchro event
                if resultK[1] == "REFEREE" and resultK[2] == "b" then
                    eventB = true
                else
                    eventB = false
                end
                if not disableUpdate then -- has F5 been pressed? if so dont update overlays?
                   simultaneous_update(resultK)  -- prosess the 'REFEREE' message                
                end
            end
        else    
--            if eventB then
--                if resultK[1] == "REFEREE" and resultK[2] == "b" then  
--                    synchro = false   
--                    if not disableUpdate then -- has F5 been pressed? if so dont update?
--                        single_update(resultK)  -- process the 'REFEREE' message for event B.  (Can't have a synchro Event B!)
--                    end
--                end
--            elseif resultK[1] == "REFEREE" and resultK[2] == "a" then
                if resultK[47] == "True" then
                    synchro = true  -- synchro event
                else 
                    synchro = false
                end
                if not disableUpdate then -- has F5 been pressed? if so dont update overlays?
                    single_update(resultK)  -- prosess the 'REFEREE' message for selected event (F10 - A or B).                
                end
--            end
        end
        if resultK[1] == "AVIDEO" then
            -- Do nothing in this release
        end
        if resultK[1] == "UPDATE" then
            -- Do nothing in this release
        end        
    end
--[[
    if v then -- Is there a second UDP port message present (v)?
        local resultV = {} -- empty array where we will store data from the UDP port data stream
        local delimiter = ("|") -- UDP data string delimiter chr
        for match in (v .. delimiter):gmatch("(.-)" .. delimiter) do -- fill the array
            table.insert(resultV, match)
        end
        if debug then
           print ('UDP(2) message "' .. resultV[1] .. '" received, length is ' .. #resultV .. ' fields. Last field is: ' .. resultV[#resultV])  
        end
        -- resultV is generated array with entries from the UDP data packet
        if resultV[#resultV] ~= nil then -- check if empty field at end
            resultV[#resultV] = string.sub(resultV[#resultV], 1, -2) -- CR present at end of data packet so remove from the last field else Lua gets upset when trying to displaying the last field
        end 

        if resultV[1] == "HELLO" then         
            print ('UDP(2): Server ID: ' .. resultV[2])    -- Do nothing in this release, just print it to the log.
        end 
    end
]]
    if x then -- Is there a third UDP port message present (x)?
        local resultX = {} -- empty array where we will store data from the UDP port data stream
        local delimiter = ("|") -- UDP data string delimiter chr
        for match in (x .. delimiter):gmatch("(.-)" .. delimiter) do -- fill the array
            table.insert(resultX, match)
        end
        if debug then
           print ('UDP(3) message "' .. resultX[1] .. '" received, length is ' .. #resultX .. ' fields. Last field is: ' .. resultX[#resultX])  
        end
        --  resultX is generated array with entries from the UDP data packet
        if resultX[#resultX] ~= nil then -- check if empty field at end
            resultX[#resultX] = string.sub(resultX[#resultX], 1, -2) -- CR present at end of data packet so remove from the last field else Lua gets upset when trying to displaying the last field
        end 

        if resultX[1] == "?????" then         
            single_update(resultX)  -- Process the '?????' message
        end  
    end
--[[
    if y then -- Is there a fourth UDP port message present (y)?
        local resultY = {} -- empty array where we will store data from the UDP port data stream
        local delimiter = ("|") -- UDP data string delimiter chr
        for match in (y .. delimiter):gmatch("(.-)" .. delimiter) do -- fill the array
            table.insert(resultY, match)
        end
        if debug then
           print ('UDP(4) message "' .. resultY[1] .. '" received, length is ' .. #resultY .. ' fields. Last field is: ' .. resultY[#resultY])  
        end
        --  resultY is generated array with entries from the UDP data packet
        if resultY[#resultY] ~= nil then -- check if empty field at end
            resultY[#resultY] = string.sub(resultY[#resultY], 1, -2) -- CR present at end of data packet so remove from the last field else Lua gets upset when trying to displaying the last field
        end 

        if resultY[1] == "!!!!!!" then         
            single_update(resultY)  -- Process the '!!!!!!' message
        end  
    end    
]]
end    -- end processMessage()


function UDPtimer_callback() 
        -- Get UDP data until there is no more, or an error occurs
        -- if the lua script has reloaded then stop any old timers and return    
    if id < activeId then
        obs.remove_current_callback()
        return
    end   
    local source = obs.obs_get_source_by_name("Update_File_Detected") -- disable Status Source (UpdateFileDetected).  Not really an update file now using UDP!
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
    end
    obs.obs_source_release(source)
    repeat  -- first port (58091)
        local dataClient, status = our_server1:receive_from()
        if dataClient then
             if currentDataClient ~= dataClient then
                currentDataClient = dataClient
                fileContentsChanged = true    -- not actually a file (UDP port!) but keep this logic anyway
                eventComplete = false                
                local source = obs.obs_get_source_by_name("Update_File_Detected") -- enable Status Source (UpdateFileDetected).  Not really an update file now using UDP!!
                if source ~= nil then
                    obs.obs_source_set_enabled(source, true)
                end
                obs.obs_source_release(source) 
                if debug then       
                    print("\ndataClient: " .. dataClient)
                end
                processMessage(dataClient, '', '', '')  -- allow for receiving messages from four ports, using port 58091 here
--                local source = obs.obs_get_source_by_name("Event_Complete") -- disable blue status rectangle on 'Status' source dock
--                    if source ~= nil then
--                        obs.obs_source_set_enabled(source, false)
--                    end
--                    obs.obs_source_release(source) 
            else 
                fileContentsChanged = false                    
            end         
        elseif status ~= "timeout" then
            error(status)
        end
    until dataClient == nil
--[[   
    repeat  -- second port (58092)
        local dataServer, status = our_server2:receive_from()
        if dataServer then
            if currentDataServer ~= dataServer then
                currentDataServer = dataServer
                --fileContentsChanged = true  -- clash with above UDP naming!! use perhaps 'fileContents2Changed'? 
                --eventComplete = false -- clash with above UDP naming
                processMessage('', dataServer, '', '')  -- allow for receiving messages from four ports, using P2 58092 here
                if debug then
                print("\ndataServer: " .. dataServer)
                print('dataServer IP: ' .. status:get_ip() .. ',  dataServer port: ' .. status:get_port())
                end
            else
                --fileContentsChanged = false  -- clash with above!
            end
        elseif status ~= "timeout" then
            error(status)
        end
    until dataServer == nil
]]    
    repeat  -- third port (58093)
        local dataWebUp, status = our_server3:receive_from()
        if dataWebUp then
            if currentDataWebUp ~= dataWebUp then
                currentDataWebUp = dataWebUp
                --fileContentsChanged = true  -- clash with above UDP naming!!  use perhaps 'fileContents3Changed'? 
                --eventComplete = false -- clash with above UDP naming
                processMessage('', '', dataWebUp, '')  -- allow for receiving messages from four ports, using P3 58093 here
                if debug then
                    print("\ndataWebUp: " .. dataWebUp)
                    print('dataWebUp IP: ' .. status:get_ip() .. ',  dataWebUp port: ' .. status:get_port())
                end
            else
                --fileContentsChanged = false  -- clash with above UDP naming!!
            end    
        elseif status ~= "timeout" then
            error(status)
        end
    until dataWebUp == nil

--[[
    repeat  -- fourth port (58094)
        local dataAwards, status = our_server4:receive_from()
        if dataAwards then
            if currentDataAwards ~= dataAwards then
                currentDataAwards = dataAwards
                --fileContentsChanged = true  -- clash with above UDP naming!!  use perhaps 'fileContents4Changed'? 
                --eventComplete = false -- clash with above UDP naming
                processMessage('', '', '', dataAwards)  -- allow for receiving messages from four ports, using P4 58094 here
                if debug then
                    print("\ndataAwards: " .. dataAwards)
                    print('dataAwards IP: ' .. status:get_ip() .. ',  dataAwards port: ' .. status:get_port())
                end
            else 

            end    
        elseif status ~= "timeout" then
            error(status)
        end
    until dataAwards == nil
]]   
end  -- end UDPtimer_callback()


function init()
    -- initilise the various start-up paramaters and clears screen (TV overlay)
    -- increase the timer id - old timers will be cancelled
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("init()"))
    end    
    
    activeId = activeId + 1

    id = activeId

    -- start the timer loop for udp port scanning, in ms
    obs.timer_add(UDPtimer_callback, 200)  
    obs.script_log(obs.LOG_INFO, string.format('Listening on UDP ports. Re-start ID: ' .. id))

    -- ensure nothing displayed on startup or function change
    tvBanner_remove()
    -- this does nothing now as work is passed to the UDP routines, but should perhaps initialise the Hotkeys and particular the Simultanous mode environement.  

-- Lua test area.  Code here has very little if anything to do with actually providing the overlays!
--[[



--]]

end -- init()


------------------------------------------------------------------------------------
--    ***        OBS Set-up functions for user configurable items          ***    --
------------------------------------------------------------------------------------
hk = {}                                             -- Function keys F4, F6, F7 & F11 are not used yet!
key_1 = '{ "htk_1": [ { "key": "OBS_KEY_F1" } ], '   -- HK to temp remove_overlays
key_2 = '  "htk_2": [ { "key": "OBS_KEY_F2" } ], '   -- HK to temp display_overlays (all of them)
key_3 = '  "htk_3": [ { "key": "OBS_KEY_F3" } ], '   -- HK to redisplay_overlays
key_4 = '  "htk_4": [ { "key": "OBS_KEY_F12" } ], '   -- HK to toggle_event_position
key_5 = '  "htk_5": [ { "key": "OBS_KEY_F9" } ], '   -- HK to toggle_event_type (synchro or individual)
key_6 = '  "htk_6": [ { "key": "OBS_KEY_F5" } ], '   -- HK to permanently remove overlays
key_7 = '  "htk_7": [ { "key": "OBS_KEY_F8" } ], '   -- HK to disable auto-hide of overlays
key_8 = '  "htk_8": [ { "key": "OBS_KEY_F10" } ], '   -- HK to toggle Event A or Event B
key_9 = '  "htk_9": [ { "key": "OBS_KEY_S" } ] }'     -- HK to toggle simultaneous events mode. Need different methodology for key modifiers such as Ctrl or Shft
                                                      
json_s = key_1 .. key_2 .. key_3 .. key_4 .. key_5 .. key_6 .. key_7 .. key_8 .. key_9
default_hotkeys = {
    {id='htk_1', des='Temporary Remove DR2TVOverlays ',              callback=remove_overlays},
    {id='htk_2', des='Temporary Display All DR2TVOverlays ',         callback=display_overlays},
    {id='htk_3', des='Re-display Overlays ',                         callback=redisplay_overlays},
    {id='htk_4', des='Toggle Event Overlay Position ',               callback=toggle_event_position},
    {id='htk_5', des='Toggle Event Type (Synchro or Individual) ',   callback=toggle_event_type},
    {id='htk_6', des='Permanently Remove All Overlays ',             callback=toggle_display_disable},
    {id='htk_7', des='Disable Auto-hide of Overlays ',               callback=toggle_disable_of_autohide},
    {id='htk_8', des='Toggle to Display Event A or Event B ',        callback=toggle_event_a_or_b},
    {id='htk_9', des='Toggle to/from Simultaneous Event Overlays ',  callback=toggle_simultaneous_events},
}

-- The function named "script_load" will be called on startup
function script_load(settings)
    s = obs.obs_data_create_from_json(json_s)
    for _,v in pairs(default_hotkeys) do
      a = obs.obs_data_get_array(s,v.id)
      h = obs.obs_hotkey_register_frontend(v.id,v.des,v.callback)
      obs.obs_hotkey_load(h,a)
      obs.obs_data_array_release(a)
    end
    obs.obs_data_release(s)

    -- Servers needed to get data from the four UDP ports
    our_server1 = assert(socket.create("inet", "dgram", "udp"))
    obs.script_log(obs.LOG_INFO, string.format("\nHostingClient udp at: " .. Address1:get_ip() .. ":" .. Address1:get_port()))
    assert(our_server1:set_option("reuseaddr", 1))      -- Must set "reuseaddr" or bind will fail when you reload the script  
    assert(our_server1:set_blocking(false))             -- Must set non-blocking to prevent the locking the OBS UI thread
    assert(our_server1:bind(Address1, portClient))      -- Bind our_port on all available local interfaces    
--[[
    our_server2 = assert(socket.create("inet", "dgram", "udp"))
    obs.script_log(obs.LOG_INFO, string.format("HostingServer udp at: " .. Address2:get_ip() .. ":" .. Address2:get_port()))
    assert(our_server2:set_option("reuseaddr", 1))
    assert(our_server2:set_blocking(false))
    assert(our_server2:bind(Address2, portServer))
--]]
    our_server3 = assert(socket.create("inet", "dgram", "udp"))
    obs.script_log(obs.LOG_INFO, string.format("HostingWebUp udp at: " .. Address3:get_ip() .. ":" .. Address3:get_port()))
    assert(our_server3:set_option("reuseaddr", 1))
    assert(our_server3:set_blocking(false))
    assert(our_server3:bind(Address3, portWebUp))
--[[
    our_server4 = assert(socket.create("inet", "dgram", "udp"))
    obs.script_log(obs.LOG_INFO, string.format("HostingAwards udp at: " .. Address4:get_ip() .. ":" .. Address4:get_port()))
    assert(our_server4:set_option("reuseaddr", 1))
    assert(our_server4:set_blocking(false))
    assert(our_server4:bind(Address4, portAwards))
--]]    
end

-- The function named "script_unload" will be called on removal of script
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
--]]    
    if our_server3 ~= nil then
        print('Shutting down our server')
        assert(our_server3:close())
        our_server3 = nil
    end
--[[
    if our_server4 ~= nil then
        print('Shutting down our server')
        assert(our_server4:close())
        our_server4 = nil
    end 
--]]      
end

-- The function named "script_update" will be called when settings are changed by the user
function script_update(settings)
    flagLoc = obs.obs_data_get_string(settings, "flagLoc") -- Flag file path
    dinterval = obs.obs_data_get_int(settings, "dinterval") -- Overlay display period
    debug = obs.obs_data_get_bool(settings, "debug") -- Set debug on or off

    obs.script_log(obs.LOG_INFO, string.format("\nOBS defaults updated, by Script_update()"))  
    obs.script_log(obs.LOG_INFO, string.format("simultaneousEvents: %s", simultaneousEvents)) 
    obs.script_log(obs.LOG_INFO, string.format("Synchro selected: %s", synchro))
    obs.script_log(obs.LOG_INFO, string.format("B Event selected: %s", eventB))
    obs.script_log(obs.LOG_INFO, string.format("Event Complete: %s", eventComplete))
    obs.script_log(obs.LOG_INFO, string.format("Disable Updates: %s", disableUpdate))
    obs.script_log(obs.LOG_INFO, string.format("File Contents Changed: %s", fileContentsChanged))
    obs.script_log(obs.LOG_INFO, string.format("TVBanner removed: %s", tvBanner_removed))
    init()  -- set-up done, now start the main work of this script!
end

-- The function named "script_description" returns the description shown to the user
function script_description()
    return [[<center><h2>Display DiveRecorder Data as a Video Overlay or Overlays</h></center>
             <p>Display diver and scores from DiveRecorder for single individual or synchro diving event or simultaneous individual events.  The approporate OBS Source (.json) file must be imported into OBS for this video overlay to function correctly. You must be connected to the same Class C sub-net as the DR computers. </p><p>Andy - V3.3.0 2023NOV08</p>]]
end

-- The function named script_properties defines the properties that the user can change for the entire script module itself
function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_path(props, "flagLoc", "Path to flags folder (select any file in the folder)", obs.OBS_PATH_FILE, "", nil)
    obs.obs_properties_add_int(props,  "dinterval", "TVOverlay display period (ms)", 4000, 15000, 2000)
    obs.obs_properties_add_bool(props, "debug", "Show debug data in Log file")
    return props
end

-- The function named "script_defaults" will be called to set the default settings and file locations
function script_defaults(settings)
    obs.obs_data_set_default_string(settings, "flagLoc", "C:/Users/<your UserID>/Documents/OBS/mdt/flags/anyfile.png")
    obs.obs_data_set_default_int(settings,  "dinterval", 5000)
    obs.obs_data_set_default_bool(settings, "debug", false)
end

-- The function named "script_save" will be called when the script is saved
-- NOTE: This function is usually used for saving extra data (such as a hotkey's settings).  Settings set via the 'properties' function are saved automatically.
function script_save(settings)
 -- I think this script works better starting from default settings, thus the following commented out!!   
 -- for k, v in pairs(hk) do   -- Saving current Hotkey settings  
 --   a = obs.obs_hotkey_save(hk[k])
 --   obs.obs_data_set_array(settings, k, a)
 --   obs.obs_data_array_release(a)
 -- end
end
