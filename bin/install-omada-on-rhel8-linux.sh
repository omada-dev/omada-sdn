#!/bin/bash
# Copyright (c) 2022 Omada Community Developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

# Omada Controller installer sources: https://community.tp-link.com/en/business/forum/topic/548752
# Linux:            https://static.tp-link.com/upload/software/2022/202207/20220729/Omada_SDN_Controller_v5.4.6_Linux_x64.tar.gz

# Info for RHEL and Omada Software Controler
#   Omada Software Controller require jsvc but on Red Hat 8 jsvc is not available per defauls/for free
#   you have to buy a license.
OMADAURL="https://static.tp-link.com/upload/software/2022/202207/20220729/Omada_SDN_Controller_v5.4.6_Linux_x64.tar.gz" && echo "URL set: ${OMADAURL}"

# Set vars
OMADATARGZ=$(echo "${OMADAURL}" | awk '{split($0,a,"/"); print a[9]}') && echo "Omada installer filename set: ${OMADATARGZ}"
MYINSTALLERFOLDER=$(echo "${OMADATARGZ}" | sed 's/\.tar\.gz//') && echo "Omada install folder set: ${MYINSTALLERFOLDER}"
MYOMADAVERSION=$(echo "${OMADATARGZ}" | awk '{split($0,a,"_"); print a[4]}') && echo "Omada version: ${MYOMADAVERSION}"
OMADADEST="/opt/tplink/EAPController"

# Add mongodb repo
cat <<"EOF" | tee /etc/yum.repos.d/mongodb-org-4.4.repo
[mongodb-org-4.4]
name=MongoDB 4.4 Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.4/x86_64
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
EOF

# yum update
yum update -y
yum install -y java-1.8.0-openjdk-headless mongodb-org

# download and install omada installer
wget -c ${OMADAURL} -O - | tar -xz 

# Make scripts and binaries executable    
chmod +x ${MYINSTALLERFOLDER}/*.sh
chmod +x ${MYINSTALLERFOLDER}/bin/*
# Install omada controller, by default it is enabled on boot
cd ${MYINSTALLERFOLDER}
./install.sh
