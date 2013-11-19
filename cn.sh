#/bin/bash

DATA="$HOME/conn.data"

# Color function
# Input: $1->color, $2->message, $3->newline or not
function color_msg
{
	echo -e $3 "\033[1;$1m$2\033[0m"
}

function color_msg_len
{
	echo -ne "\033[1;$1m"
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

		exit 1
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
	unset site_desc
	unset site_status
	unset site_feq
}

# Read all sites data into 'sites'
function read_sites()
{
	local len=0
	local read_max=0
	num_of_sites=0
	max_num_len=2
	max_userip_len=7
	max_desc_len=11
	max_status_len=6
	max_feq_len=9
	unset_site

	while read site
	do
		if [ $read_max -ne 0 ]; then
			local th=$(echo "$site" | awk -F "_" {'print $1'} | bc)
			site_num[$th]=$th
			site_userip[$th]=$(echo "$site" | awk -F "_" {'print $2'})
			site_desc[$th]=$(echo "$site" | awk -F "_" {'print $3'})
			site_status[$th]=$(echo "$site" | awk -F "_" {'print $4'})
			site_feq[$th]=$(echo "$site" | awk -F "_" {'print $5'} | bc)

			if [ "${site_num[$th]}" != "" ]; then
				num_of_sites=$(($num_of_sites+1))
			fi
		else
			max_num_len=$(echo "$site" | awk -F "_" {'print $1'} | bc)
			max_userip_len=$(echo "$site" | awk -F "_" {'print $2'} | bc)
			max_desc_len=$(echo "$site" | awk -F "_" {'print $3'} | bc)
			max_status_len=$(echo "$site" | awk -F "_" {'print $4'} | bc)
			max_feq_len=$(echo "$site" | awk -F "_" {'print $5'} | bc)
			read_max=1
		fi
	done < $DATA
}

function export_to_file()
{
	echo "$max_num_len"_"$max_userip_len"_"$max_desc_len"_"$max_status_len"_"$max_feq_len" > $DATA

	for i in ${!site_num[*]}; do
		echo "${site_num[$i]}"_"${site_userip[$i]}"_"${site_desc[$i]}"_"${site_status[$i]}"_"${site_feq[$i]}"
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

	echo "+"
}

# Print table's head and tail
# Input:
#   $1->option: head/tail
#   $1->max_id_len
#   $2->max_userip_len
#   $3->max_desc_len
function print_head_tail()
{
	print_dash

	if [ "$1" == "head" ];then
		color_msg 37 "| " -n
		color_msg_len 37 "NO" $max_num_len -n
		color_msg 37 " | " -n
		color_msg_len 37 "user@IP" $max_userip_len -n
		color_msg 37 " | " -n
		color_msg_len 37 "Description" $max_desc_len -n
		color_msg 37 " | " -n
		color_msg_len 37 "Status" $max_status_len -n
		color_msg 37 " | " -n
		color_msg_len 37 "Frequency" $max_feq_len -n
		color_msg 37 " |"

		print_dash $2 $3 $4
	fi

}

# Display the given site
# Input: $1-> color, $2->site number
function display_entry()
{
		color_msg 37 "| " -n
		color_msg_len $1 "$2" $max_num_len -n
		color_msg 37 " | " -n
		color_msg_len $1 "${site_userip[$2]}" $max_userip_len -n
		color_msg 37 " | " -n
		color_msg_len $1 "${site_desc[$2]}" $max_desc_len -n
		color_msg 37 " | " -n
		color_msg_len $1 "${site_status[$2]}" $max_status_len -n
		color_msg 37 " | " -n
		color_msg_len $1 "${site_feq[$2]}" $max_feq_len -n
		color_msg 37 " |"
}

# Display all of the remote sites defined in conn.data
function display_sites()
{
	color=32

	# Print table head
	print_head_tail "head"

	# Display from '1'
	for i in ${!site_num[*]}; do
		display_entry $color $i
		color=$((color+1))

		if [ $color -eq 38 ]; then
			color=32
		fi
	done

	print_head_tail "tail"
	echo -e
}

function display_scp_to()
{
	color_msg 38 "   - " -n
	color_msg 32 "ct" -n
	color_msg 38 ": cn ct \"file\" #num1 [#num2] [#num3] [...]"
	color_msg 38 "         scp a file/directory to the given site. "
	color_msg 38 "         ex: cn ct file 3"
}

