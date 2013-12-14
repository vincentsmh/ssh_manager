cmd=$(command -v lala)
if [ "$cmd" == "" ]; then
	echo "Empty"
else
	echo "not empty"
fi

echo cmd: $cmd
