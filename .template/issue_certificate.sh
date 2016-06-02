#!/bin/sh

# Helper Functions
printUsage() {
  echo "Usage: issue_certificate.sh <directory to place certificate> [path to csr file]"
  echo ""
  return 0
}

# Parameters
outputDir=$1
csrFile=$2
caDirectory=`dirname $0`

if [[ ($1 == "help") || ($1 == "-help") || ($1 == "-h") || ($1 == "--help") ]]; then
  printUsage
  exit 1
fi

if [[ -z $outputDir ]]; then
  printUsage

  echo "ERROR: A directory to place the issued certificate must be specified."
  exit 1
fi

# Print Parameters
echo "Creating certificate in $outputDir using certificate authority at $caDirectory."

# Ensure the output directory exists
mkdir -p $outputDir

if [[ -z $csrFile ]]; then
  echo "No CSR provided: generating a private key for this certificate."

  # Generate a CSR since one was not provided to us.
  openssl genrsa -out "$outputDir/private.key" 2048
  openssl req -new -key "$outputDir/private.key" -out "$outputDir/request.csr"
  csrFile="$outputDir/request.csr"
  csrGenerated=true
fi

# Generate the certificate
openssl x509 -req -in $csrFile -CA "$caDirectory/rootCA.pem" -CAkey "$caDirectory/rootCA.key" -CAcreateserial -out "$outputDir/public.pem" -days 365 -sha256

# Generate a PKCS#12 archive if we generated the CSR
if [[ $csrGenerated ]]; then
  echo "Exporting pkcs#12 archive of generated certificate and key..."
  echo "Entering a password may be required by some utilities when importing (ie. OS X Keychain)."

  openssl pkcs12 -export -out "$outputDir/archive.p12" -inkey "$outputDir/private.key" -in "$outputDir/public.pem" -certfile "$caDirectory/rootCA.pem"
fi
