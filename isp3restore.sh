#!/bin/sh
#
# THIS SCRIPT HAS BEEN UPDATED BY ALESSANDRO PERAZZETTA (https://github.com/AlessandroPerazzetta/). PLEASE SEE
# BELOW FOR ORIGINAL SCRIPT AUTHORS.
#
# ISPConfig3 restore script
#
# description: A restore script for sites and databases on ISPConfig 3 servers
# Add this script in cron tab in order to be executed once per day.
# /usr/bin/isp3backup.sh YYYY-MM-DD

## For log, precede with date
dateStatement(){
    date +'%F %H:%M:%S'
}

## Do not edit this section
SCRIPTVERSION="1.2"


if [ -z "$1" ]; then
    echo "Error: Argument is missing."
    echo "Pass YYYY-MM-DD, year sorted, eg. 2009-11-21 as backup filename to restore."
    exit 1
fi
FDATE=$1		# Full Date, YYYY-MM-DD, year sorted, eg. 2009-11-21

## End of non-editable variables

## Start user editable variables
CLIENTSDIR="/var/www/clients" 		# directory where ICPConfig 3 clients folders are located
MAILDIR="/var/vmail"					# mail directory
LETSENCRYPTDIR="/etc/letsencrypt"   #letsencrypt directory
HTTPDIR="/var/log/ispconfig/httpd" #httpd directory
APACHE2DIR="/etc/apache2"  #apache dir
PUREFTPDDIR="/etc/pure-ftpd"   #pure-ftpd directory

BACKUPDIR="/storage/ispbackup"                  # backup directory
LOGDIR="/var/log/isp3backup"   #log directory
TMPDIR="/storage/ispbackup_tmp"             # temp dir for database dump and other stuff

DBUSER=""						 # database user
DBPASS=""				# database password


## End user editable variables

if [ ! -d $LOGDIR/ ] ; then
  mkdir $LOGDIR/
fi

message="Start restore ... "
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

########### Start make and check needed directories #############

message="Checking directories exist..."
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

###### Start backup directory verification
if [ ! -d $BACKUPDIR/ ] ; then
  message="Backup directory doesn't exist. Please create it before proceed."
  echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log
  exit 0
fi
###### End backup directory verification

###### Start temp directory creation

message="Temp directory verification"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

if [ ! -d $tmpdir/ ] ; then
  mkdir $tmpdir/

  message="Temp directory created."
  echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log
fi
###### End temp directory creation


########### Start decompression #############
message="Start decompression"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log
rm -rf $BACKUPDIR/OUT
mkdir -p $BACKUPDIR/OUT
tar -zxf $BACKUPDIR/$FDATE.tar.gz -C $BACKUPDIR/OUT --overwrite

message="Decompression completed"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log
########### End compression #############

BACKUPOUTDIR=$(find $BACKUPDIR/OUT/ -type d -name "$FDATE" -print -quit)

if [ ! -d $BACKUPOUTDIR/ ] ; then
  message="Backup output directory not exist, something wrong happened."
  echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log
  exit 1
fi
echo "$BACKUPOUTDIR content:"
ls -1 "$BACKUPOUTDIR"

#cd "$(find $BACKUPDIR/OUT/ -type d -name "$FDATE" -print -quit)"
#find $BACKUPDIR/OUT/ -type d -name "$FDATE" -exec bash -c 'cd "{}" && exec bash' \;

########### Start ispconfig/httpd restore #############

message="Start Ispconfig/httpd restore"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

tar -zxf $BACKUPOUTDIR/httpd/httpd.tar.gz -C / --overwrite

message="Ispconfig/httpd restore completed"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

########### End ispconfig/httpd restore #############

########### Start apache2 restore #############

message="Start Apache2 restore"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

tar -zxf $BACKUPOUTDIR/apache2/sites-available.tar.gz -C / --overwrite
tar -zxf $BACKUPOUTDIR/apache2/sites-enabled.tar.gz -C / --overwrite

message="Apache2 restore completed"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

########### End apache2 restore #############

########### Start databases restore #############
message="Start MySQL databases restore"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

message="Logged in as user: "$DBUSER
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

