#!/bin/bash
set -euxo pipefail

# Log all user-data output for troubleshooting
exec > >(tee -a /var/log/user-data.log) 2>&1

echo "Starting EC2 user-data setup..."

# Install required packages
dnf install -y python3 amazon-cloudwatch-agent

# --------------------------------------------------
# 1. Create the demo application
# --------------------------------------------------

mkdir -p /var/www/app
touch /var/log/demo-app.log

cat > /var/www/app/index.html <<'HTML'
<!doctype html>
<html>
  <head>
    <title>Company Demo App</title>
  </head>
  <body>
    <h1>It works!</h1>
    <p>This application runs on a private EC2 instance.</p>
    <p>Traffic reaches this instance through an Application Load Balancer.</p>
  </body>
</html>
HTML

# Create systemd service
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
StandardOutput=append:/var/log/demo-app.log
StandardError=append:/var/log/demo-app.log

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now demo-app

# --------------------------------------------------
# 2. Configure CloudWatch Agent
# --------------------------------------------------

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CONFIG'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "namespace": "DemoApp",
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "resources": [
          "/"
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/demo-app.log",
            "log_group_name": "/demo-app/application",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/demo-app/system",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "/demo-app/cloud-init",
            "log_stream_name": "{instance_id}-output"
          },
          {
            "file_path": "/var/log/cloud-init.log",
            "log_group_name": "/demo-app/cloud-init",
            "log_stream_name": "{instance_id}-cloud-init"
          }
        ]
      }
    }
  }
}
CONFIG

# --------------------------------------------------
# 3. Start CloudWatch Agent
# --------------------------------------------------

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

# Enable agent at startup
systemctl enable amazon-cloudwatch-agent

echo "User-data setup completed successfully."