#!/bin/bash
################################################################################################################################
##                                      A script to list & control AWS instances
##
##  AWS Commands:
##    aws ec2 describe-instance-status --include-all-instances --region us-east-1 --output table
##    aws ec2 describe-instance-status --include-all-instances --region us-east-1 | jq '.InstanceStatuses[range(0;10)].InstanceId'
##    aws ec2 describe-instance-status --include-all-instances --region us-east-1 |  grep InstanceId | wc -l
##    aws ec2 reboot-instances --instance-ids <instance_id>
##    aws ec2 start-instances --instance-ids <instance_id>
##    aws ec2 stop-instances --instance-ids <instance_id>
##    aws ec2 terminate-instances --instance-ids <instance_id>
##
################################################################################################################################

reset_ink='\e[0;m'
yellow='\033[1;33m'

red='\033[0;31m'
light_red='\033[1;31m'

green='\033[0;32m'
light_green='\033[1;32m'

blue='\033[0;34m'
light_blue='\033[0;34m'

bold=$(tput bold)
normal=$(tput sgr0)
# AWS REGIONS ARRAY
AWS_REGIONS=( "us-east-1"
              "us-west-1"
              "us-west-2"
              "eu-west-1"
              "eu-central-1"
              "ap-southeast-1"
              "ap-northeast-2"
              "ap-southeast-2"
              "sa-east-1"
              "us-gov-west-1"
              "cn-north-1" )

echo -e $light_green"Loading..."$reset_ink
# Test if jq tool is installed on the system
type jq &> /dev/null
if [[ $? -eq 1 ]]; then
  echo -e $light_red"Tool jq not installed...\nyou can find installation steps in https://stedolan.github.io/jq/"$reset_ink
  exit
fi

echo -e $light_green"Locating Credentials..."$reset_ink
# Test if there exist a credentials file and it is not empty
if [[ ! -s ~/.aws/credentials ]] || [[ ! -e ~/.aws/credentials ]]; then
  echo -e $light_blue"You need to configure your AWS Credentials"$reset_ink
  aws configure
fi

echo -e $light_green"Validating Credentials..."$reset_ink
# Test if the aws credentials is correct
aws ec2 describe-instances &> /dev/null
if [[ ! $? -eq 0 ]]; then
  echo -e $light_red"Error: Wrong AWS Credentials !!!\n\n\n"$reset_ink
  exit
fi

