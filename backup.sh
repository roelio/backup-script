#!/bin/bash

if [ -n $1 ]; then
    BACKUP_NAME=$1  # Name of backup (log file, dest dir, exclude)
else 
    exit 1
fi
if [ -n "$2" ]; then
    SRC=$2          # Source files (including host)
else 
    exit 1
fi
if [ -n "$3" ]; then
    BACKUP_REPO=$3  # Repository location
else 
    exit 1
fi
if [ -n "$4" ]; then
    SSH_COMMAND=$4  # Custom ssh command (like ssh -i keyfile -l remote_user)
else 
    SSH_COMMAND=""
fi
if [ -n "$5" ]; then
    EMAIL=$5        # Email for logging
else
    exit 1
fi


# Do not touch unless sure about it

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" 
DST="$BACKUP_REPO$BACKUP_NAME"
EXCLUDE="$DIR/$BACKUP_NAME.exclude"
LOG="$DIR/$BACKUP_NAME.log"
RSYNC_PATH="sudo /usr/bin/rsync"

DATE=`date +%Y-%m-%d`   # Full date 2012-12-31
DOW=`date +%w`          # Day of the week 1 is Monday
DOM=`date +%d`          # Date of the Month e.g. 27

if [ ! -d "$DST/current" ]; then
    mkdir -p $DST/current
fi
if [ ! -d "$DST/Daily" ]; then
    mkdir $DST/Daily
fi
if [ ! -d "$DST/Weekly" ]; then
    mkdir $DST/Weekly
fi
if [ ! -d "$DST/Monthly" ]; then
    mkdir $DST/Monthly
fi

if [ ! -d "$DST/incomplete" ]; then
    rm -rf $DST/incomplete
fi


# Monthly full backup
if [ $DOM = "01" ]; then
        DATE_DST=$DST/Monthly/`date +%B`

# Weekly full backup
elif [ $DOW = "5" ]; then
    	DATE_DST=$DST/Weekly/$DATE

# Make incremental backup - overwrite last weeks
else
	DATE_DST=$DST/Daily/`date +%A`
fi


rsync -e "$SSH_COMMAND" --rsync-path="$RSYNC_PATH" -az --numeric-ids --stats --human-readable --delete --exclude-from "$EXCLUDE" --delete-excluded --link-dest=$DST/current $SRC $DST/incomplete > $LOG 2>&1 && cat $LOG | mail -s "Rsync $BACKUP_NAME: success" $EMAIL || cat $LOG | mail -s "Rsync $BACKUP_NAME: failed" $EMAIL

if [ -d "$DATE_DST" ]; then
    rm -rf $DATE_DST
fi

mv $DST/incomplete $DATE_DST
rm -rf $DST/current 
ln -s $DATE_DST $DST/current
