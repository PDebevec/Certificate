openssl rand -base64 12 > passwd.conf

openssl req -config generate-server.conf -newkey rsa:4096 -sha256 -passout file:passwd.conf -out servercert.csr -outform PEM