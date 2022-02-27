--[[
Open Broadcaster Software

OBS > Tools > Scripts

OBS Lua Script - DR2TVOverlay

Provides a number of OBS-Studio Text(GDI+) Sources which display the event information from DiveRecorder (DR) onto the event video stream.  Uses the data provided by DR's 
DR2Video software.  Automatically checks the DR2Video files and if change detected displays the new information.   Has the capability to automatically hide the dive 
information banner and re-display it when DR file changes detected.  Works for both Individual events and Synchro events.  May get updated someday to work for simultanious
events (A & B) as DR2Video has this capability but likley never to be updated for a skills circuit!  May also get updated to display Start Lists and Rankings when I've learnt
enough Lua!!  Needs to use Mono Type of fixed length fonts.  Else award alignment will be wrong and some data may be outside the video display area. 


  V0.13.1 2021-11-21  Clean re-code of original concepts (V0.1.0 - V0.13.0) based on original OBS addon 'textmonitor.lua'.  Still does not generate the banner Source Text(GDI+)
                      in code!   Soon, I think I know how but.....
  V1.0.0  2021-11-27  First version out in the wild!  Now only uses two lines of text at the bottom of the screen.  Includes BD logo at the start of the banner
  V1.0.1  2021-11-30  Judge awards now in individual text cells and Synchro Judge role labels added.  With auto resize of display for synchro awards.  Now needs refactoring as
                      original concept changed so now OBS Source names not representative of content.
  V1.1.1  2021-12-03  Refactored with new concept as TVbanner, visability now triggered by DR text file changes.  Judge awards Text Source name now hard coded into script!  
                      Else this would require far too many user text source selections and text source groups to be viable for user input, (some 28, and a very very particular
                      size, font & screen location for each.  Will make the full OBS Source abcde.json available for users in GitLab/GitHub, sometime...).
  V1.1.2  2021-12-07  Group Scene fade introduced for the Banner.  May need more than one fade routine to work correctly as banner is more than one group.  Still neeeds a major
                      sort out as little oop used (cus I don't realy understand Lua)!
  V1.1.3  2021-12-29  Fade delay added for banner display and banner removal (does not work - removed!)
  V1.1.4  2022-01-09  Dummy file read added (and deletion) as a flag to read DR Dive/Synchro.txt text file for the new data. (Not yet implemented in DR2Video though, so 
                      commented out)
  V1.1.5  2022-01-15  New display format and methodology.  Two lines and thus variables only (lineOne & lineTwo) and data inserted into blank line at required locations.
                      Previous methodology uses four display variables, two per line, (displayName, displayLine1, displayDescription, displayLine2). Display of Judge Awards
                      remains unchanged as each a seperate Text Source group!!
  V1.1.6  2022-01-29  Ranking now generated when Diver and Round complete, eg. Diver 10/10  Round 6/6.  Need to insert ranking into Source Text(GDI+)
  V1.1.7  2022-01-31  Just a tidy-up of previous and addition of delay before Ranking displayed.
  V1.1.8  2022-02-02  Cleaning up the way it works now we have an update file to trigger file read
  V1.1.9  2022-02-03  Changed Text(GDI+) Source names to be more meaningfull as well as variables within the script.
  V1.2.0  2022-02-04  Second version, for National Cup test.  9 judge synchro not well displayed as gap between E4 and S1
  V1.2.1  2022-02-10  Changes to Synchro award box labels to differentate bbetween 9 judge and 11 judge
  V1.2.2  2022-02-17  Ranking display removed from display (does not work).  Code left in for now.
  

*** Things of note ***
1. On start-up sometimes old dive data or judge awards shown.   Sorted if the 'Recorder' does a screen refresh
2. Need to select 'Synchro Event' in script setting for this to work correctly.  In theory as we have two Update files (Individual and Synchro) the script could select 
   appropoate way of working automatically.
3. Text(GDI+) source names are no longer meaningfull.
4. The user setting for 'DR File Check Interval' may be removed in future.
5. For those happy to modify the script, change the file location example to one related to your log-in ID.  Else need to be selected all five file location on each update!
6. For initial configuration it is usefull to be able to generate the two Update text files so that their Windows location can be selected in the scripts user settings
7. TVBanner = TVOverlay!

  The position of data elements in the Dive/Synchro.txt and the Rank.txt strings from DR2Video.
  In Dive/Synchro there are two lines of text in these DR files. First line of the DR file (which would be split_string1[n]) is headers and not generated or used by this script.
  The second line becomes split_string2[n] and get processed and displayed as the video overlay. The rank file data is put into an 2d array (arrRank[][]) with the Diver as the
  first and his/her/their data as the second vairable
      Name:            split_string2[1]                                           Rank            arrRank[Diver][1]
      Team:            split_string2[2]                                           Name            arrRank[Diver][2]
      Dive:            split_string2[3]                                           Team            arrRank[Diver][3]
      Position:        split_string2[4]                                           Score           arrRank[Diver][4]
      Board:           split_string2[5]                                           Flag            arrRank[Diver][5]
      DD:              split_string2[6]                                           Start No        arrRank[Diver][6]
      DiveDescription: split_string2[7]                                           Completed       arrRank[Diver][7]
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
local interval, dinterval, debug  -- interval = time between dummy file checks.  dinterval = time to display the TV overlay after file update
local activeId = 0 -- active file check id's
local rankTextstring = " " -- the ranking display text string
local current = {} -- current user values to compare with next user update.  Not used (I think!), left over from original 'textmonitor.lua' script

-- what is the following doing?   when does this get called??  Why just TVBanner, what about the other text sources?
local source = obs.obs_get_source_by_name("TVBanner") -- disable text Source (TVBanner group) after time period set by user
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
        local result = {} -- empty array where will store data from the DR2Video text files
        local delimiter = ("|") -- DR text string delimiter chr, can be a "," if user has not changed DR2Video defaults
        for match in (line2 .. delimiter):gmatch("(.-)" .. delimiter) do -- fill the array
            table.insert(result, match)
        end
        split_string2 = result -- generates an array with 28 entries from line 2 of the DR text file (line 1 which is headers not used)
        split_string2[28] = string.sub(split_string2[28], 1, -2) -- CR present at end of each DR text line so remove from the last field [28] else Lua gets upset when displaying the last field
    end
    eventComplete = false

    obs.timer_add( -- start TV Overlay display timer if enabled
        function()
            remove_TVbanner()
        end,
        dinterval
    ) -- start display timer, when expires then Soures's hidden if option is enabled by user. This construct does not look correct but seems to work!!

    displayRankinghide()  -- Hide the ranking display in case left on screen!
    
    local source = obs.obs_get_source_by_name("TVBanner") -- enable text Source (TVBanner group) for display of dive/awards
    if source ~= nil then
        obs.obs_source_set_enabled(source, true)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "TVBanner "))
        end
    end
    obs.obs_source_release(source)

    -- first generate empty text display lines
    lineOne = string.rep(" ", 59) -- set overlay display text line 1 to blanks (the full line)
    lineTwo = string.rep(" ", 59) -- set overlay display text line 2 to blanks (the full line)
    tvBanner_removed = false -- as we are about to display dive data or awards!

    -- now generate the various text displays for the video overlay (OBS Source)
    --                  >>>> *** If a Synchro event then *** <<<<<
    if synchro then
        if split_string2[8] ~= (" ") then -- if awards in J1 field then display them
            display1a = (split_string2[1] .. " -- " .. split_string2[2]) -- display divers names and team
            lineOne = string.insert(lineOne, display1a, 0) -- insert name and team into display vairable, lineOne
            display1b = (" " .. split_string2[3] .. split_string2[4] .. "  Rank " .. split_string2[21])
            lineOne = string.insert(lineOne, display1b, 44) -- insert DiveNo and Rank into the end of lineOne
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
            display2a = " " -- should be nothing in here as this is the awards space!!
            display2b = (" Score " .. split_string2[19] .. "  " .. "Total " .. split_string2[20])
            obs.script_log(obs.LOG_INFO, string.format("display2b=" .. string.len(display2b)))  -- why is this in the log??
            lineTwo = string.insert(lineTwo, display2b, 32) -- insert at the end of lineTwo, first part of lineTwo is the awards, but awards are not in this Text Source!

        else -- Synchro before judge awards so display dive description and ranking, then
             -- disable synchro judge awards, judgeLabels9 and judgeLabels11. Finally enable and display sourcelineTwo
            displayName = (split_string2[1] .. " -- " .. split_string2[2]) -- display divers names and team
            displayName = displayName:sub(1, 37)  -- ensure not more than 37 chrs long
            lineOne = string.insert(lineOne, displayName, 0)
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
            local source = obs.obs_get_source_by_name("sourcelineTwo") -- Enable dive description
            if source ~= nil then
                obs.obs_source_set_enabled(source, true)
                if debug then
                    obs.script_log(obs.LOG_INFO, string.format("Enable_source: " .. "sourcelineTwo "))
                end
            end
            obs.obs_source_release(source)
            --  Adjust amount of data on screen dependent upon event type and no of judges **** All the following needs sorting now using the new display regime ****
            display1a = (" Team " .. split_string2[23] .. "/" .. split_string2[28])
            display1b = ("Round " .. split_string2[24] .. "/" .. split_string2[27])
            lineOne = string.insert(lineOne, display1a, 36)
            lineOne = string.insert(lineOne, display1b, 48)
            sourcelineTwo = (split_string2[7] .. "  " .. split_string2[5] .. "m  Difficulty " .. split_string2[6])
            if sourcelineTwo:len() >= 45 then
                sourcelineTwo = (split_string2[7] .. "  " .. split_string2[5] .. "m  DD " .. split_string2[6])
                if sourcelineTwo:len() >= 50 then
                    sourcelineTwo = (split_string2[7])
                end
            end
            display2a = " "  -- just to keep debug happy so not Nil
            display2b = " "  -- as above!
            lineTwo = string.insert(lineTwo, sourcelineTwo, 0)
            display2 = ("Prev Rank " .. split_string2[21])
            local offset = string.len(display2)
            lineTwo = string.insert(lineTwo, display2, (59 - offset)) -- Insert ranking at the end of lineTwo
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
        displayName = (split_string2[1] .. " -- " .. split_string2[2]) -- display divers name and club
        lineOne = string.insert(lineOne, displayName, 0)
        if split_string2[8] ~= (" ") then -- if award in J1 position then display judge awards
            sourcelineTwo = (" ") -- empty sourcelineTwo field so no awards displayed and debug works correctly
            display1 =
                ("  " .. split_string2[3] .. split_string2[4] .. "  " .. split_string2[5] .. "m  Rank " .. split_string2[21])
            display1a = display1
            display1b = " "
            local offset = string.len(display1)
            lineOne = string.insert(lineOne, display1, (59 - (offset+1)))

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

            display2a = " " -- should be nothing in here as this is the awards space!!
            display2b = (" Score " .. split_string2[19] .. "  " .. "Total " .. split_string2[20])
            if debug then 
                obs.script_log(obs.LOG_INFO, string.format("display2b=" .. string.len(display2b)))
            end
            lineTwo = string.insert(lineTwo, display2b, 32) -- insert at the end of lineTwo, first part of lineTwo is the awards, but awards are not inserted into this Text Source!

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
            -- display first line of text
            display1a = (" Team " .. split_string2[23] .. "/" .. split_string2[28])
            display1b = ("Round " .. split_string2[24] .. "/" .. split_string2[27])
            lineOne = string.insert(lineOne, display1a, 36)
            lineOne = string.insert(lineOne, display1b, 48)

            -- Adjust amount of line2 data on screen dependent upon no of judges   ** All the following needs sorting with the new display regime!
            sourcelineTwo = (split_string2[7] .. "  " .. split_string2[5] .. "m")
            lineTwo = string.insert(lineTwo, sourcelineTwo, 0) -- Insert dive description at the start of lineTwo

            if sourcelineTwo:len() <= 44 then
                display2a = (" ")
                pos2a = 44
                if sourcelineTwo:len() <= 35 then
                    display2a = ("  DD " .. split_string2[6])
                    pos2a = 36
                    if sourcelineTwo:len() <= 28 then
                        display2a = ("  Difficulty " .. split_string2[6])
                        pos2a = 29
                    end
                end
            end
            lineTwo = string.insert(lineTwo, display2a, pos2a)
            display2b = ("  Prev Rank " .. split_string2[21])
            lineTwo = string.insert(lineTwo, display2b, 45) -- Insert ranking at the end of lineTwo
        end
    end

    if debug then -- show the banner text strings (not the awards though!)
        obs.script_log(obs.LOG_INFO, string.format("display1a Length:" .. string.len(display1a) .. " =" .. display1a))
        obs.script_log(obs.LOG_INFO, string.format("display1b Length:" .. string.len(display1b) .. " =" .. display1b))
        obs.script_log(obs.LOG_INFO, string.format("lineOne Length:" .. string.len(lineOne) .. " =" .. lineOne))
        obs.script_log(
            obs.LOG_INFO,
            string.format("sourcelineTwo=" .. string.len(sourcelineTwo) .. " =" .. sourcelineTwo)
        )
        obs.script_log(obs.LOG_INFO, string.format("display2a Length:" .. string.len(display2a) .. " =" .. display2a))
        obs.script_log(obs.LOG_INFO, string.format("display2b Length:" .. string.len(display2b) .. " =" .. display2b))
        obs.script_log(obs.LOG_INFO, string.format("lineTwo Length:" .. string.len(lineTwo) .. " =" .. lineTwo))
    end

    -- insert text into the Text(GDI+) OBS Sources
    local source = obs.obs_get_source_by_name(source_nameName) -- Banner Line-one text source insert, old variable name
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", lineOne)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end

    local source = obs.obs_get_source_by_name(source_sourcelineTwo) -- Banner Line-two text source insert, old variable name
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", lineTwo)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
end -- update(k, v)

function displayRankinghide()
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("Hide ranking display"))
    end
    local source = obs.obs_get_source_by_name("Ranking")  -- Hide ranking
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        obs.obs_source_release(source)
    end
    obs.timer_remove(displayRankinghide)
