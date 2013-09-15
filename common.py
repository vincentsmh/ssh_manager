import pexpect
import sys
import os
import time

account='root'
password='password'

ssh_newkey = 'Are you sure you want to continue connecting'
no_route = 'No route to host'
prompt="[$#] "
key_failed='Host key verification failed.'
refused="Connection refused"

def main():
    # parse command line options
    if len(sys.argv)==2:
        if sys.argv[1]=='checkcloudos':
            check_cloudos()
        elif sys.argv[1]=='sync_time':
            sync_time() 
        else:
            print_readme()
    elif len(sys.argv)<3:
        print_readme()
        sys.exit()
    elif sys.argv[1]=='all':
        snall_cmd(sys.argv[2])
        cn_cmd(sys.argv[2])
        dn_cmd(sys.argv[2])
    elif sys.argv[1]=='dn':
        dn_cmd(sys.argv[2])
    elif sys.argv[1]=='cn':
        cn_cmd(sys.argv[2])
    elif sys.argv[1]=='scp':
        scp_cmd(sys.argv[2],sys.argv[3],password)
    elif sys.argv[1]=='scp2':
        scp_cmd2(sys.argv[2],sys.argv[3],password)        
    elif sys.argv[1]=='sn':
        snall_cmd(sys.argv[2])
#        print 'Not finished yet'
    else:
        sn_cmd(sys.argv[1],sys.argv[2])
#=======================================================
def print_readme():
        print 'No action specified. Not enough args'
        print 'python cloudcmd.py all ["command1,command2"] =>all machine except sn1'
        print 'python cloudcmd.py dn ["command1,command2"] =>all Data Node'
        print 'python cloudcmd.py cn ["command1,command2"] =>all Compute Node'
        print 'python cloudcmd.py sn ["command1,command2"] =>all Service Node except sn1'
        print 'python cloudcmd.py sync_time =>sync time for all machine'
        print 'python cloudcmd.py scp [source] [destination] =>scp file or directory'    
#=======================================================   
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
#=======================================================    
def scp_cmd(src, dest, pwd):
    child = pexpect.spawn('scp -r %s %s' % (src, dest))
    child.logfile = sys.stdout
    timeout_count=0
    while(1):
        #index = child.expect(['password: ', ssh_newkey,pexpect.TIMEOUT,pexpect.EOF,key_failed,no_route])
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
            timeout_count=timeout_count+1
            if timeout_count>5:
                print "Timeout: login fail!!"
                child.close
                break
            else:
                print "Timeout!!"+str(timeout_count)
                continue
        elif index==4:
            child.close
	    break
        elif index==5:
            print 'no route'
            child.close
            break  
        elif index==6:
            print "Connection refused: login fail!!"
            child.close
            break            
    return child
#=======================================================
def scp_cmd2(src, dest, pwd):
    child = pexpect.spawn('scp -r %s %s' % (src, dest))
    child.logfile = sys.stdout
    while(1):
        index = child.expect(['password: ', ssh_newkey,pexpect.TIMEOUT,pexpect.EOF,key_failed,no_route])
        if index == 0:
            child.sendline(pwd)
            while(1):
                index=child.expect([prompt,pexpect.EOF,pexpect.TIMEOUT])
                if index<2:
                    break
            child.close
            break
        elif index == 1:
            child.sendline('yes')
        elif index==2:
            continue
        elif index==4:
            os.system('rm -rf /root/.ssh/known_hosts')
        elif index==5:
            print 'no route'
            child.close
            break  
    return child
#=======================================================
def dn_cmd(cmds):
    print '\n**************Data Node command**************************'
    list = read_ip('dn.txt')
    for host in list:
        print "\n------------------["+host + ']--------------------'
        ssh_cmd(host, account,password, cmds)
    print '\n****************Finished Data Node Command********************'
#=======================================================
def cn_cmd(cmds):
    print '\n**************Compute Node command**************************'
    list = read_ip('cn.txt')
    for host in list:
        print "\n------------------["+host + ']--------------------'
        ssh_cmd(host, account,password, cmds)
    print '\n****************Finished Compute Node Command********************'
