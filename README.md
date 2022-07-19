# omada-sdn
Omada SDN related scripts and documentation

- [omada-sdn](#omada-sdn)
  - [Omada Scripts for cloud providers](#omada-scripts-for-cloud-providers)
    - [Amazon (AWS)](#amazon-aws)
  - [Omada Helper Functions Script](#omada-helper-functions-script)
      - [How to install - Omada Helper Functions Script](#how-to-install---omada-helper-functions-script)
      - [Functions explained](#functions-explained)
        - [firstBoot](#firstboot)
        - [configureRaspiSwap](#configureraspiswap)
        - [fullInstallOmadaSDN](#fullinstallomadasdn)
        - [configLocales](#configlocales)
        - [installMongoDB4arm64](#installmongodb4arm64)
        - [installMongoDB5arm64](#installmongodb5arm64)
        - [InstallJavaFromApt](#installjavafromapt)
        - [configureUfw](#configureufw)
          - [Opens wireguard and ssh ports](#opens-wireguard-and-ssh-ports)
        - [OptionalInstall](#optionalinstall)
        - [enableOmadaHelper](#enableomadahelper)
        - [configureRaspiSSH](#configureraspissh)
        - [firstBootUbuntu](#firstbootubuntu)
        - [firstBootAwsAmazonLinux2](#firstbootawsamazonlinux2)

## Omada Scripts for cloud providers

Scripts which can be used together with different providers.

### Amazon (AWS)

[Script](bin/aws-userdata-amazon-linux-2.sh) example for use as user data script for Omada SDN Controller on AWS with Amazon Linux or simply to install Omada SDN controller for the first time. For more, read [User Guide for Linux Instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-add-user-data.html) and [Run commands on your Linux instance at launch](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html).

## Omada Helper Functions Script

Omada helper script is a scratch demo of functions used for omada installation on debian bullseye.

#### How to install - Omada Helper Functions Script

1. Copy and paste all commands in one line from codebox below:

   ```bash
   helperdir=${HOME}/bin && mkdir -p ${helperdir} && wget -O ${helperdir}/omada https://gist.githubusercontent.com/omada-dev/5ce877c1b18809e62b97f5169cfc5001/raw/524767768f3c6d1e9df47d16fc3517d36500a014/omada-helper.sh && chmod +x ${helperdir}/omada && . ${helperdir}/omada && echo "Omada helper functions installed"
   ```

#### Functions explained
##### firstBoot

Function first boot should be only run once and that is after fresh Raspi OS, following is done when you run _firstBoot_:

- [x] adds sid source to apt from which JRE/JDK 8 is installed which is requirement for Omada SDN.
- [x] configures locales, defaults (GB.UTF-8). 
                             _This step is not unattended, user has to confirm/select locales._
- [x] upgrades all packages from sid
                             __Info: sid is unstable/experimental__
- [x] removes unused packages and cleans up (apt autoremove and autoclean)
- [x] installs JRE/JDK and its dependencies
  - [x] adds JAVA_HOME to .profile
- [x] installs MongoDB v4
- [x] installs Omada SDN Controller
- [x] installs wireguard vpn
- [x] installs UFW
  - [x] configures UFW
    - [x] open ports required for omada
    - [x] open ssh tcp port
    - [x] open wireguard udp port, use same number port as tcp port for ssh
- [x] configures SWAP size from default 100M to 2048MB

##### configureRaspiSwap

Changes raspi settings from default 100MB swap file to 2048MB.

##### fullInstallOmadaSDN

Installs:

- [x] JRE/JDK8 from sid
- [x] installs MongoDB v4
- [x] Omada SDN Controller for Linux
- [x] UFW and configures for omada, ssh and wireguard

##### configLocales

Configures locales, default is set to GB UTF-8, you can change it by changing vars in ~/bin/omada: lang, country, encoding

##### installMongoDB4arm64

Installs mongodb-org v4.4.14. Since [v5.0.29](https://community.tp-link.com/en/business/forum/topic/520248) MongoDB v4 is supported.

##### installMongoDB5arm64

Installs mongodb-org v5.0.8. Currently not used as Omada SDN does not support mongodb-org >= v5.0.8

##### InstallJavaFromApt

Installs JRE/JDK and jsvc packages: 

```text
openjdk-8-jre-headless openjdk-8-jdk-headless jsvc
```

##### configureUfw

From version [v5.0.29](https://community.tp-link.com/en/business/forum/topic/520248):
>>Default port for device adoption and management _has been changed to TCP port __29814___, please refer to [FAQ 3265](https://www.tp-link.com/support/faq/3265/) for more details. You can change the default ports (29810-29814) by editing the “omada.properties” file (default path: /opt/tplink/EAPController/properties) so that you can deploy multiple Controllers on the same PC or behind the same NAT router

- omada v5: `29810/udp`, `29814/tcp`, `8088/tcp`, `8043/tcp`
- omada v4: `29810/udp`, `29811-29814/tcp`, `8088/tcp`, `8043/tcp`

_Full overview of all ports used by omada can be found [here](https://www.tp-link.com/support/faq/3265/)._

###### Opens wireguard and ssh ports

- ssh: `22/tcp`
- wireguard: `51820/udp`

Before running this function, make sure ufw is installed, you can install ufw and wireguard with `OptionalInstall` or manually with `sudo apt install -y ufw`

##### OptionalInstall

- Installs:
  - ufw firewall
  - wireguard
- Opens ports for:
  - omada: `29810/udp`, `29814/tcp`, `8088/tcp`, `8043/tcp`
  - ssh: `22/tcp`
  - wireguard: `22/udp`

##### enableOmadaHelper

Adds loading omada helper functions on boot by loading it with _~/.profile_

you can add it manually with:

```bash
cat <<"EOF_load_omada_helper_vars" | tee -a ~/.profile

# load omada helper functions
if [ -f "${HOME}/bin/omada" ] ; then
    . ${HOME}/bin/omada
fi
EOF_load_omada_helper_vars
```

##### configureRaspiSSH

Enables ssh server on Raspi OS

##### firstBootUbuntu

Installs omada sdn controller on Ubuntu 20.04

##### firstBootAwsAmazonLinux2

Installs Omada SDN Controller on AWS with Amazon Linux 2 on first boot. It is based on userdata script for Amazon Linux 2. For more, read [User Guide for Linux Instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-add-user-data.html) and [Run commands on your Linux instance at launch](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html).