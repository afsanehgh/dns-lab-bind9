whoami
id bind
stat /var/cache/bind
ls -ld /var/cache/bind
chown -R bind:bind /var/cache/bind
chmod 775 /var/cache/bind
ls -ld /var/cache/bind
/usr/sbin/named -g -u bind