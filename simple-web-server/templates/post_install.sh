#!/bin/bash
yum install epel-release -y
yum install nginx -y
mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.bak
echo '<center><div style="display:inline; white-space:nowrap;"><div style="display:inline; white-space:nowrap;"><p style="font-weight: bold;font-size: 100px;">Hello <img src="https://www.pngkey.com/png/full/321-3217317_verizon-logo-transparent-png-sticker-verizon-wireless-prepaid.png" alt="Hello Verizon!" style="height:100px;" />!</p></div></div></center>' > /usr/share/nginx/html/index.html
systemctl enable nginx
systemctl start nginx
