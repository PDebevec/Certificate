openssl ca -config .\CA\sign-ca.conf -policy signing_policy -extensions signing_req -out servercert.pem -passin file:./ca/passwd.conf -infiles servercert.csr