## Starting database restore
for dbarchive in $BACKUPOUTDIR/db/*.tar.gz; do
  tar -zxf "$dbarchive" -O | mysql -u$DBUSER -p$DBPASS
  message=$dbarchive" restored"
  echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log
done

message="MySQL databases restore completed"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

message="Please remind to update MySQL ispconfig password with old stored password from, or set from newly installed system:"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

## Tips message to update ispconfig SQL user password on DB and CODE:
message="\n\t*** Edit following files ***\n
/usr/local/ispconfig/server/lib/config.inc.php\n
/usr/local/ispconfig/interface/lib/config.inc.php\n
\t*** Search for db section ***\n
\$conf['db_user'] = 'ispconfig';\n
\$conf['db_password'] = 'long_string_password';\n
\t*** Alter SQL user command ***\n
ALTER USER 'ispconfig'@'localhost' IDENTIFIED BY 'long_string_password';\n\n"
echo "$message"

file="/usr/local/ispconfig/server/lib/config.inc.php"    
# Search for the string $conf['db_password'] = in the file    
result=$(grep "\$conf\['db_password'\] =" "$file")    
# Display the search result    
echo "Use backup password and replace current password from $file:\n\t$result"

file="/usr/local/ispconfig/interface/lib/config.inc.php"    
# Search for the string $conf['db_password'] = in the file    
result=$(grep "\$conf\['db_password'\] =" "$file")    
# Display the search result    
echo "Use backup password and replace current password from $file:\n\t$result"

# Wait for user to press a key
# read -n 1 -s -r -p "Press any key to continue"
read -p "Press Enter to continue" key

########### End databases restore #############

########### Start websites restore #############
message="Start websites restore"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

clientslist=`ls $BACKUPOUTDIR/webs/ | grep ^client`
for client in $clientslist; do
  if [ ! -d $CLIENTSDIR/$client/ ] ; then
  # create sub-directory for this client
    message="Sub-directory creation: $CLIENTSDIR/$client/"
    echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log
    mkdir -p $CLIENTSDIR/$client
    message="Sub-directory created"
    echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log
  
  # list all websites for this client
    # webslist=`ls $BACKUPOUTDIR/webs/$client/ | grep ^web`
    webslist=$(ls $BACKUPOUTDIR/webs/$client/ | grep ^web | sed 's/\.tar\.gz//')
    for web in $webslist; do
      if [ ! -d $CLIENTSDIR/$client/$web/ ] ; then
        mkdir $CLIENTSDIR/$client/$web/
        tar -zxf $BACKUPOUTDIR/webs/$client/$web.tar.gz -C $CLIENTSDIR/$client/$web/ --overwrite

        message="Website backup completed $client/$web"
        echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log
      fi
    done
  fi
done

message="All websites restore completed"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log
########### End websites restore #############

########### Start mails restore #############
message="Start email restore"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

mailslist=$(ls $BACKUPOUTDIR/vmail/ | sed 's/\.tar\.gz//')
for mail in $mailslist; do
  if [ ! -d $MAILDIR/$mail/ ] ; then
    mkdir -p $MAILDIR/$mail/

    tar -zxf $BACKUPOUTDIR/vmail/$mail.tar.gz -C $MAILDIR/$mail/

    message="Mail restoresd: "$mail
    echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log
  fi
done

message="Emails restore completed"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log
########### End mails restore #############

########### Start users restore #############
message="Start users restore"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

# export UGIDLIMIT=5000
# awk -v LIMIT=$UGIDLIMIT -F: '($3>=LIMIT) && ($3!=65534)' /etc/passwd > $BACKUPDIR/$FDATE/users/passwd.bk
# awk -v LIMIT=$UGIDLIMIT -F: '($3>=LIMIT) && ($3!=65534)' /etc/group > /$BACKUPDIR/$FDATE/users/group.bk
# awk -v LIMIT=$UGIDLIMIT -F: '($3>=LIMIT) && ($3!=65534) {print $1}' /etc/passwd | tee - |egrep -f - /etc/shadow > $BACKUPDIR/$FDATE/users/shadow.bk
# awk -v LIMIT=$UGIDLIMIT -F: '($3>=LIMIT) && ($3!=65534) {print $1}' /etc/passwd | tee - |egrep -f - /etc/gshadow > $BACKUPDIR/$FDATE/users/gshadow.bk

cp /etc/passwd /etc/passwd.BAK
cp /etc/group /etc/group.BAK
cp /etc/shadow /etc/shadow.BAK
cp /etc/gshadow /etc/gshadow.BAK

cat $BACKUPOUTDIR/users/passwd.bk >> /etc/passwd
cat $BACKUPOUTDIR/users/group.bk >> /etc/group
cat $BACKUPOUTDIR/users/shadow.bk >> /etc/shadow
cat $BACKUPOUTDIR/users/gshadow.bk >> /etc/gshadow

message="Users restore completed"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

########### End user restore #############

########### Start let's encrypt restore #############

message="Start LetsEncrypt restore"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

tar -zxf $BACKUPOUTDIR/letsencrypt/letsencrypt.tar.gz -C / --overwrite

message="LetsEncrypt restore completed"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

########### End let's encrypt restore #############

########### Start pure-ftpd restore #############

message="Start Pure-FTPd restore"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

tar -zxf $BACKUPOUTDIR/pure-ftpd/pure-ftpd.tar.gz -C / --overwrite

message="Pure-FTPd restore completed"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

########### End pure-ftpd restore #############

########### Start ispconfig core restore #############

message="Start ispconfig core restore"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

cp /usr/local/ispconfig/server/scripts/ispconfig_update.sh /usr/local/ispconfig/server/scripts/ispconfig_update.sh.ORI_PRE_RESTORE
cp /usr/local/ispconfig/server/lib/config.inc.php /usr/local/ispconfig/server/lib/config.inc.php.ORI_PRE_RESTORE
cp /usr/local/ispconfig/interface/lib/config.inc.php /usr/local/ispconfig/interface/lib/config.inc.php.ORI_PRE_RESTORE
tar -zxf $BACKUPOUTDIR/ispconfig.tar.gz -C / --overwrite

message="ispconfig core restore completed"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

########### End ispconfig core restore #############


# all done

message="Process completed. See you tomorrow"
echo $(dateStatement) $message | tee -a $LOGDIR/$FDATE.log

exit 0
