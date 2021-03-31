#!/usr/bin/python

import yaml
import os
import sys


def ssh_check():
   result=0
   f = open(sys.argv[1])
   yaml_file = yaml.safe_load(f)
   for svr in yaml_file:
     result = os.system("ssh -q vagrant@"+svr['box']['name']+ " exit" )
     return(result)
   return (0) 

print ssh_check()