#!/bin/bash

PASS="not-so-dummy"

mysql -u root --password=${PASS} < remove-db.sql
mysql -u root --password=${PASS} < remove-user.sql
mysql -u root --password=${PASS} < init-create-db.sql
mysql -u root --password=${PASS} < init-create-user.sql
mysql -u root --password=${PASS} < init-grant-user.sql
mysql -u root --password=${PASS} < init-tables.sql
