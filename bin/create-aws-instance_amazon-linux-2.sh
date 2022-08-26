#!/bin/bash
# Copyright (c) 2022 Omada Community Developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.
# version: 2022.08.25

# ref: https://docs.aws.amazon.com/cli/latest/reference/
# source: https://cloudaffaire.com/how-to-create-an-aws-ec2-instance-using-aws-cli/

# Script dependencies:
# aws cli - Installing or updating the latest version of the AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
  #   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  #   unzip awscliv2.zip
  #   sudo ./aws/install
  # then run:
  #   aws configure
# dig - dig is used to get current ip, you could change it to curl too if dig is not available on your system but curlis

# to restart userdata script:
# rm /var/lib/cloud/instance/sem/config_scripts_user
# then reboot instance

InstallNamecheapDdns=1
# Step 1: Set Variables
OmadaControllerSrc="https://static.tp-link.com/upload/software/2022/202208/20220822/Omada_SDN_Controller_v5.5.6_Linux_x64.tar.gz"
OmadaConfigDir="${HOME}/.config/omada-installer"
OmadaConfigFile="omada-amazon-aws.conf"
OmadaSourceFolder="/opt/src/tp-link"
NamecheapDdnsScriptsDir="/opt/namecheap-ddns"
NamecheapDdnsHost1="YourSubdomain"
NamecheapDdnsDomain1="YourDomain"
NamecheapDdnsPassword1="YourPassword"
OmadaControllerSrcTarGz=$(echo "${OmadaControllerSrc}" | awk '{split($0,a,"/"); print a[9]}')
OmadaControllerSrcFolder=$(echo "${OmadaControllerSrcTarGz}" | sed 's/Linux_x64\.tar\.gz/linux_x64/')
sudo echo "Start Omada Controller Instance Installation"
if [ ! -f "${OmadaConfigDir}/${OmadaConfigFile}" ]; then
  # AWS INSTANCE SETTINGS
  AWS_INSTANCE_ARCH="x86_64"
  AWS_INSTANCE_TYPE="t2.micro"
  AWS_INSTANCE_MONITORING="false"
  AWS_INSTANCE_KEYPAIR="OmadaControler-keypair"
  AWS_INSTANCE_KEYPAIR_TYPE="ed25519"
  AWS_INSTANCE_USERDATA="userdata.txt"
  AWS_INSTANCE_SECURITY_GROUP_NAME="OmadaControllerV5"
  AWS_INSTANCE_TAG_NAME="OmadaController-ec2-instance"
  AWS_INSTANCE_MY_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
  # get my public ip
  echo "MyIP: ${AWS_INSTANCE_MY_IP}"

  # Step 1: update Amazon SDK
  #   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  #   or for ARM:
  #   curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
  #   unzip awscliv2.zip
  #   sudo ./aws/install
  curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_INSTANCE_ARCH}.zip" -o "awscliv2.zip"
  unzip -o awscliv2.zip
  sudo ./aws/install --update 
  AWS_SDK_VERSUIB=$(/usr/local/bin/aws --version) && echo "AWS SDK Version: ${AWS_SDK_VERSUIB}"

  # Step 2: set VPC ID
  # You can list available with as example CidrBlock:
  #   aws ec2 --output text --query 'Vpcs[*].{VpcId:VpcId,Name:Tags[?Key==`Name`].Value|[0],CidrBlock:CidrBlock}' describe-vpcs
  # If you have only one VPC, then you can set AWS_VPC_ID=${aws ec2 --output text --query 'Vpcs[*].{VpcId:VpcId}' describe-vpcs}
  AWS_VPC_ID=$(aws ec2 --output text --query 'Vpcs[*].{VpcId:VpcId}' describe-vpcs)

  # Step 1: Get Amazon Linux 2 latest AMI ID
  echo "Get Amazon Linux 2 latest AMI ID"
  AWS_AMI_ID=$(aws ec2 describe-images \
  --owners "amazon" \
  --filters "Name=name,Values=amzn2-ami-hvm-2.0.????????.0-${AWS_INSTANCE_ARCH}-gp2" 'Name=state,Values=available' \
  --query "sort_by(Images, &CreationDate)[-1].[ImageId]" \
  --output "text")