function display_scp_from()
{
	color_msg 38 "   - " -n
	color_msg 32 "cf" -n
	color_msg 38 ": cn cf \"file\" #num1 [#num2] [#num3] [...]"
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
			scp -r "${site_userip[$i]}:$file" .
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
	if [ -z $1 ] || [ -z $2 ]; then
		display_scp_to
		exit 0
	fi

	file="$1"
	shift 1

	for i in $@; do
		if [ "${site_num[$i]}" != "" ]; then
			scp -r "$file" "${site_userip[$i]}:"
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
	local user=$(find_user "$1")
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
	ssh ${site_userip[$1]} "$cmd"
	check_n_exit $? "Register public key failed"

	echo -e
	color_msg 32 "Register public key to $ip successfully."
}

function add_node_to_num()
{
	local field1_len=$(strlen "$1")
	local field2_len=$(strlen "$2")
	local field3_len=$(strlen "$3")

	if [ $field1_len -gt $max_num_len ]; then
		max_num_len=$field1_len
	fi

	if [ $field2_len -gt $max_userip_len ]; then
		max_userip_len=$field2_len
	fi

	if [ $field3_len -gt $max_desc_len ]; then
		max_desc_len=$field3_len
	fi

	site_num[$1]="$1"
	site_userip[$1]="$2"
	site_desc[$1]="$3"
	ping_site $1
	site_feq[$1]=0

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
		color_msg 31 "No arguments. Please input at least 'user@ip'."
		exit 1
	fi

	num=$(find_insert_num)

	echo -e

	while true; do
		echo -n "Add this node to position "
		color_msg 32 "[$num] " -n
		read -p "(y/n)" yn

		case $yn in
			[Yy]* ) add_node_to_num "$num" "$1" "$2";;
			[Nn]* ) read -p "Input your number:" un
					add_node_to_num $un "$1" "$2";;
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
	color_msg 38 "This utility is created by " -n
	color_msg 36 "Vincent Shi-Ming Huang."
	color_msg 38 "If you have any problem or you hit some issue/bug, please send your comment to " -n
	color_msg 36 "Vincent.SM.Huang@gmail.com"
	color_msg 38 "http://vincent-smh.appspot.com"
}

# Display the usage of 'md' command
function display_md_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "md" -n
	color_msg 38 ": Modify a site's description."
	color_msg 38 "         ex: cn md 3 \"New description to site 3\""

}

function display_reg_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "r" -n
	color_msg 38 ": cn r #num"
	color_msg 38 "        Register public key to site #num. You would be asked to input password for"
	color_msg 38 "        several times. After the registration, you can connect to that site without"
	color_msg 38 "        type password."
	color_msg 38 "        ex: cn r 3"
}

function display_deploy_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "dp" -n
	color_msg 38 ": cn dp #num [#num2] [#num3] ..."
	color_msg 38 "       Deploy this utility to some sites."
}

function display_cmd_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "cmd" -n
	color_msg 38 ": cn cmd \"commands\" #num [#num2] [#num3] ..."
	color_msg 38 "          Send commands to some sites"
}

