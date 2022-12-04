del *.pfx

openssl pkcs12 -inkey serverkey.pem -in servercert.pem -passin file:passwd.conf -export -out server.pfx