end -- displayRankinghide


function displayRanking() -- insert the rankings text into an OBS Source Text+GDI
    -- need to always remove ranking after a display period, even if overlay hide is disabled else the dive data and awards overlay will be shown together with last ranking!
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("Below is the Ranking text to be displayed\n".. rankTextstring))
    end 

    local source = obs.obs_get_source_by_name("Ranking") -- Enable Text Source for Ranking 
    if source ~= nil then
        obs.obs_source_set_enabled(source, true)
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", rankTextstring)  -- "text" will be inserted into the ranking Text Source for overlay
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
    obs.timer_add(displayRankinghide, dinterval*4) -- now hide the ranking after delay period   
end -- displayRanking()


function displayRankingdelay()  -- delay the ranking display
--    if disable display hide (so banner always displayed) then hide banner and then show ranking 
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("Delay ranking display after last dive awards"))
    end
    displayRanking()  -- now display the ranking
    obs.timer_remove(displayRankingdelay)
end   -- displayRankingdelay


function ranking() -- event finished so generate ranking
    local f, err = io.open(textFileR, "rb")
    if err then print("Ranking file missing; how did we get to this point!!") end
    local arrRank = {}  -- array to insert rank info into
    local i = 0
    for line in f:lines() do
        i = i + 1 --  will provide the number of lines in the rank file
        local row = {}
        for match in string.gmatch(line, "[^|]+") do -- find field delimiter of "|" as .txt file used, could be a "," if .csv file used!
            table.insert(row, match)
        end
        table.insert(arrRank, row)
    end
    f:close()
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("No of divers in Rank file: " .. i-1))
    end

    if arrRank[1][7] == 1 then eventCompleted = true else eventCompleted = false end 
    obs.script_log(obs.LOG_INFO, string.format("Event Completed: %s", eventCompleted))

    rankTextstring =
        (split_string2[25] .. "\n     RESULTS         (Unoffical) \n Rank         Name/Club           Score ")
    for divers = 2, i do
        local rankText = string.rep(" ", 40) -- set display text line to blanks
        rankText = string.insert(rankText, arrRank[divers][1], 1)
        rankText = string.insert(rankText, (arrRank[divers][2] .. " " .. arrRank[divers][3]), 5)
        rankText = string.insert(rankText, arrRank[divers][4], 32)
        rankTextstring = rankTextstring .. "\n" .. rankText
    end
    rankTextstring = rankTextstring .. "\n                                   "
    obs.timer_add(displayRankingdelay,dinterval*1.5)
