This script creates directories and moves files as per the request of the client.

This will search through the working directory to check for instances where there are 8-character-long directories that are the same 8 characters as the beginning of a longer-named directory in the same parent directory. It will then move all files from the longer-named directory into the shorter-named directory.

This script will also create shorter-named directories if they don't already exist and move the files as previously described.

This could likely but cut down into a single if statement that uses New-Item to attempt to create a directory if it doesn't already exist without having to check for its existence first, totally elmininating the "else" block.
