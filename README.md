[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fployt0%2Fpostfix-spamassassin.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fployt0%2Fpostfix-spamassassin?ref=badge_shield)
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/ployt0/antispam-postfix/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/ployt0/antispam-postfix)

This is the next generation of my super-simple postfix-dkim repo. That one was intended to be built from source. Now I have moved the build logic into a run-time script that accepts the domain name as a parameter to docker run.


---------

This includes DKIM support, and SPF, if your DNS zone uses these. You'll probably want to set the MX and rDNS records, additionally.

This supports TLS certificates. Specifically, LetsEncrypt's, by hardcoding their path in /root/run.sh. Either point that to your key and certificate, or set  `domain_name` to `localhost` to retain the provided snakeoil ones (which work surprisingly well!).

DKIM, SPF, and postfix already make for a secure, credible, MTA. Unwanted spam may still come from pseudo-credible sources.

Spamassassin combats this. It adds a lot to the image size, which is why it is going public in this repository. I'll work on getting the size down, as and when. Key for me is that it runs postfix. I'll probably migrate both to alpine if I don't figure out how to marshal their communications to port 783.

## Evaluation runs

Play with the container locally and on your VPS, where you should be able to send mail using DKIM and SPF:

```shell
your_domain=domain_you_have_keys_to.com
dkim_selector=x
docker run -d --name spamasstest -h $your_domain -e domain_name=$your_domain -e dkim_selector=$dkim_selector ployt0/antispam-postfix:0.1.0
```

## Run on the web

Run it with a port so you can test receiving email:

```shell
docker run -d --name spamasstest      -h $your_domain -e domain_name=$your_domain -e dkim_selector=$dkim_selector -p 26:25 ployt0/antispam-postfix
docker run -d --name production_posty -h $your_domain -e domain_name=$your_domain -e dkim_selector=$dkim_selector -p 25:25 ployt0/antispam-postfix
```

Copy `letsencrypt` certificates from where your webserver container is managing them; or from the host, if it is:

```shell
docker cp nginxservice:/etc/letsencrypt . || echo "Missing TLS certs on web server"
docker cp letsencrypt {{ mta_container }}:/etc/
```

Copy your DKIM key, here from `/root/dkim-key.pem`; after first setting its permissions:

```shell
sudo chmod 600 /root/dkim-key.pem
sudo docker cp /root/dkim-key.pem {{ mta_container }}:/etc/dkimkeys/
```

Stop and start opendkim to reload its view of the dkim-key:

```shell
docker exec {{ mta_container }} /root/reloaddkim.sh
```

Test sending mail from the container:

```shell
echo -e "From: root@$your_domain\nSubject: change this\nStill reading\n" | sendmail -v real_recipient@gmail.com
```

## Integrate with Fail2Ban

Fail2Ban may be running on the host, but mail logs aren't kept in their own folder in the container. We have to create a file for the host side of the volume mount (or use the new and preferred mount method). Volume mounting `mail.log` works like this:

```shell
sudo touch /var/log/mail.log
sudo chown root:adm /var/log/mail.log
docker run -d --name production_posty -h $your_domain -e domain_name=$your_domain -e dkim_selector=$dkim_selector -p 25:25 -v /var/log/mail.log:/var/log/mail.log ployt0/antispam-postfix
```