end -- ranking()


local function checkFile(id)
    -- if the lua script has reloaded then stop any old timers and return
    if id < activeId then
        obs.remove_current_callback()
        return
    end
    obs.timer_remove(disable_source) -- remove the banner display timer (is this the correct timer??)

    -- script not reloaed so check for DUpdate and SUpdate files
    -- now check if event ended and the display of the last dive is complete (display time ended)  If so display Ranking for the 2x display period set by user.  **** This now removed in V1.2.2 ****
    if eventComplete then
        if tvBanner_removed then
    -- this left in in case we need to do something at the end of an event.  Such as remove overlay if not on timed removal?
--            obs.script_log(obs.LOG_INFO, string.format("Display Ranking!"))
--            tvBanner_remove()   -- should this be enabled even if not displaying ranking??  Then what about awards and judge roles source, disable them??
--            ranking()
            eventComplete = false
        end
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

-- String insert function.  Keeps original string length; almost! First position is 0 not as per usual with Lua of 1.  So use 0 for the pos vairable if insert required at beginning of str1.  If new string longer than original (because insert is towards the end and inserted string is longer than available length) error printed in log.  Function does not fail though, however all formatting bets for this OBS script are off as returned string will be longer then original!!!
function string.insert(str1, str2, pos)
    local lenstr1 = string.len(str1)
    local lenstr2 = string.len(str2)
    if (lenstr2 + pos) > string.len(str1) then
        print("Function String.Insert length error")
    end
    return str1:sub(1, pos) .. str2 .. str1:sub(pos + (1 + lenstr2))
