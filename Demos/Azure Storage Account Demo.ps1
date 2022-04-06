#           _          _
#        __| |____ ___| |__
#       / _  |__  / __| '_ \           Script: 'Azure Storage Account Demo.ps1'
#      | (_| |(_| \__ \ | | |          Author: Paul 'Dash'
#       \__,_\__,_|___/_| |_(_)        E-mail: paul@dash.training
#       T  R  A  I  N  I  N  G


# Create a SA
New-AzStorageAccount -ResourceGroupName $RGName `
                     -Location $Loc `
                     -Name 'gdcstoragedemo2' `
                     -SkuName 'Standard_LRS' `
                     -OutVariable sa

$sa.Context

# Create a BLOB Container in the SA
New-AzStorageContainer -Name 'gallery' -Context $sa.Context -Permission blob

# Upload some files
Get-ChildItem C:\Users\Paul\OneDrive\Pictures\_MG*.jpg |
ForEach-Object {
  Set-AzStorageBlobContent -Container 'gallery' `
                           -File $_.FullName `
                           -Blob $_.Name `
                           -Context $sa.Context `
                           -Properties @{"ContentType" = "image/jpg"}
}

# Retrieve links for access
(Get-AzStorageBlob -Container 'gallery' -Context $sa.Context).ICloudBlob.uri.AbsoluteUri