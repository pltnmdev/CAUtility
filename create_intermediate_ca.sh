#!/bin/bash

# Copyright (c) 2016, Platinum Supplemental Insurance, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Helper Functions
printUsage() {
  echo "Usage: create_intermediate_ca.sh <directory to place CA> <directory containing the root CA> [number of years CA cert is valid (default: 10)]"
  echo ""
  return 0
}

# Paramters
outputDirectory=$1
absoluteOutputDirectory="`pwd`/$outputDirectory"
rootCADirectory=$2
caYears=$3
scriptDirectory=`dirname $0`

if [[ ($1 == "help") || ($1 == "-help") || ($1 == "-h") || ($1 == "--help") ]]; then
  printUsage
  exit 1
fi

if [[ -z $outputDirectory ]]; then
  printUsage

  echo "ERROR: A directory for the CA must be specified."
  exit 1
fi

if [[ -z $rootCADirectory ]]; then
  printUsage

  echo "ERROR: A directory for the Root CA must be specified."
  exit 1
fi

if [[ -z $caYears ]]; then
  caYears=`expr 10`
fi

let caDays=$(($caYears*365))

# Print parameters
echo "Generating intermediate CA in $outputDirectory"
echo "The certificate will be signed by the root CA in $rootCADirectory"
echo "The intermediate CA certificate will be valid for $caYears years ($caDays days)."

# Ensure CA directories exist
mkdir -p $outputDirectory
mkdir "$outputDirectory/certs"
mkdir "$outputDirectory/crl"
mkdir "$outputDirectory/csr"
mkdir "$outputDirectory/newcerts"
mkdir "$outputDirectory/private"

# Copy files from the template into the CA directory
cp -R "$scriptDirectory/.template/intermediate/" $outputDirectory

# Modify the config file to point to our current directory
sed -i '' -e "s|%rootDir%|$absoluteOutputDirectory|g" "$outputDirectory/openssl.conf"

# Lock down the private directory
chmod 700 "$outputDirectory/private"

# Generate Intermediate CA private key
openssl genrsa -aes256 -out "$outputDirectory/private/intermediate.key.pem" 4096

# Lock down the private key
chmod 400 "$outputDirectory/private/intermediate.key.pem"

# Generate Intermediate CA CSR
openssl req -config "$outputDirectory/openssl.conf" -new -sha256 -key "$outputDirectory/private/intermediate.key.pem" -out "$outputDirectory/csr/intermediate.csr.pem"

# Issue Intermediate CA certificate via the Root CA
openssl ca -config "$rootCADirectory/openssl.conf" -extensions v3_intermediate_ca -days $caDays -notext -md sha256 -in "$outputDirectory/csr/intermediate.csr.pem" -out "$outputDirectory/certs/intermediate.cert.pem"

# Lock down the public certificate
chmod 444 "$outputDirectory/certs/intermediate.cert.pem"

# Create the certificate chain
cat "$outputDirectory/certs/intermediate.cert.pem" "$rootCADirectory/certs/root.cert.pem" > "$outputDirectory/certs/ca-chain.cert.pem"
chmod 444 "$outputDirectory/certs/ca-chain.cert.pem"

# Generate a PKCS#12 archive
echo "Exporting pkcs#12 archive of generated certificate and key..."
echo "Entering a password may be required by some utilities when importing (ie. OS X Keychain)."

openssl pkcs12 -export -out "$outputDirectory/private/archive.p12" -inkey "$outputDirectory/private/intermediate.key.pem" -in "$outputDirectory/certs/intermediate.cert.pem" -certfile "$rootCADirectory/certs/root.cert.pem"
