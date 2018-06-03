#!/usr/bin/env python3

import argparse
import yaml
import os

from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--inventory", required=True, help="Ansible inventory file")
parser.add_argument("--known-hosts", default=os.path.join(Path.home(), ".ssh", "known_hosts"), help=".ssh known_hosts file path")
args = parser.parse_args()

config = yaml.load(open(args.inventory, "rt"))

remove_cmd = "ssh-keygen -f \"{known_hosts}\" -R {ip}"

for host in config["all"]["hosts"].values():
    os.system(remove_cmd.format(known_hosts=args.known_hosts, ip=host["ansible_host"]))
