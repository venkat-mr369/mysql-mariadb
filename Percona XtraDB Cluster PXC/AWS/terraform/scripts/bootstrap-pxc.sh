#!/bin/bash

exec > /var/log/bootstrap.log 2>&1

echo "Bootstrap Started"

dnf update -y

dnf install -y \
wget \
vim \
rsync \
socat \
net-tools \
xfsprogs \
amazon-ssm-agent

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

echo "Waiting for EBS volume..."

while [ ! -b /dev/nvme1n1 ]; do
  sleep 10
done

echo "EBS volume detected"

mkfs.xfs -f /dev/nvme1n1

mkdir -p /data/mysql

mount /dev/nvme1n1 /data/mysql

UUID=$(blkid -s UUID -o value /dev/nvme1n1)

echo "UUID=$UUID /data/mysql xfs defaults,nofail 0 0" >> /etc/fstab

echo "Bootstrap Completed"