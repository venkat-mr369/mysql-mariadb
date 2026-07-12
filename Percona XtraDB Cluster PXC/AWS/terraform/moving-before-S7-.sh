#!/bin/bash

echo ""
echo "======================================================="
echo "          PXC AWS ENVIRONMENT VALIDATION"
echo "======================================================="

echo ""
echo "===== VPC ====="

aws ec2 describe-vpcs \
--filters "Name=tag:Name,Values=*" \
--query 'Vpcs[*].[Tags[?Key==`Name`].Value|[0],VpcId,CidrBlock,State]' \
--output table

echo ""
echo "===== SUBNETS ====="

aws ec2 describe-subnets \
--query 'Subnets[*].[Tags[?Key==`Name`].Value|[0],SubnetId,CidrBlock,AvailabilityZone,State]' \
--output table

echo ""
echo "===== INTERNET GATEWAYS ====="

aws ec2 describe-internet-gateways \
--query 'InternetGateways[*].[InternetGatewayId,Attachments[0].VpcId,Attachments[0].State]' \
--output table

echo ""
echo "===== NAT GATEWAYS ====="

aws ec2 describe-nat-gateways \
--query 'NatGateways[*].[NatGatewayId,VpcId,SubnetId,State]' \
--output table

echo ""
echo "===== ROUTE TABLES ====="

aws ec2 describe-route-tables \
--query 'RouteTables[*].[RouteTableId,VpcId]' \
--output table

echo ""
echo "===== EC2 INSTANCES ====="

aws ec2 describe-instances \
--query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],Tags[?Key==`Role`].Value|[0],InstanceId,Placement.AvailabilityZone,InstanceType,State.Name,PrivateIpAddress,PublicIpAddress]' \
--output table

echo ""
echo "===== PXC NODE VALIDATION ====="

aws ec2 describe-instances \
--filters "Name=tag:Role,Values=PXC" \
--query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],Placement.AvailabilityZone,PrivateIpAddress]' \
--output table

echo ""
echo "===== EBS VOLUMES ====="

aws ec2 describe-volumes \
--query 'Volumes[*].[Tags[?Key==`Name`].Value|[0],VolumeId,Size,State,AvailabilityZone]' \
--output table

echo ""
echo "===== EBS ATTACHMENTS ====="

aws ec2 describe-volumes \
--query 'Volumes[*].[Tags[?Key==`Name`].Value|[0],Attachments[0].InstanceId,AvailabilityZone,State]' \
--output table

echo ""
echo "===== SECURITY GROUPS ====="

aws ec2 describe-security-groups \
--query 'SecurityGroups[*].[GroupName,GroupId,VpcId]' \
--output table

echo ""
echo "===== ELASTIC IPS ====="

aws ec2 describe-addresses \
--query 'Addresses[*].[AllocationId,PublicIp,AssociationId]' \
--output table

echo ""
echo "===== KEY PAIRS ====="

aws ec2 describe-key-pairs \
--query 'KeyPairs[*].[KeyName,KeyPairId]' \
--output table

echo ""
echo "===== TERRAFORM STATE ====="

terraform state list

echo ""
echo "===== TERRAFORM RESOURCE COUNT ====="

terraform state list | wc -l

echo ""
echo "===== TERRAFORM OUTPUTS ====="

terraform output

echo ""
echo "======================================================="
echo "               VALIDATION COMPLETED"
echo "======================================================="