#/bin/sh

for CLEAN in $(find /var/log/ -type f)
do
    cp /dev/null  $CLEAN
done
