#Start-BackupTool

<# Known issues, bug fixes, and features to be added:
- Fix issue where interactive prompts do not properly set multiple users variable/array
- The Restore function should just automatically restore all Backup folders in their Home Directory
- Restore function is not working at all, Get-BackupFolders not working
- De-pluralize names of functions to follow naming convention best practices for PowerShell
--- Change "folders" to "directory"
#>

#Region Global Variables
#Set the appropriate variables for your domain/environment
$global:domainName = ""
#endregion

#Region Interactive Functions
function Show-Menu
{
    param
    (
        [string]$Title = 'Local User Data Backup and Restore Tool'
    )

  Clear-Host

  Write-Host "`nYou must have the Remote Server Administration Tools installed."

  Write-Host "`nYou must run this as an Administrator."

  Write-Host "`n================ $Title ================"
 
  Write-Host "`n1: Press '1' to back up data from a locally-attached drive."
  Write-Host "`n2: Press '2' to back up data from a remote computer."
  Write-Host "`n3: WORK IN PROGRESS: Press '3' to restore $env:USERNAME's data to this computer as shortcuts (run as target user as non-admin!)"
  Write-Host "`n4: WORK IN PROGRESS: Press '4' to remotely restore user data from their Home Directory to their computer as shortcuts."
  Write-Host "`n5: Press '5' to exit."
}

function Start-Prompts
{
    do
    {
        Show-Menu
        $input = Read-Host "`nType selection and press Enter"
        switch ($input)
        {
            '1' #Scope: Local Selected
            {
                Clear-Host
                $scope = "Local" #Set $scope to Local
                
                Get-PSDrive -PSProvider 'FileSystem' #Show available drive letters

                $driveLetter = Read-Host "Enter the letter of the target drive" #Ask for which drive letter to target

                $computer = Read-Host "Enter the name of the computer to be backed up" #Ask for name of computer the drive is from
                
                Get-ChildItem -Path "${driveLetter}:\Users\" -Name #Display list of available user profiles on target drive

                $users = Read-Host "Enter usernames to be backed up, seperated by commas. Leave blank if you'd like to back up all users besides IT/service/built-in accounts" #Ask for list of users if applicable, default to all users except exceptions if input is blank
                $users = $users.Split(',')  #Remove commas for a proper array
                #Currently, multiple user entries does not work.

                Backup-Data -Scope $scope -Computer $computer -Users $users -DriveLetter $driveLetter

                PAUSE
            }
            '2' #Scope: Remote Selected
            {
                Clear-Host

                $scope = "Remote" #Set $scope to Remote

                $computer = Read-Host "Enter the name of the target computer" #Ask for name of computer to target

                Get-ChildItem -Path "\\${computer}\C$\Users\" -Name #Display list of available user profiles

                $users = Read-Host "Enter usernames to be backed up, seperated by commas. Leave blank if you'd like to back up all users besides IT/service/built-in accounts" #Ask for list of users if applicable, default to all users except exceptions if input is blank
                $users = $users.Split(',') #Remove commas for a proper array
                #Currently, multiple user entries does not work.

                Backup-Data -Scope $scope -Computer $computer -Users $users -DriveLetter $driveLetter

                PAUSE
            }
            '3' #Locally restore files from a user's Home directory as shortcuts
            {
                Clear-Host

                $scope = "Local" #Set $scope to Local

                Restore-Data -Scope $scope -User $env:USERNAME

                PAUSE
            }
            '4' #Remotely restore files from a user's Home directory as shortcuts
            {
                Clear-Host

                $scope = "Remote" #Set $scope to Local
                
                Get-ChildItem -Path "$personalDrive" -Name #Display list of available user profiles

                $user = Read-Host "Enter username to restore files for" #Ask for target user

                Restore-Data -Scope $scope -Computer $computer -User $user -DriveLetter $driveLetter

                PAUSE
            }
        }
    }
    until ($input -eq '5')
}
#endregion

