Introduction
============
This is a little tool to manage ssh connection. This tool allows you to define
sites and connect to them quickly.

Requirement
===========
python

Install
==========
sudo bash setup.sh

How to use
==========
Usage: cn <num|l|r|a|d|s|rn> [args]

- num: SSH to site #num. <br>
ex. cn 2                                                                                                                                                                
- l: list all sites.
- r: Register public key to site #num. <br>
ex: cn r 3 password
- a: Add a new site. <br>
ex: cn a user@127.0.0.1 "Description of the site." <br>
ex: cn a "-p 2222 user@127.0.0.1 "Description of the site." (Assign a port)
- d: Delete a site (num). <br>
ex: cn d 3 
- s: scp a file/directory to the given site. <br>
ex: cn s file 3
- rn: reorder the number of all sites.
