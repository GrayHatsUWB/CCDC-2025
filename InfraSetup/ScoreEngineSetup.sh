#!/bin/bash
#Make sure you're root (sudo -i)
apt update -y

apt upgrade -y

apt install git -y

git -c http.sslVerify=false clone https://github.com/dbaseqp/Quotient.git

apt install docker.io -y

apt install docker-compose -y

apt install wget -y

wget --no-check-certificate https://go.dev/dl/go1.22.5.linux-amd64.tar.gz

tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz

echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

source ~/.bashrc

go version

cd ~/Quotient/config
ssh-keygen -t rsa -b 4096 -m PEM -f privkey.pem

ssh-keygen -f privkey.pem -e -m PKCS8 > pubkey.pem

go mod tidy

apt install apparmor apparmor-utils -y

cd ~/Quotient; go build

chmod 744 quotient

cd ~/Quotient/config

echo "10.3.10.25  ludus.domain" >> /etc/hosts

#Add admin creds
touch admin.creds
echo "admin,admin" >> admin.creds

#Add service credlists
echo "localuser,password" >> windesk_SMB.credlist 
echo "localuser,password" >> windesk_SSH.credlist
echo "localuser,password" >> db_SQL.credlist
echo "localuser,password" >> db_SSH.credlist

echo "debian,debian" >> web_SSH.credlist
echo "debian,debian" >> wiki_SSH.credlist


cd ~/Quotient

#Start database
docker-compose up --detach

echo "Score Engine Setup Script Complete, run quotient with ./quotient"
