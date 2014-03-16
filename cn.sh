#/bin/bash

DATA="$HOME/conn.data"
VERSION="1.3.7" #Current version
LAST_UPDATE="201400316_1655"
DEFAULT_SSH_PORT=22
DEFAULT_MAX_NUM_LEN=2
DEFAULT_MAX_USERIP_LEN=7
DEFAULT_MAX_PORT_LEN=2
DEFAULT_MAX_DESC_LEN=11
DEFAULT_MAX_STATUS_LEN=6
DEFAULT_MAX_FEQ_LEN=9
DEFAULT_MAX_TAG_LEN=3
CHECKOUT_FOLDER=".cn_upgrade"
ENABLE_AUTO_CHECK_UPDATE=1

# Color function
# Input: $1->color, $2->message, $3->newline or not
function color_msg
{
	echo -e $3 "\033[$1m$2\033[0m"
}

function color_msg_len()
{
	echo -ne "\033[$1m"
	printf %-$3s "$2"
	echo -e $4 "\033[0m"
}

function log()
{
	echo "$1" >> $HOME/conn.log
}

function check_n_exit()
{
	if [ $1 -ne 0 ]; then
		color_msg 31 "$2"

		exit $1
	fi
}

function strlen()
{
	if [ -z $2 ]; then
		local len=$(($(echo "$1" | wc -c | bc) - 1 ))
	else
		local len=$(($(echo $1 | wc -c | bc) - 1 ))
	fi

	echo $len
}

function unset_site()
{
	unset site_num
	unset site_userip
	unset site_port
	unset site_desc
	unset site_status
	unset site_feq
	unset site_tag
}

function check_max_len()
{
	if [ $max_num_len -lt $DEFAULT_MAX_NUM_LEN ]; then
		max_num_len=$DEFAULT_MAX_NUM_LEN
	fi

	if [ $max_userip_len -lt $DEFAULT_MAX_USERIP_LEN ]; then
		max_userip_len=$DEFAULT_MAX_USERIP_LEN
	fi

	if [ $max_port_len -lt $DEFAULT_MAX_PORT_LEN ]; then
		max_port_len=$DEFAULT_MAX_PORT_LEN
	fi

	if [ $max_desc_len -lt $DEFAULT_MAX_DESC_LEN ]; then
		max_desc_len=$DEFAULT_MAX_DESC_LEN
	fi

	if [ $max_status_len -lt $DEFAULT_MAX_STATUS_LEN ]; then
		max_status_len=$DEFAULT_MAX_STATUS_LEN
	fi

	if [ $max_feq_len -lt $DEFAULT_MAX_FEQ_LEN ]; then
		max_feq_len=$DEFAULT_MAX_FEQ_LEN
	fi

	if [ $max_tag_len -lt $DEFAULT_MAX_TAG_LEN ]; then
		max_tag_len=$DEFAULT_MAX_TAG_LEN
	fi
}

# $1 -> string to be converted
# $2:
#   0: replace _ by \=\=
#   1: replace \=\= by _
function convert_symbol()
{
	if [ $2 -eq 0 ]; then
		echo "$1" | sed "s/_/\\\=\\\=/g"
	elif [ $2 -eq 1 ]; then
		echo "$1" | sed "s/\=\=/_/g"
	else
		color_msg 31 "Error in convert_symbol(). Please check $HOME/conn.log"
		log "Fail in convert_symbol(). Wrong second argument [$2]"
	fi
}

# Read all sites data into 'sites'
function read_sites()
{
	local len=0
	local read_max=0
	num_of_sites=0
	max_num_len=$DEFAULT_MAX_NUM_LEN
	max_userip_len=$DEFAULT_MAX_USERIP_LEN
	max_port_len=$DEFAULT_MAX_PORT_LEN
	max_desc_len=$DEFAULT_MAX_DESC_LEN
	max_status_len=$DEFAULT_MAX_STATUS_LEN
	max_feq_len=$DEFAULT_MAX_FEQ_LEN
	max_tag_len=$DEFAULT_MAX_TAG_LEN
	total_len=0
	unset_site

	while read site
	do
		unset array
		IFS='_' read -a array <<< "$site"

		if [ $read_max -ne 0 ]; then
			local th=$(echo ${array[0]} | bc)
			site_num[$th]=$th
			site_userip[$th]=$( convert_symbol "${array[1]}" 1 )
			site_port[$th]=${array[2]}
			site_desc[$th]=$( convert_symbol "${array[3]}" 1 )
			site_status[$th]=${array[4]}
			site_feq[$th]=${array[5]}
			site_tag[$th]=$( convert_symbol "${array[6]}" 1 )

			if [ "${site_num[$th]}" != "" ]; then
				num_of_sites=$(($num_of_sites+1))
			fi
		else
			# Read max length for each column at the first loop
			max_num_len=$( echo ${array[0]} | bc )
			max_userip_len=$( echo ${array[1]} | bc )
			max_port_len=$( echo ${array[2]} | bc )
			max_desc_len=$( echo ${array[3]} | bc )
			max_status_len=$( echo ${array[4]} | bc )
			max_feq_len=$( echo ${array[5]} | bc )
			max_tag_len=$( echo ${array[6]} | bc )
			lst_ckday=$( echo ${array[7]} | bc )

			if [ "$lst_ckday" == "" ]; then
				lst_ckday=$(date +"%d")
			fi

			check_max_len
			read_max=1
			total_len=$(( $max_num_len + $max_userip_len + $max_port_len + $max_desc_len + $max_status_len + $max_feq_len + $max_tag_len + 10 ))
		fi
	done < $DATA
}

function export_to_file()
{
	echo "$max_num_len"_"$max_userip_len"_"$max_port_len"_"$max_desc_len"_"$max_status_len"_"$max_feq_len"_"$max_tag_len"_"$lst_ckday" > $DATA

	for i in ${!site_num[*]}; do
		local userip=$(convert_symbol "${site_userip[$i]}" 0)
		local desc=$(convert_symbol "${site_desc[$i]}" 0)
		local tag=$(convert_symbol "${site_tag[$i]}" 0)

		echo "${site_num[$i]}"_"$userip"_"${site_port[$i]}"_"$desc"_"${site_status[$i]}"_"${site_feq[$i]}"_"$tag"
	done >> $DATA
}

# Check if the given node exists in conn.data.
# 0: does not exist, 1: exist
function is_site_exist()
{
	# Check if the node is existed.
	if [ "${site_num[$1]}" == "" ]; then
		return 0
	else
		return 1
	fi
}

# Parse conn.data to retrieve node's IP according to the given node number
# Input: $1->site number
function find_ip()
{
	if [ "${site_num[$1]}" == "" ]; then
		return 1
	fi

	local cmd="echo ${site_userip[$1]} | awk -F \"@\" {'print \$2'}"
	local ip=$(eval $cmd)
	echo $ip
}

# Parse conn.data to retrieve user according to the given node number
function find_user()
{
	if [ "${site_num[$1]}" == "" ]; then
		return 1
	fi

	local cmd="echo ${site_userip[$1]} | awk -F \"@\" {'print \$1'}"
	local user=$(eval $cmd)
	echo $user
}

# Input: $1->brief mode
function print_dash()
{
	echo -n "+"
	for ((i=0;i<=$(($max_num_len+1));i++))
	do
		echo -n "-"
	done
	echo -n "+"

	for ((i=0;i<=$(($max_userip_len+1));i++))
	do
		echo -n "-"
	done

	if [ -z $1 ]; then
		echo -n "+"

		for ((i=0;i<=$(($max_port_len+1));i++))
		do
			echo -n "-"
		done

		echo -n "+"

		for ((i=0;i<=$(($max_desc_len+1));i++))
		do
			echo -n "-"
		done
		echo -n "+"

		for ((i=0;i<=$(($max_status_len+1));i++))
		do
			echo -n "-"
		done

		echo -n "+"

		for ((i=0;i<=$(($max_feq_len+1));i++))
		do
			echo -n "-"
		done

		echo -n "+"

		for ((i=0;i<=$(($max_tag_len+1));i++))
		do
			echo -n "-"
		done
	fi

	echo "+"
}

function print_tag_dash()
{
	echo -n "+"

	for ((i=0;i<=$(($total_len+9));i++))
	do
		echo -n "-"
	done

	echo "+"
}

# Print tagle's head when listing by Tag
# Input: $1->Tag name
function print_tag_head()
{
	if [ "$1" == "" ]; then
		local tag="no_tag"
	else
		local tag="$1"
	fi

	print_tag_dash

	color_msg 37 "| Tag: " -n
	color_msg_len "1;32" "$tag" $(($total_len+3)) -n
	color_msg 37 " |"

	print_dash
}

# Print table's head and tail
# Input:
#   $1->option: head/tail
#   $2->brief
function print_head_tail()
{
	print_dash "$2"

	if [ "$1" == "head" ];then
		color_msg 37 "| " -n
		color_msg_len 37 "NO" $max_num_len -n
		color_msg 37 " | " -n
		color_msg_len 37 "user@IP" $max_userip_len -n

		if [ -z $2 ]; then
			color_msg 37 " | " -n
			color_msg_len 37 "Port" $max_port_len -n
			color_msg 37 " | " -n
			color_msg_len 37 "Description" $max_desc_len -n
			color_msg 37 " | " -n
			color_msg_len 37 "Status" $max_status_len -n
			color_msg 37 " | " -n
			color_msg_len 37 "Frequency" $max_feq_len -n
			color_msg 37 " | " -n
			color_msg_len 37 "Tag" $max_tag_len -n
		fi
		
		color_msg 37 " |"
		print_dash "$2"
	fi
}

function empty_check()
{
	if [ "$1" == "NA" ]; then
		echo " "
	else
		echo "$1"
	fi
}

# Display the given site
# Input: $1-> color, $2->site number, $3->brief mode
function display_entry()
{
		color_msg 37 "| " -n
		color_msg_len $1 "$2" $max_num_len -n
		color_msg 37 " | " -n
		color_msg_len $1 "${site_userip[$2]}" $max_userip_len -n

		if [ -z $3 ]; then
			color_msg 37 " | " -n
			color_msg_len $1 "${site_port[$2]}" $max_port_len -n
			color_msg 37 " | " -n
			color_msg_len $1 "$(empty_check "${site_desc[$2]}")" $max_desc_len -n
			color_msg 37 " | " -n
			color_msg_len $1 "$(empty_check "${site_status[$2]}")" $max_status_len -n
			color_msg 37 " | " -n
			color_msg_len $1 "${site_feq[$2]}" $max_feq_len -n
			color_msg 37 " | " -n
			color_msg_len $1 "$(empty_check "${site_tag[$2]}")" $max_tag_len -n
		fi

		color_msg 37 " |"
}

# Display all of the remote sites briefly.
# Input $1,$2,...->keywords
function display_sites_brief()
{
	color=32

	print_head_tail "head" "b"

	for i in ${!site_num[*]}; do
		display_entry $color $i "b"
		color=$((color+1))

		if [ $color -eq 38 ]; then
			color=32
		fi
	done

	print_head_tail "tail" "b"
	echo -e
}
# Display all of the remote sites defined in conn.data
# Input $1,$2,...->keywords
function display_sites()
{
	color=32

	# Print table head
	print_head_tail "head"

	if [ -z $1 ]; then
		# Display all site entries
		for i in ${!site_num[*]}; do
			display_entry $color $i
			color=$((color+1))

			if [ $color -eq 38 ]; then
				color=32
			fi
		done
	else
		# Display only the sites which contain the given keyword.
		local kw_exist_userip=0
		local kw_exist_desc=0

		for i in ${!site_num[*]}; do
			for kw in $@; do
				kw_exist_userip=$(echo "${site_userip[$i]}" | grep -c "$kw")
				kw_exist_desc=$(echo "${site_desc[$i]}" | grep -c "$kw")

				if [ "$kw_exist_userip" != "0" ] || [ "$kw_exist_desc" != 0 ]; then
					display_entry $color $i
					color=$((color+1))

					if [ $color -eq 38 ]; then
						color=32
					fi

					break
				fi
			done # for kw
		done # for i
	fi

	print_head_tail "tail"
	echo -e
}

function display_ac_usg()
{
	color_msg 38 "   - " -n
	color_msg 32 "ac" -n
	color_msg 38 ": cn ac " -n
	color_msg 33 "\"user@ip\" [\"desc\"]"
	color_msg 38 "         Add a new site and connect to it."
}

function display_scp_to()
{
	color_msg 38 "   - " -n
	color_msg 32 "ct" -n
	color_msg 38 ": cn ct " -n
	color_msg 33 "\"file\" #num1 [#num2] [#num3] [...]"
	color_msg 38 "         scp a file/directory to the given site. "
	color_msg 38 "         ex: cn ct file 3"
}

