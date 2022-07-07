# windows-gpg-keys-exporter
Small Powershell to export and sort gpg keys.

1. Export all keys from kleopatra. 
2. Name keys like email.gpg(user@domain.com.gpg) 
3. Check key SCE date. (pass ```$MinimalDate``` variable)
4. Sort keys by date and domain.

Pass this variables for you needs: 
```
[string]$FolderToExport = "C:\gpgexport\" 
[string]$CompanyDomain = "example.com"
[string]$MinimalDate = "2018-01-01"
```
