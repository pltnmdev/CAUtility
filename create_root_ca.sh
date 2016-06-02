#!/bin/sh

# Helper Functions
printUsage() {
  echo "Usage: create_root_ca.sh <directory to place CA> [number of years CA cert is valid (default: 20)]"
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
mkdir "$outputDirectory/newcerts"
mkdir "$outputDirectory/private"

# Copy files from the template into the CA directory
cp -R "$scriptDirectory/.template/root/" $outputDirectory

# Modify the config file to point to our current directory
sed -i '' -e "s|%rootDir%|$absoluteOutputDirectory|g" "$outputDirectory/openssl.conf"

# Lock down the private directory
chmod 700 "$outputDirectory/private"

# Generate CA private key
openssl genrsa -aes256 -out "$outputDirectory/private/ca.key.pem" 4096

# Generate CA certificate
openssl req -config "$outputDirectory/openssl.conf" -key "$outputDirectory/private/ca.key.pem" -new -x509 -days $caDays -sha256 -extensions v3_ca -out "$outputDirectory/certs/ca.cert.pem"

# Generate a PKCS#12 archive
echo "Exporting pkcs#12 archive of generated certificate and key..."
echo "Entering a password may be required by some utilities when importing (ie. OS X Keychain)."

openssl pkcs12 -export -out "$outputDirectory/private/archive.p12" -inkey "$outputDirectory/private/ca.key.pem" -in "$outputDirectory/certs/ca.cert.pem"
