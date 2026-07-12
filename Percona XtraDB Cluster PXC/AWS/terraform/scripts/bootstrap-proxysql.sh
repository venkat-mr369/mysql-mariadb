#!/bin/bash

exec > /var/log/bootstrap.log 2>&1

echo "Bootstrap Started"

dnf update -y

dnf install -y \
wget \
vim \
net-tools \
git \
amazon-ssm-agent

systemctl enable amazon-ssm-agent

systemctl start amazon-ssm-agent

echo "Bootstrap Completed"