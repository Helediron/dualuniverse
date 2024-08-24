# Find all *.blueprint and change createor id to Aphelia. Otherwise the blueprint fails to import.
$pattern = ($args[0]) ? $args[0] : "*.blueprint"

$files = Get-ChildItem  -Path $pattern
$filecount = $files.Count
Write-Host "Scanning $filecount files: $pattern"
if ($filecount -lt 1)
{
   Write-Host "No files."
   exit
}

Write-Host "Fixing CreatorId..."
$files | ForEach-Object {
   If (Get-Content $_.FullName | Select-String -Pattern '"CreatorId"\s*:\s*2,') 
   {
      Write-Host Not touching $_.Name
   } else {
      Write-Host Modifying $_.Name
      (Get-Content $_ | ForEach-Object {$_ -replace '"CreatorId":\s*[0-9]+\s*,', '"CreatorId":2,'}) | Set-Content $_ 
   }
}

Write-Host "Fixing PlayerId..."
$files | ForEach-Object {
   If (Get-Content $_.FullName | Select-String -Pattern '"playerId":\s*[0-9][0-9]+\s*,') 
   {
      Write-Host Modifying $_.Name
      (Get-Content $_ | ForEach-Object {$_ -replace '"playerId":\s*[0-9][0-9]+\s*,', '"playerId":0,'}) | Set-Content $_ 
   } else {
      Write-Host Not touching $_.Name
   }
}
