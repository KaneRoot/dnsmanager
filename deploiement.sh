#!/bin/bash

# install applications
sudo apt-get install mysql-server # bind9

# Get libs
bash ./get_libs.sh

# db install
mysql -u root -p < init.sql
