#!/usr/bin/env bash

set -e

COMMIT_MESSAGE_PREFIX="docs(doc): "
COMMIT_MESSAGE="open-falcon"

function usage()
{
    cat<<EOF
$0 [commit_message]
EOF
    exit 1;
}

function nslib_log()
{
    local level="$1"
    local msg="$2"

    case $level in
        error)          echo -e "\033[41;30;1m[ERROR] ${msg}\033[0m";;
        warn|warning)   echo -e "\033[43;30;1m[WARNING] ${msg}\033[0m";;
        info)           echo -e "\033[47;30;1m[INFO] ${msg}\033[0m";;
        debug)          echo "[DEBUG] ${msg}";;
        *)              echo "[NOTSET] ${msg}";;
    esac
}

if [ $# -eq 0 ]; then
    :
elif [ $# -eq 1 ]; then
    case "$1" in
        -h | -H | --help)
            usage;
            ;;

        *)
            COMMIT_MESSAGE="$1"
            ;;
    esac
else
    usage;
fi

nslib_log "info" "git add -A"
git add -A

nslib_log "info" "git status"
git status

nslib_log "info" "git commit"
git commit -m "${COMMIT_MESSAGE_PREFIX}${COMMIT_MESSAGE}"

nslib_log "info" "git log -n 1 --stat"
git log -n 1 --stat

nslib_log "info" "git push"

read -e -p "是否继续[Y/N]? " -i "Y" answer
case $answer in
Y | y | yes | YES | Yes)
    git push
    ;;
*)
    nslib_log "error" "放弃提交"
    exit 1;
    ;;
esac