function display_scp_from()
{
	color_msg 38 "   - " -n
	color_msg 32 "cf" -n
	color_msg 38 ": cn cf " -n
	color_msg 33 "\"file\" #num1 [#num2] [#num3] [...]"
	color_msg 38 "         scp a remote file/directory of the given sites to local"
	color_msg 38 "         ex: cn cf file 3 (=> scp user@site3_ip:file .)"
}

# Secure copy file from the remote site.
# Input: $1->the file which will be copied, $2,3,...->site number
function scp_from()
{
	if [ -z $1 ] || [ -z $2 ]; then
		display_scp_from
		exit 0
	fi

	file="$1"
	shift 1

	for i in $@; do
		if [ "${site_num[$i]}" != "" ]; then
			scp -r -P "${site_port[$i]}" "${site_userip[$i]}:$file" .
		fi
	done

	if [ $? -eq 0 ]; then
		color_msg 32 "Copy file successfull."
		return 0
	else
		color_msg 31 "Copy file failed."
		return 1
	fi
}

# Secure copy file to the remote site.
# Input: $1->the file which will be copied, $2,3,...->site number
function scp_to()
{
	if [ -z "$1" ] || [ -z "$2" ]; then
		display_scp_to
		exit 0
	fi

	file="$1"
	shift 1

	for i in $@; do
		if [ "${site_num[$i]}" != "" ]; then
			scp -r -P ${site_port[$i]} "$file" "${site_userip[$i]}:"
		fi
	done

	if [ $? -eq 0 ]; then
		color_msg 32 "Copy file successfull."
		return 0
	else
		color_msg 31 "Copy file failed."
		return 1
	fi
}

function find_pk()
{
	# Check if have id_rsa.pub
	local pk="$HOME/.ssh/id_rsa.pub"

	if [ -f $pk ]; then
		echo $pk
	fi
}

# This function will regiester local's public key (id_rsa.pub) to the remote
# site.
# Input: $1->site number
function reg_key()
{
	if [ -z $1 ]; then
		display_reg_usage
		exit 0
	fi

	local pk=$(find_pk)
	if [ "$pk" == "" ]; then
		color_msg 31 "No public key found. Please generate your key-pair first."
		return 1
	fi

	local ip=$(find_ip $1)
	check_n_exit $? "[$1] does not exist."

	# Copy local public key to the remote site.
	echo -e
	color_msg 32 "Copying local public key to [" -n
	color_msg 33 "$ip" -n
	color_msg 32 "] ..."
	scp_to "$pk" "$1"
	check_n_exit $? "Copy file to site [$1] failed."

	# Cat public key to remote site's authorized_key
	echo -e
	color_msg 32 "Registering public key to [" -n
	color_msg 33 "$ip" -n
	color_msg 32 "] ..."

	local cmd="mkdir -p ~/.ssh; cat id_rsa.pub >> ~/.ssh/authorized_keys; rm -rf id_rsa.pub"
	ssh -p ${site_port[$1]} ${site_userip[$1]} "$cmd"
	check_n_exit $? "Register public key failed"

	echo -e
	color_msg 32 "Register public key to $ip successfully."
}

# Check if the give site is connectable.
# Input: $1->site number
function is_reachable()
{
	ping_site $1

	if [ "${site_status[$1]}" == "On" ]; then
		return 1
	else
		return 0
	fi
}

function add_node_to_num()
{
	local field1_len=$(strlen "$1")
	local field2_len=$(strlen "$2")
	local field3_len=$(strlen "$3")
	local field4_len=$(strlen "$4")

	if [ $field1_len -gt $max_num_len ]; then
		max_num_len=$field1_len
	fi

	if [ $field2_len -gt $max_userip_len ]; then
		max_userip_len=$field2_len
	fi

	if [ $field3_len -gt $max_desc_len ]; then
		max_desc_len=$field3_len
	fi

	if [ $field4_len -gt $max_port_len ]; then
		max_port_len=$field4_len
	fi

	site_num[$1]="$1"
	site_userip[$1]="$2"
	site_desc[$1]="$3"
	site_status[$1]="NA"
	site_feq[$1]=0
	site_tag[$1]=""

	if [ "$4" == "" ]; then
		site_port[$1]="$DEFAULT_SSH_PORT"
	else
		site_port[$1]="$4"
	fi

	export_to_file
}

# Read suitable number for insertion.
function find_insert_num()
{
	for ((i=1;i<=$num_of_sites;i++ )); do
		if [ "${site_num[$i]}" == "" ]; then
			break
		fi
	done

	echo $i
}

function add_node()
{
	if [ -z "$1" ]; then
		display_add_usage
		exit 1
	fi

	num=$(find_insert_num)

	echo -e

	while true; do
		echo -n "Add this node to position "
		color_msg 32 "[$num] " -n
		read -p "(y/n)" yn

		case $yn in
			[Yy]* ) add_node_to_num "$num" "$1" "$2" "$3"
					return $num
					;;
			[Nn]* ) read -p "Input your number:" un
					add_node_to_num $un "$1" "$2" "$3";;
			* ) echo "Please answer y or a number you want to add";;
		esac

		if [ $? -eq 0 ]; then
			break
		fi
	done
}

# Display author information
function display_author()
{
	color_msg 38 "This utility is maintained by " -n
	color_msg 36 "Vincent Shi-Ming Huang."
	color_msg 38 "If you have any problem or you hit some issue/bug, please send your comment to "
	color_msg 36 "Vincent.SM.Huang@gmail.com"
	color_msg 35 "http://vincent-smh.appspot.com"
}

# Display the usage of 'mu' command
function display_mu_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "mu" -n
	color_msg 38 ": cn mu " -n
	color_msg 33 "#num \"user@ip\""
	color_msg 38 "         Modify a site's user@ip"
	color_msg 38 "         ex: cn md 3 \"vincent@127.0.0.1\""

}

# Display the usage of 'md' command
function display_md_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "md" -n
	color_msg 38 ": cn md " -n
	color_msg 33 "#num \"desc\""
	color_msg 38 "         Modify a site's description."
	color_msg 38 "         ex: cn md 3 \"New description to site 3\""

}

# Display the usage of 'mp' command
function display_mp_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "mp" -n
	color_msg 38 ": cn mp " -n
	color_msg 33 "#num port"
	color_msg 38 "         Modify a site's port."
	color_msg 38 "         ex: cn mp 3 2222"

}

