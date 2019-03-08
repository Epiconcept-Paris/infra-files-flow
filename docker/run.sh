#!/bin/bash

source ~/bin/public/bashlibs/docker.lib.sh

id=$(docker run -d --name filesflow_files tests_ssh:latest)
cntip $id
id=$(docker run -d --name filesflow_front tests_ssh:latest)
cntip $id