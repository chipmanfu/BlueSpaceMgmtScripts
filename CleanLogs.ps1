<# PowershellScript for clearing out exchange logs.  Best to run this via scheduled tasks once a week to prevent exchange from filling up.
    WRITTEN BY: Chip McElvain
    VERSION HISTORY: version 1 1-15-2021
    CREDIT:  This script is mostly derived from two sources
        - https://gallery.technet.microsoft.com/office/Clear-Exchange-2013-Log-71abba44#content
        - https://ephams.com/2018/09/powershell-how-to-delete-exchange-transation-logs/

    TO BE EXECUTED ON: Windows Server running Exchange 2019, 2016 or 2013

   NOTE: If you get "Not Digitally Signed" ERROR.
   Then open the script in Powershell ISE, then make a simple edit and save it. For example delete the line below
     PRE-REQs: N/A
#>

### INFORMATIONAL - Below are default locations for exchange logs, you're deployment is possibly different.
###  IISLogPath c:\inetpub\logs\LogFiles\
###  ExchangeLoggingPath  c:\Program Files\Microsoft\Echange Server\V15\Logging\
###  $ETLLoggingPath=  c:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\Logs\


#### USER SET VARIABLES SECTION ####
######------ Default Settings below - change this based on your exchange install/log folder locations.
$days=0
$IISLogPath="C:\inetpub\logs\LogFiles\"
$ExchangeLoggingPath="E:\Exchange2016\Logging\"
$ETLLoggingPath="E:\Exchange2016\Bin\Search\Ceres\Diagnostics\Logs\"
######------ MI6 Range Settings below
#### END USER VARIABLE EDIT SECTION ####

### CleanLogfiles function START
Function CleanLogfiles($TargetFolder){
  write-host -debug -ForegroundColor Yellow -BackgroundColor Cyan $TargetFolder
  if (Test-Path $TargetFolder) {
    $Now = Get-Date
    $LastWrite = $Now.AddDays(-$days)
    $Files = gci $TargetFolder -Recurse | Where { $_.Extension -in ".log",".blg",".etl" } | where {$_.lastWriteTime -le "$lastwrite"} 
    foreach ($File in $Files){
      $FullFileName = $File.FullName  
      Write-Host "Deleting file $FullFileName" -ForegroundColor "yellow"; 
      Remove-Item $FullFileName -ErrorAction SilentlyContinue | out-null
    }
  } Else {
    Write-Host "The folder $TargetFolder doesn't exist! Check the folder path!" -ForegroundColor "red"
  }
}
### CleanLogFiles Function END

### CleanTransactionLogs fuction START
### NOTE: The location of these logs can be determined by the script.  Additionally you can't just open the folder 
### where transaction logs are kept and delete all transaction logs, if you delete transition logs past the last checkpoint
### you WILL BREAK Exchange.  This script determines the last checkpoint and prevents deletion beyond that point. 
function CleanTransactionLogs {
  $db = get-mailboxdatabase
  $logpath = $db.LogFolderPath
  $logprefix = $db.LogFilePrefix
  $file = "$logpath\$logprefix.chk"
  $checkpointfind = eseutil /mk $file | select-string 'Checkpoint:'
  if ($checkpointfind -ne $Null){
    $checkpoint = $checkpointfind[1].ToString().Split(',')[0].Split('x')[1]
    $zeros = "0"*(8 - $checkpoint.Length)
    $chkfilename = $db.LogFilePrefix+$zeros+$checkpoint+".log"
    $chkfile = Get-ChildItem -path $db.LogFolderPath -Filter $chkfilename
    $info = "The log file at the last checkpoint is called "+$chkfile.name+", and was written to at: "+$chkfile.LastWriteTime;$info;echo ' '
    $files = (Get-ChildItem -path $db.LogFolderPath -filter "*.log" | where {$_.name -ne $db.LogFilePrefix+".log" -and $_.name -notlike "*tmp*" -and $_.LastWriteTime -lt $chkfile.LastWriteTime})
    $number = $files.Count
    foreach ($File in $Files){
      $FullFileName = $File.FullName  
      Write-Host "Deleting file $FullFileName" -ForegroundColor "yellow"; 
      Remove-Item $FullFileName -ErrorAction SilentlyContinue | out-null
    }
    $report = "Completed clearing "+$number+" Committed Transaction Logs for "+$db.name+"."
    write-host $report
    echo ' '
  } else {
    $report = "No committed Transaction Logs for "+$db.Name
    write-host $report
    echo ' '
  }
}
### CleanTransactionLogs Function END

##### Execution Section
Add-PSSnapin -name Microsoft.Exchange.Management.Powershell.SnapIn
CleanLogfiles($IISLogPath)
CleanLogfiles($ExchangeLoggingPath)
CleanLogFiles($ETLLoggingPath)
CleanTransactionLogs
