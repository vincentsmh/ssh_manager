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
   - num: SSH to node #num
   - l: list all nodes
   - c: <conn c num> scp file to the node of #num.
   - r: <conn r num> register public key to to the node of #num.
   - a: conn a <user@ip> ["Description"]
   - d: conn d <num>: delete node #num
