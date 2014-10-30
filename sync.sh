#!/bin/bash
echo "STARTING RESTORE"

/var/lib/asterisk/bin/backup.php --id=2
echo "DONE"
exit 0
