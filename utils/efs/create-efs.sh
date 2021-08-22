#!/bin/bash -e

function get_vpc_id {
    ClusterName="${1}"
    aws eks describe-cluster \
        --name "${ClusterName}" \
        --query "cluster.resourcesVpcConfig.vpcId" \
        --output text
}

function get_cidr_range {
    vpc_id="${1}"
    aws ec2 describe-vpcs \
        --vpc-ids "${vpc_id}" \
        --query "Vpcs[].CidrBlock" \
        --output text
}

function get_security_group_id {
    SecurityGroupName=$1
    vpc_id=$2
    aws ec2 describe-security-groups \
        --query "SecurityGroups[*].GroupId" \
        --output text \
        --filters \
            Name=vpc-id,Values="${vpc_id}" \
            Name=group-name,Values="${SecurityGroupName}"
}

function create_security_group_id {
    SecurityGroupName=$1
    vpc_id=$2
    aws ec2 create-security-group \
        --group-name "${SecurityGroupName}" \
        --description "${SecurityGroupName} security group" \
        --vpc-id "${vpc_id}" \
        --output text
}

function get_ingress_rule {
    security_group_id=$1
    cidr_range=$2
    aws ec2 describe-security-groups \
        --group-ids "${security_group_id}" \
         | jq -r ".SecurityGroups[].IpPermissions[]|select(.FromPort==2049).IpRanges[]|select(.CidrIp==\"${cidr_range}\").CidrIp"
}

function create_ingress_rule {
    security_group_id=$1
    cidr_range=$2
    aws ec2 authorize-security-group-ingress \
        --group-id "${security_group_id}" \
        --protocol tcp \
        --port 2049 \
        --cidr "${cidr_range}" \
        --query SecurityGroupRules[*].SecurityGroupRuleId \
        --output text
}

function get_filesystem {
    name=$1
    aws efs describe-file-systems \
        | jq -r ".FileSystems[] | select(.Tags[].Value==\"${name}\").FileSystemId"
}

function create_filesystem {
    name=$1
    aws efs create-file-system \
        --performance-mode generalPurpose \
        --tags Key=Name,Value="${name}" \
        --encrypted \
        --query 'FileSystemId' \
        --output text
}

function get_mount_targets {
    FileSystemId=$1
    aws efs describe-mount-targets \
        --file-system-id "${FileSystemId}" \
        --query "MountTargets[*].MountTargetId" \
        --output text
}

function create_mount_target {
    file_system_id=$1
    subnet_id=$2
    security_group_id=$3
    aws efs create-mount-target \
    --file-system-id "${file_system_id}" \
    --subnet-id "${subnet_id}" \
    --security-groups "${security_group_id}" \
    --query 'MountTargetId' \
    --output text
}

function get_subnets {
    vpc_id=$1
    aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=${vpc_id}" \
        --query 'Subnets[*].SubnetId' \
        --output text
}


function delete_fs {
    file_system_id=$1
    aws efs delete-file-system --file-system-id "${file_system_id}"
    echo "Volumen EFS: ${file_system_id} Eliminado";
}

function delete_mount_target {
    MountTargetId=$1
    aws efs delete-mount-target --mount-target-id "${MountTargetId}"
    echo "Mount Target: ${MountTargetId} Eliminado";
}

function get_mount_targets {
    file_system_id=$1
    aws efs describe-mount-targets \
        --file-system-id "${file_system_id}" \
        --query MountTargets[*].MountTargetId \
        --output text
}

function delete_sg {
    group_id=$1
    aws ec2 delete-security-group --group-id "${group_id}"
    echo "Security Group: ${group_id} Eliminado";
}

function create {
    CLUSTER_NAME=$1
    VOLUME_NAME="${1}Volume"
    vpc_id=$(get_vpc_id "${CLUSTER_NAME}")
    echo "VPC ID: ${vpc_id}"
    cidr_range=$(get_cidr_range "${vpc_id}")
    echo "CIDR: ${cidr_range}";
    security_group_id=$(get_security_group_id "${VOLUME_NAME}" "${vpc_id}")
    if [ -z "${security_group_id}" ]; then
        echo "Creando Security Group"
        security_group_id=$(create_security_group_id "${VOLUME_NAME}" "${vpc_id}")
    fi
    echo "Security Group id: ${security_group_id}"
    sg_rule_id=$(get_ingress_rule "${security_group_id}" "${cidr_range}")
    if [ -z "${sg_rule_id}" ]; then
        sg_rule_id=$(create_ingress_rule "${security_group_id}" "${cidr_range}")
        echo "EFS Security Group Rule id: ${sg_rule_id}"
    else
        echo "EFS SG Rule exists for CIDR: ${sg_rule_id}"
    fi

    file_system_id=$(get_filesystem "${VOLUME_NAME}")
    if [ -z "${file_system_id}" ]; then
        file_system_id=$(create_filesystem "${VOLUME_NAME}")
        sleep 10;
    fi

    echo "Volumen EFS: ${file_system_id}";

    subnet_ids=$(get_subnets "${vpc_id}");
    # echo "subnets: ${subnet_ids}";

    for subnet_id in ${subnet_ids}; do
        mount_target_id=$(create_mount_target "${file_system_id}" "${subnet_id}" "${security_group_id}");
        echo "Mount target - Subnetid=${subnet_id} Mount_target_id=${mount_target_id}";
    done
}


function delete {
    CLUSTER_NAME=$1
    VOLUME_NAME="${1}Volume"

    file_system_id=$(get_filesystem "${VOLUME_NAME}")
    if [[ -n "${file_system_id}" ]]; then
        mount_target_ids=$(get_mount_targets "${file_system_id}")
        if [[ -n "${mount_target_ids}" ]]; then
            for mount_target_id in ${mount_target_ids}; do
                delete_mount_target "${mount_target_id}"
            done
            sleep 20;
        fi
        delete_fs "${file_system_id}"
    fi
    vpc_id=$(get_vpc_id "${CLUSTER_NAME}")
    security_group_id=$(get_security_group_id "${VOLUME_NAME}" "${vpc_id}")
    if [[ -n "${security_group_id}" ]]; then
        delete_sg "${security_group_id}"
    fi
}

## Main
while [[ $# -gt 0 ]]; do
    key="${1}"
    shift;
    case "${key}" in
        -c|--create)
            create "${1}";
            shift;
            ;;
        -d|--delete)
            delete "$1";
            shift;
            ;;
        *)
            echo "usage: $0 -c cluster_name"
            shift $#;
            ;;
    esac
done