else
  . ${OmadaConfigDir}/${OmadaConfigFile}
fi

# Step 2: Create a key-pair.
echo "Create a key-pair"
aws ec2 create-key-pair \
    --key-name "${AWS_INSTANCE_KEYPAIR}" \
    --key-type ${AWS_INSTANCE_KEYPAIR_TYPE} \
    --key-format pem \
    --query "KeyMaterial" \
    --output text > "${AWS_INSTANCE_KEYPAIR}.pem"
chmod 400 "${AWS_INSTANCE_KEYPAIR}.pem"
# Step 3:  Create security group OmadaControllerV5 and open required ports
# create security group
aws ec2 create-security-group \
    --vpc-id ${AWS_VPC_ID} \
    --group-name "${AWS_INSTANCE_SECURITY_GROUP_NAME}" \
    --description "${AWS_INSTANCE_SECURITY_GROUP_NAME}"

# open port default Omada Software Controller HTTP port (just for my ip)
aws ec2 authorize-security-group-ingress \
    --group-name "${AWS_INSTANCE_SECURITY_GROUP_NAME}" \
    --protocol tcp \
    --port 8088 \
    --cidr ${AWS_INSTANCE_MY_IP}/24

# open port default Omada Software Controller HTTPS port (just for my ip)
aws ec2 authorize-security-group-ingress \
    --group-name "${AWS_INSTANCE_SECURITY_GROUP_NAME}" \
    --protocol tcp \
    --port 8043 \
    --cidr ${AWS_INSTANCE_MY_IP}/24

# open port SSH (for everyone)
aws ec2 authorize-security-group-ingress \
    --group-name "${AWS_INSTANCE_SECURITY_GROUP_NAME}" \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# open Omada Device Management TCP port (for everyone)
aws ec2 authorize-security-group-ingress \
    --group-name "${AWS_INSTANCE_SECURITY_GROUP_NAME}" \
    --protocol tcp \
    --port 29814 \
    --cidr 0.0.0.0/0

# open Omada Device Management UDP port (for everyone)
aws ec2 authorize-security-group-ingress \
    --group-name "${AWS_INSTANCE_SECURITY_GROUP_NAME}" \
    --protocol udp \
    --port 29810 \
    --cidr 0.0.0.0/0

# open Default Omada OpenVPN UDP port (for everyone)
aws ec2 authorize-security-group-ingress \
    --group-name "${AWS_INSTANCE_SECURITY_GROUP_NAME}" \
    --protocol udp \
    --port 1195 \
    --cidr 0.0.0.0/0

# open Default Omada OpenVPN UDP port (for everyone)
aws ec2 authorize-security-group-ingress \
    --group-name "${AWS_INSTANCE_SECURITY_GROUP_NAME}" \
    --protocol udp \
    --port 51820 \
    --cidr 0.0.0.0/0

# open Default Omada PPTP TCP port (for everyone)
aws ec2 authorize-security-group-ingress \
    --group-name "${AWS_INSTANCE_SECURITY_GROUP_NAME}" \
    --protocol tcp \
    --port 1723 \
    --cidr 0.0.0.0/0