function list_instances() {
  echo -e $reset_ink
  for region in "${AWS_REGIONS[@]}" ; do
    instancesCount=`aws ec2 describe-instance-status --include-all-instances --region $region |  grep InstanceId | wc -l`
    echo -e ${bold}"Region: "${normal}$region"\t\t${bold}Number of instances: "$instancesCount${normal}

    instancesIDs=( `aws ec2 describe-instance-status --include-all-instances --region $region | jq -r '.InstanceStatuses[range(0;'$instancesCount')].InstanceId'` )
    instancesStates=( `aws ec2 describe-instance-status --include-all-instances --region $region | jq -r '.InstanceStatuses[range(0;'$instancesCount')].InstanceState.Name'`  )

    instancesPublicIPs=( `aws ec2 describe-instances --region $region --instance-ids ${instanceIDs[@]}  | jq -r '.Reservations[range(0;'$instancesCount')].Instances[0].PublicIpAddress'` )
    instancesPrivateIPs=( `aws ec2 describe-instances --region $region --instance-ids ${instanceIDs[@]}  | jq -r '.Reservations[range(0;'$instancesCount')].Instances[0].PrivateIpAddress'` )
    instancesTypes=( `aws ec2 describe-instances --region $region --instance-ids ${instanceIDs[@]}  | jq -r '.Reservations[range(0;'$instancesCount')].Instances[0].InstanceType' ` )

    for (( i = 0; i < 104; i++ )); do echo -n "=" ; done
    echo -en "\n"

    echo -en ${bold}"Instance ID\t\tInstance State\tInstance Type\t\tPrivate IP\t\tPublic IP\n"${normal}

    echo -en $reset_ink
    for (( i = 0; i < 104; i++ )); do echo -n "=" ; done
    echo -en "\n"

    for (( i = 0; i < $instancesCount; i++ )); do
      if [[ "${instancesStates[$i]}" == "running" ]]; then
        echo -e $green${instancesIDs[$i]}"\t\t"${instancesStates[$i]}"\t\t"${instancesTypes[$i]}\
        "\t\t"${instancesPrivateIPs[$i]}"\t\t"${instancesPublicIPs[$i]}

      elif [[ "${instancesStates[$i]}" == "stopped" ]]; then
        echo -e $yellow${instancesIDs[$i]}"\t\t"${instancesStates[$i]}"\t\t"${instancesTypes[$i]}\
        "\t\t"${instancesPrivateIPs[$i]}"\t\t"${instancesPublicIPs[$i]}
      elif [[ "${instancesStates[$i]}" == "terminated" ]]; then
        echo -e $red${instancesIDs[$i]}"\t\t"${instancesStates[$i]}"\t\t"${instancesTypes[$]}\
        "\t\t"${instancesPrivateIPs[$i]}"\t\t"${instancesPublicIPs[$i]}
      else
        echo -e $reset_ink${instancesIDs[$i]}"\t\t"${instancesStates[$i]}"\t\t"${instancesTypes[$]}\
        "\t\t"${instancesPrivateIPs[$i]}"\t\t"${instancesPublicIPs[$i]}
      fi
    done

    if [[ $instancesCount -gt 0 ]]; then
      echo -en $reset_ink
      for (( i = 0; i < 104; i++ )); do echo -n "=" ; done
    fi
    echo -e "\n\n"
  done
}

function change_def_region(){
  echo $light_blue
  PS3="Select a region: "
  select def_region in ${AWS_REGIONS[@]}
  do
    case $def_region in
      * ) export region=$def_region
          echo -e $yellow
          PS3="What do you want to do next? "
          break
          ;;
    esac
  done
  sed -i 's/region = .*/region = '$def_region'/' ~/.aws/config
  echo -e $yellow
}

function start_instances(){
  echo -en $light_blue"Enter instance-ids to start: "$reset_ink
  read instance_id
  aws ec2 start-instances --instance-ids $instance_id 1> /dev/null
  echo -e $yellow
}


function stop_instances(){
  echo -en $light_blue"Enter instance-ids to stop: "$reset_ink
  read instance_id
  aws ec2 stop-instances --instance-ids $instance_id 1> /dev/null
  echo -e $yellow
}


function reboot_instances(){
  echo -en $light_blue"Enter instance-ids to reboot: "$reset_ink
  read instance_id
  aws ec2 reboot-instances --instance-ids $instance_id 1> /dev/null
  echo -e $yellow
}

function terminate_instances(){
  echo -en $light_blue"Enter instance-ids to terminate:"$reset_ink
  read instance_id
  aws ec2 terminate-instances --instance-ids $instance_id 1> /dev/null
  echo -e $yellow
}


Option=(  "Change AWS Configuration"
          "Change Default Region"
          "List Instances"
          "Start Instances"
          "Stop Instances"
          "Reboot Instances"
          "Terminate Instances"
          "Quit" )

echo -e $yellow
PS3="What do you want to do next? "
select Option in "${Option[@]}"
do
  case $Option in

    "Change AWS Configuration" )  aws configure ;;

    "List Instances" )  list_instances ;;

    "Change Default Region") change_def_region ;;

    "Start Instances" ) start_instances ;;

    "Stop Instances" )  stop_instances ;;

    "Reboot Instances" ) reboot_instances ;;

    "Terminate Instances" ) terminate_instances ;;

    "Quit" )  echo -e $reset_ink ; exit ;;
  esac
done