end -- string.insert()


function remove_TVbanner()
    -- remove the TV Banner from the screen after a user configurable period of time.  But only if not final dive.  If last dive then remove banner after time period anyway.
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
        tvBanner_remove()
        obs.remove_current_callback()
    end
    tvBanner_removed = true
end --remove_TVbanner()


function tvBanner_remove()
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("tvBanner_remove()"))
    end
    local source = obs.obs_get_source_by_name("TVBanner") -- disable text Source (TVBanner group)
    if source ~= nil then
        obs.obs_source_set_enabled(source, false)
        if debug then
            obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "TVBanner "))
        end
    else 
        obs.script_log(obs.LOG_INFO, string.format("Disable_source (tvBanner_remove): " .. "TVBanner source not available!"))
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
    end -- this may not work as textFile is allocated to either textFileI or textFileS dependent upon synchro settings.  Thus one file is allways true!

    -- start the timer id to check the text file
    local id = activeId

    -- start timer to check for DUpdate or SUpdate file
    obs.timer_add(
        function()
            checkFile(id)
        end,
        interval
    ) -- the file check timer and calling the checkFile() function

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
    textFileR = obs.obs_data_get_string(settings, "textFileR") -- Ranking data file, usually Rank.txt
    textFileDI = obs.obs_data_get_string(settings, "textFileDI") -- Dummy file to act as Individual event new data trigger
    textFileDS = obs.obs_data_get_string(settings, "textFileDS") -- Dummy file to act as Synchro event new data trigger
    source_nameName = obs.obs_data_get_string(settings, "sourcelineOne") -- Source Text(GDI+) to insert Name string into start of line 1
    source_sourcelineTwo = obs.obs_data_get_string(settings, "sourcelineTwo") -- Source Text(GDI+) to insert Dive description into start of line 2
    source_ranking = obs.obs_data_get_string(settings, "sourceRanking") -- Source Text(GDI+) to insert Rankings into
    interval = obs.obs_data_get_int(settings, "interval") -- Interval between file check actions
    dinterval = obs.obs_data_get_int(settings, "dinterval") -- Banner and ranking display period
    debug = obs.obs_data_get_bool(settings, "debug") -- Set debug on or off
    synchro = obs.obs_data_get_bool(settings, "synchro") -- Select for a Synchro event
    hideDisable = obs.obs_data_get_bool(settings, "hideDisable") -- Turn off banner hide
    if synchro then -- this now may not be needed in the Update trigger file way of working!!  Will need a default file though for the programme to function correclty else sees no file selected
        textFile = textFileS
    else
        textFile = textFileI
    end
    if debug then
        obs.script_log(obs.LOG_INFO, string.format("(OBS defaults updated) Script_update()"))
    end    
    obs.script_log(obs.LOG_INFO, string.format("\nSynchro selected: %s", synchro))
    init()  -- now start processing 
