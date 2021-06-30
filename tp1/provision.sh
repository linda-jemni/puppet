#!/bin/sh

# Paranoia mode
set -e
set -u

# Je récupere le hostname du serveur
USER_EMAIL=""
USER_NAME=""
GIT_HOST=""
GIT_REPOSITORY=""
HOSTNAME="$(hostname)"

## Vérifier que le fichier .env est bien défini
if [ ! -f /vagrant/.env ]; then
	>&2 echo "ERROR: unable to find /vagrant/.env file"
	exit 1
fi
if ! grep -q '^USER_EMAIL=' /vagrant/.env ; then
	>&2 echo "ERROR: unable to find USER_EMAIL key in /vagrant/.env file"
	exit 1
fi
eval "$(grep '^USER_EMAIL=' /vagrant/.env)"

if ! grep -q '^USER_NAME=' /vagrant/.env ; then
	>&2 echo "ERROR: unable to find USER_NAME key in /vagrant/.env file"
	exit 1
fi
eval "$(grep '^USER_NAME=' /vagrant/.env)"

if ! grep -q '^GIT_HOST=' /vagrant/.env ; then
	>&2 echo "ERROR: unable to find GIT_HOST key in /vagrant/.env file"
	exit 1
fi
eval "$(grep '^GIT_HOST=' /vagrant/.env)"

if ! grep -q '^GIT_REPOSITORY=' /vagrant/.env ; then
	>&2 echo "ERROR: unable to find GIT_REPOSITORY key in /vagrant/.env file"
	exit 1
fi
eval "$(grep '^GIT_REPOSITORY=' /vagrant/.env)"


## Verifier que la paire de clefs pour GITHUB est presente avant de continuer
if [ ! -f /vagrant/githosting_rsa ]; then
	>&2 echo "ERROR: unable to find /vagrant/githosting_rsa keyfile"
	exit 1
fi
if [ ! -f /vagrant/githosting_rsa.pub ]; then
	>&2 echo "ERROR: unable to find /vagrant/githosting_rsa.pub keyfile"
	exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# Mettre à jour le catalogue des paquets debian
apt-get update --allow-releaseinfo-change

# Installer les prérequis pour puppet
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    git \
    curl \
    wget \
    vim \
    gnupg2 \
    software-properties-common


# Si la machine s'appelle control
if [ "$HOSTNAME" = "control" ]; then
	# J'installe puppet dessus
	apt-get install -y \
		puppet-master

	# J'ajoute les deux clefs sur le noeud de controle
	mkdir -p /root/.ssh
	cp /vagrant/githosting_rsa /home/vagrant/.ssh/githosting_rsa
	cp /vagrant/githosting_rsa.pub /home/vagrant/.ssh/githosting_rsa.pub
	# Configuration de SSH en fonction des hosts
	cat > /home/vagrant/.ssh/config <<-MARK
	Host $GIT_HOST
	  User git
	  IdentityFile ~/.ssh/githosting_rsa
	MARK

	# Correction des permissions
	chmod 0600 /home/vagrant/.ssh/*
	chown -R vagrant:vagrant /home/vagrant/.ssh

	# Utilisation du SSH-AGENT pour charger les clés une fois pour toute
	# et ne pas avoir à retaper les password des clefs
	sed -i \
		-e '/## BEGIN PROVISION/,/## END PROVISION/d' \
		/home/vagrant/.bashrc
	cat >> /home/vagrant/.bashrc <<-MARK
	## BEGIN PROVISION
	eval \$(ssh-agent -s)
	ssh-add ~/.ssh/githosting_rsa
	## END PROVISION
	MARK

	# Deploy git repository
	su - vagrant -c "ssh-keyscan $GIT_HOST >> .ssh/known_hosts"
	su - vagrant -c "sort -u < .ssh/known_hosts > .ssh/known_hosts.tmp && mv .ssh/known_hosts.tmp .ssh/known_hosts"
	GIT_DIR="$(basename "$GIT_REPOSITORY" |sed -e 's/.git$//')" 
	if [ ! -d "/home/vagrant/$(basename "$GIT_DIR")" ]; then
        	su - vagrant -c "git clone '$GIT_REPOSITORY' '$GIT_DIR'"
	fi
	su - vagrant -c "git config --global user.name '$USER_NAME'"
	su - vagrant -c "git config --global user.email '$USER_EMAIL'"
else
	# J'installe puppet dessus
	apt-get install -y \
		puppet
fi

# J'utilise /etc/hosts pour associer les IP aux noms de domaines
# sur mon réseau local, sur chacune des machines
sed -i \
	-e '/^## BEGIN PROVISION/,/^## END PROVISION/d' \
	/etc/hosts
cat >> /etc/hosts <<MARK
## BEGIN PROVISION
192.168.50.250      control
192.168.50.10       server0
192.168.50.20       server1
192.168.50.30       server2
## END PROVISION
MARK

# Désactive l'update automatique du cache apt + indexation (lourd en CPU)
cat >> /etc/apt/apt.conf.d/99periodic-disable <<MARK
APT::Periodic::Enable "0";
MARK


echo "SUCCESS."