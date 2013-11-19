Introduction
============
This is a little tool to manage ssh connection. This tool allows you to define
sites and connect to them quickly with multiple protocols, (SSH, FTP, RDP,
VNC).

Requirement
===========
- Linux/Unix/OS X system 

Install
==========
sudo bash setup.sh

How to use
==========
Usage: cn <num|l|r|a|d|ct|cf|p|m|pa|rn|md|sf|doff|rst|dp|cmd> [args]

- num: cn #num [x|f|v|r]<br>
ex. cn 2 (SSH to site 2)<br>
ex. cn 2 x (with X-forwarding)<br>
ex. cn 2 f (FTP to site 2)<br>
ex. cn 2 r (RDP to site 2)<br>
ex. cn 2 v (VNC to site 2)<br>
- l: list all sites.<br>
- r: cn r #num<br>
Register public key to site #num. You would be asked to input password for
several times. After the registration, you can connect to that site without
type password.<br>
ex: cn r 3<br>
- a: Add a new site.<br>
ex: cn a user@127.0.0.1 "Description of the site."<br>
ex: cn a "-p 2222 user@127.0.0.1 "Description of the site." (Assign a port)<br>
- d: Delete a site (num). <br>
ex: cn d 3<br>
- ct: cn ct "file" #num1 [#num2] [#num3] [...]<br>
scp a file/directory to the given site. <br>
ex: cn ct file 3<br>
- cf: cn cf "file" #num1 [#num2] [#num3] [...]<br>
scp a remote file/directory of the given sites to local<br>
ex: cn cf file 3 (=> scp user@site3_ip:file .)<br>
- p: Ping a site to test the connectivity. <br>
ex: cn p 3<br>
- pa: Ping all sites to test their connectivity.<br>
- md: Modify a site's description.<br>
ex: cn md 3 "New description to site 3"<br>
- rn: reorder the number of all sites.<br>
- sf: cn sf [D|I]<br>
Sort sites by the frequency. D: decreasing, I: increasing<br>
- doff: Delete sites whose status are Off<br>
- rst: cn rst [#num]: Reset sites' frequency to 0.<br>
- m: Move a site #num1 to #num2<br>
ex: cn m 10 3<br>
- dp: cn dp #num [#num2] [#num3] ...<br>
Deploy this utility to some sites.<br>
- cmd: cn cmd "commands" #num [#num2] [#num3] ...<br>
Send commands to some sites<br>
