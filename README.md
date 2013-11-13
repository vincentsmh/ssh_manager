Introduction
============
This is a little tool to manage ssh connection. This tool allows you to define
sites and connect to them quickly.

Requirement
===========
- Linux/Unix system
- Python: if you would like to use some features, like key registration to
some site, you need to install python in your system inadvance.

Install
==========
sudo bash setup.sh

How to use
==========
Usage: cn <num|l|r|a|d|s|rn> [args]

- num: SSH to site #num. <br>
ex. cn 2                                                                                                                                                                                                        
ex. cn 3 -X (with X-forwarding)
- l: list all sites.<br>
- r: Register public key to site #num.<br>
ex: cn r 3 password
- a: Add a new site.<br>
ex: cn a user@127.0.0.1 "Description of the site."
ex: cn a "-p 2222 user@127.0.0.1 "Description of the site." (Assign a port)
- d: Delete a site (num).<br>
ex: cn d 3
- s: scp a file/directory to the given site.<br>
ex: cn s file 3
- p: Ping a site to test the connectivity.<br>
ex: cn p 3
- pa: Ping all sites to test their connectivity.<br>
- md: Modify a site's description.<br>
ex: cn md 3 "New description to site 3"
- rn: reorder the number of all sites.<br>
- sf: cn sf [D|I]<br>
Sort sites by the frequency. D: decreasing, I: increasing
- m: Move a site #num1 to #num2<br>
ex: cn m 10 3
