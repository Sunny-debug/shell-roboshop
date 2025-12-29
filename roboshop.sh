#!/bin/bash
set -e

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0e25d883f9f15d071"

for instance in "$@"
do
  InstanceID=$(
    aws ec2 run-instances \
      --image-id "$AMI_ID" \
      --instance-type t3.micro \
      --security-group-ids "$SG_ID" \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
      --query 'Instances[0].InstanceId' \
      --output text
  )

  # Wait until AWS assigns IPs (otherwise you may get "None")
  aws ec2 wait instance-running --instance-ids "$InstanceID"

  if [ "$instance" != "frontend" ]; then
    IP=$(aws ec2 describe-instances \
      --instance-ids "$InstanceID" \
      --query 'Reservations[0].Instances[0].PrivateIpAddress' \
      --output text)
  else
    IP=$(aws ec2 describe-instances \
      --instance-ids "$InstanceID" \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text)
  fi

  echo "$instance:$IP"
done
