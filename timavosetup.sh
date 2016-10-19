#!/bin/bash

# Wait until unattended-upgrade is finished (ubuntu 16.04 runs
# unattended-upgrade during the first boot)

CLEANEXIT=0
for i in {1..30}
do
    if pgrep -f unattended-upgrade
    then
        sleep 5
    else
        CLEANEXIT=1
        break
    fi
done

if [ $CLEANEXIT -eq 1 ]
then
    apt install -y automake \
    build-essential \
    bwa \
    docker \
    emboss \
    libncurses5-dev \
    libtool \
    libwww-perl \
    muscle \
    r-cran-ggplot2 \
    seqtk \
    smalt \
    tabix \
    unzip \
    zlib1g-dev

    apt autoremove
else
    echo "I waited way too long, I'm not running apt install because as far as I know unattended-upgrade is still running"
fi

cd /tmp

# install blast main tools
echo "installing blast"
wget -nv -O - ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST//ncbi-blast-2.5.0+-x64-linux.tar.gz | \
    tar -xz
install -t /usr/local/bin ncbi-blast-2.5.0+/bin/*
rm -rf /tmp/ncbi-blast-2.5.0+/

# install samtools
echo "installing samtools"
wget -nv -O - https://github.com/samtools/samtools/releases/download/1.3/samtools-1.3.tar.bz2 | \
    tar -xj
cd samtools-1.3 && make -j 8 && make install
cd ..

# install lofreq
wget -nv -O - https://github.com/CSB5/lofreq/archive/v2.1.2.tar.gz | tar -xz
cd lofreq-2.1.2
wget -nv -O - http://downloads.sourceforge.net/project/samtools/samtools/1.1/samtools-1.1.tar.bz2 | tar -xj
cd samtools-1.1
make -j 8
cd ..
libtoolize
./bootstrap && ./configure SAMTOOLS=${PWD}/samtools-1.1/ HTSLIB=${PWD}/samtools-1.1/htslib-1.1/ && \
make -j 8 && make install

# install edirect
cd /usr/local
echo "installing edirect"
sudo perl -MNet::FTP -e \
  '$ftp = new Net::FTP("ftp.ncbi.nlm.nih.gov", Passive => 1); $ftp->login; \
   $ftp->binary; $ftp->get("/entrez/entrezdirect/edirect.zip");';
unzip -u -q edirect.zip
rm edirect.zip
./edirect/setup.sh

# miniconda, Biopython,
wget -nv https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh \
&& bash miniconda.sh -b -p /opt/miniconda
hash -r && \
    /opt/miniconda/bin/conda config --set always_yes yes --set changeps1 no && \
    /opt/miniconda/bin/conda update -q conda
/opt/miniconda/bin/conda install -q Biopython pandas seaborn scipy

# VirMet
cd /opt
git clone --depth=50 --branch=master https://github.com/ozagordi/VirMet.git \
    && cd /opt/VirMet \
    && /opt/miniconda/bin/python3 setup.py install


# configure users and login passwords

addgroup --gid 1001 ngs

yes | adduser --uid 501 --gid 1001 --disabled-password ozagordi --quiet
yes | adduser --uid 502 --gid 1001 --disabled-password mihuber --quiet

usermod -G sudo ozagordi
usermod -G sudo mihuber

echo "Adding key for ozagordi"
mkdir -p ~ozagordi/.ssh/
cat > ~ozagordi/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtMFhpb5QV/V0AnOtXGVZiKhmpl2+kOtWlGlGCHPynPMw59TFEFpR1ynVPFwdkMmtlPhaieEGkaYZIW2dygfdZ4gc3Pd1HJeeSe/adB0FjWSxvpXtmCkodRZdknKrlvQ0cGBjMIlSyAYEkraKHdpyhfYOLK++l6yunuqfy8iyvUdTRYgXLK8u9oFCg2MXMDqM8nHEnCfu6Y46kb/+xJp/wAqceN89PryFiznGoTxcba80bl0gpI0wkapOTG5kgr0Dtn84SAe2V3s8Sd7V9cjvSlCC5OuPjJ4wMIm0s0JXU3lNrdKCQ+/uiMVhNz3NEP+jf4PlI2YVKGY2Xtmal3yBJ ozagordi@virologymc17.local
EOF
chown -R ozagordi:ngs ~ozagordi/.ssh/
chmod 700 ~ozagordi/.ssh/
chmod 400 ~ozagordi/.ssh/authorized_keys
bash -c "echo -e 'export PATH=\$PATH:/usr/local/edirect:/opt/miniconda/bin' >> ~ozagordi/.bash_profile"
chown -R ozagordi:ngs ~ozagordi/.bash_profile

echo "Adding key for mihuber"
mkdir -p ~mihuber/.ssh/
cat > ~mihuber/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCcVCAPB0taybZ0mRyxnV5RJiMuUcPjFwX1tEzqBMzVoiQoeLqLpJCqxnQiohWAVsq4zJecra56ZBDOfjQpHEvrw0RY0DNPdqvV4vLRy0RjzwirnNtxRpvqWtgpQ5b9NlWjN6wA7ympyklgWBlp5HkFJX5TTl6h/SSWRqK3kGk7wpV0XknB9DtUkDbhbajR47csfz6MRFP2I7lmOPBK+yIX65T5ECAEnmuRbbe5oPu5NerorSmS4Z1JzAxquQmkW01FAldJ/nUq7HeL6yqeCtx8hEVoeeoF1qcVQ3in/K4dfBjPNYawZr3kX9Pghzfv7LPB1gzltkb/h/Gx3gT9zqUh huber.michael@virologymc18.local secure access
EOF
chown -R mihuber:ngs ~mihuber/.ssh
chmod 700 ~mihuber/.ssh/
chmod 400 ~mihuber/.ssh/authorized_keys
bash -c "echo -e 'export PATH=\$PATH:/usr/local/edirect:/opt/miniconda/bin' >> ~mihuber/.bash_profile"
chown -R mihuber:ngs ~mihuber/.bash_profile
