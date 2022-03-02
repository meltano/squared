#!/usr/bin/env bash

# This script generates certificate for client vpn
# AWS Client VPN Pricing: https://aws.amazon.com/vpn/pricing/

[ -z "$1" ] && echo "Usage: $0 first.last" && exit 1

export EASYRSA_BATCH=1

client="$1"
cert_domain="aws-vpn.meltano.com"
client_full="${client}.${cert_domain}"
outfile="/tmp/${client}-cvpn-endpoint.ovpn"
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
    --output text >| $outfile
sed -i~ "s/^remote /remote ${client}./" $outfile
echo "<cert>"                      >> $outfile
cat pki/issued/${client_full}.crt  >> $outfile
echo "</cert>"                     >> $outfile
echo "<key>"                       >> $outfile
cat pki/private/${client_full}.key >> $outfile
echo "</key>"                      >> $outfile

tput setaf 2; echo ">> $outfile ..."; tput setaf 9
ls -alh $outfile