﻿#           _          _       
#        __| |____ ___| |__    
#       / _  |__  / __| '_ \           Script: 'New-X509v3Certificate.ps1'
#      | (_| |(_| \__ \ | | |          Author: Paul 'Dash'
#       \__,_\__,_|___/_| |_(_)        E-mail: paul@dash.training
#       T  R  A  I  N  I  N  G 


# Original author: Adam Conkle - Microsoft Corporation 
# Original source: http://social.technet.microsoft.com/wiki/contents/articles/4714.how-to-generate-a-self-signed-certificate-using-powershell.aspx

# Adopted by:      Paul Wojcicki-Jarocki - Paul Dash (paul@pauldash.com)
# Adopted because: * change to more secure sha256
#                  * commented throughout
#                  * certificate validity period is corrected
#                  * generated certificate is added to correct stores


Write-Warning "This script is provided AS-IS with no warranties and confers no rights."
Write-Host    "This script sample will generate a self-signed certificates with private key for code signing purposes.`n"

$ContextAnswer = Read-Host "Store certificate in the User or Computer store? (U/C)"
if ($ContextAnswer -eq "U") { 
    $machineContext = 0 
    $initContext = 1
    $CertStoreLocation = 'CurrentUser' 
} elseif ($ContextAnswer -eq "C") { 
    $machineContext = 1 
    $initContext = 2
    $CertStoreLocation = 'LocalMachine'
} else { 
    Write-Host "Invalid selection. Exiting."
    Exit 
}

# Set certificate Subject name based on user input
$Subject = Read-Host "Subject of the certificate  "
$DistinguishedName = New-Object -ComObject "X509Enrollment.CX500DistinguishedName.1"  
$DistinguishedName.Encode("CN=$Subject", 0)

# Generate private key
$key = New-Object -ComObject 'X509Enrollment.CX509PrivateKey.1'  
$key.ProviderName = 'Microsoft RSA SChannel Cryptographic Provider'
#$key.ProviderName = 'Microsoft Base Smart Card Crypto Provider' # from CryptoAPI
#$key.ProviderName = 'Microsoft Smart Card Key Storage Provider' # from CNG 
$key.KeySpec = 1 # for other purposes: 3
$key.Length = 2048 
$key.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)"  
$key.MachineContext = $machineContext 
$key.ExportPolicy = 1 # 0 for non-exportable Private Key
$key.Create()

# Create OID for code signing
### TODO: check out the .NET type System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension
$codesigningoid = New-Object -ComObject "X509Enrollment.CObjectId.1"
### TODO: put this in a SWITCH
$codesigningoid.InitializeFromValue("1.3.6.1.5.5.7.3.3")        # Code Signing
#$codesigningoid.InitializeFromValue("1.3.6.1.5.5.7.3.1")       # Server Authentication
#$codesigningoid.InitializeFromValue("1.3.6.1.5.5.7.3.2")       # Client Authentication
#$codesigningoid.InitializeFromValue("1.3.6.1.5.5.7.3.4")       # Secure Email
#$codesigningoid.InitializeFromValue("1.3.6.1.5.5.7.3.8")       # Time Stamping
#$codesigningoid.InitializeFromValue("1.3.6.1.4.1.311.10.3.12") # Document Signing

# Add OID to list
$ekuoids = New-Object -ComObject "X509Enrollment.CObjectIds.1"
$ekuoids.Add($codesigningoid) 

# Add list of OIDs to extensions
$ekuext = New-Object -ComObject "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1"
$ekuext.InitializeEncode($ekuoids) 

# Create certificate request
$CertReq = New-Object -ComObject "X509Enrollment.CX509CertificateRequestCertificate.1"  
$CertReq.InitializeFromPrivateKey($initContext, $key, "")
### $CertReq.CriticalExtensions.Remove(0) # Remove 'Key Usage'
$CertReq.Subject = $DistinguishedName
$CertReq.Issuer = $CertReq.Subject
$CertReq.NotBefore = (Get-Date).Date ### TODO: fix for GMT
$CertReq.NotAfter = $CertReq.NotBefore.AddYears(1)

# Set signing algorithm to sha256
[string]$SigAlgorithmName = "sha256"
$SigAlgorithmOID = New-Object -ComObject X509Enrollment.CObjectId
$SigAlgorithmOID.InitializeFromValue(([Security.Cryptography.Oid]$SigAlgorithmName).Value)
$CertReq.HashAlgorithm = $SigAlgorithmOID

# Add list of extensions to request
$CertReq.X509Extensions.Add($ekuext)

# Generate request
$CertReq.Encode() 

# Send request
$enrollment = New-Object -ComObject "X509Enrollment.CX509Enrollment.1"  
$enrollment.InitializeFromRequest($CertReq)
# Receive requested certificate
$Cert = $enrollment.CreateRequest(0)

# Install certificate in store
$enrollment.InstallResponse(4, $Cert, 0, "") 

### TODO: Add handling if creation fails!
Write-Host "Certificate creation: $($enrollment.Status.ErrorText)" -ForegroundColor Green

# Export certificate to a file
$FilePath = Read-Host "Directory to store .CER file"
if (Test-Path -Path $FilePath -PathType Container) {
    $SignedCert = Get-ChildItem "Cert:\$CertStoreLocation\My\" | Where-Object {$_.Subject -eq "CN=$Subject"}
    if ($SignedCert.Count -gt 1) {
        Write-Warning "Certificate export: Multiple certificates exist for subject '$Subject'. None exported."
        exit
    }
    $ExportedCert = Export-Certificate -Cert $SignedCert -FilePath (Join-Path -Path $FilePath -ChildPath "$Subject.cer")
} else {
    Write-Warning "Certificate export: Could not write to path $FilePath."
    exit
}
# Verify export
if (Test-Path -Path $ExportedCert -PathType Leaf) {
    Write-Host "Certificate export: Completed successfully." -ForegroundColor Green
} else {
    Write-Warning "Certificate export: File export failed. Will not save to Root CA and Trusted Publishers stores."
    exit
}

# Import certificate into Root CA and Trusted Publishers
Import-Certificate -FilePath $ExportedCert -CertStoreLocation "Cert:\$CertStoreLocation\Root" | Out-Null
Import-Certificate -FilePath $ExportedCert -CertStoreLocation "Cert:\$CertStoreLocation\TrustedPublisher" | Out-Null
# Verify import
### TODO: look up Thumbprint instead of doing the Where-Object
if ((Get-ChildItem "Cert:\$CertStoreLocation\Root\" | Where-Object {$_.Subject -eq "CN=$Subject"}) -and
(Get-ChildItem "Cert:\$CertStoreLocation\TrustedPublisher\" | Where-Object {$_.Subject -eq "CN=$Subject"})) {
    Write-Host "Certificate import: Completed successfully." -Fore Green
}

Write-Host "Done! Use this path for Set-AuthenticodeSignature:`nCert:\$CertStoreLocation\My\$($SignedCert.Thumbprint)"