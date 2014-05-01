#/bin/bash

DATA="$HOME/conn.data"
DEFAULT_SSH_PORT=22

# Color function
# Input: $1->color, $2->message, $3->newline or not
function color_msg
{
	echo -e $3 "\033[$1m$2\033[0m"
}

# Find out the deply path according to Linux of OS X
function find_deploy_folder()
{
	# Check the deploy OS is Linux or Mac(Darwin)
	os=`uname`

	if [ "$os" == "Linux" ]; then
		echo "/usr/local/bin"
	else
		echo "/usr/bin"
	fi
}

function unset_site()
{
	unset site_num
	unset site_userip
	unset site_desc
	unset site_status
	unset site_feq
	unset site_tag
}

function init_max_len()
{
	max_num_len=2
	max_userip_len=7
	max_desc_len=11
	max_status_len=6
	max_feq_len=9
	max_tag_len=3
	max_port_len=2
}

function find_port()
{
	local port=$(echo "$1" | awk -F " " {'print $2'})

	if [ "$port" == "" ]; then
		echo $DEFAULT_SSH_PORT
	else
		echo $port
	fi
}

function find_userip()
{
	local userip=$(echo "$1" | awk -F " " {'print $3'})

	if [ "$userip" == "" ]; then
		echo "$1"
	else
		echo $userip
	fi
}

function update_port_max()
{
	if [ $1 -gt $max_port_len ]; then
		max_port_len=$1
	fi
}

function check_n_exit()
{
	if [ $1 -ne 0 ]; then
		color_msg 31 "$2"
		exit $1
	fi
}

function check_empty()
{
	if [ "$1" == "" ]; then
		echo "NA"
	else
		echo "$1"
	fi
}

# Read all sites data into 'sites'
function read_sites()
{
	local read_max=0

	while read site
	do
		unset array
		IFS='_' read -a array <<< "$site"

		if [ $read_max -ne 0 ]; then
			local th=$(echo ${array[0]} | bc)
			site_num[$th]=$th
			site_userip[$th]=$(find_userip "${array[1]}")
			site_desc[$th]=$(check_empty "${array[2]}")
			site_status[$th]=${array[3]}
			site_feq[$th]=${array[4]}
			site_tag[$th]=$(check_empty "${array[5]}")
			site_port[$th]=$(find_port "${array[1]}")
			update_port_max ${#site_port[$th]}
		else
			# Read max length for each column at the first loop
			max_num_len=$( echo ${array[0]} | bc )
			max_userip_len=$( echo ${array[1]} | bc )
			max_desc_len=$( echo ${array[2]} | bc )
			max_status_len=$( echo ${array[3]} | bc )
			max_feq_len=$( echo ${array[4]} | bc )
			max_port_len=$(echo "${#DEFAULT_SSH_PORT}")

			if [ "${array[5]}" != "" ]; then
				max_tag_len=$( echo ${array[5]} | bc )
			fi

			read_max=1
		fi
	done < $DATA
}

function export_to_file()
{
	echo "$max_num_len"_"$max_userip_len"_"$max_port_len"_"$max_desc_len"_"$max_status_len"_"$max_feq_len"_"$max_tag_len" > $DATA

	for i in ${!site_num[*]}; do
		echo "${site_num[$i]}"_"${site_userip[$i]}"_"${site_port[$i]}"_"${site_desc[$i]}"_"${site_status[$i]}"_"${site_feq[$i]}"_"${site_tag[$i]}"
	done >> $DATA
}

# Check site data format
function check_sitedata_fmt()
{
	local check7=$(cat ~/conn.data | awk -F "_" {'print $7'})
	local check6=$(cat ~/conn.data | awk -F "_" {'print $6'})

	if [ "$check7" == "" ] && [ "$check6" != "" ]; then
		return 1
	fi

	return 0
}

# Main 
## Deploy 'cn' script
DEPLOY_FOLDER=$(find_deploy_folder)
SITEDATA_PATH="$HOME/conn.data"
mkdir -p $DEPLOY_FOLDER
sudo cp cn.sh $DEPLOY_FOLDER/cn
sudo chmod 755 $DEPLOY_FOLDER/cn
check_n_exit $? "Deploy binary failed"
color_msg 32 "Deploy binary successfully"

## Deploy site data
if [ -f $SITEDATA_PATH ]; then
	# Check site data format. If the format is in old version, convert it to
	# the new site data format.
	check_sitedata_fmt

	if [ $? -eq 1 ]; then
		color_msg 32 "Start site data convertion..." -n
		read_sites
		export_to_file
		color_msg 32 "successfully"
	fi
else
	touch $SITEDATA_PATH
	check_n_exit $? "Fail to deploy user data"
	color_msg 32 "Deploy user data successfully"
fi
