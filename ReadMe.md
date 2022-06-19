# Description
DR2TVOverlay is an extension for [OBS Studio](https://obsproject.com/) built on top of its scripting facilities utilising the built-in embedded LuaJIT
interpreter. This Lua script uses a number of OBS-Studio Sources to display the event information from [DiveRecorder](https://www.diverecorder.co.uk) (DR) onto
the live event video stream.  To use this script the user will need to be reasonably familiar with Diverecorder and OBS-Studio.
Use the latest version, others kept for my reference during ongoing development.

The script uses the data provided by DR's DR2Video software and its associated text files.  Once running the script
automatically checks the DR2Video files and if a change is detected displays the new information.  The user has the 
capability to automatically hide the dive information overlay and re-display it when DR has updated the file and changes
detected by OBS.  Works for both Individual events and Synchro events and a variable number of judges.  The script works 
with simultaneous events (A & B) as DR2Video has this capability however the user must select which event the overlay is for.
The script does NOT work for a skills circuit!

The information overlay uses two Mono type fonts which need to be loaded on the PC, else the awards alignment will be wrong
and some data may be outside the video overlay area (see Installation notes below).  This script will not function 
correctly without the OBS Source's generated by the JSON file which needs to be imported into OBS by the user.  All the
set-up information is retained by OBS for future runs and does not need to be re-entered.

Diverecorders DR2Video software has a number of user configurable fields where the relevant computer files will be located. 
These file locations need to be entered into the DR2TVOverlay script fields.  An example file location is shown by the script
but this will not work without modification by the user for their specific computer user-id (you can edit the Lua script with
you User-ID if you wish).

There are two different overlay layouts provided by the two script major versions, however at present only script V2.n.n has
the necessary JSON source file available in this repository.  It is unlikely that the V1.n.n script and associated layout 
will be developed further.  

Most user functions (V2.1.0 onwards) can be controlled by hotkeys, as follows:

    F1 = Temporary remove overlays (until next DR2Video file update)

    F2 = Temporary show overlays (until next DR2Video file update)

    F3 = Disable overlay updates (freeze the display)

    F5 = Permanently remove all overlays

    F8 = Disable auto-hide of overlays

    F9 = Toggle event type, Individual or Synchro

    F10 = Toggle to display Event A or Event B (there is no Event B option for Synchro)

    F11 = OBS full screen mode (a predefined OBS hotkey)
    
    F12 = Toggle Event overlay position, top left or top right

# Installation 
These installation notes are for a Windows PC only.  I do not know how a Linux or Mac works and have not tried any of the
following steps on anything other then a Windows 7, 10 and 11 PC.  It MAY work on other OS's as I know OBS-Studio does.
However DR2Video will only run under Windows and thus the file mapping would have to use a networked drive into the OBS 
machine.  

- Download and install two monotype fonts.   The script uses absolute placement for individual data items and if a
proportional font is used the data may extend out of the 'Overlay' bounds or more likely not line-up with other data.  The 
two fonts used are 'DejaVu Sans Mono Book' and 'Monofonto Regular'.  Other monotype fonts may work.

- Download and install Exeldro's [Source Dock](https://obsproject.com/forum/resources/source-dock.1317/), [Gradient Source](https://obsproject.com/forum/resources/gradient-source.1172/) and optionally from Palakis [obs-websocket](https://obsproject.com/forum/resources/obs-websocket-remote-control-obs-studio-from-websockets.466/) add-ins to
OBS-Studio.

- Download zip file from (https://github.com//andy5211d/DR2TVOverlay), unpack/unzip.

    Add `divingoverlaysV2.x.x.lua` to OBS Studio via Tools>Scripts > "+" button 

    Import 'basic.ini' to OBS-Studio via Profile>Import and select the required .ini file

    Import 'divingoverlays-obssourceV2.json' to OBS Studio via Scene Collection>Import and select the required .json file

- Download and install the 'flags' files in the appropriate folder.  Not all the FINA country flags are in the repository
and thus the user may have to download flag files specific to their event.  I use the club logos for local events in Great
Britain.  There are numerous flag file sites on the internet.  OBS seems to work with both .gif and .jpg format files,
however the correct file type must be entered into DR2Video file area (see below).  The user will need to change the
default flag file to one relevant to their event.  The default flag is set to the 'British Diving' logo.

On first install the user must map the necessary DR2Video files in OBS as can be seen in the following two screenshots.

The file location mapping in DR2Video:
![gif](/gifs/DR2Videofilelocations.gif)


The file location mapping in OBS-Studio DR2TVOverlay script:
![gif](/gifs/OBSscriptfilelocations.gif)

The above are two file mapping examples, you can use any mapping that make sense to Windows and your configuration, but
ensure that they are consistent!  Errors in file mapping are the usual cause of the script not working.  It will be
necessary to run an event or two in Diverecorder to generate the files in DR2Video so as to be able to map them. One event
will need to be Event B to produce the required files.  This file mapping should only need to be done once, on initial 
installation of the script. 

# Usage
These operating instructions assume that the user is familiar with Diverecorder and OBS-Studio.  Both programs have lots of
on-line resources on set-up and operation and thus will not be repeated here.  Diverecorder's DR2Video should be loaded and
the scoreboard enabled before OBS-Studio will function correctly (as well of course Diverecorder running an event!).  It is
not important the exact load sequence but I tend to run DR2Video before OBS-Studio.

The default start-up of the script has the following settings:
- Individual Event (F9)
- Event A (F10)
- Event Overlay top left (F12)
- Auto-hide of overlay enabled (F8)
- Overlay Update enabled (F3)
- Overlays Visible (F5)

If the initialisation has gone correctly then the Hotkey status dock will look something like this:
![gif](/gifs/hotkeystatusdock.gif)

The user should use the Hotkeys to change the mode of operation as desired.  In most cases F9 and F10 are only needed
to set-up an event with F1, F2, F3 and F5 used during the event to disable or remove the overlay temporary or permanently
if the event is not going to plan!  

It is likely on initial start-up or re-start that there will be the Event overlay showing with data from the last event.
This overlay can be removed using either Hotkey F1 or F5 dependent upon user preference.  

The overlay script will generally follow what the event Recorders are doing in Diverecorder.  Once running there should be
little to do but note, DR2TVOverlay does not have anyway of showing the reason for deductions, thus user intervention in
the overlay may be desirable at times.

If 'obs-websocket' has been installed in OBS-Studio then it is possible to remotely control OBS using an iPhone or other
portable device, the functions available remotely dependent upon the app loaded on the portable device.  I'm still 
experimenting with this capability!  

## Screenshots

The DR2TVOverlay script generates two overlay banners, a smallish Event banner at the top, either top left or top right
dependent upon the use of Hotkey F12.  The Hotkey status Dock shows the current position of the event banner in the F12
icon.  And a larger dive information banner across the bottom which will show the divers name and dive description and 
then after the judges have entered their awards into DR the divers name and the individual awards, ranking and totals.

For an Individual event the video with a dive description overlay will look something like this:
![gif](/gifs/IndividualDescription.gif)

The large bottom overlay will then disappear after 5 sec (see script settings) and reappear when the judges awards are
displayed on the main scoreboard, something like this:
![gif](/gifs/IndividualAwards.gif)

For a Synchro event the video with dive description overlay will look similar to this:
![gif](/gifs/SynchroDescription.gif)

and when the awards are shown:
![gif](/gifs/SynchroAwards.gif)

The script will automatically cater for a differing number of judges with a minimum of 5 for individual events, for
Synchro events only 9 and 11 judges are supported.  

# To Do
Improve the above instructions!   

Generate 'deductions' Hotkeys with associated descriptive text.  In this version of DR2TVOverlay the display of the reason
for the deduction cannot be automated.  The necessary data is not available in DR2Video to automatically trigger a 
deductions overlay/description.