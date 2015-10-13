#!/bin/bash

# install applications
sudo apt-get install mysql-server # bind9

# Get libs
bash ./get_libs.sh

# db install
mysql -u root --password="${PASS}" < init-create-user.sql
mysql -u root --password="${PASS}" < init-create-db.sql
mysql -u root --password="${PASS}" < init-grant-user.sql
mysql -u root --password="${PASS}" < init-tables.sql
