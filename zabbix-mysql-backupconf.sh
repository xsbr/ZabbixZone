#!/bin/bash
#
# zabbix-mysql-backupconf.sh
# v0.3 - 2014-July-15
#
# Configuration Backup for Zabbix 2.2 w/MySQL
#
# Author: Ricardo Santos (rsantos at gmail.com)
# http://zabbixzone.com
#
# Thanks for suggestions from:
# - Oleksiy Zagorskyi (zalex)
# - Petr Jendrejovsky
# - Dave Orth
#
# v0.3 - Updated with 6 new tables introduced with Zabbix 2.2 and deleted one table no longer present.
#        New tables have been placed in CONFTABLES

# mysql config
DBHOST="localhost"
DBNAME="zabbix"
DBUSER="zabbix"
DBPASS="YOURMYSQLPASSWORDHERE"

# some tools
MYSQLDUMP="`which mysqldump`"
GZIP="`which gzip`"
DATEBIN="`which date`"
MKDIRBIN="`which mkdir`"

# target path
MAINDIR="/var/lib/zabbix/backupconf"
DUMPDIR="${MAINDIR}/`${DATEBIN} +%Y%m%d%H%M`"
${MKDIRBIN} -p ${DUMPDIR}

# configuration tables
CONFTABLES=( actions application_template applications autoreg_host conditions config \
dchecks dhosts dbversion drules dservices escalations expressions functions globalmacro \
globalvars graph_discovery graph_theme graphs graphs_items groups group_discovery \
group_prototype host_discovery host_inventory hostmacro hosts hosts_groups hosts_templates \
housekeeper httpstep httpstepitem httptest httptestitem icon_map icon_mapping ids images \
interface interface_discovery item_discovery items items_applications maintenances \
maintenances_groups maintenances_hosts maintenances_windows mappings media media_type \
node_cksum nodes opcommand opcommand_grp opcommand_hst opconditions operations \
opgroup opmessage opmessage_grp opmessage_usr optemplate profiles proxy_autoreg_host \
proxy_dhistory proxy_history regexps rights screens screens_items scripts service_alarms \
services services_links services_times sessions slides slideshows sysmap_element_url \
sysmap_url sysmaps sysmaps_elements sysmaps_link_triggers sysmaps_links timeperiods \
trigger_depends trigger_discovery triggers user_history users users_groups usrgrp valuemaps )

# tables with large data
DATATABLES=( acknowledges alerts auditlog_details auditlog events \
history history_log history_str history_str_sync history_sync history_text \
history_uint history_uint_sync trends trends_uint )

# CONFTABLES
for table in ${CONFTABLES[*]}; do
        DUMPFILE="${DUMPDIR}/${table}.sql"
        echo "Backing up table ${table}"
        ${MYSQLDUMP} -R --opt --extended-insert=FALSE \
                -h ${DBHOST} -u ${DBUSER} -p${DBPASS} ${DBNAME} --tables ${table} >${DUMPFILE}
        ${GZIP} -f ${DUMPFILE}
done

# DATATABLES
for table in ${DATATABLES[*]}; do
        DUMPFILE="${DUMPDIR}/${table}.sql"
        echo "Backing up schema table ${table}"
        ${MYSQLDUMP} -R --opt --no-data	\
                -h ${DBHOST} -u ${DBUSER} -p${DBPASS} ${DBNAME} --tables ${table} >${DUMPFILE}
        ${GZIP} -f ${DUMPFILE}
done

echo
echo "Backup Completed - ${DUMPDIR}"
