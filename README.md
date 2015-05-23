HipChat Screenshot
==================

This is a simple ruby script to take a screenshot, on Mac OS or from UN*X
running Gnome desktop, and post it to your choice of a HipChat room.

1. gem install hipchat
1. put script wherever you want and run it once; it will create a skeletal `~/.hipchat-screenshot.yml` file, which you should edit with your list of rooms, API token, username, etc.
1. run script; it will give you crosshairs to make a selection, then ask you whether/where to post it, then post it

### Configuration ###

In `~/.hipchat-screenshot.yml` you may configure:

* `username`: required: your hipchat username
* `api_token`: required: you can get it from [here](https://www.hipchat.com/account/api)
* `rooms`: required: a hash of Room Name: Room Id   You can find the room ids [here](https://www.hipchat.com/rooms?t=mine) by looking at the links to the various rooms; the id is the number after `/show/` in the URL.
* `save_dir`: optional: path to a directory where screenshots will be saved; default is to delete them after upload

### Keyboard Shortcut for Easier Launching ###

#### MacOS ####

* Open Automator
* Create a new Service
* Service receives "no input"
* Drag the "Run Shell Script" action to the right
* Replace the script with something like `/usr/bin/ruby /path/to/hipchat-screenshot || true`
* Save the service as something like "Hipchat Screenshot"
* Go to the "Keyboard Shortcuts" section of the "Keyboard" preferences pane
* Choose "Services" on the left and scroll to the bottom to find "Hipchat Screenshot"
* Double-click on the area on the right and press the keys for something sufficiently unique but memorable; I like "Command-Control-Shift-4" (which requires unchecking the "Copy picture of selected area to clipboard" shortcut under "Screen Shots" on the left; but I never used that anyway)
