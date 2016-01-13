#!/bin/sh

CDIR=`dirname $0`

usage() {
    echo "usage : $0 cmd
    
    cmd in :

    installdep      : install packages from your distribution
    perlmodules     : install cpan modules
    dbinstall       : install the database with a password provided by \$PATH
    dbreinstall     : reinstall the database with a password provided by \$PATH
    all             : do the full installation
" 2>&1

    exit 1
}

if [ $# -lt 1 ] ; then
    usage
fi

# install required applications
installdep_f() {
    sudo apt-get update
    cat ${CDIR}/dependancies.ubuntu | xargs sudo apt-get install
}

# install Perl modules
perlmodules_f() {
    cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
    cat ${CDIR}/perlmodules | xargs cpanm
}

# SQL
dbinstall_core_f() {
    mysql -u root --password="${PASS}" < ${CDIR}/sql/init-create-user.sql
    mysql -u root --password="${PASS}" < ${CDIR}/sql/init-create-db.sql
    mysql -u root --password="${PASS}" < ${CDIR}/sql/init-grant-user.sql
    mysql -u root --password="${PASS}" < ${CDIR}/sql/init-tables.sql
}

dbinstall_f() {
    PASS=${PASS-notsodummy}
    dbinstall_core_f
}

dbreinstall_f() {
    PASS=${PASS-notsodummy}
    mysql -u root --password="${PASS}" < ${CDIR}/sql/remove-db.sql
    mysql -u root --password="${PASS}" < ${CDIR}/sql/remove-user.sql
    dbinstall_core_f
}

case $1 in
    installdep)     installdep_f    ;;
    perlmodules)    perlmodules_f   ;;
    dbinstall)      dbinstall_f     ;;
    dbreinstall)    dbreinstall_f   ;;
    all)
        installdep_f
        perlmodules_f
        dbinstall_f
        ;;
    *)              usage           ;;
esac
