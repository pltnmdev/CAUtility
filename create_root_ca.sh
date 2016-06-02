#!/bin/sh

# Helper Functions
printUsage() {
  echo "Usage: create_root_ca.sh <directory to place CA> [number of years CA cert is valid (default: 5)]"
  echo ""
  return 0
}

# Paramters
caDirectory=$1
caYears=$2
scriptDirectory=`dirname $0`

if [[ ($1 == "help") || ($1 == "-help") || ($1 == "-h") || ($1 == "--help") ]]; then
  printUsage
  exit 1
fi

if [[ -z $caDirectory ]]; then
  printUsage

  echo "ERROR: A directory for the CA must be specified."
  exit 1
fi

if [[ -z $caYears ]]; then
  caYears=`expr 5`
fi

let caDays=$(($caYears*365))

# Print parameters
echo "Generating CA in $caDirectory"
echo "CA cert will be valid for $caYears years ($caDays days)."

# Ensure CA directory exists
mkdir -p $caDirectory

# Copy files from the template into the CA directory
cp -R "$scriptDirectory/.template/" $caDirectory

# Generate CA private key
openssl genrsa -out "$caDirectory/rootCA.key" 2048

# Generate CA certificate
openssl req -x509 -new -nodes -key "$caDirectory/rootCA.key" -sha256 -days $caDays -out "$caDirectory/rootCA.pem"

# Generate a PKCS#12 archive
echo "Exporting pkcs#12 archive of generated certificate and key..."
echo "Entering a password may be required by some utilities when importing (ie. OS X Keychain)."

openssl pkcs12 -export -out "$caDirectory/archive.p12" -inkey "$caDirectory/rootCA.key" -in "$caDirectory/rootCA.pem"