function display_reg_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "r" -n
	color_msg 38 ": cn r " -n
	color_msg 33 "#num"
	color_msg 38 "        Register public key to site #num. You would be asked to input password "
	color_msg 38 "        for several times. After the registration, you can connect to that "
	color_msg 38 "        site without type password."
	color_msg 38 "        ex: cn r 3"
}

function display_deploy_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "dp" -n
	color_msg 38 ": cn dp " -n
	color_msg 33 "#num [#num2] [#num3] ..."
	color_msg 38 "         Deploy this utility to site(s) of #num1 (#num2, #num3, ...)."
}

function display_cmd_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "cmd" -n
	color_msg 38 ": cn cmd " -n
	color_msg 33 "\"commands\" #num1 [#num2] [#num3] ..."
	color_msg 38 "          Send commands to site(s) of #num1 (#num2, #num3, ...)."
	color_msg 38 "          ex: cn cmd \"ls\" 2"
	color_msg 38 "          ex: cn cmd \"cn 3\" 2 " -n
	color_msg 34 "(Site 2 also installed this utility. You can "
	color_msg 34 "              connect to site 3 through site 2. This is helpful if site 3 is "
	color_msg 34 "              under firewall that only site 2 can connect to.)"
}

function display_usg_tag()
{
	color_msg 38 "   - " -n
	color_msg 32 "t" -n
	color_msg 38 ": cn t \"TAG_str\" " -n
	color_msg 33 "#num1 [#num2] [#num3] [...]"
	color_msg 38 "        Assign TAG to site(s) #num1, #num2 ... "
	color_msg 38 "        ex: cn t \"TAG\" 3 5 6 8"
}

function display_add_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "a" -n
	color_msg 38 ": cn a " -n
	color_msg 33 "\"user@ip\" [\"desc\"] [port]"
	color_msg 38 "        Add a new site."
	color_msg 38 "        ex: cn a user@127.0.0.1"
	color_msg 38 "        ex: cn a user@127.0.0.1 \"Description of the site.\""
	color_msg 38 "        ex: cn a user@127.0.0.1 \"Description of the site.\" 2222"
}

function display_del_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "d" -n
	color_msg 38 ": cn d " -n
	color_msg 33 "#num1 [#num2] [#num3]"
	color_msg 38 "        Delete a site (num). "
	color_msg 38 "        ex: cn d 3"
	color_msg 38 "        ex: cn d 3 5 7 9"
}

function display_acu_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "acu" -n
	color_msg 38 ": cn acu " -n
	color_msg 33 "0/1"
	color_msg 38 "          Enable/Disalbe auto check update. 1:enable, 0: disable"
}
# Display the usage of 'cn' command
function display_usage()
{
	echo -e
	color_msg 38 "Usage: cn " -n
	color_msg 32 "<commands>" -n
	color_msg 33 " [args]"

	color_msg 32 "<commands> " -n
	color_msg 38 "are listed as follows:"

	color_msg 38 "   - " -n
	color_msg 32 "num" -n
	color_msg 38 ": cn #num " -n
	color_msg 33 "[x|f|v|r] [port]"
	color_msg 38 "          ex. cn 2 (SSH to site 2)"
	color_msg 38 "          ex. cn 2 x (with X-forwarding)"
	color_msg 38 "          ex. cn 2 f (FTP to site 2)"
	color_msg 38 "          ex. cn 2 r (RDP to site 2)"
	color_msg 38 "          ex. cn 2 r 5010 (RDP to site 2 by port number 5010)"
	color_msg 38 "          ex. cn 2 v (VNC to site 2)"
	color_msg 38 "          ex. cn 2 v 5903 (VNC to site 2 by port number 5903)"

	color_msg 38 "   - " -n
	color_msg 32 "l" -n
	color_msg 38 ": cn l " -n
	color_msg 33 "[keyword1] [keyword2] [...]."
	color_msg 38 "        List all sites or list some sites which contain the given keywords."
	color_msg 38 "        ex. cn l (List all sites)"
	color_msg 38 "        ex. cn l \"CCMA\" \"10.209\"" -n
	color_msg 34 "(List the sites contains keywords of CCMA or "
	color_msg 34 "            10.209)"
	
	color_msg 38 "   - " -n
	color_msg 32 "lb" -n
	color_msg 38 ": cn lb"
	color_msg 38 "         List all sites briefly (only site number and user@IP)."

	color_msg 38 "   - " -n
	color_msg 32 "lt" -n
	color_msg 38 ": cn lt " -n
	color_msg 33 "[tag]"
	color_msg 38 "         List all sites and group them by tag."
	color_msg 38 "         ex. cn lt"
	color_msg 38 "         ex. cn lt TAG " -n
	color_msg 34 "(list only sites which are tagged as TAG.)"

	display_reg_usage
	display_add_usage
	display_ac_usg
	display_del_usage
	display_scp_to
	display_scp_from

	color_msg 38 "   - " -n
	color_msg 32 "p" -n
	color_msg 38 ": cn p " -n
	color_msg 33 "#num [#num2] [#num3]"
	color_msg 38 "        Ping site(s) to test their connectivity. "
	color_msg 38 "        ex: cn p 3 4 5"

	display_usg_tag

	color_msg 38 "   - " -n
	color_msg 32 "pa" -n
	color_msg 38 ": cn pa. Ping all sites to test their connectivity."

	display_mu_usage
	display_md_usage
	display_mp_usage

	color_msg 38 "   - " -n
	color_msg 32 "rn" -n
	color_msg 38 ": reorder the number of all sites."

	display_usage_sbf

	color_msg 38 "   - " -n
	color_msg 32 "doff" -n
	color_msg 38 ": Delete all sites whose status are Off"

	color_msg 38 "   - " -n
	color_msg 32 "rst: " -n
	color_msg 38 "cn rst " -n
	color_msg 33 "[#num]"
	color_msg 38 "          Reset sites' frequency to 0."

	display_move_usage
	display_deploy_usage
	display_cmd_usage
	display_acu_usage

	color_msg 38 "   - " -n
	color_msg 32 "upgrade: " -n
	color_msg 38 "Upgrade cn utility to the newest version. This will checkout the "
	color_msg 38 "              newest version from github and install it."

	color_msg 38 "   - " -n
	color_msg 32 "v: " -n
	color_msg 38 "Show version infomation."

	echo -e
	display_author
	echo -e
}

