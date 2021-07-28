SYNOPSIS:

Set-WorkingProject automates the process of switching the active working project for an application called "PenManager" by printing all other available project directories within the root projects folder, prompting user to select a one of the available projects, closing the application, then renaming the folders as needed for the application to switch to the newly selected project.

INSTRUCTIONS:

-Be sure to set the variables at the top of the script to ensure this functions properly in your environment!

-Be sure to verify that the user profile from which you run this script has the permissions to modify the contents of the project directories (aka you may need to run this as admin)

-Please create an info file (i.e. info.txt) in each project folder with the following formatting:

ProjectName=HELLOWORLD

LastStartDate=07272021

LastStopDate=07282021
