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

```bash
$ bash setup.sh
```

How to use
==========
After install this this tool, please type 'cn' to see the usage.

- Quick start:
    * Add a node  
      ```bash
      $ cn a "user@ip" ["desc"] [port]
      ```

    * List all added node  
      ```bash
      $ cn l
      ```

    * Connect to a node  
      ```bash
      $cn [num]
      ```
