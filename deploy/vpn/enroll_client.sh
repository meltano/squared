#!/usr/bin/env bash

# This script generates certificate for client vpn
# AWS Client VPN Pricing: https://aws.amazon.com/vpn/pricing/

set -e
set -o pipefail

[ -z "$1" ] && echo "Usage: $0 <email>" && exit 1

[ ! -x "$(command -v op)" ] && echo "The 1Password CLI must be installed: https://developer.1password.com/docs/cli/install-server/" && exit 1

op account get > /dev/null
[ $? -ne 0 ] && echo "You must sign-in to the 1Password CLI by running: https://developer.1password.com/docs/cli/sign-in-manually" && exit 1

# Exit early if the 1Password session token has expired
op item list > /dev/null

export EASYRSA_BATCH=1

email="$1"
client="${email%@*}"
domain="${email#*@}"
[ "$client" == "$domain" ] && echo "Invalid email address '$email' - missing '@' symbol" && exit 1
# Technically it's missing the "local-part", but "user" gets the message across better.
[ -z "$client" ] && echo "Invalid email address '$email' - missing user" && exit 1
[ -z "$domain" ] && echo "Invalid email address '$email' - missing domain" && exit 1

vault="Temporary"
cert_domain="aws-vpn.meltano.com"
client_full="${client}.${cert_domain}"
tempfile="/tmp/${client}-cvpn-endpoint.ovpn"
outfile="/tmp/${client}-meltano-vpn.zip"
vpn_endpoint_id="cvpn-endpoint-03a021f1bd288258e"

tput setaf 2; echo ">> clone repo ..."; tput setaf 9
cd `mktemp -d`
git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa/easyrsa3

tput setaf 2; echo ">> init ..."; tput setaf 9
./easyrsa init-pki
./easyrsa build-ca nopass
rm -f pki/ca.crt
rm -f pki/private/ca.key

tput setaf 2; echo ">> get ca crt/key from param store ..."; tput setaf 9
(aws --profile tf_data \
    ssm get-parameters \
    --names /vpn/crt/ca \
    --with-decryption \
    --query Parameters[0].Value \
    --output text || exit 2) | base64 --decode > pki/ca.crt
(aws --profile tf_data \
    ssm get-parameters \
    --names /vpn/key/ca \
    --with-decryption \
    --query Parameters[0].Value \
    --output text || exit 3) | base64 --decode > pki/private/ca.key

tput setaf 2; echo ">> create and import crt/key for $client ..."; tput setaf 9
./easyrsa build-client-full ${client_full} nopass
aws --profile tf_data \
    acm import-certificate \
    --certificate fileb://pki/issued/${client_full}.crt \
    --private-key fileb://pki/private/${client_full}.key \
    --certificate-chain fileb://pki/ca.crt

tput setaf 2; echo ">> generate vpn client config file ..."; tput setaf 9
aws --profile tf_data \
    ec2 export-client-vpn-client-configuration \
    --client-vpn-endpoint-id $vpn_endpoint_id \
    --output text >| $tempfile
sed -i~ "s/^remote /remote ${client}./" $tempfile
echo "<cert>"                      >> $tempfile
cat pki/issued/${client_full}.crt  >> $tempfile
echo "</cert>"                     >> $tempfile
echo "<key>"                       >> $tempfile
cat pki/private/${client_full}.key >> $tempfile
echo "</key>"                      >> $tempfile

# We cannot upload the file directly to 1Password, so we encrypt the file by zipping it, then upload the password.
# https://1password.community/discussion/129401/how-do-you-upload-a-file-via-the-connect-server-api
(
# Execute in a subshell with `set +x` to avoid printing the password.
set +x
# The subshell also avoids cases were the user sources this script and ends up with the password in
# their environment. That said, obviously a determined user running this script can get the
# password out of it, trivially if they are able to edit the script. These measures are mostly in
# place to avoid accidental password leakage.

# Generate a random 32 character password
password="$(head /dev/urandom | LC_ALL=C tr -dc A-Za-z0-9 | head -c32)"

tput setaf 9
zip --password "$password" "$outfile" "$tempfile"
rm -f "$tempfile"
itemid="$(op item create \
    --vault "$vault" \
    --category Password \
    --title "Data VPN password for OpenVPN configuration zip file for $email" \
    password="$password" | head -n1 | awk '{print $2}')"
sharelink="$(op item share \
    --vault "$vault" \
    --emails "$email" \
    --view-once \
    "$itemid")"
tput setaf 2
echo "Share the following link with the newly enrolled client (via Slack, email, etc.):"
tput init
echo "$sharelink"
tput setaf 2
echo "Only they can view it. It can only be viewed once.
It contains the password necessary to decrypt the zip file.
The zipped OpenVPN configuration must also be shared with them (via Slack, email, etc.)"
) 2>&1

tput setaf 2; echo ">> $outfile ..."; tput setaf 9
ls -alh $outfile
