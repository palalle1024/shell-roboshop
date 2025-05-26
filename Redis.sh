#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

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
            echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
        else 
            echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE 
            exit 1
        fi 
}

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disabling Default Redis version"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "enabling Redis:7"

dnf install redis -y  &>>$LOG_FILE
VALIDATE $? "installing redis"

sed -i  -e 's/127.0.0.1/0.0.0.0/g'  -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf  &>>$LOG_FILE
VALIDATE $? "Edited redis.conf to accept remote connections"

systemctl enable redis &>>$LOG_FILE
systemctl start redis &>>$LOG_FILE
VALIDATE $? "starting redis"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully,  $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE




