#!/bin/bash
#Purpose: Download then try to extract data from MMS messages
#Depends: curl, recoverjpeg, libnotify-bin, sox

#Proxy URL / Port
#This is the mms apn settings from you service provider
#You can probably find them in /us:wqr/share/mobile-broadband-provider-info/apns-conf.xml
PROXYURL="proxy.mobile.att.net"
PROXYPORT="80"

#Where to store the mms files
MMS_STORE_DIR="/home/manjaro/mms"
MMS_WORK_DIR="$MMS_STORE_DIR/temp"
DOWNLOAD_LIST="$MMS_WORK_DIR/download.list"

#Alert/notification sound file (must be playable with the "play" command)
SOUND_FILE="/usr/share/sounds/librem5/stereo/message-new-instant.oga"

#Modem number using in mmcli -m 
MODEM_NUM="1";
#Interface as found in ip addr (must be connected with data to the service provider network)
INTERFACE="wwan0";

#Date Format for the saved files.
DATE=$(date +%d-%m-%y_%H-%M)

echo "checking and making dirs"
if [ ! -d $MMS_STORE_DIR ]; then mkdir -p $MMS_STORE_DIR; fi
if [ ! -d $MMS_WORK_DIR ]; then mkdir -p $MMS_WORK_DIR; fi

function get_modem_messages() {
    for SMSNUM in $(mmcli -m $MODEM_NUM --messaging-list-sms |grep "received" | cut -f 6 -d '/' | awk '{print $1}')
    do
        mmcli -m $MODEM_NUM -s $SMSNUM --create-file-with-data=$MMS_WORK_DIR/$SMSNUM.sms
        mmcli -m $MODEM_NUM --messaging-delete-sms $SMSNUM;
    done
}

function build_download_list() {
    if [ -f $DOWNLOAD_LIST ]; then  rm $DOWNLOAD_LIST; fi
    for file in $(ls $MMS_WORK_DIR/*.sms)
    do
        FROM=$(cat -v $file |sed "s/\^C/\n/ig" |sed "s/\^@/\n/ig"|grep -E "\+[0-9]{9}" |head -1 )
        FROM=${FROM%/*}
        DOWNLOAD=$(cat -v $file |sed "s/\^C/\n/ig" |sed "s/\^@//ig"|grep "htt.*/"|head -1)
        FILENAME=$(basename -s .sms "$file")
        echo "$FILENAME|$FROM|$DOWNLOAD" >> $DOWNLOAD_LIST
    done
    #rm "$MMS_WORK_DIR/*.sms"
    mkdir -p $MMS_WORK_DIR/$DATE
    mv $MMS_WORK_DIR/*.sms $MMS_WORK_DIR/$DATE
}

function download_messages() {
    for message in $(cat $DOWNLOAD_LIST)
    do
        DOWNLOAD=${message#*|*|}
        FILENAME=${message%|*|*}
        echo "$FILENAME"
        FROM=${message#*|}
        FROM=${FROM%|*}
        export FROM
        curl --interface $INTERFACE --proxy $PROXYURL:$PROXYPORT "$DOWNLOAD" -o $MMS_WORK_DIR/$FILENAME.mms
        mkdir -p $MMS_STORE_DIR/$FILENAME_$DATE/
        echo "FROM: $FROM" > $MMS_STORE_DIR/$FILENAME_$DATE/$FILENAME.info
        TO=$(cat -v $MMS_WORK_DIR/$FILENAME.mms |sed "s/.*\^@.[0-9]//ig"|sed "s/\^W/\n/ig"|sed "s/\/.*//ig"|grep -E "\+[0-9]{9}.*"|tr "\n" " ")
        echo "TO: $TO" >> $MMS_STORE_DIR/$FILENAME_$DATE/$FILENAME.info
        echo "MESSAGE:" >> $MMS_STORE_DIR/$FILENAME_$DATE/$FILENAME.info
        echo $(cat -v $MMS_WORK_DIR/$FILENAME.mms |tail -1 |grep "text"|sed "s/.*.txt\^@//ig") >> $MMS_STORE_DIR/$FILENAME_$DATE/$FILENAME.info
        recoverjpeg -b1 $MMS_WORK_DIR/$FILENAME.mms -o $MMS_STORE_DIR/$FILENAME_$DATE -f $FILENAME.jpg

    done
    #rm "$MMS_WORK_DIR/*.mms"
    mv $MMS_WORK_DIR/*.mms $MMS_WORK_DIR/$DATE
}
    
    
IP=$(ip a show dev wwan0 | grep "inet" | head -n 1)
if [ -z "$IP" ] ; then
    echo "I have no cellular IP address! Please connect to mobile data"
    notify-send "I have no cellular IP address! Please connect to mobile data"
    play $SOUND_FILE &> /dev/null
    exit
else
    echo "getting messages from modem"
    get_modem_messages
    echo "checking for messages"
    file_check=`ls -1 $MMS_WORK_DIR/*.sms 2>/dev/null | wc -l`
    if [ $file_check != 0 ]; then 
        echo "making download list"
        build_download_list;
        echo "Downloading mms messages and extracting data"
        download_messages;
        notify-send "MMS Downloaded from $FROM"
        paplay $SOUND_FILE
    fi
fi
