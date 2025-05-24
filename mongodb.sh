#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="var/log/shellscript-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER 
echo "script started executing at: $(date)" | tee -a $LOG_FILE 

if [ $USERID -ne 0 ]
then 
     echo -e "$R ERROR:: Please run this script with root user access $N" | tee -a $LOG_FILE
     exit 1 # give other 0 upto 127 
else 
    echo "You are running with  root access" | tee -a $LOG_FILE
fi 

#validate function takes input as exit status, what command they tried to install or execute
VALIDATE () {
        if [ $1 -eq 0 ]
        then 
            echo -e "Installing $2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
        else 
            echo -e "Installing $2 is ... $R FAILURE $N" | tee -a $LOG_FILE 
            exit 1
        fi 
}


cp mongodb.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying MongoD repo"

dnf install mongodb-org -y
VALIDATE $? "Installing mongodb server"

systemctl enable mongod
VALIDATE $? "Enabling MongoDB"

systemctl start mongodb
VALIDATE $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf 
VALIDATE $? "Editing MongoDB for remote connections"

systemctl restart mongod 
VALIDATE $? "Restarting MongoDB"





















