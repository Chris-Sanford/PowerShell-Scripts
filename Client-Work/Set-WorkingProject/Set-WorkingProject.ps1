#Set-WorkingProject.ps1

<# ReadMe
Be sure to set the variables below to ensure this functions properly in your environment!
Be sure to verify that the user context in which you run this script has the permissions to modify the contents of the project directories (aka you may need to run this as admin)
#>

<# NOTES / IN-PROGRESS
Add more user output and progress notes at each step
Create functions like Get/Set-ProjectInfo where necessary
Use Get-Date to define start/stop times/dates
This could probably be done through the creation and/or modification of symbolic links rather than actually renaming folders.
#>

#region Variables
#The following 3 variables are for the user to define:
$baseDirectory = "$ENV:USERPROFILE\Documents\PenManagerProjects" #Define the root directory containing the working project directory and the other available projects. Use either $ENV:UserProfile or $ENV:ProgramFiles or $ENV:ProgramFiles(x86) as a best practice.
$workingProjectName = "WorkingProject"
$infoFileName = "info.txt"

#The following variables are defined dynamically:
$workingProjectDirectory = "$baseDirectory\$workingProjectName"
$workingProjectInfoPath = "$workingProjectDirectory\$infoFileName"
#endregion

<#region Diagnostics
Write-Output "Your base project directory is $baseDirectory"
Write-Output "Your working project directory is $workingProject"
Write-Output "The project you've selected is $newProject"

Write-Output "Getting contents of base project directory..."
Get-ChildItem -Path $baseDirectory
Write-Output "Getting contents of working project directory..."
Get-ChildItem -Path $workingProject
Write-Output "Getting contents of new project directory..."
Get-ChildItem -Path $newProject
#>#endregion

#region Interactive segment begins

#Verify base and working directories, and tell user to modify them in the script if necessary
if (Test-Path $baseDirectory)
{
    Write-Output "Your base project directory is valid."
}
else
{
    Write-Output "Your base project directory is misconfigured. Please modify the `$baseDirectory variable at the top of the script to define your root project folder."
}

if (Test-Path $workingProjectDirectory)
{
    Write-Output "Your working project directory is valid."
}
else
{
    Write-Output "Your working project directory is misconfigured. Please modify the `$workingProjectName variable at the top of the script to define your working project folder."
}

#Verify $infoFileName exists within each project folder, if not, tell user to add them (or automate their creation by prompting user for ProjectName info)


#List all directories/projects within the root/base
Get-ChildItem -Path $baseDirectory

#Allow the user to select the desired project to switch to
$selectedProject = Read-Host "Enter the exact name of the directory of the project you'd like to work on"

$selectedProjectDirectory = "$baseDirectory\$selectedProject" #Sets the directory of the selected project

Write-Output "You've chosen to work on $selectedProject located at $selectedProjectDirectory"

#Warn user that we will close PenManager now, so save their work before proceeding
Stop-Process -Name "PenManager" -Force #Stops the PenManager process. This is necessary to properly switch projects

#Renames working directory to its project name so we can rename the selected project's directory name to $workingProjectDirectory
##Check to make sure info.txt exists in the working project directory
if (Test-Path -Path $workingProjectInfoPath -PathType Leaf)
{
    Write-Output "Info file for working project exists."
    ##Get metadata of working project from text file and create a variable array
    $workingProjectInfo = Get-Content $workingProjectInfoPath | Out-String | ConvertFrom-StringData

    ##Set current working directory folder name to the project name from info.txt
    #First either check to see if it's open by another process (i.e. explorer.exe or notepad.exe) or kill the associated explorer.exe instance entirely
    Rename-Item -Path $workingProjectDirectory -NewName $workingProjectInfo.ProjectName

    #Renames the newly-selected project to $workingDirectory
    #First either check to see if it's open by another process (i.e. explorer.exe or notepad.exe) or kill the associated explorer.exe instance entirely
    Rename-Item -Path $selectedProjectDirectory -NewName $workingProjectName
}
else
{
   Write-Output "Info file for working project does not exist. Please create one following the provided template." 
}

#endregion
