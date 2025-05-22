#!/usr/bin/env bash
# Helper script: provisions a t3.medium Amazon Linux 2 instance in default VPC
REGION=${AWS_REGION:-us-east-1}
KEYNAME="k8s-lab-key"
AMI="ami-0c02fb55956c7d316"   # AL2 in us-east-1

aws ec2 create-key-pair --key-name $KEYNAME --query "KeyMaterial" --output text > ${KEYNAME}.pem
chmod 400 ${KEYNAME}.pem

SG_ID=$(aws ec2 create-security-group --group-name k8s-lab-sg --description "K8s Lab SG" --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0

INSTANCE_ID=$(aws ec2 run-instances           --image-id $AMI           --instance-type t3.medium           --key-name $KEYNAME           --security-group-ids $SG_ID           --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=k8s-lab}]'           --query 'Instances[0].InstanceId' --output text)

echo "Waiting for instance..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID           --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "Instance is ready: $PUBLIC_IP"
echo "SSH: ssh -i ${KEYNAME}.pem ec2-user@$PUBLIC_IP"
