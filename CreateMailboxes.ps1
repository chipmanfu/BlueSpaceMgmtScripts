
# Need to add Powershell Exchange Snap in to the shell.
#  Run the following in the terminal First.  Add-PSSnapin -name Microsoft.Exchange.Management.Powershell.SnapIn
# Grab user data
$UserImport = Import-CSV C:\Users\Administrator\Desktop\SetupScripts\GFUsers.csv
$OUpath = "OU=Users,OU=sis-Accounts,DC=galfed,DC=com"
# Loop through users and create accounts and set group memberships.
$UserImport | ForEach-Object {
  $alias = $_.FirstName + "." + $_.LastName

  Enable-Mailbox -Identity $alias -Database sis-maildb

}

