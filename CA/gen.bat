del passwd.conf
del *.pem

openssl rand -base64 12 > passwd.conf

openssl req -x509 -config generate-ca.conf -newkey rsa:4096 -sha256 -passout file:passwd.conf -out cacert.pem -outform PEM

