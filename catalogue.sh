#!/bin/bash

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

dnf module disable nodejs -y &>>LOG_FILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>LOG_FILE
VALIDATE $? "Enabling nodejs:20"

dnf install nodejs -y &>>LOG_FILE
VALIDATE $? "Installing nodejs:20"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "system user roboshop already created  ... $Y SKIPPING $N"
fi


mkdir -p /app 
VALIDATE $? "Creating app Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>LOG_FILE
VALIDATE $? "Downloading Catalogue"

rm -rf /app/*
cd /app &>>LOG_FILE
unzip /tmp/catalogue.zip &>>LOG_FILE
VALIDATE $? "Unzipping catalogue"

npm install &>>LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>LOG_FILE
VALIDATE $? "copying catalogue.service"


systemctl daemon-reload
systemctl enable catalogue 
systemctl start catalogue &>>LOG_FILE
VALIDATE $? "Starting catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>LOG_FILE
VALIDATE $? "copying mongoDB repo"

dnf install mongodb-mongosh -y &>>LOG_FILE
VALIDATE $? "Installing Mongodb client"


STATUS=$(mongosh --host mongodb.palalle.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.palalle.site </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi



