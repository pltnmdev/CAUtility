CA Utility
==========

This set of bash scripts is designed to make setting up and managing an OpenSSL based certificate authority easier.

Many thanks to [this article series](https://jamielinux.com/docs/openssl-certificate-authority/introduction.html) for helping me understand how certificate authorities with OpenSSL are supposed to work.  Much of the setup of the final CAs are based on input from this series.

This repository is freely available to be forked and expanded upon.  We simply ask that if you do something cool with it, you send us a pull request so we can incorporate it into our version.

See LICENSE for conditions on the use and distribution of this software.

Creating a Root CA
------------------
Usage: `create_root_ca.sh <directory to place CA> [number of years CA cert is valid (default: 20)]`

This script creates a Root Certificate Authority.  This CA is only capable of issuing certificates for intermediate certificate authorities and should be kept in a secure location that is rarely accessed.  Something like an air-gapped machine would be ideal.  A password is currently required for the CA's private key.

The indicated directory will be created and the contents of the CA will be placed inside.

Creating an Intermediate CA
---------------------------
Usage: `create_intermediate_ca.sh <directory to place CA> <directory containing the root CA> [number of years CA cert is valid (default: 10)]`

This script will create an Intermediate Certificate Authority, using the Root Certificate you created using the included Root CA script.  This CA template includes a script for issuing client and server certificates from the CA.  A password is currently required for the CA's private key.

The indicated directory will be created and the contents of the CA will be placed inside.

Creating server and client certificates
---------------------------------------
Usage: `issue_certificate.sh <directory to place certificate> <type of certificate (options: server, client)> [path to csr file]`

This script will either 1.) Take in a CSR file and issue a certificate based on the request or 2.) Generate a private key and then issue a certificate for that key, depending on whether you provide an existing CSR file.  Right now only client certificates (SSL/TLS, Email) and server certificates (SSL/TLS) are supported.

If a private key is created, a packed .p12 file will be included in the output.
