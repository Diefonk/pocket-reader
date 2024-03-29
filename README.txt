Put TXT files in Data/net.diefonk.PocketReader/ to start reading.
Connect your Playdate to your computer and hold d-pad left + Lock button + Menu button to put it in data disk mode, so you can access the data folder.

When opening a file for the first time it will take some time to load it, but subsequent times it will open faster. A JSON file is generated in the data folder, and is what gets loaded later. For large files it is recommended that you use the web loader tool at diefonk.itch.io/pocket-reader, and then put the resulting JSON file on your Playdate (make sure the file name ends with .txt.json), as this will be much faster. Files that have been loaded once are displayed with [L] when selected in the menu. Those files no longer need the source file in the data folder. Files that still have the source file in the data folder are displayed with [S] when selected in the menu.

Menu controls:
* D-pad up/down to make selection.
* A button to open selected file.
* B button held for one second to delete loaded version of selected file, as well as the bookmark for that file. Only works if source file is also present.

Reading controls:
* Crank or d-pad up/down to scroll.
* D-pad left/right to jump between start/end/current position, or scroll one page up/down, or nothing. Set which of these three you want in the System Menu.
* A button held to edit scroll speeds. D-pad left/right to edit crank speed, and up/down to edit d-pad speed.
* B button held to edit margins. D-pad left/right to edit x-margin, and up/down to edit y-margin. Y-margin will be displayed immediately. X-margin left will also be displayed immediately, but the file needs to be re-loaded (delete loaded version and open again) for the right margin to update.