#=======================================================    
def snall_cmd(cmds):
    print '=================Connect to Service Node============================='
    list = read_ip('sn.txt')
    for host in list[1:]:
        print "\n------------------["+host + ']--------------------'
        ssh_cmd(host, account,password, cmds)
    print '\n===================Finished Service Node========================='
#=======================================================    
def sn_cmd(sn, cmds):
    print '=================Connect to ' + sn +"============================="
    ssh_cmd(sn, account,password, cmds)
    print '\n===================Finished '+sn+'========================='
#=======================================================  
#def get_sn_ip(sn):
#    ip=""
#    sn_idx = {'prm':0, 'pdcm':0, 'log':0, 'vdcm':1, 'apis':1, 'rpm':2, 'rs':0, 'dms':3, 'slb':4, 'secs':4,'ds':5,'iscsitarget':6,'dss':7}
#    sn_list = read_ip('sn.txt')
#    if sn_idx.has_key(sn) and len(sn_list) > sn_idx[sn]:
#        ip = sn_list[sn_idx[sn]]
#    return ip

#=======================================================  
    
#=======================================================  
def read_ip(file):
    file = open(file)
    list = []
    try:
        hosts = file.read()
    finally:
        file.close() 
    for host in hosts.split("\n"):
        if host:
            items=host.split("\t")
            host=items[len(items)-1]
            list.append(host)
    return list
#=======================================================  
#def read_bmcip(file):
#    file = open(file)
#    list = []
#    try:
#        hosts = file.read()
#    finally:
#        file.close() 
#    for host in hosts.split("\n"):
#        if host:
#            items=host.split("\t")
#            if len(items)==5:
#                host=items[2]
#            list.append(host)
#    return list
#=======================================================  
def check_cloudos():
    #sn_list = read_ip('sn.txt')
    #for ip in sn_list[1:]:
    cn_list = read_ip('cn.txt')
    for ip in cn_list:
        ssh_cmd(ip, account,password, "ps aux | grep eucalyptus")
        
#=======================================================  
def change_passwd_cmd(ip,user,pwd,newpwd):
    ssh_newkey = 'Are you sure you want to continue connecting'
    newp="New UNIX password:"
    retypep="Retype new UNIX password:"

    prompt="[$#] "
    child = pexpect.spawn('ssh %s@%s' % (user, ip))
    child.logfile = sys.stdout
    while(1):
        index = child.expect(['password: ', ssh_newkey,pexpect.TIMEOUT,pexpect.EOF,no_route])
        if index == 0:
            child.sendline(pwd)
            child.expect(prompt)
            child.sendline('passwd')
            index=child.expect([prompt,pexpect.EOF,pexpect.TIMEOUT,newp])
            if index==3:
                child.sendline(newpwd)
                index=child.expect([prompt,pexpect.EOF,pexpect.TIMEOUT,retypep])
                if index==3:
                    child.sendline(newpwd)
            child.sendline("logout")
            child.close
            break
        elif index == 1:
            child.sendline('yes')
        elif index==2:
            print "Timeout: login fail!!"
            child.close
            break
        elif index>=3:
            child.close
            break 
    return child
#=======================================================
def sync_time():
    sn_list = read_ip('sn.txt')
    for ip in sn_list[1:]:
        ssh_cmd(ip, account,password, "service ntpd stop,ntpdate prm.ccma.itri,service ntpd start")
    cn_list = read_ip('cn.txt')
    for ip in cn_list:
        ssh_cmd(ip, account,password, "service ntpd stop,ntpdate prm.ccma.itri,service ntpd start")
    dn_list = read_ip('dn.txt')
    for ip in dn_list:
        ssh_cmd(ip, account,password, "service ntpd stop,ntpdate prm.ccma.itri,service ntpd start")
#=======================================================
if __name__ == "__main__":
   main()

