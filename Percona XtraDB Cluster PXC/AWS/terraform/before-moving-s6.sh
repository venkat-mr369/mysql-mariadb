#!/bin/bash

echo "===== VPC ====="
aws ec2 describe-vpcs \
--query 'Vpcs[*].[VpcId,CidrBlock,State]' \
--output table


echo "===== SUBNETS ====="
aws ec2 describe-subnets \
--query 'Subnets[*].[SubnetId,VpcId,CidrBlock,AvailabilityZone,State]' \
--output table


echo "===== INTERNET GATEWAY (IGW) ====="
aws ec2 describe-internet-gateways \
--query 'InternetGateways[*].[InternetGatewayId,Attachments[0].VpcId,Attachments[0].State]' \
--output table


echo "===== ROUTE TABLES ====="
aws ec2 describe-route-tables \
--query 'RouteTables[*].[RouteTableId,VpcId,Routes[0].GatewayId,Routes[0].NatGatewayId]' \
--output table


echo "===== NAT GATEWAYS ====="
aws ec2 describe-nat-gateways \
--query 'NatGateways[*].[NatGatewayId,VpcId,SubnetId,State]' \
--output table


echo "===== EC2 ====="
aws ec2 describe-instances \
--query 'Reservations[*].Instances[*].[Tags[0].Value,InstanceId,InstanceType,State.Name,PrivateIpAddress,PublicIpAddress]' \
--output table


echo "===== EBS VOLUMES ====="
aws ec2 describe-volumes \
--query 'Volumes[*].[VolumeId,Size,State,AvailabilityZone]' \
--output table


echo "===== SECURITY GROUPS ====="
aws ec2 describe-security-groups \
--query 'SecurityGroups[*].[GroupId,GroupName,VpcId]' \
--output table


echo "===== ELASTIC IPs ====="
aws ec2 describe-addresses \
--query 'Addresses[*].[AllocationId,PublicIp,AssociationId]' \
--output table


echo "===== TERRAFORM RESOURCES ====="
terraform state list


echo "===== TERRAFORM RESOURCE COUNT ====="
terraform state list | wc -l