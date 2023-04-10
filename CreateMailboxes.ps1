
# This script will enable/add exchangemailboxes for all the users in the AD.
# Grab user data, this is a CSV file that has the first line as "FirstName,LastName,MiddleInitial,Occupation", then the following lines follow with
# the information you are using for your AD users.
$UserImport = Import-CSV C:\Users\Administrator\Desktop\SetupScripts\GFUsers.csv
# Change the below variable to match the OU where you're users live.
$OUpath = "OU=Users,OU=GF-Accounts,DC=galfed,DC=com"
# Loop through users and create accounts and set group memberships.
Add-PSSnapin -name Microsoft.Exchange.Management.Powershell.SnapIn
$UserImport | ForEach-Object {
  $alias = $_.FirstName + "." + $_.LastName

  Enable-Mailbox -Identity $alias -Database sis-maildb

}
