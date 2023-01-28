# Description
DR2TVOverlay is an extension for [OBS Studio](https://obsproject.com/) built on top of its scripting facilities utilising the built-in embedded LuaJIT
interpreter. This Lua script uses a number of OBS-Studio Sources to display the event information from [DiveRecorder](https://www.diverecorder.co.uk) (DR) onto
the live event video stream.  To use this script the user will need to be reasonably familiar with Diverecorder and OBS-Studio.

The script uses the data provided by DR's UDP data broadcasts.  Once running the script automatically checks the UDP data
and if a change is detected displays the new information.  The user has the capability to automatically hide the dive 
information overlay and re-display it when DR has updated the file and changes detected by OBS.  Works for both Individual
events and Synchro events and a variable number of judges.  The script works with simultaneous events (A & B) however the
user must select which event the overlay is for.  The script does NOT work for a skills circuit!

The information overlay uses two Mono type fonts which need to be loaded on the PC, else the awards alignment will be wrong
and some data may be outside the video overlay area (see Installation notes below).  This script will not function 
correctly without the OBS Source's generated by the JSON file which needs to be imported into OBS by the user.  All the
set-up information is retained by OBS for future runs and does not need to be re-entered.

Most user functions can be controlled by hotkeys, as follows:

    F1 = Temporary remove overlays (until next DR2Video file update)

    F2 = Temporary show overlays (until next DR2Video file update)

    F3 = Disable overlay updates (freeze the display)

    F5 = Permanently remove all overlays

    F8 = Disable auto-hide of overlays

    F9 = Toggle event type, Individual or Synchro (automatic)

    F10 = Toggle to display Event A or Event B (there is no Event B option for Synchro)

    F11 = OBS full screen mode (a predefined OBS/Windows hotkey)
    
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

    Add `divingoverlaysV2.x.x.lua` to OBS Studio via Tools>Scripts > "+" button (script needs to be placed in 
    the C:\Program Files\obs-studio\data\obs-plugins\frontend-tools\scripts folder)

    Import 'basic.ini' to OBS-Studio via Profile>Import and select the required .ini file

    Import 'divingoverlays-obssourceV2.json' to OBS Studio via Scene Collection>Import and select the required .json file

- Download and install the 'flags' files in the appropriate folder.  Not all the FINA country flags are in the repository
and thus the user may have to download flag files specific to their event.  I use the club logos for local events in Great
Britain.  There are numerous flag file sites on the internet and  OBS seems to work with both .gif and .jpg format files,
however the correct file type must be entered into DR2Video file area (see below).  The user will need to change the
default flag file to one relevant to their event.  The default flag is set to the 'British Diving' logo.

The file location mapping in OBS-Studio DR2TVOverlay script:  (not as shown, now changed to only map the flag files path)
![gif](/gifs/OBSscriptfilelocations.gif)

Errors in file mapping are the usual cause of the divers country flags not being shown.   

Your video settings may be different as will be dependent upon the camera you use and the bandwidth available for the stream
out to the internet and the performance of the computer used for streaming.  These are the settings that seem to work well
for us in the UK with >8Mbps internet service:  

1. Go to File, Settings and then select Output. Under 'Streaming' select a Video Bitrate of 4600Kbps and whatever encoder you
hardware supports.  If you have a machine that provides hardware encoding this will be visible under the Encoder option. Use
hardware encoding if available.   
2. In the 'Video' setting again select a resolution your system can support; we use 1920 x 1080 (16:9) at 50 FPS PAL.  This
should be same as your camera output.  If your camera supports progressive framing for the video output then select this
option, (1080p @ 50PAL).  

# Usage
These operating instructions assume that the user is familiar with Diverecorder and OBS-Studio.  Both programs have lots of
on-line resources on set-up and operation and thus will not be repeated here.  Diverecorder's DR2Video should be loaded and
its scoreboard enabled before OBS-Studio will function correctly (as well of course Diverecorder running an event!).  It is
not important the exact load sequence but I tend to run Diverecorder before starting OBS-Studio.

The default start-up of the script has the following settings: (does not seem to be consistent, toggle each after start-up!)
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
little to do.

If 'obs-websocket' has been installed in OBS-Studio then it is possible to remotely control OBS using an iPhone or other
portable device, the functions available remotely dependent upon the app loaded on the portable device.  I'm still 
experimenting with this capability but OBS Blade seems to work!  

## Screenshots

The DR2TVOverlay OBS script generates two overlay banners, a smallish Event banner at the top, either top left or top
right dependent upon the use of Hotkey F12.  The Hotkey status Dock shows the current position of the event banner in 
the F12 icon.  And a larger dive information banner across the bottom which will show the divers name and dive 
description and then after the judges have entered their awards into DR the divers name and the individual awards, ranking
and totals.

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
Improve the above instructions!  Update the file path mapping picture to the latest single flag file path input.

Figure out why the Hotkeys do not start in a known state!  Sometimes the settings are not what the 'Hotkeys' status dock
show on first run!  User needs to toggle each a few times to 'synch' with the status display.  

Configure a useful remote control capability for OBS-Studio.  Several apps are available such as UPDeck, OBS Blade and
Touch Portal, all for iPhone and I guess for other portable devices as well.  Not used either for an event, yet, and would
require a WiFi connection, something not generally used for a Diverecorder set-up!

Make the main overlay dynamic in its length so as to remove the 'white space' when events have a reduced number of judges.

Hotkey F3 seems unnecessary in my experience of running events.  However a 'Re-display' option would be useful.
F3 may get re-purposed...