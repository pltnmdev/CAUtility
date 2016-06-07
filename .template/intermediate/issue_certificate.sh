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
  echo "Usage: issue_certificate.sh <directory to place certificate> <type of certificate (options: server, client)> [path to csr file]"
  echo ""
  return 0
}

# Parameters
outputDir=$1
certType=$2
csrFile=$3
caDirectory=`dirname $0`
dateStamp=`date +%Y-%m-%dT%H-%M-%S`

if [[ ($1 == "help") || ($1 == "-help") || ($1 == "-h") || ($1 == "--help") ]]; then
  printUsage
  exit 1
fi

if [[ -z $outputDir ]]; then
  printUsage

  echo "ERROR: A directory to place the issued certificate must be specified."
  exit 1
fi

case $certType in
  server)
    ca_extension="server_cert"
    ;;
  client)
    ca_extension="client_cert"
    ;;
  *)
    printUsage

    echo "ERROR: Certificate type is not one of the available options."
    exit 1
esac

# Print Parameters
echo "Creating $certType certificate in $outputDir using certificate authority at $caDirectory."

# Ensure the output directory exists
mkdir -p $outputDir

if [[ -z $csrFile ]]; then
  echo "No CSR provided: generating a private key for this certificate."

  # Generate a CSR since one was not provided to us.
  openssl genrsa -out "$outputDir/private.key.pem" 2048
  openssl req -config "$caDirectory/openssl.conf" -new -sha256 -key "$outputDir/private.key.pem" -out "$outputDir/request.csr.pem"
  csrFile="$outputDir/request.csr.pem"
  csrGenerated=true
fi

# Make a copy of the CSR for future reference
csrFileName=`basename $csrFile`
cp $csrFile "$caDirectory/csr/${csrFileName%%.*}-$dateStamp.csr.pem"

# Generate the certificate
openssl ca -config "$caDirectory/openssl.conf" -extensions $ca_extension -days 375 -notext -md sha256 -in $csrFile -out "$outputDir/public.cert.pem"

# Generate a PKCS#12 archive if we generated the CSR
if [[ $csrGenerated ]]; then
  echo "Exporting pkcs#12 archive of generated certificate and key..."
  echo "Entering a password may be required by some utilities when importing (ie. OS X Keychain)."

  openssl pkcs12 -export -out "$outputDir/archive.p12" -inkey "$outputDir/private.key.pem" -in "$outputDir/public.cert.pem" -certfile "$caDirectory/certs/ca-chain.cert.pem"
fi
