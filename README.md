HipChat Screenshot
==================

This is a simple ruby script to take a screenshot, on Mac OS or from UN*X
running Gnome desktop, and post it to your choice of a HipChat room.

1. gem install hipchat
1. put script wherever you want and run it once; it will create a skeletal `~/.hipchat-screenshot.yml` file, which you should edit with your list of rooms, API token, username, etc.
1. run script; it will give you crosshairs to make a selection, then ask you whether/where to post it, then post it
