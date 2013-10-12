Introduction
============
This is a little tool to manage ssh connection. This tool allows you to define
sites and connect to them quickly.

Requirement
===========
python

Install
==========
sudo sh setup.sh

How to use
==========
Usage: conn <num|l|c|r|a|d> [args]
   - num: SSH to site #num
   - l: list all sites
   - r: conn r site_num password
     Register public key to to the site of #num.
   - a: conn a user@ip "Description to adding site."
     Add a site to the management list
   - d: conn d num
    Delete the site with #num
   - s: conn s num file
    scp file f to site #num.
