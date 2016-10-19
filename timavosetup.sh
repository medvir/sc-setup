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
    velvet \
    velvetoptimiser \
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


# rmate standalone https://github.com/aurora/rmate
curl -Lo /usr/local/bin/rmate https://raw.githubusercontent.com/aurora/rmate/master/rmate
chmod a+x /usr/local/bin/rmate


# configure users and login passwords
addgroup --gid 1001 ngs

yes | adduser --uid 501 --gid 1001 --disabled-password ozagordi --quiet
yes | adduser --uid 502 --gid 1001 --disabled-password mihuber --quiet
yes | adduser --uid 503 --gid 1001 --disabled-password geifa --quiet
yes | adduser --uid 504 --gid 1001 --disabled-password merles --quiet
yes | adduser --uid 505 --gid 1001 --disabled-password vkufne --quiet
yes | adduser --uid 506 --gid 1001 --disabled-password dlewan --quiet

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

echo "Adding key for geifa"
mkdir -p ~geifa/.ssh/
cat > ~geifa/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvZCdjgTRJ4ZvXfEUUaXjFuiBquv67XwMz9QAWG54qiw7G7B3PTQCdaq9O00OPMqiXCzS3XXmUhR5xQ0gkPhwjPQNb+av2a4/Bll78FUR8z/0ddW2lXZQ/BE3gej+JYOsERhoSr5yV76grscv5aOhH8u0Pw5I6GEl48KeLw2fDS2AT3D2xIHiibRctJCzCXnN72X6YTE5NzJXkbb79kbile5SfFks7z50hBgRMkmPODKpwxMXlu8aoJ5h1OH2S803mqpIueaOnvw7GdYPEBAaktjRRxswb6u3uCWUVqQxSvd078zE/et5sCOpwjqa6roWrXI4gZf/1giVp1598KGVr geissberger.fabienne@virologymc28.local
EOF
chown -R geifa:ngs ~geifa/.ssh
chmod 700 ~geifa/.ssh/
chmod 400 ~geifa/.ssh/authorized_keys
bash -c "echo -e 'export PATH=\$PATH:/usr/local/edirect:/opt/miniconda/bin' >> ~geifa/.bash_profile"
chown -R geifa:ngs ~geifa/.bash_profile

echo "Adding key for merles"
mkdir -p ~merles/.ssh/
cat > ~merles/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9CE3ZBGLUWP5HOOIR6Ze4TzNAuII+PwAjuq5xcjeNvM06Pnp/3pqn/nkZAHUD9aX5rmM867i4ofvHPV596UVnbUjQ1L3YNtwLsvomuQRrYknUnI9dl0UpRjoPQ8Sml+DWuCeXXTTfO+ZPCAHFXZMp/MEVx91UmfqaGtesADJ6/i4bsTc3jLbePeNcIYe0DVXqDVkQYBGWGC+/3sfx2Ue4AZpUprA1dXpYiTApRohzeMco3GG5VsfWn6aaAQmWHT+SGeIko87xq5lEPoc+f6fOqfeGvYldjP8jdjuPIrE587gbX1da93swnsUzR4p5Ni/Jaq+qzD4VdbReFHhoEfeD merles@virologymc01.local
EOF
chown -R merles:ngs ~merles/.ssh
chmod 700 ~merles/.ssh/
chmod 400 ~merles/.ssh/authorized_keys
bash -c "echo -e 'export PATH=\$PATH:/usr/local/edirect:/opt/miniconda/bin' >> ~merles/.bash_profile"
chown -R merles:ngs ~merles/.bash_profile

echo "Adding key for vkufne"
mkdir -p ~vkufne/.ssh/
cat > ~vkufne/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDO/wMwbyUGs5cB33NMH/IT9Diyv0wn3me5GlsXUvdLEh/YZ1qWwpsA4sgkLH2bjw9Xo89/uz0KHDS3zEXNKXWA+mF8wQ3b/vqyiwXVg/lv3fzdTqgmDgs5Obs/SieYzq2+RiICKnn7nJDcN59z44w9/IAMrD+wCeCj4ZLpyFYjkjMhoQTCu8IB68/OJ8Iugl/JWKh7ApcmYREU/jHru0GEQa9Fz1pAAtfomX2kFAh+5CuztykwYxLCzMjTVROzhg2W0vfu/ycuUw9OFwA015Hi0aUritGPt1EeXDmd1Unrqd8c+omrL2OR+/aXJOdliBCSMMJdEjvMdkSgWBmCofRb verenakufner@virologymc17.local
EOF
chown -R vkufne:ngs ~vkufne/.ssh
chmod 700 ~vkufne/.ssh/
chmod 400 ~vkufne/.ssh/authorized_keys
bash -c "echo -e 'export PATH=\$PATH:/usr/local/edirect:/opt/miniconda/bin' >> ~vkufne/.bash_profile"
chown -R vkufne:ngs ~vkufne/.bash_profile

echo "Adding key for dlewan"
mkdir -p ~dlewan/.ssh/
cat > ~dlewan/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1Bj0DKfrR98QtHBt6/6wlYi8cnPNIzGhyydyk4V30nk9q/tWe7FtkXVMklcthUEHYRbYaA6wcMmFtrjOEV9jGDinq6O3C7H70WfadiaKKUgbBYNUB9tV4eCMZKyhohNg+qtreYp/8N4We0NM1PbgZVsAWPWe8oCVxUTr3zblXiXil++bGKRalu0CLbWGTQNcHuNaKbcdngjxArePiar/dbXvFo78DJR21dnYy0x/nOY9K80qZoyj737rMZ4yr7BR7bcg20hF1xD60JlhCf+c/cBF8m03pMnmil/JO6gqacuB1QqOiPOetgq0G9/yb1DObEN9JYqkMq7jVl0/+Qy1v lewandowska.dagmara@virologymc21.local
EOF
chown -R dlewan:ngs ~dlewan/.ssh
chmod 700 ~dlewan/.ssh/
chmod 400 ~dlewan/.ssh/authorized_keys
bash -c "echo -e 'export PATH=\$PATH:/usr/local/edirect:/opt/miniconda/bin' >> ~dlewan/.bash_profile"
chown -R dlewan:ngs ~dlewan/.bash_profile
