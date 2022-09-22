#!/usr/bin/env python 
#pylint: disable=invalid-name
'''
Takes a properties file and inserts key=value pairs into the specified Dockerfile as ARGs
'''

import argparse
import os.path as path
#os.path.dirname(path)

def insert_args():
    ''' do the conversion '''
    outputFileName = args.dockerfile + "-with-ARGs"
    with open(args.propFile) as pfh, open(args.dockerfile) as dfh, open(outputFileName, 'w') as ofh:
        dfContent = dfh.readlines()
        insertPoint = -1
        for index, line in enumerate(dfContent):
            if line.startswith('FROM') and insertPoint == -1:
                insertPoint = index
                print(line.rstrip(), file=ofh)
                print(file=ofh) # blank line
                print("# ARGS inserted using docker-repo/scripts/env2args.py script", file=ofh)
                for line in pfh:
                    if not line.startswith("#") and '=' in line:
                       print('ARG ' + line.rstrip(), file=ofh)
            else:
                print(line.rstrip(), file=ofh)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='convert property file contents to Dockerfile ARGs')
    parser.add_argument('-p', '--propFile', help="full path to .props (e.g., site-admin.props) file" , required=True)
    parser.add_argument('-d', '--dockerfile', help="full path to Dockerfile", required=True)

    args = parser.parse_args()

    insert_args()

