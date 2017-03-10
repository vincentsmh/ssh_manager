#!/bin/bash

DATA="$HOME/.conn.data"
OLD_DATA="$HOME/conn.data"
DEFAULT_SSH_PORT=22

# Color function
# Input: $1->color, $2->message, $3->newline or not
function color_msg
{
  echo -e $3 "\033[$1m$2\033[0m"
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

# Main 
# Check root privilege for deployment
if [ "$(id -u)" != "0" ]; then
  color_msg 38 "Need " -n
  color_msg 31 "root " -n
  color_msg 38 "privilege."
  echo -e
  exit 1
fi

## Deploy 'cn' script
DEPLOY_FOLDER="/usr/local/bin"
mkdir -p $DEPLOY_FOLDER
cp cn.sh $DEPLOY_FOLDER/cn
chmod 755 $DEPLOY_FOLDER/cn
check_n_exit $? "Deploy binary failed"
color_msg 32 "Deploy binary successfully"

## Migrate data to new location
if [ -f ${OLD_DATA} ]; then
  mv ${OLD_DATA} ${DATA}
fi

## Deploy site data
if [ ! -f $DATA ]; then
  touch $DATA
fi

check_n_exit $? "Fail to deploy user data"
color_msg 32 "Deploy user data successfully"
echo -e
echo -ne "You can use command "
color_msg 33 "cn " -n
echo -e "to see the help now."
echo -e "
Here is a quick start:
+ Add a new site
cn a 'user@192.168.1.1' 'My first site'

+ List managed sites
cn l

+ Connect to a site with its number, 1
cn 1
"

# Fix user owner of the conn.data
fix_userowner
