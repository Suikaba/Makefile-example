#!/bin/sh

if [ $# -ne 1 ]; then
    echo "invalid parameter" 1>&2
    exit 1
fi

if [ $1 = "debug" ]; then
    BUILD_PATH=build/debug
    BIN_PATH=bin/debug
elif [ $1 = "release" ]; then
    BUILD_PATH=build/release
    BIN_PATH=bin/release
elif [ $1 != "clean" ]; then
    echo "invalid parameter" 1>&2
    exit 1
fi

export BUILD_PATH
export BIN_PATH

make $1
