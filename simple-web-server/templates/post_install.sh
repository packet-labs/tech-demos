#!/bin/bash
yum install epel-release -y
yum install nginx -y
mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.bak
echo '<center><div style="display:inline; white-space:nowrap;"><div style="display:inline; white-space:nowrap;"><p style="font-weight: bold;font-size: 100px;">Hello <img src="https://www.packet.com/packet-v4/images/logo-main@2x.png" alt="Hello Packet!" style="height:100px;" />!</p></div></div></center>' > /usr/share/nginx/html/index.html
systemctl enable nginx
systemctl start nginx
