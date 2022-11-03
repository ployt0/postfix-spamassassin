FROM debian:bullseye-20221004-slim
RUN { \
        echo postfix postfix/mailname string example.com; \
        echo postfix postfix/main_mailer_type string 'Internet Site'; \
    } | debconf-set-selections

RUN \
  apt-get update && \
  apt-get -y --no-install-recommends install \
    procps \
    postfix \
    opendkim && \
  apt-get -y install rsyslog spamassassin && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists

RUN echo "-----BEGIN PRIVATE KEY-----\n\
MIIEowIBAAKCAQEAyFSKkZovoW0J+YjC8jw8Dm6fdrH1SfVBBVF0gsflYM9n38pB\
DBCJdum9Rc7pEpxqYxtGUWhbmHln7ZAJJTsB5ARxckWSg82987jqKrUCAahkcT1k\
CtvwgnSZ2W1/JWRZHOLPv65ZATZk9jGa+F0q8LmqlTQ3wKj/OUSZc7LbBcWyymGD\
3Mkm7PkImk+6yuehMLfXzB4GTOud5FnSFX0kELApslpYa8rn2P3gb3RzSaXdRFfN\
LlMmgWfQrhRdXKPc9WhBvXFHhMdG6imTzhOoqzwOfaruOX2UXIczoogkkU+7Vhp/\
w8b1j45NPR863vCGIAxGnhQ9lIEhYQGsROappwIDAQABAoIBAHBNTFzxRZBF8xiK\
/VYUREqG4ygD/RDXxvp3PkxuSP0rZ/zBghOEVbturucqZehD/TPPv2y1htuD+6nm\
W+oeGSI9B2fa7paqyLiPSd5lGFnbj2sX0jRwNXS8bt6/jk5k4bvavkGjOEwAtTp6\
dniSqhbGzoTUAAkl8+Wjui5s7nFd8zpWp+Pc6fyng/rfRavrFj4EUqsiJ4EMG062\
hY+rRXxkAZlHiNnyZYaHrEI07Liwmi4wxGdasPv7H5vWSc5JzpP9w00zs+UvPQU5\
AAIYUmUTA8DeXtuqQ7+tcvh3QFKNoJ9IvLECuhgOdS9nYk6oxocfifMaYpsWJVor\
q/UCvXkCgYEA8a/njzbf7ArjUPl2ZfLS1kmpHpXufiRdQlMwxi7PL7RslauGHwcb\
B3PMr3Kr+LlYebNs5w386Hgpn/1IUK5z//HuSvmQ4lEY5BXc1zbBATyZnVnOMRzb\
d9c5RHWnUvN59vcDpbbbPKonbj/EH/x5EPq5kuS8T7WIwAbtigtU7eUCgYEA1DGl\
YtSiIsUIDGnB8yLtTavxg/jwA3FwF8aib3PeJQccV1GflFnmEieguxMWLiP7OrMl\
Jdr/Nzk+x0OSwOmdBq1VsW0VC58CbTHPprXwMt/c5C8LjyEZU0Tul7SoELpMyZkd\
6uThG/EY7nWyjmwEC0tlaSsKBzXn14yP6ePmIJsCgYEAjFElLkecr60OlreOntfg\
wpqXfnNruH6iSlyEJ7uLfFXS6P5haug0MBpyDraT017AWD/sjSTY3ZrOB94EOxtd\
q44pXAwSquKMgfeTdLuMSIyHXwyBoo/vd19UF0P7djR3bgOxcWd9V3YuWFrbIfrx\
ywLV9Mup7NknYN1k0c2MbGUCgYAe2/V8cQX/Xn40J/E/5dVzFU1zbvGg3o95tbaL\
1OL6qZUSkdlOXuCZxU+XxUfVgAAaYlFFtxqksluR6R7flVnzzaOHwSBtZzuYG8Vi\
LlV3YJ0kRj89GogvVvgH8gr7G8ztCKqULaMbSC3jCBTmp4jTB60A5XR45fsImvWX\
A0DFfwKBgBrv2owyj/ivUN+VjUk04VqJuhNvWjDIYGoI4GYIs9Ybfj/QKuzYm17a\
X5kBB6/dUr+Ke1EB2SBeYyv57MF2m9XEBu2kVfD+BgvAoscbg9J0BmThF9UqPimX\
4KfuUjEDwGOI8eJFvT2P57fg/+5/ZgPhW7RmuW68O78Zy3w2GnfQ\n\
-----END PRIVATE KEY-----\n" > /etc/dkimkeys/dkim-key.pem

RUN \
  touch /etc/dkimkeys/dkim-key.pem && \
  chmod 0600 /etc/dkimkeys/dkim-key.pem


RUN \
  echo 'smtpd_milters = inet:127.0.0.1:8891' >> /etc/postfix/main.cf && \
  echo 'non_smtpd_milters = $smtpd_milters' >> /etc/postfix/main.cf && \
  echo 'milter_default_action = accept' >> /etc/postfix/main.cf && \
  echo 'milter_protocol = 6' >> /etc/postfix/main.cf

RUN \
  sed -Ei 's/(smtp *inet *n *- *y *- *- *smtpd)/\1 -o content_filter=spamassassin/' /etc/postfix/master.cf && \
  echo 'spamassassin unix -     n       n       -       -       pipe' >> /etc/postfix/master.cf && \
  echo '    user=debian-spamd argv=/usr/bin/spamc -f -e' >> /etc/postfix/master.cf && \
  echo '    /usr/sbin/sendmail -oi -f ${sender} ${recipient}' >> /etc/postfix/master.cf && \
  sed -Ei 's|OPTIONS="--create-prefs --max-children 5 --helper-home-dir"|OPTIONS="--create-prefs --max-children 5 --helper-home-dir --username debian-spamd -s /var/log/spamd.log"|' /etc/default/spamassassin

RUN \
  echo "Domain                  example.com" >> /etc/opendkim.conf && \
  echo "Selector                x" >> /etc/opendkim.conf && \
  echo 'KeyFile                 /etc/dkimkeys/dkim-key.pem' >> /etc/opendkim.conf && \
  echo 'Canonicalization        relaxed' >> /etc/opendkim.conf && \
  echo 'Mode                    sv' >> /etc/opendkim.conf && \
  sed -Ei "s/^#* *Socket(\t.*)$/#Socket\1/" /etc/opendkim.conf && \
  sed -Ei "s/^#* *Socket(\t.*)(inet:8891@localhost)$/Socket\1\2/" /etc/opendkim.conf


COPY run.sh /root/
COPY reloaddkim.sh /root/

ENV domain_name example.com
ENV dkim_selector x

CMD /root/run.sh $domain_name $dkim_selector && tail -F /var/log/mail.log
