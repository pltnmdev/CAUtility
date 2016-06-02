#!/bin/sh

# Helper Functions
printUsage() {
  echo "Usage: create_intermediate_intermediate.sh <directory to place CA> <directory containing the root CA> [number of years CA cert is valid (default: 10)]"
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
