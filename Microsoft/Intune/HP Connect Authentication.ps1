#C:\Program Files\OpenSSL-Win64\bin\

# Endorsement Key Certificate
.\openssl.exe req -x509 -nodes -newkey rsa:2048 -keyout C:\temp\SkotheimsvikHPAuthpriv.pem -out c:\temp\SkotheimsvikHPAuth.crt -days 3650 -subj ‘/C=NO/ST=mro/L=Bud/O=Skotheimsvik/OU=Skotheimsvik/CN=hpbiosauth.skotheimsvik.no’
.\openssl.exe pkcs12 -inkey C:\temp\SkotheimsvikHPAuthpriv.pem -in C:\temp\SkotheimsvikHPAuth.crt -export -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -out C:\temp\SkotheimsvikHPAuthpriv.pfx -name ‘Skotheimsvik SPM Endorsement Key Certificate’
#Sekret666

# Signing Key Certificate
.\openssl.exe req -x509 -nodes -newkey rsa:2048 -keyout c:\temp\SkotheimsvikSKpriv.pem -out c:\temp\SkotheimsvikSK.crt -days 3650 -subj ‘/C=NO/ST=mro/L=Bud/O=Skotheimsvik/OU=Skotheimsvik/CN= hpbiosauth.skotheimsvik.no’
.\openssl.exe pkcs12 -inkey c:\temp\SkotheimsvikSKpriv.pem -in c:\temp\SkotheimsvikSK.crt -export -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -out C:\temp\SkotheimsvikSK.pfx -name ‘Skotheimsvik SPM Signing Key Certificate’
#Sekret666

# Local Access Key Certificate
.\openssl.exe req -x509 -nodes -newkey rsa:2048 -keyout c:\temp\SkotheimsvikLAK.pem -out c:\temp\SkotheimsvikLAK.crt -days 3650 -subj ‘/C=NO/ST=mro/L=Bud/O=Skotheimsvik/OU=Skotheimsvik/CN= hpbiosauth.Skotheimsvik.no’
.\openssl.exe pkcs12 -inkey c:\temp\SkotheimsvikLAK.pem -in c:\temp\SkotheimsvikLAK.crt -export -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -out C:\temp\SkotheimsvikLAK.pfx -name ‘Skotheimsvik SPM Local Access Key Certificate’
