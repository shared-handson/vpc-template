#!/bin/bash
yum install -y iptables-services
systemctl enable --now iptables
/sbin/iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
/sbin/iptables -F FORWARD
service iptables save
sysctl -w net.ipv4.conf.all.forwarding=1 >> /etc/sysctl.d/99-sysctl.conf
sysctl -p /etc/sysctl.d/99-sysctl.conf
cat << "EOF" >> /etc/ssh/sshd_config.d/portforward-only.conf
Match User ec2-user
    AllowTcpForwarding yes
    X11Forwarding no
    AllowAgentForwarding no
    PermitTTY no
EOF
systemctl restart sshd
dnf install -y fail2ban rsyslog
cat << "EOF" > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
[sshd]
bantime = 3600
findtime = 300
maxretry = 3
enabled = true
port = ssh
logpath = /var/log/secure
EOF
systemctl restart fail2ban && systemctl enable fail2ban
