#!/bin/bash

# Enable services and launch them
systemctl enable node-app-1.service
systemctl enable node-app-2.service
systemctl enable node-app-3.service
systemctl enable node-app-4.service
systemctl start 'node-app-*' --all

systemctl status 'node-app-*'

# Restart nginx
echo "[NGINX] Restarting Nginx"
/etc/init.d/nginx restart
