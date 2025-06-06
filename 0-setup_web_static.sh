#!/usr/bin/env bash

# Install Nginx if it's not installed
if ! dpkg -s nginx >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y nginx
fi

# Ensure Nginx is running
if ! systemctl is-active --quiet nginx; then
    sudo systemctl start nginx
fi

# Create required directories
mkdir -p /data/web_static/releases/test/
mkdir -p /data/web_static/shared/

# Create fake HTML file
echo "<h1>Hello World</h1>" > /data/web_static/releases/test/index.html

# Recreate symbolic link
if [ -L "/data/web_static/current" ] || [ -e "/data/web_static/current" ]; then
    rm -rf /data/web_static/current
fi
ln -s /data/web_static/releases/test/ /data/web_static/current

# Set ownership
chown -R ubuntu:ubuntu /data/

# Add Nginx config for /hbnb_static if not already present
config_file="/etc/nginx/sites-available/default"
alias_config="location /hbnb_static/ {
    alias /data/web_static/current/;
    index index.html;
}"

if ! grep -q "/hbnb_static/" "$config_file"; then
    # Insert location block before the last closing brace of the server block
    sudo sed -i "/server_name _;/a \\\n    $alias_config\n" "$config_file"
fi

# Test and restart Nginx
sudo nginx -t && sudo systemctl restart nginx

echo "Web static setup complete and available at /hbnb_static/"
