#!/bin/bash
echo `date` > /tmp/user_data.txt
#echo "Huawei@123" | passwd --stdin root
echo "root:Huawei@123" | sudo chpasswd
sudo apt update -y &&
sudo apt install -y nginx
echo "Hello World" > /var/www/html/index.html