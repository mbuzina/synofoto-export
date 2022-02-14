# synofoto-export
Script to export Synology Photo Metadata to file for further use

# No warranty whatsoever
No guarantee, use at your own risk. It might scramble all of your photos and empty your bank account, sell your house and write a resignation letter to your boss.

# How to use
connect to the synofoto database as the user postgres and execute the sql. Pipe it to a file for re-use. I used it to set tags for faces using exiftools.

ssh user@yournasip
sudo su - postgres
*** su password ***
psql synofoto

pase the sql command for testing

# things to look out for
1. This dumps all the database for all the users. You may want to add a where clause to limit this behaviour. Paths to files are relative to the users path (or to /photo for the shared library)
2. The place names are currently set to german. This can be changed by modifying the line that reads: where gi.lang=7 to whatever language numeber you prefer. 0 = original, 1 = english, 7 = german, I have not checked the rest
3. It tries to map the 6 level of location detail provided in Synology Photos to the 4 levels of detail in EXIF. It tries to be smart about it. It isn't.

# Improvements are welcome
