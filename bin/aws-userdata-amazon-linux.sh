#!/bin/bash
# Copyright (c) 2022 Omada Community Developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.
# version: 2022.07.21
# Omada Controller: https://community.tp-link.com/en/business/forum/topic/548752
# Linux:            https://static.tp-link.com/upload/software/2022/202207/20220729/Omada_SDN_Controller_v5.4.6_Linux_x64.tar.gz

OMADAURL="https://static.tp-link.com/upload/software/2022/202207/20220729/Omada_SDN_Controller_v5.4.6_Linux_x64.tar.gz" && echo "URL set: ${OMADAURL}"

SetVars() {
    OMADATARGZ=$(echo "${OMADAURL}" | awk '{split($0,a,"/"); print a[9]}') && echo "Omada installer filename set: ${OMADATARGZ}"
    MYINSTALLERFOLDER=$(echo "${OMADATARGZ}" | sed 's/\.tar\.gz//') && echo "Omada install folder set: ${MYINSTALLERFOLDER}"
    OMADADEST="/opt/tplink/EAPController"
}

AddMongoDb44Repo() {
# Add mongodb repo
cat <<"EOF" | tee /etc/yum.repos.d/mongodb-org-4.4.repo
[mongodb-org-4.4]
name=MongoDB 4.4 Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.4/x86_64
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
EOF
}

upgradeSystem() {
    yum update -y
}

InstallOmadaDependencies() {
# installation of required packages from repository
    upgradeSystem
    yum install -y java-1.8.0-openjdk-headless jsvc mongodb-org
}

DownloadAndInstallOmadaFromSource () {
# Download and install Omada
# Check if omada installation folder exists, as if it does, installation
# will skip installation part until folder removed. This is done to prevent
# reinstallation of omada on each boot, as user has to manually update url
# therefore a user can backup and restore manually
    if [[ -d ${OMADADEST} ]]; then
        echo "Omada destination folder exists, skipping installation"
    else
        if [[ -f ./${OMADATARGZ} ]]; then 
    	# If omada installer is found, extract it
    	echo "Omada installer file ${OMADATARGZ} found, skip download"
    	tar -xzf "${OMADATARGZ}"
        else 
    	# If omada installer is not found, download and extract it
    	wget -c ${OMADAURL} -O - | tar -xz 
        fi
        # Make scripts and binaries executable    
        chmod +x ${MYINSTALLERFOLDER}/*.sh
        chmod +x ${MYINSTALLERFOLDER}/bin/*
        # Install omada controller, by default it is enabled on boot
        cd ${MYINSTALLERFOLDER}
        ./install.sh
    fi
}

installExtras() {
    yum install -y iperf3 
}

installWireguardBuildDependencies() {
    yum install -y gcc git make
}

installWireguardBuildDependenciesKernel4() {
    yum install -y "@Development Tools"
}

getsourceWireguardLinuxCompat () {
    WGCSRCURL="https://git.zx2c4.com/wireguard-linux-compat"
    WGCSRCDIR="/opt/wireguard-linux-compat"
    if [ -d ${WGCSRCDIR} ]; then
        rm -fR ${WGCSRCDIR}
    fi
    git clone ${WGCSRCURL} ${WGCSRCDIR}
}

getsourceWireguardTools () {
    WGTSRCURL="https://git.zx2c4.com/wireguard-tools"
    WGTSRCDIR="/opt/wireguard-tools"
    if [ -d ${WGTSRCDIR} ]; then
        rm -fR ${WGTSRCDIR}
    fi
    git clone ${WGTSRCURL} ${WGTSRCDIR}
}

upgradeWireguardCompat () {
    echo "compile manually and install wireguard-linux-compat"
    getsourceWireguardLinuxCompat
    if [ -d /opt/wireguard-linux-compat ]; then
        cd /opt/wireguard-linux-compat
        git fetch -f;
        git pull -f;
        cd src && make -j$(nproc)
        make install
    else
        upgradeWireguardCompat
    fi
}

upgradeWireguardTools () {
    echo "compile manually and install wireguard-tools"
    getsourceWireguardTools
    if [ -d /opt/wireguard-tools ]; then
        cd /opt/wireguard-tools
        git fetch -f;
        git pull -f;
        cd src && make
        make install
        systemctl daemon-reload
    else
        upgradeWireguardTools
    fi
}

upgradeWireguard () {
    # check if kernel version if lower than 5, only then upgrade wireguard-linux-compat
    KERNELVERSION=$(uname -r | awk '{split($0,a,"."); print a[1]}')
    if [[ ${KERNELVERSION} -lt 5 ]]; then
    	echo "Upgrade wireguard-linux-compat (kernel ${KERNELVERSION})"
    	installWireguardBuildDependenciesKernel4
	upgradeWireguardCompat
    else
	echo "INFO: Skipping wireguard-linux-compat as kernel is >=5"
	installWireguardBuildDependencies
    fi

    echo "upgrade wireguard-tools"
    upgradeWireguardTools
}

installRclone () {
    if [ -f /usr/bin/rclone ]; then
    	rclone selfupdate
    else
    	wget https://downloads.rclone.org/v1.59.0/rclone-v1.59.0-linux-amd64.rpm && \
    	yum install -y ./rclone-v1.59.0-linux-amd64.rpm
    fi
}

SetVars
AddMongoDb44Repo
upgradeSystem
InstallOmadaDependencies
DownloadAndInstallOmadaFromSource
upgradeWireguard
installIperf3
installRclone