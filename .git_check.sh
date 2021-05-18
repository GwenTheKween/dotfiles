#! /bin/bash

check_compile(){
    if [[ "$#" -eq 0 ]]
    then
        echo "usage: $0 <start> [<finish>]"
        echo ""
        echo "this will checkout to every commit starting from <start> commits back, until <finish> commits back, and attempt to do a full system build at every point, warning you of points where compilation failed"
        echo "if <finish> is not defined, the check works until HEAD"
        return 0
    fi

    start=$1
    if [[ "$2" -ge 2 ]]; then
        finish=$2
    else
        finish=0
    fi

    if [[ $start -le $finish ]]; then
        echo "range with size 0 or negative. Have you inverted the parameters?"
        return 1
    fi

    curr_commit=$(git rev-parse --short HEAD)
    for ((i=$start; i >= $finish; i--)); do
        git checkout HEAD~$i 2>/dev/null
        #this will be changed for compiling
        make -j 32 >/dev/null
        if [ $? -ne 0 ]; then
            echo "compilation failed in commit $(git rev-parse --short HEAD)"
        fi
        #move back to original spot
        git checkout $curr_commit 2>/dev/null
    done
}
