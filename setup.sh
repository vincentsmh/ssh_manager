
# Check the deploy OS is Linux or Mac(Darwin)
os=`uname`

if [ "$os" == "Linux" ]; then
	DEPLOY_FOLDER="/usr/local/bin"
else
	DEPLOY_FOLDER="/usr/bin"
fi

mkdir -p $DEPLOY_FOLDER
su $SUDO_USER -c "touch $HOME/conn.data"
cp cn.sh $DEPLOY_FOLDER/cn
