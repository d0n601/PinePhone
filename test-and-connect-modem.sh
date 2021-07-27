#!/bin/bash
FILE=/dev/ttyUSB2

if ! test -c "$FILE"; then
  systemctl restart eg25-manager
fi
