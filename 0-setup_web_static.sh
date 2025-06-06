#!/usr/bin/env bash
# Sets up web servers for deployment of web_static

# Exit on error
set -e

# Install Nginx if not installed
if ! dpkg -s nginx >/dev/null 2>&1; then
    sudo apt update -y
    sudo apt install -y nginx
fi

# Ensure Nginx is running
if ! sudo systemctl is-active --quiet nginx; then
    sudo systemctl start nginx
fi

# Create required directories
sudo mkdir -p /data/web_static/releases/test/
sudo mkdir -p /data/web_static/shared/

# Create a fake HTML file
echo "<h1>Hello World</h1>" | sudo tee /data/web_static/releases/test/index.html > /dev/null

# Create or recreate symbolic link
sudo ln -sfn /data/web_static/releases/test/ /data/web_static/current

# Give ownership to ubuntu user and group
sudo chown -R ubuntu:ubuntu /data/

# Nginx config update
CONFIG="/etc/nginx/sites-available/default"
ALIAS_BLOCK="location /hbnb_static/ {
    alias /data/web_static/current/;
    index index.html;
}"

# Add alias block if not present
if ! grep -q "location /hbnb_static/" "$CONFIG"; then
    sudo sed -i "/server_name _;/a \\\n    $ALIAS_BLOCK\n" "$CONFIG"
fi

# Reload Nginx
sudo nginx -t && sudo systemctl reload nginx

# Always exit successfully
exit 0