# Display the usage of 'cn' command
function display_usage()
{
	echo -e
	color_msg 38 "Usage: cn " -n
	color_msg 32 "<num|l|r|a|d|ct|cf|p|m|pa|rn|md|sf|doff|rst|dp|cmd>" -n
	color_msg 33 " [args]"
	color_msg 38 "   - " -n
	color_msg 32 "num" -n
	color_msg 38 ": cn #num " -n
	color_msg 33 "[x|f|v|r]"
	color_msg 38 "          ex. cn 2 (SSH to site 2)"
	color_msg 38 "          ex. cn 2 x (with X-forwarding)"
	color_msg 38 "          ex. cn 2 f (FTP to site 2)"
	color_msg 38 "          ex. cn 2 r (RDP to site 2)"
	color_msg 38 "          ex. cn 2 v (VNC to site 2)"

	color_msg 38 "   - " -n
	color_msg 32 "l" -n
	color_msg 38 ": list all sites."

	display_reg_usage

	color_msg 38 "   - " -n
	color_msg 32 "a" -n
	color_msg 38 ": Add a new site."
	color_msg 38 "        ex: cn a user@127.0.0.1 \"Description of the site.\""
	color_msg 38 "        ex: cn a \"-p 2222 user@127.0.0.1 \"Description of the site.\" (Assign a port)"

	color_msg 38 "   - " -n
	color_msg 32 "d" -n
	color_msg 38 ": Delete a site (num). "
	color_msg 38 "        ex: cn d 3"

	display_scp_to
	display_scp_from

	color_msg 38 "   - " -n
	color_msg 32 "p" -n
	color_msg 38 ": Ping a site to test the connectivity. "
	color_msg 38 "        ex: cn p 3"

	color_msg 38 "   - " -n
	color_msg 32 "pa" -n
	color_msg 38 ": Ping all sites to test their connectivity."

	display_md_usage

	color_msg 38 "   - " -n
	color_msg 32 "rn" -n
	color_msg 38 ": reorder the number of all sites."

	display_usage_sbf

	color_msg 38 "   - " -n
	color_msg 32 "doff" -n
	color_msg 38 ": Delete sites whose status are Off"

	color_msg 38 "   - " -n
	color_msg 32 "rst: cn rst [#num]" -n
	color_msg 38 ": Reset sites' frequency to 0."

	display_move_usage

	display_deploy_usage

	display_cmd_usage

	echo -e
	display_author
	echo -e
}

# Find maximum string length.
# Input: $1->find the maximum number string length
#        $2->find the maximum userip string length
#        $3->find maximum description string length
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
		max_desc_len=0

		for i in ${!site_desc[*]}; do
			len=$(strlen "${site_desc[$i]}")

			if [ $len -gt $max_desc_len ]; then
				max_desc_len=$len
			fi
		done
	fi
}

# Delete the given node
function del_site()
{
	if [ -z "$2" ]; then
		display_sites

		echo -e
		color_msg 38 "Usage: conn d [num1 num2 num3 ...]"
		exit 0
	fi

	shift 1
	local num_check=0
	local userip_check=0
	local desc_check=0

	# Find indexes of the deleting site
	for num in $@; do
		if [ $(strlen "${site_num[$num]}") -eq $max_num_len ]; then
			num_check=1
		fi

		if [ $(strlen "${site_userip[$num]}") -eq $max_userip_len ]; then
			userip_check=1
		fi

		if [ $(strlen "${site_desc[$num]}") -eq $max_desc_len ]; then
			desc_check=1
		fi

		unset_entry $num
	done

	find_max_len $num_check $userip_check $desc_check
	export_to_file
}

function assign_tmp_entry()
{
	tmp_site_num[$1]="$2"
	tmp_site_userip[$1]="$3"
	tmp_site_desc[$1]="$4"
	tmp_site_status[$1]="$5"
	tmp_site_feq[$1]="$6"
}

function unset_tmp_site()
{
	unset tmp_site_num
	unset tmp_site_userip
	unset tmp_site_desc
	unset tmp_site_status
	unset tmp_site_feq
}

function clone_tmp_to_site()
{
	j=1
	for i in ${!tmp_site_num[*]}; do
		site_num[$j]="${tmp_site_num[$i]}"
		site_userip[$j]="${tmp_site_userip[$i]}"
		site_desc[$j]="${tmp_site_desc[$i]}"
		site_status[$j]="${tmp_site_status[$i]}"
		site_feq[$j]="${tmp_site_feq[$i]}"
		j=$(($j+1))
	done
}

function renumber_sites()
{
	j=1

	for i in ${!site_num[*]}; do
		assign_tmp_entry $j "$j" "${site_userip[$i]}" "${site_desc[$i]}" "${site_status[$i]}" "${site_feq[$i]}"
		j=$(($j+1))
	done

	unset_site
	clone_tmp_to_site
	unset_tmp_site
	export_to_file
}

function display_move_usage()
{
	color_msg 38 "   - " -n
	color_msg 32 "m" -n
	color_msg 38 ": Move a site #num1 to #num2"
	color_msg 38 "        ex: cn m 10 3"
}

function assign_entry_data()
{
	site_num[$1]="$2"
	site_userip[$1]="$3"
	site_desc[$1]="$4"
	site_status[$1]="$5"
	site_feq[$1]="$6"
}

