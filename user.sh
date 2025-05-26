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


dnf module disable nodejs -y  &>>$LOG_FILE
VALIDATE $? "disabling  default nodejs"

dnf module enable nodejs:20 -y  &>>$LOG_FILE
VALIDATE $? "enabling nodejs:20"

dnf install nodejs -y  &>>$LOG_FILE
VALIDATE $? "Installing nodejs:20" 

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating the roboshop system  user"
else 
    echo -e "System user roboshop  already created ... $Y SKIPPING $N"
fi 

 mkdir  -p /app 
 VALIDATE $? "Creating app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
VALIDATE $? "Downloading user"


rm -rf /app/*  &>>$LOG_FILE
cd /app 
unzip /tmp/user.zip  &>>$LOG_FILE
VALIDATE $? "Unzippiing user"

npm install   &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service  &>>$LOG_FILE
VALIDATE $? "Copying user service"

systemctl daemon-reload  &>>$LOG_FILE
VALIDATE $? "Reloading"

systemctl enable user  &>>$LOG_FILE
VALIDATE $? "Enabling user"

systemctl start user
VALIDATE $? "Starting user"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully,  $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE




