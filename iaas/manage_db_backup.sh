#!/bin/bash

REMOTE_TOOLS_FOLDER="/home/ubuntu/db-tools"
REMOTE_BACKUP_LOCATION="/mnt/disk1"

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") -h | -l | -c | -r index

This script can be used to manage the database backups.
It can list all available backups, create a new one, or restore a specific backup.

-h,         Prints this message to the console
-l,         List all available backups
-c,         Create a new backup 
-r index,   Restore the backup with the specified index

EOF
  exit
}

create() {
    echo "Creating new backup..."

    ssh ubuntu@$FLOATING_IP -i ~/.ssh/ssh_admin "$REMOTE_TOOLS_FOLDER/backup_db.sh"

    if [[ $? -eq 0 ]] 
    then
        echo "Backup created correctly!"
    else
        echo "Error while creating backup"
    fi
    exit
}

list(){
    re='s/^db-backup-([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}).sql$/\1/p'
    i=1
    echo "Fetching list..."
    avail=`ssh ubuntu@$FLOATING_IP -i ~/.ssh/ssh_admin "ls $REMOTE_BACKUP_LOCATION" | sed -nr $re`
    echo "Available backups"
    while IFS= read -r line; do
        d=`date --date=$line "+%d/%m/%Y %H:%M:%S"`
        printf "$i:\t$d\n"
        ((i=i+1))
    done <<< "$avail"
    exit
}

restore(){
    echo "Fetching list..."
    if [[ ! -z $DB_TO_RESTORE ]]
    then 
        re='^[0-9]+$'
        if ! [[ $DB_TO_RESTORE =~ $re ]] ; then
            printf "The index parameter needs to be an integer\n\n"
            usage
        else
            re='s/^db-backup-([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}).sql$/\1/p'
            i=1

            avail=`ssh ubuntu@$FLOATING_IP -i ~/.ssh/ssh_admin "ls $REMOTE_BACKUP_LOCATION" | sed -nr $re`
            while IFS= read -r line; do
                if [[ $i -eq $DB_TO_RESTORE ]]
                then
                    found=1
                    d=`date --date=$line "+%d/%m/%Y %H:%M:%S"`
                    break
                fi
                ((i=i+1))
            done <<< "$avail"

            if [[ -z $found ]]
            then
                echo "The specified index does not exist"
            else
                og_filename="db-backup-$line.sql"
                printf "Selected backup is dated: $d\n"
                printf "Its original filename is: $og_filename\n"
                printf "Are you sure you want to restore it? (y/n): "
                read choice
                if [[ $choice = 'y' ]]
                then
                    ssh ubuntu@$FLOATING_IP -i ~/.ssh/ssh_admin "$REMOTE_TOOLS_FOLDER/restore_db.sh $og_filename"

                    if [[ $? -eq 0 ]] 
                    then
                        echo "Backup restored correctly!"
                    else
                        echo "Error while restoring backup"
                    fi
                else
                    echo "No backup was restored"
                    exit
                fi
            fi
        fi
    else
        echo "No index specified"
    fi
    exit
}



while getopts :lchr: flag
do
    case "${flag}" in
        l) list ;;
        c) create ;;
        r) DB_TO_RESTORE=${OPTARG} restore;;
        h) usage && exit;;
        *) usage && exit;;
    esac
done

# No parameter was passed
usage

