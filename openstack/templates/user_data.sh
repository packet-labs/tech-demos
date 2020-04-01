#!/bin/bash 
systemctl disable firewalld
systemctl stop firewalld
systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl enable network
systemctl start network
yum update -y
yum install -y centos-release-openstack-stein
yum-config-manager --enable openstack-stein
yum update -y
yum install -y openstack-packstack lvm2* ntp
pvcreate /dev/nvme0n1
vgcreate cinder-volumes /dev/nvme0n1
systemctl enable ntpd
systemctl start ntpd
sed -i s/SELINUX=enforcing/SELINUX=permissive/g /etc/selinux/config
setenforce 0
modprobe bridge
modprobe 8021q
modprobe bonding
modprobe tun
modprobe br_netfilter
echo bridge > /etc/modules-load.d/os.conf
echo 8021q >> /etc/modules-load.d/os.conf
echo bonding >> /etc/modules-load.d/os.conf
echo tun >> /etc/modules-load.d/os.conf
echo br_netfilter >> /etc/modules-load.d/os.conf
echo net.ipv4.conf.all.rp_filter=0 >> /etc/sysctl.conf
echo net.ipv4.conf.default.rp_filter=0 >> /etc/sysctl.conf
echo net.bridge.bridge-nf-call-iptables=1 >> /etc/sysctl.conf
echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
echo net.ipv4.tcp_mtu_probing=2 >> /etc/sysctl.conf
sysctl -p
