#!/bin/bash
################################################################################################################################
##                                      A script to list & control AWS instances
##
## AWS Commands:
##    aws ec2 describe-instance-status --include-all-instances --region us-east-1 --output table
##    aws ec2 describe-instance-status --include-all-instances --region us-east-1 | jq '.InstanceStatuses[range(0;10)].InstanceId'
##    aws ec2 describe-instance-status --include-all-instances --region us-east-1 |  grep InstanceId | wc -l
##    aws ec2 reboot-instances --instance-ids <instance_id>
##    aws ec2 start-instances --instance-ids <instance_id>
##    aws ec2 stop-instances --instance-ids <instance_id>
##    aws ec2 terminate-instances --instance-ids <instance_id>
################################################################################################################################

# AWS REGIONS ARRAY
AWS_REGIONS=("us-east-1" "us-west-1" "us-west-2" "eu-west-1"
"eu-central-1" "ap-southeast-1" "ap-northeast-2" "ap-southeast-2"
"sa-east-1" "us-gov-west-1" "cn-north-1")

echo "Loading..."
# Test if jq tool is installed on the system
type jq &> /dev/null
if [[ $? -eq 1 ]]; then
  echo -e "Tools jq not installed...\nyou can found installation steps in https://stedolan.github.io/jq/"
  exit
fi

echo "Locating Credentials..."
# Test if there exist a credentials file and it is not empty
if [[ ! -s ~/.aws/credentials ]] || [[ ! -e ~/.aws/credentials ]]; then
  echo "You need to configure your AWS Credentials"
  aws configure
fi

echo "Validating Credentials..."
# Test if the aws credentials is correct
aws ec2 describe-instances &> /dev/null
if [[ ! $? -eq 0 ]]; then
  echo -e "Error: Wrong AWS Credentials !!!\n\n\n"
  exit
fi

PS3="What do you want to do next?  "
Option=( "Change AWS Configuration" "List Instances" "Change Default Region"
"Start Instances" "Reboot Instances" "Stop Instances" "Terminate Instances" "Quit")


select Option in "${Option[@]}"
do
  case $Option in

    "Change AWS Configuration" )
    aws configure
    ;;

    "List Instances" )

    for region in "${AWS_REGIONS[@]}" ; do

      echo "=========================================================="

      echo "Region: "$region

      instanceCount=`aws ec2 describe-instance-status --include-all-instances --region $region |  grep InstanceId | wc -l`
      echo "Number of instances: "$instanceCount

      instanceIDs=( `aws ec2 describe-instance-status --include-all-instances --region $region | jq -r '.InstanceStatuses[range(0;'$instanceCount')].InstanceId'` )
      #echo ${instanceIDs[@]}

      instanceStates=( `aws ec2 describe-instance-status --include-all-instances --region $region | jq -r '.InstanceStatuses[range(0;'$instanceCount')].InstanceState.Name'`  )
      #echo ${instanceStates[@]}

      echo -e "Instance ID\t\tInstance State\n"
      for (( i = 0; i < $instanceCount; i++ )); do
        echo -e ${instanceIDs[$i]}"\t\t"${instanceStates[$i]}
      done

      echo -e "==========================================================\n\n\n"

    done
    ;;

    "Change Default Region")

    echo " Select a region: "
    select defreg in ${AWS_REGIONS[@]}
    do
      case $defreg in
        * ) export region=$defreg
        break
        ;;
      esac
    done
    sed -i 's/region = .*/region = '$defreg'/' ~/.aws/config
    ;;


    "Start Instances" )
    echo -n "Enter instance-ids to start: "
    read instance_id
    aws ec2 start-instances --instance-ids $instance_id 1> /dev/null
    ;;

    "Stop Instances" )
    echo -n "Enter instance-ids to stop: "
    read instance_id
    aws ec2 stop-instances --instance-ids $instance_id 1> /dev/null
    ;;

    "Reboot Instances" )
    echo -n "Enter instance-ids to reboot: "
    read instance_id
    aws ec2 reboot-instances --instance-ids $instance_id 1> /dev/null
    ;;



    "Terminate Instances" )
    echo -n "Enter instance-ids to terminate: "
    read instance_id
    aws ec2 terminate-instances --instance-ids $instance_id 1> /dev/null
    ;;

    "Quit" )
    exit;
    ;;
  esac
done
