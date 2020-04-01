#!/bin/bash
SUBNET_CIDR="${public_cidr}"
SUBNET_GW="${first_ip}"
SUBNET_PREFIX"${prefix_length}"

cd /root/
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
packstack --allinone \
    --os-swift-install=y \
	--os-cinder-install=y \
	--os-ceilometer-install=n \
	--os-neutron-ml2-type-drivers=flat,vxlan \
	--os-heat-install=y \
    --os-manila-install=n \
    --os-ceilometer-install=n \
    --os-aodh-install=n \
    --os-panko-install=n \
    --os-sahara-install=n \
    --os-magnum-install=n \
    --os-trove-install=n \
    --os-ironic-install=n \
    --os-neutron-lbaas-install=n \
    --os-neutron-metering-agent-install=n \
    --os-neutron-vpnaas-install=n
source /root/keystonerc_admin
subnet_id=`openstack subnet show public_subnet -f value -c id`
router_id=`openstack router show router1 -c id -f value`
neutron router-gateway-clear $router_id
openstack subnet delete $subnet_id


ns1=`grep nameserver /etc/resolv.conf | head -1 | awk '{print $2}'`
ns2=`grep nameserver /etc/resolv.conf | tail -1 | awk '{print $2}'`
openstack subnet create \
    --network public \
    --subnet-range $SUBNET_CIDR \
    --dns-nameserver $ns1 \
    --dns-nameserver $ns2 \
    --gateway $SUBNET_GW \
    "sub-$SUBNET_CIDR"

openstack router create admin-router
openstack router set --external-gateway public admin-router

internal_subnet="192.168.10.0/24"

openstack network create internal

openstack subnet create \
    --network internal \
    --dns-nameserver $ns1 \
    --dns-nameserver $ns2 \
    --subnet-range $internal_subnet \
    "sub-$internal_subnet"

internal_subnet_id=`openstack subnet show "sub-$internal_subnet" -c id -f value`
openstack router add subnet admin-router $internal_subnet_id

ip addr del 172.24.4.1/24 dev br-ex
ip addr add $SUBNET_GW/$SUBNET_PREFIX dev br-ex
ip link set br-ex up

image_name="centos-7_cloud-init.qcow2"
image_url="http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
image_distro="centos"
curl -Lo $image_name $image_url
glance --os-image-api-version 2 image-create --protected True --name $image_name --file $image_name \
    --visibility public --disk-format qcow2 --container-format bare --property os_distro=$image_distro --progress

image_name="ubuntu-18.04_cloud-init.qcow2"
image_url="https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img"
image_distro="ubuntu"
curl -Lo $image_name $image_url
glance --os-image-api-version 2 image-create --protected True --name $image_name --file $image_name \
    --visibility public --disk-format qcow2 --container-format bare --property os_distro=$image_distro --progress

systemctl restart httpd
for i in `systemctl list-units --type=service | grep openstack | awk '{print $1}'`; do systemctl condrestart $i; done

cat /root/keystonerc_admin