function unset_entry()
{
	unset site_num[$1]
	unset site_userip[$1]
	unset site_desc[$1]
	unset site_status[$1]
	unset site_feq[$1]
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
		assign_entry_data $2 "$2" "${site_userip[$1]}" "${site_desc[$1]}" "${site_status[$1]}" "${site_feq[$1]}"
		return 0
	fi

	# local variable for recursive call
	#local num="${site_num[$2]}"
	local num="$2"
	local userip="${site_userip[$1]}"
	local desc="${site_desc[$1]}"
	local status="${site_status[$1]}"
	local feq="${site_feq[$1]}"

	# Check if the dest site number is existed.
	if [ "${site_num[$2]}" != "" ]; then
		move_function $2 $(($2+1)) $3
	fi

	# We have make sure the dest is empty or is moved to its next. So, we can
	# assign value to it (move over).
	assign_entry_data $2 "$num" "$userip" "$desc" "$status" "$feq"

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

	rm -rf $DEPLOY_FOLDER/cn
	rm -rf $DATA
}

# Ping the given site to test if the it is reachable.
# Input: $1->the number of site
function ping_site()
{
	local ip=$(find_ip $1)

	ping -c 1 -W 1500 $ip

	if [ $? -eq 0 ]; then
		site_status[$1]="On"
	else
		site_status[$1]="Off"
	fi

	export_to_file
	return 0
}

# Ping all site to check their connectivity
function ping_all_sites()
{
	local ip=""

	for i in ${!site_num[*]}; do
		ip=$(find_ip $i)
		ping -c 1 -W 1500 $ip

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
		find_max_len 0 0 1
		export_to_file
	else
		display_md_usage
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

		assign_tmp_entry $i "$i" "${site_userip[$found_i]}" "${site_desc[$found_i]}" "${site_status[$found_i]}" "${site_feq[$found_i]}"
		unset_entry $found_i
	done

	for i in ${!tmp_site_num[*]}; do
		assign_entry_data $i "${tmp_site_num[$i]}" "${tmp_site_userip[$i]}" "${tmp_site_desc[$i]}" "${tmp_site_status[$i]}" "${tmp_site_feq[$i]}"
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

# Connect to the given site by the given protocol(command)
# Input: $1->utility name
function connect_by()
{
	if [ "$(is_osx)" == "1" ]; then
		case "$1" in
		ftp ) open ftp://$2 ;;
		vncviewer ) open vnc://$2 ;;
		rdesktop ) open rdp://$2 ;;
		esac
	else
		check=$(command -v "$1" | grep -c "$1")

		if [ "$check" == "1" ]; then
			color_msg 32 "Connecting ($1) to $ip ..."
			$1 $2
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
		echo "usr/local/bin/cn"
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
		ssh -t ${site_userip[$i]} "sudo mv ~/cn /usr/local/bin/cn"
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
		ssh -t ${site_userip[$i]} "$cmd"
	done
}

# main()
if [ -z "$1" ]; then
	display_usage
else
	read_sites

	case "$1" in
		[l] )
			echo -e
			display_sites
			exit 0;;
		[a] )
			add_node "$2" "$3"
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
			ping_site $2
			display_sites
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
		md )
			modify_desc $2 "$3"
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
			cmd_to $@
			exit 0;;
	esac

	is_site_exist $1

	if [ $? -eq 0 ]; then
		color_msg 32 "[$1] does not exist"
	else
		increase_feq $1

		if [ -z "$2" ]; then
			color_msg 32 "SSH to ${site_userip[$1]}"
			ssh ${site_userip[$1]}
			exit 0
		else
			ip=$(find_ip $1)

			case "$2" in
			[f] )
				connect_by "ftp" "$ip"
				;;
			[v] )
				connect_by "vncviewer" "$ip"
				;;
			[r] )
				connect_by "rdesktop" "$ip"
				;;
			[x] )
				color_msg 32 "SSH to ${site_userip[$1]} with X-Forwarding"
				ssh -X ${site_userip[$1]}
				;;
			[*] )
				color_msg 32 "Unrecognized argument: $2."
				;;
			esac
		fi
	fi
fi
