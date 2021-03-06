#! /usr/bin/env bash
#
# zenoss_init_pre
#
# This script is intended to be run before the zenoss processes have

#
# Note: it is run by root
#
##############################################################################
#
# Copyright (C) Zenoss, Inc. 2007, all rights reserved.
#
# This content is made available according to terms specified in
# License.zenoss under the directory where your Zenoss product is installed.
#
##############################################################################

set -e
set +x

. ${ZENHOME}/install_scripts/install_lib.sh


# set the python shebang line
shebang

RABBITMQ_ADMIN="/usr/local/bin/rabbitmqadmin"
if [ ! -x "$RABBITMQ_ADMIN" ]; then
   if curl -s -o "$RABBITMQ_ADMIN" http://localhost:15672/cli/rabbitmqadmin; then
      chmod +x "$RABBITMQ_ADMIN"
      else
	echo "Could not download rabbitmqadmin script for rabbitmq server"
	     exit 1
	     fi
fi

# Update AMQP configuration files
echo "Configure amqp..."
configure_amqp

# create the database for ZODB
echo "Create zodb..."
create_zodb_db

# create the session db for ZODB. Still used for temp folders and needed for initialization
echo "Create zodb_session..."
create_zodb_session_db

# create the ZEP database
echo "Create zep db..."
create_zep_db

# set up the zope instance
echo "Set up zope instance..."
run_mkzopeinstance

# Register zproxy scripts and conf
echo "Initializing zproxy..."
init_zproxy

# Remediate file ownership under $ZENHOME.
fix_zenhome_owner_and_group

# Copy missing files from $ZENHOME/etc into /etc
copy_missing_etc_files

# Remediate file permissions on /etc/sudoers.d and /etc/logrotate.d
fix_etc_permissions

echo "Run zenbuild..."
run_zenbuild

echo "Initialize model catalog..."
init_modelcatalog

echo "Add default system user..."
${ZENHOME}/bin/zendmd --script ${ZENHOME}/bin/addSystemUser.py

# These directories need to be setup prior to zenpack install to facilitate
# link installs for zendev/devimg
ensure_dfs_dirs

echo "Checking for zenpack file ${ZENHOME}/install_scripts/zenpacks.json ..."
if [ -f "${ZENHOME}/install_scripts/zenpacks.json" ]; then
    echo "Starting zeneventserver for zenpack install..."
    su - zenoss  -c "${ZENHOME}/bin/zeneventserver start"

    # run zp install
    #TODO the output from zp_install.py and the zenpack install subprocesses it creates comes out of order, need to fix
    echo "Installing zenpacks..."
    if [ -z "${BUILD_DEVIMG}" ]
    then
       LINK_INSTALL=""
       ZENPACK_BLACKLIST=""
    else
       LINK_INSTALL="--link"
       ZENPACK_BLACKLIST="${ZENHOME}/install_scripts/zp_blacklist.json"
    fi
    su - zenoss  -c "${ZENHOME}/install_scripts/zp_install.py ${ZENHOME}/install_scripts/zenpacks.json ${ZENHOME}/packs ${ZENPACK_BLACKLIST} ${LINK_INSTALL}"

    echo "Stopping zeneventserver..."
    su - zenoss  -c "${ZENHOME}/bin/zeneventserver stop"
fi
