# isp3backup
A backup script for websites, databases and other stuff on ISPConfig 3 servers

ISPConfig default backup tool is good but not completed. For this reason, this script can be useful: it backup other things than databases and websites
as Let's Encrypt files, /vmail directory or Apache2 config. It can also put your backup to another server using FTP. 
I hope it will help you as it helps me in my dailies backup management.

## How use this script
1. Save this script somewhere on your server (`/usr/bin` for me);
2. Create the backup directory (root mode);
3. Edit the script, set the variables and be careful about everything;
4. Execute the file using `sh isp3backup.sh`;

All logs are put in the console and on a single log file create by script (`var/log/isp3backup/YYYY-MM-DD.log`)
You can execute the script using a cron task. 
For that, edit your cron tab using `sudo crontab -e`. Be sure that the file is executable using `chmod +x {YOUR SCRIPT PATH}`

## What this script does
This script can help you in your daily backups. 
Here are the files and directories include in the backup file:

- ISPConfig HTTPD Log (/var/log/ispconfig/httpd)
- Apache2 config files (/etc/apache2/sites-available and /etc/apache2/sites-enabled)
- All your websites (/var/www/clients)
- Your mail directories (/var/vmail)
- System users and groups created by ISPConfig
- Let's Encrypt directory
- Pure-FTPd directory
- ispconfig core files (contains user passwords)

All files are compressed in a .tar.gzip file. 
By default, only one daily backup is keeped on server as you can send it via FTP.

## Editable variables

Directories backed-up: 
- `CLIENTSDIR="/var/www/clients"`: Your website directory
- `MAILDIR="/var/vmail"`: Your mails directory
- `LETSENCRYPTDIR="/etc/letsencrypt"`: Let's Encrypt directory
- `HTTPDIR="/var/log/ispconfig/httpd"`: Log for ISPConfig HTTPD
- `APACHE2DIR="/etc/apache2"`: Apache2 directory
- `PUREFTPDDIR="/etc/pure-ftpd"`: pure-ftpd directory
- `ISPCONFIG CORE FILES="/usr/local/ispconfig/server/scripts/ispconfig_update.sh /usr/local/ispconfig/server/lib/config.inc.php /usr/local/ispconfig/interface/lib/config.inc.php"`: ispconfig core files


Directories used by script:
- `BACKUPDIR="/storage/ispbackup"`: Directory where backup will be saved. **Please create it before proceed !**
- `LOGDIR="/var/log/isp3backup"`: Directory where log will be saved. Created by script
- `TMPDIR="/storage/ispbackup_tmp"`: Temporary directory. Created and deleted by script

SQL variables:
- `DBUSER="XX"`: The user used by the script for backing-up. Please be sure this user has the right to proceed.
- `DBPASS="XX"`: You know what
- `DBCHECK=1`: Enable database check and fix any errors found

FTP configuration:
- `FTPBACKUP=1`: Enable FTP backup if set to 1. If you want to deactivate this option, set to 0 (default: 1)
- `FTPMAXBACKUP=2`: Max number of backups keeped on remote server (default: 2)
- `FTPHOST='XX'`: Your FTP Host
- `FTPUSER='XX'`: FTP User
- `FTPPASSWD='XX'`: FTP Password
- `FTPBACKUPDIR='ispconfig_backup'` FTP Backup directory, where backups will be saved. **Please create it before proceed**

# isp3restore
A restore script for websites, databases and other stuff on ISPConfig 3 servers

## How use this script
1. Save this script somewhere on your server (`/usr/bin` for me);
2. Create the backup directory (root mode);
3. Edit the script, set the variables and be careful about everything;
4. Execute the file using `sh isp3restore.sh YYYY-MM-DD`;


## Authors
The script was originaly created by **Ioannis Sannos** in 2010 (http://www.isopensource.com) and published under GPL Licence. 
It was updated by **Alex Ward** in 2012 (https://www.geekonthepc.com/tag/ispc3backup/).
It was updated by **jcosic** in 2018 (https://github.com/jcosic/isp3backup).
I updated in 2024, add mysql dump params (--single-transaction --routines --triggers --databases --add-drop-database) added minor comments, awk changes and explanation, some checks and flags for more control. Also created isp3restore.sh to recover data on a new installation