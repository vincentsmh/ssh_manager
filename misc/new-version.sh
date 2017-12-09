#!/bin/bash

function get_current_version()
{
  head cn.sh | grep "VERSION=" | awk -F "\"" {'print $2'}
}

function get_current_datetime()
{
  head cn.sh | grep "LAST_UPDATE=" | awk -F "\"" {'print $2'}
}

cd ..
new_datetime=$(date '+%Y%m%d%H%M%S')
cur_ver=$(get_current_version)
cur_dt=$(get_current_datetime)

read -p "Current version is ${cur_ver}. Please assign a new version: " new_ver

cp cn.sh cn_blk.sh
sed_cmd="sed -e '0,/VERSION=\"${cur_ver}\"/ s/VERSION=\"${cur_ver}\"/VERSION=\"${new_ver}\"/' cn.sh > cn_new.sh"
eval ${sed_cmd}
mv cn_new.sh cn.sh
sed_cmd="sed -e '0,/LAST_UPDATE=\"${cur_dt}\"/ s/LAST_UPDATE=\"${cur_dt}\"/LAST_UPDATE=\"${new_datetime}\"/' cn.sh > cn_new.sh"
eval ${sed_cmd}
mv cn_new.sh cn.sh

git add cn.sh
git commit -m "Update to version ${new_ver}"
git tag ${new_ver}
