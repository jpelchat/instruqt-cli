#!/bin/bash

if [ -z "${BASH_VERSION:-}" ]
then
  echo "Bash is required to interpret this script."
  exit 1
fi

get_latest_release() {
  curl --silent "https://api.github.com/repos/instruqt/cli/releases/latest" | 
  grep '"tag_name":' | 
  sed -E 's/.*"([^"]+)".*/\1/'
}

# Get latest release tag
RELEASE=$(get_latest_release)

# Determine OS
OS=$(uname)
if [[ "${OS}" == "Linux" ]]
then
  LINUX_INSTALL=1
elif [[ "${OS}" == "Darwin" ]]
then
  MACOS_INSTALL=1
else
  echo "Instruqt CLI is not supported on this machine type."
  exit 1
fi

# Set macos package prefix
if [[ -n "${MACOS_INSTALL}" ]]
then
  MACHINE_TYPE=$(uname -m)
  if [[ "${MACHINE_TYPE}" == "arm64" ]]
  then
    PACKAGE_PREFIX="instruqt-darwin-arm64"
  else
    PACKAGE_PREFIX="instruqt-darwin-amd64"
  fi    
fi

# Set Linux package prefix
if [[ -n "${LINUX_INSTALL}" ]]
then
    PACKAGE_PREFIX="instruqt-linux"
fi

# Set GitHub donwload URL
URL=https://github.com/instruqt/cli/releases/download/$RELEASE/$PACKAGE_PREFIX-$RELEASE.zip

# Download Instruqt CLI
tmp=$(mktemp -d /tmp/instruqt-cli.XXXXXX)
cd $tmp
echo "Downloading Instruqt CLI"
curl -sL $URL -o instruqt.zip

# Compare hash
SHA256=$(curl -sL $URL.sha256sum | awk '{ print $1 }')
CHECKSUM=$(openssl dgst -sha256 ./instruqt.zip | awk '{ print $2 }')

if [[ "$CHECKSUM" != "$SHA256" ]]
then
  echo "Checksum validation failed."
  exit 1
fi

# Install the CLI
unzip -qq instruqt.zip 
sudo cp instruqt /usr/local/bin 
sudo chmod +x /usr/local/bin/instruqt

# Cleanup 
rm -f instruqt.zip

# Test command
if instruqt > /dev/null 2> /dev/null
then
  echo "Instruqt CLI installed succesfully. Go forth and create."
else
  echo "Instruqt CLI installation failed. Try again or contact support!"
fi