#cp cp checklog.sh /etc/cron.daily/checklog
0 0,12 * * * /root/checklog.sh >> /var/log/checklog_auto.log 2>&1
