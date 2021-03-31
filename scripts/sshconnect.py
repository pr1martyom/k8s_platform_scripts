#!/usr/bin/python

import yaml
import os
import sys

f = open(sys.argv[1])
yaml_file = yaml.safe_load(f)
for svr in yaml_file:
   result = os.system("ssh -q vagrant@svr['box']['name'] exit; echo $? ")
   print result