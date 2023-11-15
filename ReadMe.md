# Description
(** The following needs major update now Simultaneous Mode has been implemented.  Diagrams below only show Single event mode
at present **)

DR2TVOverlay is an extension for [OBS Studio](https://obsproject.com/) built on top of its scripting facilities utilising the built-in embedded LuaJIT
interpreter. This Lua script uses a number of OBS-Studio Sources to display the event information from [DiveRecorder](https://www.diverecorder.co.uk) (DR) onto
the live event video stream.  To use this script the user will need to be reasonably familiar with Diverecorder and OBS-Studio.

The script uses the data provided by DR's UDP data broadcasts.  Once running the script automatically checks the UDP data
and if a change is detected displays the new information.  The user has the capability to automatically hide the dive 
information overlay and re-display it when DR sends new data.  Works for both Individual events and Synchro events and a 
variable number of judges.  The script works with simultaneous events (A & B) however the user must select which event the
overlay is for.  A future version may show limited information for both events.  The script does NOT work for a skills
circuit!

The information overlay uses two Mono type fonts which need to be loaded on the PC, else the Judge awards alignment will
be wrong and some data maybe outside the video overlay area (see Installation notes below).  This script will not function 
correctly without the OBS customised source's generated by the JSON file which needs to be imported into OBS by the user.
All the set-up information is retained by OBS for future runs and does not need to be re-entered.

Most user functions can be controlled by hotkeys, as follows:

    F1 = Temporary remove overlays (until next Diverecorder update)

    F2 = Temporary show overlays (until next Diverecorder update and the timeout period)

    F3 = Re-display dive information.  Not used in Simultaneous Events mode

    F5 = Permanently remove all overlays

    F6 = Toggle to display Event A or Event B (there is no Event B option for Synchro). Not used for Simultaneous
         Events mode

    F8 = Disable auto-hide of overlays.  Not used in Simultaneous Events mode

    F10 = Toggle Event overlay position, top left or top right or for Simultaneous Events mode between Event A on the left
          and B on the right or Event B on the left and A on the right

    F11 = OBS full screen mode (a predefined OBS/Windows hotkey)
    
    F12 = Switch between Single Event mode and Simultaneous Events mode

# Installation 
These installation notes are for a Windows PC only.  I do not know how a Linux or Mac works and have not tried any of the
following steps on anything other than a Windows 7, 10 and 11 PC.  It MAY work on other OS's as I know OBS-Studio does
(but Diverecorder certainly will not!).  

- Download and install two monotype fonts.   The script uses absolute placement for individual data items and if a
proportional font is used the data may extend out of the 'Overlay' bounds or more likely not line-up with other displayed 
data.  The two fonts used are 'DejaVu Sans Mono Book' and 'Monofonto Regular'.  Other monotype fonts may work.

- Download and install Exeldro's [Source Dock](https://obsproject.com/forum/resources/source-dock.1317/), [Gradient Source](https://obsproject.com/forum/resources/gradient-source.1172/) and from Palakis [obs-websocket](https://obsproject.com/forum/resources/obs-websocket-remote-control-obs-studio-from-websockets.466/) add-ins to OBS-Studio.

- Download zip file from (https://github.com//andy5211d/DR2TVOverlay), unpack/unzip.

    Add 'ljsocket.lua' to OBS Studio in the C:\Program Files\obs-studio\data\obs-plugins\frontend-tools\scripts folder

    Add 'divingoverlaysV3.x.x.lua' to OBS Studio via Tools>Scripts > "+" button (script needs to be placed in 
    the C:\Program Files\obs-studio\data\obs-plugins\frontend-tools\scripts folder)

    Import 'basic.ini' to OBS-Studio via Profile>Import and select the required .ini file

    Import 'divingoverlays-obssourceV3.x.x.json' to OBS Studio via Scene Collection>Import and select the required .json file

- Download and install the 'flags' files into an appropriate folder.  Not all the FINA country flags are in this repository
and thus the user may have to download flag files specific to their event.  I use the club logos for local events in Great
Britain where a country flag would not be appropriate.  There are numerous flag file sites on the internet and OBS seems to
work with both .gif, .png and .jpg format files; I use .png.  The default flag is set to the 'British Diving' logo. You
will need to change the default flag file to one relevant to your event.   Re-name your default flag file to 'default.png'
as appropriate.

The flag file location mapping in OBS-Studio DR2TVOverlay script:

![gif](/gifs/OBSscriptfilelocations.gif)

Errors in file mapping are the usual cause of the divers country or club flags not being shown.   

Your video settings may be different and will be dependent upon the camera you use and the bandwidth available for the stream
out to the internet and the performance of the computer used for streaming.  These are the settings that seem to work well
for us in the UK with >8Mbps internet service:  

1. Go to File, Settings and then select Output. Under 'Streaming' select a Video Bitrate of 4600Kbps and whatever encoder your
hardware supports.  If you have a machine that provides hardware encoding this will be visible under the Encoder option. Use
hardware encoding if available.   
2. In the 'Video' setting again select a resolution your system can support; we use 1920 x 1080 (16:9) at 50 FPS PAL.  This
should be same as your camera output.  If your camera supports progressive framing for the video output then select this
option, (1080p @ 50PAL).  

# Usage
These operating instructions assume that the user is familiar with Diverecorder and OBS-Studio.  Both programs have lots of
on-line resources on set-up and operation and thus will not be repeated here.  It is not important the exact load sequence 
but I tend to run Diverecorder before starting OBS-Studio (on a separate computer).  You cannot run Diverecorder or any of 
the DR utilities on the same machine you are running OBS-Studio.

*** The computer OBS-Studio is running on must be on the same Ethernet Class C Sub-net that Diverecorder is connected to ***

There are no other settings necessary as this OBS script receives the UDP data broadcast by a Diverecorder instance or 
instances.  Event A or Event B should be selected as necessary if more than one event is running.  This script does NOT work
for a skills circuit!

The default start-up of the script has the following settings: (does not seem to be consistent, toggle each a few times 
after start-up!)
- Single Event (F12)
- Individual Event (F9)
- Event A (F6)
- Event Overlay top left (F10)
- Auto-hide of overlay enabled (F8)
- Overlay Update enabled (F3)
- Overlays Visible (F5)

If the initialisation has gone correctly then the Hotkey status dock will look something like this:
![gif](/gifs/hotkeystatusdock.gif)

The user should use the Hotkeys to change the mode of operation as desired.  In most cases F9 and F10 are only needed
to set-up an event with F1, F3 and F5 used during the event to disable or remove the overlay temporary or permanently
if the event is not going to plan!  

It is likely on initial start-up or re-start that there will be the Event overlay showing with data from the last event.
This overlay can be removed using either Hotkey F1 or F5 dependent upon user preference.  

The overlay script will generally follow what the event Recorders are doing in Diverecorder.  Once running there should be
little to do!

It is possible to remotely control OBS using an iPhone or other portable device, the functions available remotely dependent
upon the app loaded on the portable device.  I'm still experimenting with this capability but OBS Blade seems to work!  

## Screenshots

In Single Event mode the DR2TVOverlay OBS script generates two overlay banners, a smallish Event banner at the top, either
top left or top right dependent upon the use of Hotkey F12.  The Hotkey status Dock shows the current position of the event
banner in the on screen F12 icon.  And a larger dive information banner across the bottom which will show the divers name
and dive description and then after the judges have entered their awards into DR the divers name and the individual awards,
ranking and totals and if appropriate any penalty.  Note: Awards only shown after ALL judges have entered their awards.  
(As of V3.1.1 may not be exactly as shown below.)  

In Simultaneous Events mode there are two smallish banners at the top of the screen.  One for Event A and the other for
Event B.  These are switched by the use of Hotkey F12.

For an Individual event the video with a dive description overlay will look something like this:
![gif](/gifs/IndividualDescription.gif)

The large bottom overlay will then disappear after 5 sec (see script settings) and reappear when the judges awards are
displayed on the main scoreboard, something like this:
![gif](/gifs/IndividualAwards.gif)

For a Synchro event the video with dive description overlay will look similar to this:
![gif](/gifs/SynchroDescription.gif)

and when the awards are shown:
![gif](/gifs/SynchroAwards.gif)

For the Simultaneous Events mode the overlays will look something like this:


The script will automatically cater for a differing number of judges with a minimum of 5 for individual events, for
Synchro events only 9 and 11 judges are supported (although 7 and 5 may work, not tested).  

# To Do

Figure out why the Hotkeys do not start in a known state!  Sometimes the settings are not what the 'Hotkeys' status dock
show on first run!  User needs to toggle each a few times to 'synch' with the status display.  

Configure a useful remote control capability for OBS-Studio.  Several apps are available such as UPDeck, OBS Blade and
Touch Portal, all for iPhone and I guess for other portable devices as well.  Not used either for an event, yet, and would
require a WiFi connection, something not generally used for a Diverecorder set-up!

Make the main overlay dynamic in its length so as to remove the 'white space' when events have a reduced number of judges.
