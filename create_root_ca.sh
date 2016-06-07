#!/bin/sh

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
  echo "Usage: create_root_root.sh <directory to place CA> [number of years CA cert is valid (default: 20)]"
  echo ""
  return 0
}

# Paramters
outputDirectory=$1
absoluteOutputDirectory="`pwd`/$outputDirectory"
caYears=$2
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

if [[ -z $caYears ]]; then
  caYears=`expr 20`
fi

let caDays=$(($caYears*365))

# Print parameters
echo "Generating root CA in $outputDirectory"
echo "CA cert will be valid for $caYears years ($caDays days)."

# Ensure CA directories exist
mkdir -p $outputDirectory
mkdir "$outputDirectory/certs"
mkdir "$outputDirectory/crl"
mkdir "$outputDirectory/csr"
mkdir "$outputDirectory/newcerts"
mkdir "$outputDirectory/private"

# Copy files from the template into the CA directory
cp -R "$scriptDirectory/.template/root/" $outputDirectory

# Modify the config file to point to our current directory
sed -i '' -e "s|%rootDir%|$absoluteOutputDirectory|g" "$outputDirectory/openssl.conf"

# Lock down the private directory
chmod 700 "$outputDirectory/private"

# Generate CA private key
openssl genrsa -aes256 -out "$outputDirectory/private/root.key.pem" 4096

# Lock down the private key
chmod 400 "$outputDirectory/private/root.key.pem"

# Generate CA certificate
openssl req -config "$outputDirectory/openssl.conf" -key "$outputDirectory/private/root.key.pem" -new -x509 -days $caDays -sha256 -extensions v3_ca -out "$outputDirectory/certs/root.cert.pem"

# Lock down the public certificate
chmod 444 "$outputDirectory/certs/root.cert.pem"

# Generate a PKCS#12 archive
echo "Exporting pkcs#12 archive of generated certificate and key..."
echo "Entering a password may be required by some utilities when importing (ie. OS X Keychain)."

openssl pkcs12 -export -out "$outputDirectory/private/archive.p12" -inkey "$outputDirectory/private/root.key.pem" -in "$outputDirectory/certs/root.cert.pem"
