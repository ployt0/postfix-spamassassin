#!/usr/bin/env bash
set -e

for i in {1..15}
do
  if test -f /run/opendkim/opendkim.pid
  then
    break
  fi
  sleep 1
done

echo "Stopping OpenDKIM with PID `cat /run/opendkim/opendkim.pid`"
kill -9 `cat /run/opendkim/opendkim.pid`
service opendkim start
sleep 3
echo "Started OpenDKIM with PID `cat /run/opendkim/opendkim.pid`"