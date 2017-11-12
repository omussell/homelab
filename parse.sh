#!/bin/sh -
set -e

CONFIG_FILE="/home/oem/test.yaml"
CONFIG_ENV=$(grep -i environment ${CONFIG_FILE} | awk -F '=' {'print $2'} | tr -d '[:punct:]')
CONFIG_BRANCH=$(grep -i branch ${CONFIG_FILE} | awk -F '=' {'print $2'})
HIERA_BRANCH_FILE="/home/oem/data/groups/${CONFIG_ENV}.yaml"
#HIERA_JAILS_FILE="/home/oem/data/groups/${CONFIG_ENV}/host_app.yaml"

sed -i "s/branch.*/branch: ${CONFIG_BRANCH}/" ${HIERA_BRANCH_FILE}
