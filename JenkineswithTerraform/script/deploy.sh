#!/bin/bash
sudo apt-get update -y
sudo apt-get install nginx -y

# Copy project to nginx html folder
sudo cp -r /home/ubuntu/sample.app/* /var/www/html/

sudo systemctl restart nginx
echo "Deployment Completed"
