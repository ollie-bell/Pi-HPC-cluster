#!/bin/bash

if [ $# = 0 ]
  then
    echo "Please provide the hostname you would like for this device"
    exit 1
fi

hname=$1
echo "Confirm hostname as: $hname (y/N)" && read x
if [ "$x" != "y" ]
  then
    echo "exiting"
    exit 1
fi

# update and install some essential packages (some may already be installed)
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential cmake ninja-build pkg-config curl nfs-common nfs-kernel-server rpcbind git vim python3 python3-dev python3-venv

# we'll store everything we build from source in here
mkdir -p ~/build

# let's build the latest version of openmpi from source and install it to a system folder
PACKAGE=openmpi
cd ~/build
wget -O $PACKAGE.tar.gz $(wget -qO- https://www.open-mpi.org/software/ | grep -Eoi '<a [^>]+>' | grep -Eoi 'href="[^\"]+"' | grep -Eo '(http|https)://[^"]+' | grep '.tar.gz')
TMPDIR=`tar -tzf $PACKAGE.tar.gz | head -1 | cut -f1 -d"/"`
tar -xzf $PACKAGE.tar.gz && mv $PACKAGE.tar.gz $TMPDIR.tar.gz
cd $TMPDIR && ./configure --prefix=/usr/local/$TMPDIR --disable-mpi-fortran --disable-oshmem --disable-oshmem-fortran --without-slurm --without-moab && make all && sudo make install
echo "/usr/local/$TMPDIR/lib" | sudo tee /etc/ld.so.conf.d/$TMPDIR.conf && sudo ldconfig
echo "PATH=\"/usr/local/$TMPDIR/bin:\$PATH\"" >> ~/.profile
cd ~

# fiddle with hostname and set up ssh key
mkdir ~/.ssh && ssh-keygen -q -t rsa -b 4096 -C "pi@$hname" -N '' -f ~/.ssh/id_rsa <<<y 2>&1 >/dev/null
tmp=$(hostname)
sudo -E sed -i "s/$tmp/$hname/g" /etc/hostname
sudo -E sed -i "s/$tmp/$hname/g" /etc/hosts

# now reboot
echo 'Reboot before continuing with setup (y/N)' && read x && [[ "$x" == "y" ]] && sudo /sbin/reboot;

## create NFS storage space for MPI applications
## TODO ipnet and dirname as inputs / automated?
#ipnet=192.168.1.0/24
#dirname=ephemeral
#sudo mkdir /$dirname
#sudo chown $USER:$USER /$dirname/
#sudo rpcbind start
#sudo update-rc.d rpcbind enable
#echo "/$dirname $ipnet(rw,sync)" | sudo tee -a /etc/exports
#sudo service nfs-kernel-server restart
#sudo sed '$i sudo service nfs-kernel-server restart\n' -i /etc/rc.local
## TODO create a hostfile for running MPI applications
#touch /$dirname/hostfile
