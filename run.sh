#!/usr/bin/env bash
set -e

: ${1?Missing DOMAIN_NAME parameter}
DOMAIN_NAME=$1
: ${2?Missing DKIM_SELECTOR parameter}
DKIM_SELECTOR=$2

sed -Ei "s/^Domain *[^ ]*$/Domain                  $DOMAIN_NAME/" /etc/opendkim.conf
sed -Ei "s/^Selector *[^ ]*$/Selector                $DKIM_SELECTOR/" /etc/opendkim.conf

echo $DOMAIN_NAME > /etc/mailname
if [ "$DOMAIN_NAME" != "localhost" ] &&  [ "$DOMAIN_NAME" != "example.com" ]; then
  postconf -e "smtpd_tls_cert_file = /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem"
  postconf -e "smtpd_tls_key_file = /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem";
fi

sed -Ei "s/example.com/$DOMAIN_NAME/" /etc/postfix/main.cf


service rsyslog start
service postfix start
service opendkim start
service spamassassin start
