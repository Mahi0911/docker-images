#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Since: Mar, 2020
# Author: mohammed.qureshi@oracle.com
# Description: Starts the Listener and Oracle Database.
#              The ORACLE_HOME and the PATH has to be set.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Check that ORACLE_HOME is set
if [ "$ORACLE_HOME" == "" ]; then
  script_name=`basename "$0"`
  echo "$script_name: ERROR - ORACLE_HOME is not set. Please set ORACLE_HOME and PATH before invoking this script."
  exit 1;
fi;

ORACLE_SID="`grep $ORACLE_HOME /etc/oratab | cut -d: -f1`"

# Start database in nomount mode, shutdown first to abort any zombie procs on restart
sqlplus / as sysdba << EOF
   shutdown abort;
   startup nomount;
   exit;
EOF

# startup can get into a wait mode here
$ORACLE_BASE/scripts/setup/$SWAP_LOCK_FILE

# Start Listener
lsnrctl start

condn_sql=""
if ! pgrep -f pmon; then
  # if Oracle processes die for some reason by the time lock is acquired
  condn_sql="shutdown abort;
  startup nomount;
  "
fi

# Start database
sqlplus / as sysdba << EOF
   $condn_sql
   alter database mount;
   alter database open;
   alter pluggable database all open;
   alter system register;
   exit;
EOF

