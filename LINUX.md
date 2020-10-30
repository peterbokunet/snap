
echo "local2.*  /var/log/snap.log" >> /etc/rsyslog.conf
touch /var/log/snap.log
# edit /etc/logrotate.d/syslog to add snap.log
systemctl restart rsyslog.service
yum -y install perl-Sys-Syslog perl-LWP-Protocol-https

