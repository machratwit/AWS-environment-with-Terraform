
#!/bin/bash
set -euxo pipefail

dnf install -y python3

mkdir -p /var/www/app

cat > /var/www/app/index.html <<'HTML'
<!doctype html>
<html>
  <head><title>Company Demo App</title></head>
  <body>
    <h1>It works!</h1>
    <p>This application runs on a private EC2 instance.</p>
    <p>Traffic reaches this instance through an Application Load Balancer.</p>
  </body>
</html>
HTML

cat > /etc/systemd/system/demo-app.service <<'SERVICE'
[Unit]
Description=Demo web application
After=network.target

[Service]
Type=simple
WorkingDirectory=/var/www/app
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 0.0.0.0 --directory /var/www/app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now demo-app
