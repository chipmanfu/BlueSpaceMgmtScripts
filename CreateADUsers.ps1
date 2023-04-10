# This script is for adding users to an Active directory.  Modify however you wish.  The current values are based off a domain called galfed.com.
 # Create destination AD Structures
New-ADOrganizationalUnit -name "GF-Accounts" -path "DC=galfed,DC=com" 
New-ADOrganizationalUnit -name "Users" -path "OU=GF-Accounts,DC=galfed,DC=com"
New-ADOrganizationalUnit -name "Admins" -path "OU=GF-Accounts,DC=galfed,DC=com"
New-ADOrganizationalUnit -name "GF-Groups" -path "DC=galfed,DC=com"

# Set custom parent AD Paths variables
$useracctpath = "OU=Users,OU=GF-Accounts,DC=galfed,DC=com"
$adminacctpath = "OU=Admins,OU=GF-Accounts,DC=galfed,DC=com"
$grouphomepath = "OU=GF-Groups,DC=galfed,DC=com"

# Creatr catchall group for Similar occupations
New-ADGroup -Name "IT support" -GroupScope Global -Path $grouphomepath
New-ADGroup -Name "Executive" -GroupScope Global -Path $grouphomepath

# Grab user data
$UserImport = Import-CSV c:\Users\Administrator\Desktop\SetupScripts\GFUsers.csv

# Loop through users and create accounts and set group memberships.
$UserImport | ForEach-Object {
  $givenname = $_.Firstname
  $initial = $_.MiddleInitial 
  $surname = $_.LastName
  $fullname = $_.FirstName + " " + $_.MiddleInitial + " " + $_.LastName
  $samname = $_.FirstName + "." + $_.LastName
  $email = $samname + "@galfed.com"
  $pass = $_.LastName + "Pass"
  $password = (ConvertTo-SecureString $pass -AsPlainText -Force)
  $group = $_.Occupation

  New-ADuser `
   -GivenName $givenname `
   -Initials $initial `
   -Surname $surname `
   -Name $fullname `
   -Path $useracctpath `
   -SamAccountName $samname `
   -EmailAddress $email `
   -AccountPassword $password `
   -ChangePasswordAtLogon $false `
   -PasswordNeverExpires $true `
   -Enabled $true `
   -Office $group `
   -Company "Galactic Federation" `
   -DisplayName $fullname `
   -Verbose 

# Check if System Admin, if so create second account for domain admin use.
  if ($_.Occupation -eq "Quantium Tech"){
    # Create Domain Admin account - format First.Last.admin
    $adminsam = $samname + ".adm"
    $newpass = $_.LastName + "Admin"
    $adminpass = (ConvertTo-SecureString $newpass -AsPlainText -Force)
    New-ADuser `
     -Name $fullname `
     -Path $adminacctpath `
     -SamAccountName $adminsam `
     -AccountPassword $adminpass `
     -ChangePasswordAtLogon $false `
     -PasswordNeverExpires $true `
     -Enabled $true `
     -Description $group `
     -Company "Galactic Federation" `
     -DisplayName $fullname `
     -Verbose 
    Add-ADGroupMember "Domain Admins" $adminsam -Verbose
    Add-ADGroupMember "Enterprise Admins" $adminsam -Verbose
    Add-ADGroupMember "IT support" $samname -Verbose
  } 
  ElseIf ($_.Occupation -like "Galactic Ambassador"){
    Add-ADGroupMember "Executive" $samname -Verbose
  }
  ElseIf (-not (Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue)){
    New-ADGroup -Name "$group" -GroupScope Global -Path $grouphomepath
    Add-ADGroupMember "$group" $samname -Verbose
  } else {
    Add-ADgroupMember "$group" $samname -Verbose
  }
}

