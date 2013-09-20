import sys
sys.path.insert( 0, '/usr/local/bin' )

import pexpect

ssh_newkey = 'Are you sure you want to continue connecting'
no_route = 'No route to host'
prompt="[$#] "
key_failed='Host key verification failed.'
refused="Connection refused"

def ssh_cmd(ip, user, pwd, cmds):
	ret = 0
	child = pexpect.spawn('ssh %s@%s' % (user, ip))
	child.logfile = sys.stdout

	while(1):
		index = child.expect([key_failed,'password: ', ssh_newkey,pexpect.TIMEOUT,pexpect.EOF,no_route,prompt,refused])
		if index == 0:
			os.system('rm -rf /root/.ssh/known_hosts')
			time.sleep(2)
			child.close()
			child = pexpect.spawn('ssh %s@%s' % (user, ip))
		elif index == 1:
			child.sendline(pwd)
		elif index==2:
			child.sendline('yes')
		elif index==3:
			print "Timeout: login fail!!"
			child.close
			ret = 1
			break
		elif index==4:
			child.close
			break
		elif index==5:
			child.close
			ret = 2
			break
		elif index==6:
			for cmd in cmds.split(","):
				child.sendline(cmd)
				index=child.expect([prompt,pexpect.EOF,pexpect.TIMEOUT])
				if index==2:
					print "Command failed:"+cmd
					continue
			child.sendline("logout")
			child.close
			break  
		elif index==7:
			print "Connection refused: login fail!!"
			child.close
			ret = 3
			break

	return ret

def scp_cmd(src, dest, pwd):
	ret = 0
	child = pexpect.spawn('scp -r %s %s' % (src, dest))
	child.logfile = sys.stdout
	timeout_count=0

	while(1):
		index = child.expect([key_failed,'password: ', ssh_newkey,pexpect.TIMEOUT,pexpect.EOF,no_route,refused])
		if index == 0:
			os.system('rm -rf /root/.ssh/known_hosts')
			time.sleep(2)
			child.close()
			child = pexpect.spawn('scp -r %s %s' % (src, dest))
		if index == 1:
			child.sendline(pwd)
			while(1):
				index=child.expect([prompt,pexpect.EOF,pexpect.TIMEOUT])
				if index<2:
					break
			child.close
			break
		elif index == 2:
			child.sendline('yes')
		elif index==3:
			print "Timeout: login fail!!"
			child.close
			ret = 1
			break
		elif index==4:
			child.close
			break
		elif index==5:
			print 'no route'
			child.close
			ret = 2
			break  
		elif index==6:
			print "Connection refused: login fail!!"
			child.close
			ret = 3
			break

	return ret

# Copy public key to the remove site
dest = "%s@%s:~" % (sys.argv[2], sys.argv[1])
cmd1 = "cat id_rsa.pub >> ~/.ssh/authorized_keys"
cmd2 = "rm -rf id_rsa.pub"

ret = scp_cmd(sys.argv[4], dest, sys.argv[3])
if ret != 0:
	sys.exit(ret)

ret = ssh_cmd(sys.argv[1], sys.argv[2], sys.argv[3], cmd1)
ret = ret + ssh_cmd(sys.argv[1], sys.argv[2], sys.argv[3], cmd2)
sys.exit(ret)
