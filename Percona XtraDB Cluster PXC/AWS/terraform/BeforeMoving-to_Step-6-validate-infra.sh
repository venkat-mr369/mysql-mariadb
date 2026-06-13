echo "===== EC2 ====="
aws ec2 describe-instances \
--query 'Reservations[*].Instances[*].[Tags[0].Value,State.Name]' \
--output table

echo "===== EBS ====="
aws ec2 describe-volumes \
--query 'Volumes[*].[VolumeId,State]' \
--output table

echo "===== NAT ====="
aws ec2 describe-nat-gateways \
--query 'NatGateways[*].[NatGatewayId,State]' \
--output table

echo "===== Terraform ====="
terraform state list | wc -l