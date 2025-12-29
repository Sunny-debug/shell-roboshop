#!/bin/bash

AMI_ID=ami-09c813fb71547fc4f
SG_ID=sg-0e25d883f9f15d071

for instance in $@
do
    InstanceID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-0e25d883f9f15d071 --query 'Instances[0].InstanceId'
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)
    
    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids i-00b73dd88662f9b0d --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text
            )
    else
        IP=$(aws ec2 describe-instances --instance-ids i-00b73dd88662f9b0d --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text
            )
    fi    

    echo "$instance:$IP"
done