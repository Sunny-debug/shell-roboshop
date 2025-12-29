#!/bin/bash
set -e

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0e25d883f9f15d071"
ZONE_ID="Z0095538Q74XD6XU6M0Z"
DOMAIN_NAME="dawgs.online"
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
      RECORD_NAME="$instance.$DOMAIN_NAME"
  else
    IP=$(aws ec2 describe-instances \
      --instance-ids "$InstanceID" \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text)
      RECORD_NAME="$DOMAIN_NAME"
  fi

  echo "$instance:$IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating record set"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }
    '
done
