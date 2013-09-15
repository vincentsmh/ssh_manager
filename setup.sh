DEPLOY_FOLDER="/usr/local/bin"
FILES="conn"

mkdir -p $DEPLOY_FOLDER
touch $HOME/conn.data

for file in $FILES;
do
	cp $file $DEPLOY_FOLDER
	chmod +x $DEPLOY_FOLDER/$file
done
