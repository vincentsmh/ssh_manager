
# Check the deploy OS is Linux or Mac(Darwin)
os=`uname`

if [ "$os" == "Linux" ]; then
	DEPLOY_FOLDER="/usr/local/bin"
else
	DEPLOY_FOLDER="/usr/bin"
fi

FILES="regkey.py pexpect.py"

mkdir -p $DEPLOY_FOLDER
su $SUDO_USER -c "touch $HOME/conn.data"

cp cn.sh $DEPLOY_FOLDER/cn
cp regkey.py $DEPLOY_FOLDER/regkey.py
cp pexpect.py $DEPLOY_FOLDER/pexpect.py
