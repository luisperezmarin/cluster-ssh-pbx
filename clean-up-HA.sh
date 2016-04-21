#!/bin/bash

find /var/lib/asterisk/backups/HA/ -type f -cmin +240 -exec rm {} \;
