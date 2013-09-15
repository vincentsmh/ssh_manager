# Deploy file to computer nodes
# How to use:
#   1) put cn.txt with this file at the same folder
#   2) python deploy.py src_file dst_file
#
import pexpect
import sys
import os
import re

SSH_NK = "Are you sure you want to continue connecting"

PROMPT = "[$#]"
SCP_FIN = "100%"
FPW = "please try again."
NO_ROUTE = "No route to host"
REFUSED = "Connection refused"
TIMEOUT = "Connection timed out"
CONN_CLOSE = "Connection closed by remote host"
NO_DNS = "Name or service not known"

def ssh_cmd(ip, user, pwd, cmds):
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
            break
        elif index==4:
            child.close
            break
        elif index==5:
            child.close
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
            break            
    return child           
#=============================================
def scp_cmd(p1, p2, pw):
	rtv = 0
	child = pexpect.spawn("scp %s %s" % (p1, p2) )
	child.logfile = sys.stdout

	while(1):
		index = child.expect(['password: ', SSH_NK,pexpect.TIMEOUT,pexpect.EOF,SCP_FIN,FPW,     NO_ROUTE,REFUSED,TIMEOUT,CONN_CLOSE,NO_DNS])
		if index == 0:
			child.sendline(pw)
			print "Send password: %s" % (pw)
		elif index == 1:
			child.sendline('yes')
		elif index==2:
			print "Timeout: login fail!!"
			child.close
			break
		elif index==3:
			child.close
			break
		elif index==4:
			child.close
			rtv = 1;
			break
		elif index==5:
			print "Password failed"
			break
		elif index==6:
			child.close
			break
		elif index==7:
			child.close
			break
		else:
			child.close
			break
	return rtv
#=============================================
# Main
#
