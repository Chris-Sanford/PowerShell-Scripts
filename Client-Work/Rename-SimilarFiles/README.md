SYNOPSIS
- This script will find and replace specified text, and all following characters, in the file name of all files within the current working directory.
- For example, if all files followed the convention of YYY - SOME TEXT.jpg, you can use this tool to change all files names to YYY.jpg.

DIRECTIONS

Set $start to whichever substring you'd like to find and replace. This must be a common substring among all target files.

Set $end to '.' to target all files that have a file extension.
- If you'd only like to target a specific file extension, change $end to said file extension starting with .

Save the changes you've made to the script

Open a PowerShell window and change the working directory to the folder with the files you'd like to rename (i.e. "cd C:\Users\Username\Pictures\Vacation")

Call this script by entering the full path of the script, wherever you've saved it.

Alternatively, you can copy the line of code and manually replace the $start and $end variables in the command.
