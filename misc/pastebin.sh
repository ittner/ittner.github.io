#!/bin/sh

#
# pastebin.sh - Paste code in pastebin.com from command line
# http://www.ittner.com.br/ -- This code is released in public domain.
#
#
#
# Usage: pastebin.sh [expire time]
#
#   Reads data from stdin and puts in a new pastebin; printas a link to
#   stdout. Expire time, if not given, will be "1D" (for one day). Other
#   valid values are:
#
#       N   = Never
#       10M = 10 Minutes
#       1H  = 1 Hour
#       1D  = 1 Day
#       1W  = 1 Week
#       2W  = 2 Weeks
#       1M  = 1 Month
#
#


API_KEY="485a7d3a87c4b208b0fad34ea0f9bbc2"

ARG=$1
case $ARG in
    N|10M|1H|1D|1W|2W|1M)
        EXPIRE_TIME=$ARG
        ;;
    "")
        EXPIRE_TIME="1D"
        ;;
    *)
        echo Invalid expire time >&2
        exit 1
        ;;
esac


curl \
    -F "api_option=paste" \
    -F "api_user_key=" \
    -F "api_paste_private=1" \
    -F "api_paste_name=" \
    -F "api_paste_expire_date=$EXPIRE_TIME" \
    -F "api_paste_format=text" \
    -F "api_dev_key=$API_KEY" \
    -F "api_paste_code=<-" \
    http://pastebin.com/api/api_post.php
R=$?

echo ""
exit $R

