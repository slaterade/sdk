#!/bin/sh
if test -z "$1"
then
    WORKDIR=$(pwd)
else
    WORKDIR=$1
fi
echo "sdk -> $WORKDIR ..."
docker run --rm -it -v ${WORKDIR}:${WORKDIR} -v ${HOME}/.gitconfig:/home/slaterade/.gitconfig slaterade/sdk:latest /usr/bin/zsh -c "cd ${WORKDIR} && nvim ."

