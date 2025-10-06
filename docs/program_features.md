The program has several capabilities... we will explain each one here:

## Convert Conquest card
Transforms the memory card found on the second port into a conquest card.

This feature overrides the whole card. In case it's not that obvious, yes, all data will be lost

## Repair Conquest card
Not yet implemented, since it requires a long and complex investigation of the program design. you may of course use the "Convert conquest card" feature to override your damaged original conquest cards with a blank install

## Check Conquest card Integrity
this will check the card data page by page, calculating a checksum and comparing it with the checksum stored on the card ECC area.  
mismatching checksums will be reported.

if there are 12 mismatches or less, they are shown on screen, else, the ammount is informed, and user may create a text file report by pressing X.

???+ note "Checksum mismatches..."

    Some working original conquest cards can have some checksum mismatches and still work... since we still don't clearly know wich pages are critial in terms of integrity, the program will only remark checksum mismatches if they belong to a page wich is read by the game when checking for a valid conquest card. when displaying on screen, these mismatches are shown in red. on the text report, it is clearly stated at the end of the line.  
    However, at the end of the day. you can't know till you test it on the game

## Dump Conquest card
Extracts the whole data of the conquest card into an image file located on the storage device from wich you ran the program.  
you can make up to 32 dumps, after that, the file for dump 32 will get overwritten

!!! note

    Although this program is oriented to creating conquest card clones, this program is the first PS2 homebrew to offer a safe method to dump SoulCalibur2 Conquest cards from a PS2.  
    Before this, only the PS3 MC adapter was reliable enough for the task (wich is quite expensive)


## Credits
Shows you the credits, all the people that helped me, as well as program version, commit hash and compilation date