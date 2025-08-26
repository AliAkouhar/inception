#!bin/bash

service mariadb start

sleep 5

mysql -u root -p <<EOF
    CREATE DATABASE 
EOF