# Find maximum string length.
# Input: $1->1 to find the maximum number string length
#        $2->1 to find the maximum userip string length
#        $3->1 to find the maximum port string length
#        $4->1 to find maximum description string length
#        $5->1 to find maximum tag string length
function find_max_len()
{
	local len=0

	if [ $1 -eq 1 ];then
		max_num_len=0

		for i in ${!site_num[*]}; do
			len=$(strlen "${site_num[$i]}")

			if [ $len -gt $max_num_len ]; then
				max_num_len=$len
			fi
		done
	fi

	if [ $2 -eq 1 ];then
		max_userip_len=0

		for i in ${!site_userip[*]}; do
			len=$(strlen "${site_userip[$i]}")

			if [ $len -gt $max_userip_len ]; then
				max_userip_len=$len
			fi
		done
	fi

	if [ $3 -eq 1 ];then
		max_port_len=0

		for item in ${site_port[*]}; do
			len=$(strlen "$item")

			if [ $len -gt $max_port_len ]; then
				max_port_len=$len
			fi
		done
	fi

	if [ $3 -eq 1 ];then
		max_desc_len=0

		for i in ${!site_desc[*]}; do
			len=$(strlen "${site_desc[$i]}")

			if [ $len -gt $max_desc_len ]; then
				max_desc_len=$len
			fi
		done
	fi

	if [ $4 -eq 1 ]; then
		max_tag_len=0

		for i in ${!site_tag[*]}; do
			len=$(strlen "${site_tag[$i]}")

			if [ $len -gt $max_tag_len ]; then
				max_tag_len=$len
			fi
		done
	fi
}

# Delete the given node
function del_site()
{
	if [ -z "$2" ]; then
		display_del_usage
		exit 0
	fi

	shift 1
	local num_check=0
	local userip_check=0
	local port_check=0
	local desc_check=0
	local tag_check=0

	# Find indexes of the deleting site
	for num in $@; do
		if [ $(strlen "${site_num[$num]}") -eq $max_num_len ]; then
			num_check=1
		fi

		if [ $(strlen "${site_userip[$num]}") -eq $max_userip_len ]; then
			userip_check=1
		fi

		if [ $(strlen "${site_port[$num]}") -eq $max_port_len ]; then
			port_check=1
		fi

		if [ $(strlen "${site_desc[$num]}") -eq $max_desc_len ]; then
			desc_check=1
		fi

		if [ $(strlen "${site_tag[$num]}") -eq $max_tag_len ]; then
			tag_check=1
		fi

		unset_entry $num
	done

	find_max_len $num_check $userip_check $port_check $desc_check $tag_check
	export_to_file
}

function unset_tmp_site()
{
	unset tmp_site_num
	unset tmp_site_userip
	unset tmp_site_port
	unset tmp_site_desc
	unset tmp_site_status
	unset tmp_site_feq
	unset tmp_site_tag
}

function assign_tmp_entry()
{
	tmp_site_num[$1]="$2"
	tmp_site_userip[$1]="$3"
	tmp_site_port[$1]="$4"
	tmp_site_desc[$1]="$5"
	tmp_site_status[$1]="$6"
	tmp_site_feq[$1]="$7"
	tmp_site_tag[$1]="$8"
}

function renumber_sites()
{
	local j=1

	# Save reordered site to tmp_site
	for i in ${!site_num[*]}; do
		assign_tmp_entry $j "$j" "${site_userip[$i]}" "${site_port[$i]}" "${site_desc[$i]}" "${site_status[$i]}" "${site_feq[$i]}" "${site_tag[$i]}"
		j=$(($j+1))
	done

	unset_site

	j=1
	for i in ${!tmp_site_num[*]}; do
		site_num[$j]="${tmp_site_num[$i]}"
		site_userip[$j]="${tmp_site_userip[$i]}"
		site_port[$j]="${tmp_site_port[$i]}"
		site_desc[$j]="${tmp_site_desc[$i]}"
		site_status[$j]="${tmp_site_status[$i]}"
		site_feq[$j]="${tmp_site_feq[$i]}"
		site_tag[$j]="${tmp_site_tag[$i]}"
		j=$(($j+1))
	done

	unset_tmp_site
	export_to_file
}

function display_move_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "m" -n
	color_msg 38 ": cn m " -n
	color_msg 33 "#num1 #num2"
	color_msg 38 "        Move site #num1 to #num2"
	color_msg 38 "        ex: cn m 10 3"
}

function assign_entry_data()
{
	site_num[$1]="$2"
	site_userip[$1]="$3"
	site_port[$1]="$4"
	site_desc[$1]="$5"
	site_status[$1]="$6"
	site_feq[$1]="$7"
	site_tag[$1]="$8"
}

function unset_entry()
{
	unset site_num[$1]
	unset site_userip[$1]
	unset site_port[$1]
	unset site_desc[$1]
	unset site_status[$1]
	unset site_feq[$1]
	unset site_tag[$1]
}

# Recursively move $1 to $2
# Input:
#   $1->original site number
#   $2->site number that will move to
#   $3->the site number which indicates the end of recursive moving
function move_function()
{
	if [ -z $3 ]; then
		display_move_usage
		exit 0
	fi

	# This will occurs when $1 > $2, we let $3 = $1 and this check is to limit
	# the recursive routine stops at most on the position of $1.
	if [ $2 -eq $3 ]; then
		assign_entry_data $2 "$2" "${site_userip[$1]}" "${site_port[$1]}" "${site_desc[$1]}" "${site_status[$1]}" "${site_feq[$1]}" "${site_tag[$1]}"
		return 0
	fi

	# local variable for recursive call
	#local num="${site_num[$2]}"
	local num="$2"
	local userip="${site_userip[$1]}"
	local port="${site_port[$1]}"
	local desc="${site_desc[$1]}"
	local status="${site_status[$1]}"
	local feq="${site_feq[$1]}"
	local tag="${site_tag[$1]}"

	# Check if the dest site number is existed.
	if [ "${site_num[$2]}" != "" ]; then
		move_function $2 $(($2+1)) $3
	else
		# Delete the original entry
		unset_entry $1
	fi

	# We have make sure the dest is empty or is moved to its next. So, we can
	# assign value to it (move over).
	assign_entry_data $2 "$num" "$userip" "$port" "$desc" "$status" "$feq" "$tag"

	# When $2 > $1, after we move $1 to its next, we have to unset its original
	# position
	if [ $2 -gt $1 ]; then
		unset_entry $1
	fi
}

function uninstall()
{
	local os=`uname`

	if [ "$os" == "Linux" ]; then
		local DEPLOY_FOLDER="/usr/local/bin"
	else
		local DEPLOY_FOLDER="/usr/bin"
	fi

	sudo rm -rf $DEPLOY_FOLDER/cn
	sudo rm -rf $DATA
}

# Find the wait time for ping
# In OS X, waiting time is in millisecond, but in Linux it is second.
function find_ping_wait_time()
{
	if [ "$(is_osx)" == "1" ]; then
		echo "1500"
	else
		echo "1"
	fi
}

# Ping the given sites to test if the it is reachable.
function ping_site()
{
	for i in $@; do
		local ip=$(find_ip $i)
		local wt=$(find_ping_wait_time)

		ping -c 1 -W $wt $ip >> /dev/null

		if [ $? -eq 0 ]; then
			site_status[$i]="On"
		else
			site_status[$i]="Off"
		fi
	done

	export_to_file
	return 0
}

# Ping all site to check their connectivity
function ping_all_sites()
{
	local ip=""
	local wt=$(find_ping_wait_time)

	color_msg 32 "Ping all sites ..."
	echo -e

	for i in ${!site_num[*]}; do
		ip=$(find_ip $i)
		ping -c 1 -W $wt $ip >> /dev/null

		if [ $? -eq 0 ]; then
			site_status[$i]="On"
		else
			site_status[$i]="Off"
		fi
	done

	export_to_file
}

# Increase one to the frequency of the given site
# Input: $1-> the number of a site
function increase_feq()
{
	if [ "${site_num[$1]}" != "" ]; then
		site_feq[$1]=$((${site_feq[$1]}+1))
		export_to_file
	fi
}

# Modify the site description of the given site
# Input: $1-> site number, $2->description
function modify_desc()
{
	if [ "${site_num[$1]}" != "" ] && [ "$2" != "" ]; then
		site_desc[$1]="$2"
		find_max_len 0 0 0 1 0
		export_to_file
	else
		display_md_usage
		exit 0
	fi
}

# Input: $1-> type of filed , $2->site number, $3->new value
# Parameter $1: 0->userip, 1->description, 2->port
function modify_field()
{
	if [ "${site_num[$2]}" != "" ] && [ "$3" != "" ]; then
		case "$1" in
		[0] )
			site_userip[$2]="$3"
			find_max_len 0 1 0 0 0;;
		[1] ) 
			site_desc[$2]="$3"
			find_max_len 0 0 0 1 0;;
		[2] )
			site_port[$2]="$3"
			find_max_len 0 0 1 0 0;;
		esac

		export_to_file
	else
		case "$1" in
			[0] ) display_mu_usage;;
			[1] ) display_md_usage;;
			[2] ) display_mp_usage;;
		esac

		exit 0
	fi
}

# Find the max site.
# Output: index
function find_max_feq()
{
	local max=0
	local i=0

	for j in ${!site_num[*]}; do
		if [ ${site_feq[$j]} -gt $max ]; then
			max=${site_feq[$j]}
			i=$j
		fi
	done

	echo $i
}

# Find the max site.
# Output: index
function find_mim_feq()
{
	local mim=0
	local i=0
	local first_loop=0

	for j in ${!site_num[*]}; do
		if [ $first_loop -eq 0 ]; then
			mim=${site_feq[$j]}
			i=$j
			first_loop=1
		elif [ $mim -gt ${site_feq[$j]} ]; then
			mim=${site_feq[$j]}
			i=$j
		fi
	done

	echo $i
}

function display_usage_sbf()
{
	color_msg 38 "   - " -n
	color_msg 32 "sf: cn sf [D|I]"
	color_msg 38 "         Sort sites by the frequency. D: decreasing, I: increasing"
}

# Sort by frequency
# Input: $1-> "I" means increasing and "D" means decreasing
function sort_by_feq()
{
	if [ "$1" == "I" ]; then
		local max=0
	elif [ "$1" == "D" ]; then
		local mim=0
	else
		display_usage_sbf
		exit 0
	fi

	local found_i=0

	for ((i=1;i<=$num_of_sites;i++)); do
		if [ "$1" == "D" ]; then
			found_i=$(find_max_feq)
		elif [ "$1" == "I" ];then
			found_i=$(find_mim_feq)
		fi

		assign_tmp_entry $i "$i" "${site_userip[$found_i]}" "${site_port[$found_i]}" "${site_desc[$found_i]}" "${site_status[$found_i]}" "${site_feq[$found_i]}" "${site_tag[$found_i]}"
		unset_entry $found_i
	done

	for i in ${!tmp_site_num[*]}; do
		assign_entry_data $i "${tmp_site_num[$i]}" "${tmp_site_userip[$i]}" "${tmp_site_port[$i]}" "${tmp_site_desc[$i]}" "${tmp_site_status[$i]}" "${tmp_site_feq[$i]}" "${tmp_site_tag[$i]}"
	done

	unset_tmp_site
	export_to_file
}

function del_off_site()
{
	local color=32
	local yn=""
	local del=""

	color_msg 38 "You are going to remove the following sites:"
	print_head_tail "head"

	for i in ${!site_num[*]}; do
		if [ "${site_status[$i]}" == "Off" ]; then
			display_entry $color $i
			color=$((color+1))
			del="$(echo $del) $(echo $i)"

			if [ $color -eq 38 ]; then
				color=32
			fi
		fi
	done

	if [ "$del" == "" ]; then
		echo -e
		color_msg 38 "No offline sites."
		exit 0
	fi

	print_head_tail "tail"
	color_msg 38 "Are you sure " -n
	read -p "(y/n)" yn

	case $yn in
		[Yy]* )
			for i in ${!del[*]}; do
				del_site d $del
			done
			;;
		[Nn]* ) exit 0 ;;
		* ) echo "Please answer y or n";;
	esac
}

# Reset site's frequency
# Input: none or site numbers
function reset_feq()
{
	if [ -z $2 ]; then
		for i in ${!site_num[*]}; do
			site_feq[$i]=0
		done
	else
		shift 1

		for i in $@; do
			site_feq[$i]=0
		done
	fi

	export_to_file
}

# Check if the system is OS X
function is_osx()
{
	check=$(uname -a | grep -c Mac)
	echo "$check"
}

# Find the default port of a protocol
# If there is a port number given, just return it. Otherwise, return a default
# port number according to the given protocol.
# Input:
#   - $1: protocol
#   - $2: port
function df_port()
{
	if [ -z "$2" ]; then
		case "$1" in
			ftp ) echo 21 ;;
			vncviewer ) echo 5900 ;;
			rdesktop ) echo 3389 ;;
		esac
	else
		echo $2
	fi
}

# Connect to the given site by the given protocol(command)
# Input: $1->utility name, $2->site number, $3->Port|x, $4->options
function connect_by()
{
	is_reachable $2

	if [ $? == 0 ]; then
		color_msg 31 "Site [$2] is not reachable."
		return 1
	fi

	# SSH
	if [ "$1" == "ssh" ]; then
		# With X-Forwarding
		if [ "$3" == "x" ]; then
			color_msg 32 "SSH to ${site_userip[$2]}:${site_port[$2]} with X-Forwarding"
			ssh -p ${site_port[$2]} -X ${site_userip[$2]}
		else
			color_msg 32 "SSH to ${site_userip[$2]}:${site_port[$2]}"
			ssh -p ${site_port[$2]} ${site_userip[$2]}
		fi

		return 0
	fi

	# Other connection protocol
	local ip=$(find_ip $2)
	local port=$(df_port "$1" "$3")

	color_msg 32 "Connecting ($1) to $ip [$port]..."

	if [ "$(is_osx)" == "1" ]; then
		case "$1" in
			ftp ) open ftp://$ip:$port ;;
			vncviewer ) open vnc://$ip:$port ;;
			rdesktop ) open rdp://$ip:$port ;;
		esac
	else
		has_binary "$1"

		if [ ?$ -eq 1 ]; then
			case "$1" in
				ftp )       $1 $ip $port $4 ;;
				vncviewer ) $1 $ip:$port $4 ;;
				rdesktop )  $1 $ip:$port $4 ;;
			esac
		else
			color_msg 31 "Require utility: " -n
			color_msg 32 "$1"
		fi
	fi
}

# Find utility 'cn' path
function find_this_utility()
{
	if [ -f "/usr/bin/cn" ]; then
		echo "/usr/bin/cn"
	elif [ -f "/usr/local/bin/cn" ]; then
		echo "/usr/local/bin/cn"
	fi
}

# Deploy this utility to the given site(s)
# Input: $1,2,...->site number
function deploy_to()
{
	if [ -z $1 ]; then
		display_deploy_usage
		exit 0
	fi

	local utility_path=$(find_this_utility)

	if [ "utility_path" == "" ]; then
		color_msg 31 "Cannot find 'cn' utility in your system!"
		exit 1
	fi

	scp_to $utility_path "$@"
	scp_to $DATA "$@"

	for i in $@; do
		color_msg 38 "Deploying ${site_userip[$i]}..."
		ssh -p ${site_port[$i]} -t ${site_userip[$i]} "sudo mv ~/cn /usr/local/bin/cn"
		color_msg 32 "Deploy ${site_userip[$i]} successfully."
	done
}

# Send command to some sites
# Input: $1->command, $2,3...->site number
function cmd_to()
{
	if [ -z "$1" ] || [ -z "$2" ]; then
		display_cmd_usage
		exit 0
	fi

	local cmd="$1"
	local ip=""
	shift 1

	for i in $@; do
		ip=$(find_ip $i)
		color_msg 32 "Send command to " -n
		color_msg 33 "$ip"
		ssh -p ${site_port[$i]} -t ${site_userip[$i]} "$cmd"
	done
}

function has_binary()
{
	local bin_cmd=$(command -v "$1")

	if [ "$bin_cmd" == "" ]; then
		return 0
	else
		return 1
	fi
}

function checkout_cn()
{
	mkdir -p $CHECKOUT_FOLDER &> /dev/null
	cd $CHECKOUT_FOLDER
	git clone https://github.com/vincentsmh/ssh_script &> /dev/null

	local context=$( head -5 ssh_script/cn.sh )
	new_ver=$( echo "$context" | grep "VERSION=" | awk -F "\"" {'print $2'})
	new_lst_upd=$( echo "$context" | grep "LAST_UPDATE=" | awk -F "\"" {'print $2'})
}

# Upgrade this utility to the newest version
function do_upgrade()
{
	show_version

	# Check git client tool
	has_binary "git"

	if [ $? -eq 0 ]; then
		color_msg 31 "Please make sure you have git client tool."
		return 0
	fi

	# Checkout and get version
	color_msg 38 "Checking new version and doing upgrade ... " -n
	checkout_cn

	if [ "$new_ver" != "" ] && [ "$new_ver" != "$VERSION" ]; then
		color_msg 32 "Updating ... "
		# Upgrade
		cd ssh_script
		sudo bash setup.sh
		cd ..
		show_version "$new_ver" "$new_lst_upd"
	else
		color_msg 32 "Up to date"
	fi

	# Clean up
	cd ..
	rm -rf $CHECKOUT_FOLDER
	echo -e
}

# Show current version
function show_version()
{
	echo -e
	color_msg 38 "Current version: " -n

	if [ "$1" == "" ]; then
		color_msg 33 "$VERSION" -n
	else
		color_msg 33 "$1" -n
	fi

	if [ "$2" == "" ]; then
		color_msg 32 " ($LAST_UPDATE)"
	else
		color_msg 32 " ($2)"
	fi

	echo -e
}

# Tag sites
# Input: $1->tag $2,$3,$4,...->Sites
function tag_site()
{
	if [ -z $1 ]; then
		display_usg_tag
	fi

	local tag="$1"
	local tag_len=$(strlen "$1")

	shift 1

	for i in $@; do
		site_tag[$i]="$tag"
	done

	find_max_len 0 0 0 1

	if [ $max_tag_len -lt 3 ]; then
		max_tag_len=3
	fi

	export_to_file
}

# Find all tags from all sites
# Ouput a global array: tags
function find_tags()
{
	local tag_i=0
	local j=0

	for i in ${!site_tag[*]}; do
		# Check if the tag is existed
		local tag_exit=0

		for (( j=0; j<$tag_i; j++ )); do
			if [ "${site_tag[$i]}" == "${tags[$j]}" ]; then
				tag_exit=1
				break
			fi
		done

		# Find new tag
		if [ $tag_exit -eq 0 ]; then
			tags[$tag_i]="${site_tag[$i]}"
			tag_i=$(($tag_i + 1))
		fi
	done

	return 0
}

