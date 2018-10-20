#!/bin/bash

## Upload this script to gs://project-ops/mongo/startup-script.sh

# Capture standard out and standard error in this file
touch /var/log/capture.txt
exec &> /var/log/capture.txt


#write out crontab to change hostname
crontab -l > mycron
#echo new cron into cron file
echo '@reboot hostname $(curl --silent "http://metadata.google.internal/computeMetadata/v1/instance/attributes/hostname" -H "Metadata-Flavor: Google")' >> mycron
#install new cron file
crontab mycron
#remove cronfile
rm mycron

## Check if Startup-script has already run - exit if it has
# Check for presence of log file
if [ -f /var/log/startup-script.log ]
then
  echo "/var/log/startup-script.log exists"
  # Check for presence of 'fininhed' string (quiet grep, so there's no console output)
  if grep -q "STARTUP SCRIPT FINISHED" /var/log/startup-script.log
  then
    # Write to log and exit cleanly
    echo "Startup Script has already completed - exiting."
    echo "$(date) : Startup Script has already completed - exiting." >> /var/log/startup-script.log
    exit 0
  else
    # Something might be wrong later in this script
    echo "Startup Script has run, but may not have completed - Please investigate."
    echo "$(date) : Startup Script has run, but may not have completed - Please investigate." >> /var/log/startup-script.log
  fi
else
  echo "/var/log/startup-script.log doesn't exist"
fi


## Calculate timing and Create Log
# proc/uptime contains 2x values; uptime and seconds idle
procuptime=$(cat /proc/uptime)
# below command selects just the first value, without the decimal point values.
boottime=${procuptime%%.*}
# Save Script Start time (current time since epoch)
scriptstarttime=`date +%s`
# Create & Write log
touch /var/log/startup-script.log
cat >> /var/log/startup-script.log << EOT
########################## STARTUP SCRIPT STARTED ########################
Instance boot: $boottime seconds
Startup script started: $(date)
Script start time: $scriptstarttime seconds since epoch
##########################################################################
EOT

# Edit hosts file
echo "192.168.80.2 mongodb0.example.net" | sudo tee -a /etc/hosts
echo "192.168.80.3 mongodb1.example.net" | sudo tee -a /etc/hosts
echo "192.168.80.4 mongodb2.example.net" | sudo tee -a /etc/hosts

# Install MongoDb
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
sudo echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get install -y mongodb-org=2.6.9 mongodb-org-server=2.6.9 mongodb-org-shell=2.6.9 mongodb-org-mongos=2.6.9 mongodb-org-tools=2.6.9

# MongoDB Config

sudo mkdir -p /data/mongodb
sudo chown -R mongodb:mongodb /data/mongodb
sudo chmod 0775 /data/mongodb

# Update mongod config
sudo sed -i "s|bind_ip|#bind_ip|g" /etc/mongod.conf
sudo sed -i "s|#replSet=setname|replSet=rs0|g" /etc/mongod.conf
sudo sed -i "s|dbpath=/var/lib/mongodb|dbpath=/data/mongodb|g" /etc/mongod.conf


# Restart MongoDB Service
sudo service mongod restart
echo "$(date) : Completed restarting MongoDB service" >> /var/log/startup-script.log




## Calculate timings and write to log
# Save Script timings
scriptendtime=`date +%s`
scripttime=$((($scriptendtime) - ($scriptstarttime)))
totaltime=$((($boottime) + ($scripttime)))
cat >> /var/log/startup-script.log << EOT
######################### STARTUP SCRIPT FINISHED ########################
Startup Script has finished. It will not run again fully as long as the line above exists in this file.
Startup Script finished: $(date)
Instance boot: $boottime seconds
Instance Startup Script: $scripttime seconds
Boot + Startup Script: $totaltime seconds
Use these figures to set Cooldown or Initial Delay values.
##########################################################################
EOT
