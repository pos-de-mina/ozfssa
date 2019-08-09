#!/bin/bash
#
# Agent for Check_MK to access Oracle ZFS Storage Appliance vi REST API
#
# S E T U P
#   - Install JASON Query tool
#   ln -s /omd/tools/jq /omd/sites/*/jq
#   chmod +x /omd/agent_ozfssa.sh
#   ln -s /omd/agent_ozfssa.sh /omd/versions/default/share/check_mk/agents/special/agent_ozfssa
#
# R E F
#   - https://docs.oracle.com/cd/E71909_01/html/E71922/index.html
#   - https://stedolan.github.io/jq
#
# Copyright (c) 2019-07-10 Antonio Pos-de-Mina


# ZFS Appliance host name : zfs-storage.example.com
ZFS_HOST=$1
# ZFS Read Only User
ZFS_USER=$2
# ZFS User Password
ZFS_PASSWORD=$3

# clean last call
rm -f ~/tmp/zfs_log_*


# ---------------------------
# Agent Header

echo "<<<check_mk>>>"
echo "Version: 1.0"
echo "AgentOS: Oracle ZFS Storage Appliance"


# ---------------------------
# Authentication

curl https://${ZFS_HOST}:215/api/access/v1 \
    --insecure \
    --include \
    --request POST \
    --write-out 'zfs_http_code=%{http_code}' \
    --header "X-Auth-User: ${ZFS_USER}" \
    --header "X-Auth-Key: ${ZFS_PASSWORD}" \
    --output ~/tmp/zfs_log_stdout_$$ \
    --stderr ~/tmp/zfs_log_stderr_$$ \
    --trace ~/tmp/zfs_log_trace_$$ > ~/tmp/zfs_log_metrics_$$
zfs_rc=$?
if [ "$zfs_rc" -eq "0" ]
then
    source ~/tmp/zfs_log_metrics_$$
    if [ "$zfs_http_code" -lt "300" ]
    then
        # get header "X-Auth-Session"
        ZFS_SESSION_ID=$(awk '/X-Auth-Session/ {print $2}' ~/tmp/zfs_log_stdout_$$)
    fi
fi


# ---------------------------
# Get Pools/Projects/Filesystems

echo '<<<df>>>'

curl https://${ZFS_HOST}:215/api/storage/v1/pools \
    --insecure \
    --silent \
    --header "X-Auth-Session: ${ZFS_SESSION_ID}" \
    --header "Content-Type: application/json; charset=utf-8" \
    | ~/jq -r '.pools[].name' | while read zfs_pool
do
    curl https://${ZFS_HOST}:215/api/storage/v1/projects \
        --insecure \
        --silent \
        --header "X-Auth-Session: ${ZFS_SESSION_ID}" \
        --header "Content-Type: application/json; charset=utf-8" \
        | ~/jq -r '.projects[].name' | while read zfs_project
    do
        curl https://${ZFS_HOST}:215/api/storage/v1/pools/${zfs_pool}/projects/${zfs_project}/filesystems \
            --insecure \
            --silent \
            --header "X-Auth-Session: ${ZFS_SESSION_ID}" \
            --header "Content-Type: application/json; charset=utf-8"\
            | ~/jq -r '.filesystems[] | [.pool, .project, .name, .space_data, .space_available] | @tsv' \
        | while read pool project name space_data space_available quota
        do
            space_data=$(($space_data/1024))
            space_available=$(($space_available/1024))
            space_total=$(($space_data+$space_available))
            percentage=$((($space_data*100)/($space_total)))
            echo -e "- - $space_total $space_data $space_available $percentage% /${pool}/${project}/${name}"
        done
    done
done