function list_sites_of_tag()
{
	local color=32
	local tag="$1"
	print_tag_head "$tag"

	for i in ${!site_num[*]}; do
		if [ "${site_tag[$i]}" == "$tag" ]; then
			display_entry $color $i
			color=$((color+1))

			if [ $color -eq 38 ]; then
				color=32
			fi
		fi
	done

	print_head_tail "tail"
	echo -e
}

# List all sites and group them by Tag.
# Input: $1->[Tag]
function list_by_tag()
{
	# List all sites from all tags
	if [ -z $1 ]; then
		unset tags
		find_tags

		for tag_i in ${!tags[*]}; do
			list_sites_of_tag "${tags[$tag_i]}"
		done

		unset tags
	else
		list_sites_of_tag "$1"
	fi
}

# Check if it is necessary to check new update
# 0: unnecessary, 1: necessary
function is_update_necessary()
{
	if [ $ENABLE_AUTO_CHECK_UPDATE -eq 0 ]; then
		return 0
	fi

	local UPDATE_CHECK_INTERVAL=3 # Default days for checking new version
	local cur_day=$(date +"%d")
	local utility_path=$(find_this_utility)

	if [ $cur_day -gt $lst_ckday ]; then
		diff=$(( $cur_day - $lst_ckday ))
	else
		diff=$(( $lst_ckday - $cur_day ))
	fi

	if [ $diff -ge $UPDATE_CHECK_INTERVAL ]; then
		lst_ckday=$cur_day
		export_to_file
		return 1
	else
		return 0
	fi
}

# Check if there is available update. This function will be executed in
# background.
function check_update()
{
	is_update_necessary

	if [ $? -eq 0 ]; then
		return 0
	fi

	has_binary "git"

	if [ $? -eq 0 ]; then
		return 1
	fi

	# Checkout and get version
	checkout_cn

	if [ "$new_ver" != "" ] && [ "$new_ver" != "$VERSION" ]; then
		echo -e
		color_msg "1;5;33" "[New update available]"
		echo -e
		read -p "Would you want to upgrade now? (y/n)" yn

		case $yn in
			[Yy]* )
				cd ssh_script
				sudo bash setup.sh
				cd ..
				show_version "$new_ver" "$new_lst_upd"
				;;
			[Nn]* )
				color_msg 38 "You can do 'cn upgrade' to update later"
				;;
		esac
	fi

	# Clean up
	cd ..
	rm -rf $CHECKOUT_FOLDER &> /dev/null
	return 0
}

# Enable/Disable auto check update
# $1=0 -> disalbe
# $1=1 -> enable
function switch_atckupd()
{
	if [ ! -z "$1" ]; then
		local cn_path=$(find_this_utility)

		if [ "$1" == "0" ]; then
			local org=1
			local new=0
		elif [ "$1" == "1" ]; then
			local org=0
			local new=1
		fi

		ENABLE_AUTO_CHECK_UPDATE=$new
		sed s/ENABLE_AUTO_CHECK_UPDATE=$org/ENABLE_AUTO_CHECK_UPDATE=$new/g $cn_path > tmp_cn
		sudo mv tmp_cn $cn_path
		sudo chmod +x $cn_path
	fi

	echo -e
	color_msg 38 "Auto check update is " -n

	if [ $ENABLE_AUTO_CHECK_UPDATE -eq 1 ]; then
		color_msg 32 "Enabled"
	else
		color_msg 32 "Disabled"
	fi

	echo -e
}

# main()
if [ -z "$1" ]; then
	display_usage
else
	read_sites

	case "$1" in
		[l] )
			echo -e
			shift 1
			display_sites $@
			check_update
			exit 0;;
		[a] )
			add_node "$2" "$3" "$4"
			display_sites
			exit 0;;
		[d] )
			del_site $@
			display_sites
			exit 0;;
		[r] )
			reg_key $2
			exit 0;;
		[m] )
			move_function $2 $3 $2
			export_to_file
			display_sites
			exit 0;;
		[p] )
			shift 1
			ping_site $@
			display_sites
			exit 0;;
		[v] )
			show_version
			exit 0;;
		[t] )
			shift 1
			tag_site "$@"
			exit 0;;
		lb )
			shift 1
			display_sites_brief
			exit 0;;
		lt )
			shift 1
			list_by_tag "$@"
			exit 0;;
		ct )
			shift 1
			scp_to "$@"
			exit 0;;
		cf )
			shift 1
			scp_from "$@"
			exit 0;;
		pa )
			ping_all_sites
			display_sites
			exit 0;;
		mu )
			modify_field 0 $2 "$3"
			display_sites
			exit 0;;
		md )
			modify_field 1 $2 "$3"
			display_sites
			exit 0;;
		mp )
			modify_field 2 $2 "$3"
			display_sites
			exit 0;;
		rn )
			renumber_sites
			display_sites
			exit 0;;
		sf )
			sort_by_feq "$2"
			display_sites
			exit 0;;
		rst )
			reset_feq $@
			display_sites
			exit 0;;
		doff )
			del_off_site
			display_sites
			exit 0;;
		uninstall )
			uninstall
			exit 0;;
		dp )
			shift 1
			deploy_to $@
			exit 0;;
		cmd )
			shift 1
			cmd_to "$@"
			exit 0;;
		upgrade )
			do_upgrade
			exit 0;;
		ac )
			if [ -z $2 ]; then
				display_ac_usg
				exit 0
			fi

			add_node "$2" "$3" "$4"
			connect_by "ssh" $?
			exit 0;;
		# Enable/Disalbe auto update
		acu )
			switch_atckupd $2
			exit 0;;
	esac

	is_site_exist $1

	if [ $? -eq 0 ]; then
		color_msg 32 "[$1] does not exist"
	else
		increase_feq $1

		if [ -z "$2" ]; then
			connect_by "ssh" $1
			exit $?
		else
			case "$2" in
			[f] )
				connect_by "ftp" $1 "$3" "$4" ;;
			[v] )
				connect_by "vncviewer" $1 "$3" "$4" ;;
			[r] )
				connect_by "rdesktop" $1 "$3" "$4" ;;
			[x] )
				connect_by "ssh" $1 "x" ;;
			[*] )
				color_msg 32 "Unrecognized argument: $2." ;;
			esac
		fi
	fi
fi
