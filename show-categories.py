#!/usr/bin/env python

import yaml

import sys

def main():
    if len(sys.argv) == 1:
        print("usage:", sys.argv[0], "<...yaml-files>")
        sys.exit(1)

    files = sys.argv[1:]

    for file in files:
        data = yaml.safe_load(open(file))

        print(file)
        for round in data['rounds']:
            for cat in round['categories']:
                print("     ", cat['name'])



if __name__=="__main__":
    main()
