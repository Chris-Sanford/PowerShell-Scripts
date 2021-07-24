#Future improvements should include:
#Removing the warning for the CSV format since it comes with a template CSV that's easy to understand
#Create a variable for the filename and path of the HTML template for the email body
#Remove the template.htm warning since the above change would make it redundant.
#Consolidate the `n's into the above Write-Host lines to reduce lines of code and improve readability
#Remove redundant lines between variable declarations
#Automatically get email addresses from Active Directory, remove option to set email domain name and user address(this will require the
#PowerShell AD admin tools to be installed on the machine running the script. Warn user of this)
#Warn user that user running this script must have privileges and permissions to send email as the address doing the sending
#Clean up how comments are done on each line
#Automatically write the output to a log file
#Create more user-friendly (color-coded and properly formatted) output/feedback for users

Write-Host "Make sure the CSV is formatted properly (row 1 contains column headers 'user' and 'computer') and is in the same folder as this script is being run."
Write-Host "`n"

#You can easily generate your own HTML email body by writing one up in Outlook, open it in its own window, then go to File > Save As > and select HTML as the file type.
#Just be sure to host any embedded screenshots somewhere on the Internet since you obviously cannot embed images into HTML an HTML file, but you can reference them from elsewhere.
#Make sure you change the template.htm towards the bottom of this script to the file name and path you're using as your email body template.
Write-Host "Make sure the template.htm for your email message body is in the same folder as this script is being run."
Write-Host "`n"

$targetCSV = Read-Host "Enter name of target CSV"

Import-Csv .\${targetCSV} | ForEach-Object {

#Define/declare variables

$adDomainName = "adDomainName.com"
$emailDomainName = "emailDomainName.com"

$primaryDC = "domain-controller"

$smtpServer = "mail.domain.com"

$fromEmailDisplayName = "Information Technology"

$fromEmailAddress = "IT"+"@"+"${emailDomainName}"

#Remote Desktop Gateway's Fully Qualified Domain Name
$rdsgatewayFQDN = "rdp.domain.com"

#Adds the users and computers to the security groups in Active Directory that are assigned to the RAP and CAP policies on the Gateway
#We have a Group Policy Object set up that will enable remote desktop on these computers and adds the $usersGroup to the computer's local built in Remote Desktop Users group
#You need to be a domain administrator and have the Remote Server Adminsistration tools installed on your machine for this to work
$usersGroup = "Remote_Users"
$computersGroup = "Remote_Computers"

#You'll need to import the .PFX certificate file that's bound to your gateway into your the Current User's Personal certificate store. This can be done through certmgr.msc.
#Copy and paste the hash (or thumbprint) into the $sslHash variable declaration. 
$sslHash = "THUMBPRINT"

#These assume the target CSV is formatted properly. First row in CSV should have 'user' in one column and 'computer' in the other.
${user} = $($_.user)
${computer} = $($_.computer)

$userEmailAddress = "${user}"+"@"+"${emailDomainName}"

#Active Directory identifies computer names as their hostname with a dollar sign at the end, so we'll have to make this change ourselves.
${computerADname} = ${computer}+"$"


#Generate RDPs for the user and computer. Obviously edit these values below if you'd like to customize the RDP files sent beyond pre-filling the user, computer, and gateway.
Write-Host "`n"

Set-Content -Path .\${user}_${computer}.rdp -Value "full address:s:${computer}
username:s:${adDomainName}\${user}
screen mode id:i:2
use multimon:i:0
desktopwidth:i:1920
desktopheight:i:1080
session bpp:i:32
winposstr:s:0,1,790,99,1682,868
compression:i:1
keyboardhook:i:2
audiocapturemode:i:0
videoplaybackmode:i:1
connection type:i:7
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:0
allow font smoothing:i:0
allow desktop composition:i:0
disable full window drag:i:1
disable menu anims:i:1
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
audiomode:i:0
redirectprinters:i:1
redirectcomports:i:0
redirectsmartcards:i:1
redirectclipboard:i:1
redirectposdevices:i:0
autoreconnection enabled:i:1
authentication level:i:0
prompt for credentials:i:0
negotiate security layer:i:1
remoteapplicationmode:i:0
alternate shell:s:
shell working directory:s:
gatewayhostname:s:${rdsgatewayFQDN}
gatewayusagemethod:i:1
gatewaycredentialssource:i:0
gatewayprofileusagemethod:i:1
promptcredentialonce:i:1
gatewaybrokeringtype:i:0
use redirection server name:i:0
rdgiskdcproxy:i:0
kdcproxyname:s:
drivestoredirect:s:
"

Switch ($?)
{
    true{"${user}_${computer}.rdp file generated successfully."}
    false{Write-Host "Generation of RDP file failed. This is unusual. Make sure to enter the username and computer name precisely." -ForegroundColor Red}
}

Write-Host "`n"

#Sign RDP file
rdpsign /sha256 ${sslHash} .\${user}_${computer}.rdp /q

Switch ($?)
{
    true{"${user}_${computer}.rdp file has been signed successfully. This simply makes the 'Do you trust this?' popup less aggressive."}
    false{Write-Host "Signing of ${user}_${computer}.rdp file failed. Please import/install the .PFX certificate of the RDS Gateway into your Current User Personal store." -ForegroundColor Red}
}

Write-Host "`n"

#Add user to Active Directory Remote Users group (one assigned to CAP on gateway)

Add-ADGroupMember -Server ${primaryDC} -Identity ${usersGroup} -Members ${user} 

Switch ($?)
{
    true{"${user} has been added to ${usersGroup} group in Active Directory."}
    false{Write-Host "${user} has NOT been added to ${usersGroup} group in Active Directory. Username was either spelled wrong or you need to install Remote Server Administration Tools on your machine, then reboot." -ForegroundColor Red}
}

Write-Host "`n"

#Add each computer associated to said user to Active Directory Remote Computers group (one assigned to RAP on gateway)

Add-ADGroupMember -Server ${primaryDC} -Identity ${computersGroup} -Members ${computerADname} 

Switch ($?)
{
    true{"${computer} has been added to ${computersGroup} group in Active Directory."}
    false{Write-Host "${computer} has NOT been added to ${computersGroup} group in Active Directory. Computer name was either spelled wrong or you need to install Remote Server Administration Tools on your machine, then reboot." -ForegroundColor Red}
}

Write-Host "`n"

#Email the RDP files with instructions using .htm template

$attachment = ".\${user}_${computer}.rdp"

$body = Get-Content .\template.htm

Send-MailMessage -SmtpServer ${smtpServer} -From "${fromEmailDisplayName} <${fromEmailAddress}>" -To "<${userEmailAddress}>" -Subject "Work From Home User Guide" -BodyAsHTML -Body "${body}" -Attachments ${attachment} -DeliveryNotificationOption OnFailure

Switch ($?)
{
    true{"${userEmailAddress} has been sent an email with instructions. Please note that emails will not appear in the Sent Items folder of ${emailAddress}."}
    false{Write-Host "Something failed when trying to send Email to ${user}. ${smtpServer} could be down/not found, or the script can't find template.htm, or something else." -ForegroundColor Red}
}

Write-Host "`n"
Write-Host "`n"

}

PAUSE
