<# Powershell Script for removing all emails from exchange.  
    WRITTEN BY: Chip McElvain 
    VERSION HISTORY: Version 1 1-15-2021
   
    TO BE EXECUTED ON: Windows Server running Exchange 2016 or 2013

   NOTE: If you get "Not Digitally Signed" ERROR.
   Then open the script in Powershell ISE, then make a simple edit and save it. For example delete the line below
               ### DELETE THIS LINE and save to get rid of Not Digitally signed error ###

     PRE-REQs: Script needs to be ran by User with Exchange admin rights and is a Domain Admin

     NOTE: This runs in two stages/steps.  Step 1 deletes email off the server, this can be done with the exchange database mounted.
       Step 2 will dismount the exchange database, defrag the database, and then remount it.  A necessary step to reduce the edb file size.
       However it will only be dismounted for a short time, on a typical range enviroment, less than a minute.
#>

# This needs to be ran as an admin, so check user context before continuing
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  write-warning "Insufficient permissions to run this script.  Open powershell as Administrator and run this script again."
  break
}

$ans = [system.Windows.Forms.messagebox]::Show("This script will delete all exchange emails.`r`n`nStep 1: Deletes all emails (exchange database remains mounted)`r`nStep 2: Purges all emails (exchange database is dismounted)`r`n`nYou will be prompted before continuing on to step 2 in case you don't want to dismount the database`r`n`nDo you want to continue to Step 1?",'Delete Emails Step 1',4)
if ($ans -eq 'No'){ break } 
# Need to add Exchange management snapin to Powershell
Add-PSSnapin -name Microsoft.Exchange.Management.Powershell.SnapIn
write-host "Starting Deletion of all Email"
Get-Mailbox | search-Mailbox -DeleteContent -Force -Confirm:$false
$db = Get-MailboxDatabase
$logdrive = $db.LogFolderPath.DriveName
$dbname = $db.Name
$edbpath = $db.EdbFilePath
Write-host "Emails have been deleted."
$ans = [system.Windows.Forms.messagebox]::Show("Emails have been deleted!`r`n`nThe next step will purge all emails, but requires the exchange database to be dismounted`r`n`nDo you want to continue to Step 2?",'Purge Emails Step 2',4)
if ($ans -eq 'No'){ break }

[system.windows.messagebox]::show("Next we need to fake a backup.  We need to open Diskshadow to do this.`r`nDiskshadow will open in a new cmd terminal, you will have to click Yes to the UAC prompt.`r`nOnce it opens, another popup box will provide you with directions.`r`nClick OK to open diskshadow and get started.")

Start Diskshadow
sleep 3
[system.windows.messagebox]::show("at the Diskshadow> prompt type the following lines;`r`n`tAdd Volume $logdrive`r`n`tBegin Backup`r`n`tcreate`r`n`nAfter a while you will see a line that says 'Number of shadow copies listed:1'`r`nDone worry about the initial line that says failed`r`n`nWhen you see that line type the following`r`n`n`tend backup`r`n`texit`r`n`nWhen you've completed the above steps, press OK")

#Diskshadow
$ans = [system.Windows.Forms.messagebox]::Show("If you were able to complete the diskshadow steps successfully, press yes to continue",'Purge Emails',4)
if ($ans -eq 'No'){ break }
Write-host "Dismounting $dbname database"
Dismount-database $dbname -confirm:$false
Write-host "Defragging $dbname database"
eseutil /d $edbpath
Write-host "Mounting $dbname database"
Mount-Database $dbname
Write-host "Purge is complete!, Database is mounted."