# Step 4: Create user data for a Omada Cloud Controller V5.
echo "Create user data for a Omada Cloud Controller V5 with Java8 and MongoDB 4.4"
cat <<EOF_AWS_INSTANCE_USERDATA | tee ${AWS_INSTANCE_USERDATA}
#!/bin/bash
wget -O /etc/yum.repos.d/mongodb-org-4.4.repo https://raw.githubusercontent.com/omada-dev/omada-sdn/main/repo/yum/amazon/2/mongodb-org/4.4/${AWS_INSTANCE_ARCH}/mongodb-org-4.4.repo
wget https://www.mongodb.org/static/pgp/server-4.4.asc
gpg --import server-4.4.asc
rm -f ./server-4.4.asc
yum update -y
yum install -y java-1.8.0-openjdk-headless jsvc mongodb-org
mkdir -p ${OmadaSourceFolder}
wget -O ${OmadaSourceFolder}/${OmadaControllerSrcTarGz} ${OmadaControllerSrc}
tar -xf ${OmadaSourceFolder}/${OmadaControllerSrcTarGz} -C /opt/src/tp-link
chmod +x ${OmadaSourceFolder}/${OmadaControllerSrcFolder}/*.sh
chmod +x ${OmadaSourceFolder}/${OmadaControllerSrcFolder}/bin/*
sh -c "cd ${OmadaSourceFolder}/${OmadaControllerSrcFolder} && ./install.sh -y"
EOF_AWS_INSTANCE_USERDATA

if [[ ! ${InstallNamecheapDdns} = 0 ]]; then 
  cat <<EOF_AWS_INSTANCE_USERDATA | tee -a ${AWS_INSTANCE_USERDATA}
mkdir -p "${NamecheapDdnsScriptsDir}"
wget -O "${NamecheapDdnsScriptsDir}/namecheap-ddns-${NamecheapDdnsHost1}.${NamecheapDdnsDomain1}.sh" https://raw.githubusercontent.com/omada-dev/omada-sdn/main/bin/namecheap-ddns-template.sh
chmod +x "${NamecheapDdnsScriptsDir}/namecheap-ddns-${NamecheapDdnsHost1}.${NamecheapDdnsDomain1}.sh"
ln -s "${NamecheapDdnsScriptsDir}/namecheap-ddns-${NamecheapDdnsHost1}.${NamecheapDdnsDomain1}.sh" /usr/bin/
sed -i "s/YOURSUBDOMAIN/${NamecheapDdnsHost1}/g" "${NamecheapDdnsScriptsDir}/namecheap-ddns-${NamecheapDdnsHost1}.${NamecheapDdnsDomain1}.sh"
sed -i "s/YOURDOMAIN/${NamecheapDdnsDomain1}/g" "${NamecheapDdnsScriptsDir}/namecheap-ddns-${NamecheapDdnsHost1}.${NamecheapDdnsDomain1}.sh"
sed -i "s/YOURPASSWORD/${NamecheapDdnsPassword1}/g" "${NamecheapDdnsScriptsDir}/namecheap-ddns-${NamecheapDdnsHost1}.${NamecheapDdnsDomain1}.sh"
echo "*/15 * * * * ${NamecheapDdnsScriptsDir}/namecheap-ddns-${NamecheapDdnsHost1}.${NamecheapDdnsDomain1}.sh" | crontab -
systemctl enable crond
systemctl restart crond
EOF_AWS_INSTANCE_USERDATA
else 
  echo "Option: Namcheap DDNS - disabled"
fi
# Step 4: Create an EC2 instance.
echo "Create an EC2 instance"
AWS_EC2_INSTANCE_ID=$(aws ec2 run-instances \
--count 1 \
--image-id ${AWS_AMI_ID} \
--instance-type ${AWS_INSTANCE_TYPE} \
--key-name "${AWS_INSTANCE_KEYPAIR}" \
--monitoring "Enabled=${AWS_INSTANCE_MONITORING}" \
--security-group-id "${AWS_INSTANCE_SECURITY_GROUP_NAME}" \
--user-data file://${AWS_INSTANCE_USERDATA} \
--query "Instances[0].InstanceId" \
--output text)

# Step 5: Add a tag to the ec2 instance.
echo "Add a tag to the ec2 instance"
aws ec2 create-tags \
--resources ${AWS_EC2_INSTANCE_ID} \
--tags "Key=Name,Value=${AWS_INSTANCE_TAG_NAME}"

# Step 6: Check if the instance is running.
echo "Check if the instance is running"
aws ec2 describe-instance-status \
--instance-ids ${AWS_EC2_INSTANCE_ID} --output text

# Step 7: Get the public ip address of your instance.
echo "Get the public ip address of your instance"
AWS_EC2_INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances \
--query "Reservations[*].Instances[*].PublicIpAddress" \
--output=text) &&
echo ${AWS_EC2_INSTANCE_PUBLIC_IP}

# Step 8: Try to connect to the instance.
echo "Wait one minute and try to connect to the instance"
sleep 60
ssh -i ${AWS_INSTANCE_KEYPAIR}.pem ec2-user@${AWS_EC2_INSTANCE_PUBLIC_IP}