end

-- A function named "script_description" returns the description shown to the user
function script_description()
    return [[<center><h2>Display DiveRecorder Data</h></center>
             <p>Display diver and scores from DiveRecorder for individual and synchro events.  DR2Video text file & path must be entered for individual events (Dive.txt) and for synchro events (Synchro.txt).  Dummy files (DUpdate.txt & SUpdate.txt) needs to be entered to trigger an update of the DR data .txt files.  Lastly a rank file (Rank.txt) needs to be entered for the Rank display at end of event.  The approporate OBS Source .json file must be Imported for this video banner overlay to function correctly.  </p><p>Andy - V1.2.2 2022Feb27</p>]]
end

-- A function named script_properties defines the properties that the user can change for the entire script module itself
function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_path(props, "textFileI", "Individual DR2Video File", obs.OBS_PATH_FILE, "", nil)
    obs.obs_properties_add_bool(props, "synchro", "Select if Synchro Event") --** may not be needed in the new regime of update files
    obs.obs_properties_add_path(props, "textFileS", "Synchro DR2Video File", obs.OBS_PATH_FILE, "", nil)
    obs.obs_properties_add_path(props, "textFileR", "Ranking DR2Video File", obs.OBS_PATH_FILE, "", nil)
    obs.obs_properties_add_path(
        props,
        "textFileDI",
        "DR2Video Individual Update Trigger File",
        obs.OBS_PATH_FILE,
        "",
        nil
    )
    obs.obs_properties_add_path(props, "textFileDS", "DR2Video Synchro Update Trigger File", obs.OBS_PATH_FILE, "", nil)

    -- Line one Source.  Likly to be 'LineOne'
    local p =
        obs.obs_properties_add_list(
        props,
        "sourcelineOne",
        "Text(GDI+) Source for Line One",
        obs.OBS_COMBO_TYPE_EDITABLE,
        obs.OBS_COMBO_FORMAT_STRING
    )
    local sources = obs.obs_enum_sources()
    if sources ~= nil then
        for _, sourcelineOne in ipairs(sources) do
            source_id = obs.obs_source_get_unversioned_id(sourcelineOne)
            if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
                local name = obs.obs_source_get_name(sourcelineOne)
                obs.obs_property_list_add_string(p, name, name)
            end
        end
        obs.source_list_release(sources)
    end

    --  Line two Source.  Likly to be 'LineTwo'
    local p =
        obs.obs_properties_add_list(
        props,
        "sourcelineTwo",
        "Text(GDI+) Source for Line Two",
        obs.OBS_COMBO_TYPE_EDITABLE,
        obs.OBS_COMBO_FORMAT_STRING
    )
    local sources = obs.obs_enum_sources()
    if sources ~= nil then
        for _, source_sourcelineTwo in ipairs(sources) do
            source_id = obs.obs_source_get_unversioned_id(source_sourcelineTwo)
            if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
                local name = obs.obs_source_get_name(source_sourcelineTwo)
                obs.obs_property_list_add_string(p, name, name)
            end
        end
        obs.source_list_release(sources)
    end

    --  Source for rankings.  Likly to be "Ranking".
    local p =
        obs.obs_properties_add_list(
        props,
        "sourceRanking",
        "Text(GDI+) Source for Rankings",
        obs.OBS_COMBO_TYPE_EDITABLE,
        obs.OBS_COMBO_FORMAT_STRING
    )
    local sources = obs.obs_enum_sources()
    if sources ~= nil then
        for _, source_ranking in ipairs(sources) do
            source_id = obs.obs_source_get_unversioned_id(source_ranking)
            if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
                local name = obs.obs_source_get_name(source_ranking)
                obs.obs_property_list_add_string(p, name, name)
            end
        end
        obs.source_list_release(sources)
    end

    obs.obs_properties_add_int(props, "dinterval", "TVBanner display period (ms)", 4000, 20000, 1000)
    obs.obs_properties_add_bool(props, "hideDisable", "Disable TV Banner Auto Hide")
    obs.obs_properties_add_int(props, "interval", "DR File Check Interval (ms)", 1500, 20000, 500)
    obs.obs_properties_add_bool(props, "debug", "Show debug data in Log file")

    return props