#Region Supporting Functions

function Set-Users #Sets list of users
{
    if (!$global:users)
    {
        if ($scope -eq "Local")
        {
            $global:users = Get-ChildItem -Path "${driveLetter}:\Users\" -Name
            Write-Output "The local users are $global:users"
        }
        elseif ($scope -eq "Remote")
        {
            $global:users = Get-ChildItem -Path "\\${computer}\${driveLetter}$\Users\" -Name
            Write-Output "The remote users on $computer are $global:users"
        }
    }
}

function Set-SourcePath #Sets path to user's User folder
{
    if ($scope -eq "Local")
    {
        $global:sourcePath = "${driveLetter}:\Users\$user"
    }
    elseif ($scope -eq "Remote")
    {
        $global:sourcePath = "\\${computer}\${driveLetter}$\Users\$user"
    }
    Write-Output "The Source Path has been set to $global:sourcePath"
}

function Set-Computer
{
    if ($scope -eq "Local")
    {
        if (!$global:computer) {$global:computer = $env:COMPUTERNAME} #If user doesn't provide input for computer variable, default to local machine's name
    }
    elseif ($scope -eq "Remote")
    {
        Write-Output "You must provide a computer name if you're targetting a remote machine!"
    }
}

function Start-Backup
{
    #/e copies subdirectories and /XJD ignores symbolic links which may appear in Documents folder
    #Piping to Write-Output is necessary for Start-Transcript to capture the output
    #Copy Desktop from computer's local drive to user's personal network drive under folder "$computer_Backup"
    robocopy "${sourcePath}\Desktop" "${destinationPath}\Desktop" /e /XJD | Write-Output

    #Copy Documents from computer's local drive to user's personal network drive under folder "$computer_Backup"
    robocopy "${sourcePath}\Documents" "${destinationPath}\Documents" /e /XJD /tee | Write-Output

    #Copy Downloads from computer's local drive to user's personal network drive under folder "$computer_Backup"
    robocopy "${sourcePath}\Downloads" "${destinationPath}\Downloads" /e /XJD /tee | Write-Output

    #Copy Pictures from computer's local drive to user's personal network drive under folder "$computer_Backup"
    robocopy "${sourcePath}\Pictures" "${destinationPath}\Pictures" /e /XJD /tee | Write-Output

    #Copy Chrome Bookmarks from computer's local drive to user's personal network drive under folder "$computer_Backup"
    robocopy "${sourcePath}\AppData\Local\Google\Chrome\User Data\Default" "${destinationPath}" Bookmarks | Write-Output
}

function New-BackupShortcuts ($source,$destination)
{
    Write-Output "$source will be restored as a shortcut to $destination."
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($destination)
    $Shortcut.TargetPath = $source
    $Shortcut.Save()
}

function Set-LocalUserDirectories #Set local user directories to variables
{
    if ($scope -eq "Local")
    {
        $global:localDesktop = "C:\Users\$user\Desktop"
        $global:localDocuments = "C:\Users\$user\Documents"
        $global:localDownloads = "C:\Users\$user\Downloads"
        $global:localPictures = "C:\Users\$user\Pictures"
    }
    elseif ($scope -eq "Remote")
    {
        $global:localDesktop = "\\$computer\$driveLetter$\Users\$user\Desktop"
        $global:localDocuments = "\\$computer\$driveLetter$\Users\$user\Documents"
        $global:localDownloads = "\\$computer\$driveLetter$\Users\$user\Downloads"
        $global:localPictures = "\\$computer\$driveLetter$\Users\$user\Pictures"
    }

    Write-Output "The target user's Desktop path is $global:localDesktop"
    Write-Output "The target user's Documents path is $global:localDocuments"
    Write-Output "The target user's Downloads path is $global:localDownloads"
    Write-Output "The target user's Pictures path is $global:localPictures"

}

