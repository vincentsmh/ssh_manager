
# Check the deploy OS is Linux or Mac(Darwin)
os=`uname`

if [ "$os" == "Linux" ]; then
	DEPLOY_FOLDER="/usr/local/bin"
else
	DEPLOY_FOLDER="/usr/bin"
fi

FILES="conn regkey.py pexpect.py"

mkdir -p $DEPLOY_FOLDER
su $SUDO_USER -c "touch $HOME/conn.data"

for file in $FILES;
do
	cp $file $DEPLOY_FOLDER
	chmod +x $DEPLOY_FOLDER/$file
done
