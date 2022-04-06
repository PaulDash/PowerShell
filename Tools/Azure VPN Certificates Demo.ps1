#           _          _
#        __| |____ ___| |__
#       / _  |__  / __| '_ \           Script: 'Azure VPN Certificates Demo.ps1'
#      | (_| |(_| \__ \ | | |          Author: Paul 'Dash'
#       \__,_\__,_|___/_| |_(_)        E-mail: paul@dash.training
#       T  R  A  I  N  I  N  G


# Creates a self-signed root certificate for signing client certificates
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
                                  -Subject "CN=vpn-Demo-CA" `
                                  -KeyExportPolicy Exportable `
                                  -HashAlgorithm sha256 -KeyLength 2048 `
                                  -CertStoreLocation "Cert:\CurrentUser\My" `
                                  -KeyUsageProperty Sign -KeyUsage CertSign

# Displays above root certificate
# Copy-and-paste this into the 'Point-to-site configuration' page of the 'Virtual network gateway'
# in the section 'Root certificates'
$cert.rawdata | ConvertTo-Base64 -NoLineBreak | Out-File s:\vpn-Demo-CA.txt

# Creates a client certificate that is placed into the current user's Private certificate store
New-SelfSignedCertificate -Type Custom -DnsName GDC-VPN-Client -KeySpec Signature `
                                  -Subject "CN=vpn-Demo-Client" -KeyExportPolicy Exportable `
                                  -HashAlgorithm sha256 -KeyLength 2048 `
                                  -CertStoreLocation "Cert:\CurrentUser\My" `
                                  -Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")