function Get-BackupFolders
{
    if ($scope -eq "Local")
    {
        $driveLetter = Read-Host "Enter user's Home Directory drive letter" #Ask for which drive letter to target

        $backupFolders = (Get-ChildItem -Path "${driveLetter}:\" | Where-Object -Property Name -Match "Backup").Name
        $backupFoldersParsed = @()
    }
    elseif ($scope -eq "Remote")
    {
        $personalDrive = $null #Resets variable to null so when it loops, it doesn't back up a random user account to the previous user's Home Directory
        $personalDrive = (Get-ADUser -Identity "${user}" -Properties HomeDirectory).HomeDirectory #Creates variable for User's Home Directory Network Drive
        $backupFolders = (Get-ChildItem -Path "$personalDrive" | Where-Object -Property Name -Match "Backup").Name
        $backupFoldersParsed = @()
    }

    foreach ($backupFolder in $backupFolders)
    {
        $backupFoldersParsed += $backupFolder.TrimEnd("_Backup")
    }

    Write-Output "The available backup folders are as follows:"
    $backupFoldersParsed

}

function Set-BackupDirectory
{
    if ($scope -eq "Local")
    {
    $backupDirectory = Read-Host "Please enter the name of the backup directory you'd like to restore from as displayed above" #Get Backup Directory

    Write-Output "Backup Directory to be restored is $backupDirectory"

    $personalDrive = $null #Resets variable to null so when it loops, it doesn't back up a random user account to the previous user's Home Directory
    $personalDrive = (Get-ADUser -Identity "${user}" -Properties HomeDirectory).HomeDirectory #Creates variable for User's Home Directory Network Drive

    Write-Output "$user's Home Directory is detected as $personalDrive"

    $backupDirectory = $personalDrive+"\"+$backupDirectory+"_Backup"

    Write-Output "The target backup directory folder name is $backupDirectory"

    #Set backup directories to variables
    $global:backupDesktop = "$backupDirectory\Desktop"
    $global:backupDocuments = "$backupDirectory\Documents"
    $global:backupDownloads = "$backupDirectory\Downloads"
    $global:backupPictures = "$backupDirectory\Pictures"

    Write-Output "The target user's backup Desktop directory is $global:backupDesktop"
    Write-Output "The target user's backup Documents directory is $global:backupDocuments"
    Write-Output "The target user's backup Downloads directory is $global:backupDownloads"
    Write-Output "The target user's backup Pictures directory is $global:backupPictures"
    }
    elseif ($scope -eq "Remote")
    {

    }
}

function Set-BackupFiles
{

    Write-Output "`nThe Set-BackupFiles function sees '$.backupDesktop as $global:backupDesktop"

    #Set a list of all backed up files to variables
    $global:desktopFiles = (Get-ChildItem $global:backupDesktop)
    $global:documentsFiles = (Get-ChildItem $global:backupDocuments)
    $global:downloadsFiles = (Get-ChildItem $global:backupDownloads)
    $global:picturesFiles = (Get-ChildItem $global:backupPictures)

    Write-Output "Files to be backed up include $global:desktopFiles `n $global:documentsFiles `n $global:downloadsFiles `n $global:picturesFiles"
}

function Restore-FilesToComputer
{
    #Restore all backed up files to local user directories as shortcuts
    foreach ($desktopFile in $desktopFiles) {
        Write-Output "Restoring $desktopFile to local Desktop..."
        New-BackupShortcuts -Source $desktopFile.FullName -Destination $global:localDesktop\$desktopFile.lnk
    }

    foreach ($documentsFile in $global:documentsFiles) {
        Write-Output "Restoring $documentsFile.FullName to local Documents..."
        New-BackupShortcuts -Source $documentsFile.FullName -Destination $global:localDocuments\$documentsFile.lnk
    }

    foreach ($downloadsFile in $downloadsFiles) {
        Write-Output "Restoring $downloadsFile to local Downloads..."
        New-BackupShortcuts -Source $downloadsFile.FullName -Destination $global:localDownloads\$downloadsFile.lnk
    }

    foreach ($picturesFile in $picturesFiles) {
        Write-Output "Restoring $picturesFile to local Pictures..."
        New-BackupShortcuts -Source $picturesFile.FullName -Destination $global:localPictures\$picturesFile.lnk
    }
}

#endregion

#Region Main Functions
function Backup-Data ($scope,$computer,$users,$driveLetter) #Backs up the locally stored user data on a target drive
{
    #FEATURES TO BE ADDED
    #Make it so that if user provides a list of users, it skips the process for checking for exceptions (in case we want to back up IT accounts)

    #Region Logging
    $ErrorActionPreference="SilentlyContinue"
    Stop-Transcript | Out-Null #Stop any transcripts if currently running
    $ErrorActionPreference = "Continue"
    $logPath = "C:\Logs\Backup-Data.txt"
    Start-Transcript -Path $logPath -Force
    #endregion

        #Variables
        $scope
        $global:computer = $computer
        $global:users = $users #Users should provide list of users separated by commas. This line is needed to make the parameter User instead of global:users
        $global:sourcePath
        $destinationPath

        $exceptions = @('Admin','Administrator','Default','Public')

        foreach ($exception in $exceptions) { $exceptions = $exceptions += $exception+".$global:domainName" } #Create a copy of each user in the exceptions list that ends in $global:domainName to properly parse exceptions 
        if (!$driveLetter) {$driveLetter = "C"} #If User doesn't provide input for Drive Letter, it will be set to C by default.

        Set-Users

        Set-Computer

        foreach ($user in $global:users)
        {
            #if the user is anywhere in the array of exceptions, ignore it
            if ($exceptions -contains $user)
            {
                Write-Output "We will NOT back up $user"
            }
            else
            {
                Write-Output "We will back up $user"

                $personalDrive = $null #Resets variable to null so when it loops, it doesn't back up a random user account to the previous user's Home Directory
                $personalDrive = (Get-ADUser -Identity "${user}" -Properties HomeDirectory).HomeDirectory #Creates variable for User's Home Directory Network Drive

                Write-Host "Testing connection to $personalDrive before attempting backup..."

                if (Test-Path -Path $personalDrive)#Only proceed with backup if the test to the Home Directory succeeds
                { 
                Write-Output "Home Directory seems valid! Starting backup..."

                Set-SourcePath

                $destinationPath = "${personalDrive}\${global:computer}_Backup" #Sets path to back up files to on user's Home Directory

                Start-Backup

                }
            }
        }

        $computer = $null #Resets $computer variable so it's not reused next time this command is run on a remote machine and you forget to change the parameter
        $global:users = $null

        Write-Output "Backup attempts for all target users has completed. Feel free to open $logPath to verify success."

        PAUSE

        Stop-Transcript

}

function Restore-Data ($Scope,$Computer,$User,$DriveLetter) #Creates shortcuts to the data copied from Backup-Data to the local user directories
{
    #Region Logging
    $ErrorActionPreference="SilentlyContinue"
    Stop-Transcript | Out-Null #Stop any transcripts if currently running
    $ErrorActionPreference = "Continue"
    $logPath = "C:\Logs\Restore-Data.txt"
    Start-Transcript -Path $logPath -Force
    #endregion

    #Variables
    $global:driveLetter

    Get-BackupFolders #Get a full list of all available backup folders on the user's Home Directory and display them

    Set-BackupDirectory #Prompt user to enter target backup folder from Home Directory

    Set-LocalUserDirectories #Set local directories to restore shortcuts to

    Set-BackupFiles #Set backup files to array variable

    Restore-FilesToComputer #Restore backup files to target computer

    Stop-Transcript
}

#endregion

Start-Prompts