end

-- A function named "script_defaults" will be called to set the default settings
function script_defaults(settings)

    obs.obs_data_set_default_string(settings, "textFileI", "C:/Users/<your Username>/Documents/OBS/mdt/temp/Dive.txt")
    obs.obs_data_set_default_string(settings, "textFileS", "C:/Users/<your Username>/Documents/OBS/mdt/temp/Synchro.txt")
    obs.obs_data_set_default_string(settings, "textFileR", "C:/Users/<your Username>/Documents/OBS/mdt/temp/Rank.txt")
    obs.obs_data_set_default_string(settings, "textFileDI", "C:/Users/<your Username>/Documents/OBS/mdt/temp/DUpdate.txt")
    obs.obs_data_set_default_string(settings, "textFileDS", "C:/Users/<your Username>/Documents/OBS/mdt/temp/SUpdate.txt")

    obs.obs_data_set_default_string(settings, "sourcelineOne", "")
    obs.obs_data_set_default_string(settings, "sourcelineTwo", "")
    obs.obs_data_set_default_string(settings, "sourceRanking", "")
    obs.obs_data_set_default_int(settings, "dinterval", 5000)
    obs.obs_data_set_default_int(settings, "interval", 1000)
    obs.obs_data_set_default_bool(settings, "debug", false)
    obs.obs_data_set_default_bool(settings, "synchro", false) --** may not be needed in the new regime of update files
    obs.obs_data_set_default_bool(settings, "hideDisable", true)
end

-- A function named "script_save" will be called when the script is saved
-- NOTE: This function is usually used for saving extra data (such as a hotkey's settings).  Settings set via the 'properties' function are saved automatically.
function script_save(settings)
end
