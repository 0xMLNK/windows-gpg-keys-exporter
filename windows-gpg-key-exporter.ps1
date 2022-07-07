<#	
	.NOTES
	===========================================================================
	 Created on:   	04/07/2022 13:23
	 Created by:   	MLNK
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		Small Powershell to export and sort gpg keys.
		Export all keys from kleopatra.
		Name keys like email.gpg(user@domain.com.gpg)
		Check key SCE date. (pass $MinimalDate variable)
		Sort keys by date and domain.

#>
[array]$emailList = @()
[array]$userlist = @(gpg --list-public-keys --with-colons --keyid-format LONG)

[string]$FolderToExport = "C:\gpgexport\"
[string]$CompanyDomain = "example.com"
[string]$MinimalDate = "2018-01-01"
[string]$regex = "[a-z0-9!#\$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#\$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"


function ExtractEmailsFromKeys()
{
	foreach ($user in $userList)
	{
		$user -match $regex | Out-Null
		$emailList += $Matches.values
	}
	$emailList = $emailList | Select -Unique
	
	return $emailList
}

function ExportGPGPublicKeysByEmail()
{
	$EmailList = ExtractEmailsFromKeys
	
	if (Test-Path -Path $FolderToExport)
	{
		Write-Information ("$FolderToExport exist.")
	}
	else
	{
		Write-Information ("$FolderToExport will be created.")
		New-Item $FolderToExport -itemType Directory
	}
	
	foreach ($Email in $EmailList)
	{
		[string]$KeyName = ($FolderToExport + ($Email -replace '[^a-zA-Z0-9-.@_]', '') + ".gpg")
		Write-Host($KeyName)
		if (Test-Path -Path $KeyName)
		{
			Write-Information("Public key for $KeyName already exist")
		}
		else
		{
			Write-Information("Exporting public key for $Email")
			gpg --output $KeyName --export $Email
		}
	}
}

function CheckGPGCreationDate ()
{
	[string]$FolderCompanyToImport = $FolderToExport + "company_to_import"
	[string]$FolderCompanyOld = $FolderToExport + "company_old"
	[string]$FolderCustomersToImport = $FolderToExport + "customers_to_import"
	[string]$FolderCustomersOld = $FolderToExport + "customers_old"
	[array]$KeyNames = Get-ChildItem $FolderToExport *.gpg -Recurse | Select-Object -expand FullName
	
	if (Test-Path -Path ($FolderCompanyToImport))
	{
		Write-Information ($FolderCompanyToImport + " folder exists.")
	}
	else
	{
		New-Item $FolderCompanyToImport -itemType Directory
	}
	
	if (Test-Path -Path ($FolderCompanyOld))
	{
		Write-Information ($FolderCompanyOld + " folder exists.")
	}
	else
	{
		New-Item $FolderCompanyOld -itemType Directory
	}
	
	if (Test-Path -Path ($FolderCustomersToImport))
	{
		Write-Information ($FolderCustomersToImport + " folder exists.")
	}
	else
	{
		New-Item $FolderCustomersToImport -itemType Directory
	}
	
	if (Test-Path -Path ($FolderCustomersOld))
	{
		Write-Information ($FolderCustomersOld + " folder exists.")
	}
	else
	{
		New-Item $FolderCustomersOld -itemType Directory
	}
	
	foreach ($Key in $KeyNames)
	{
		[datetime]$create_date = (gpg --show-keys $Key.ToString() | Select-String -Pattern "[\d]{4}-[\d]{2}-[\d]{2}" | Select-Object -First 1 | % { $_.Matches } | %{ $_.Value })
		
		if ((get-date $create_date) -le (get-date $MinimalDate))
		{
			if ($Key.Contains($CompanyDomain))
			{
				Write-Host ("[OUTDATED]: $create_date $Key will be moved in $FolderCompanyOld")
				Move-Item -Path $Key -Destination $FolderCompanyOld -Force
			}
			else
			{
				Write-Host ("[OUTDATED]: $create_date $Key will be moved in $FolderCustomersOld")
				Move-Item -Path $Key -Destination $FolderCustomersOld -Force
			}			 
		}
		else
		{
			if ($Key.Contains($CompanyDomain))
			{
				Write-Host ("[UPDATED]: $create_date $Key  will be moved in $FolderCompanyToImport")
				Move-Item -Path $Key -Destination $FolderCompanyToImport -Force
			}
			else
			{
				Write-Host ("[UPDATED]: $create_date $Key will be moved in $FolderCustomersToImport")
				Move-Item -Path $Key -Destination $FolderCustomersToImport -Force
			}
			
		}
	}
}

ExportGPGPublicKeysByEmail
CheckGPGCreationDate