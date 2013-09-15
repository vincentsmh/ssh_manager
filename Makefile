
all:
	echo "Make install to install file to /usr/local/bin"

install:
	cp conn.sh /usr/local/bin/conn
	cp conn.data ~/conn.data
	echo "Please edit conn.data to maintain your remote site"

uninstall:
	rm -rf /usr/local/bin/conn
	rm ~/conn.data
