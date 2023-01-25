openssl pkcs12 -inkey cakey.pem -in cacert.pem -passin file:passwd.conf -export -out CA.pfx

openssl pkcs12 -nokeys -in cacert.pem -passin file:passwd.conf -export -out CA-key.pfx