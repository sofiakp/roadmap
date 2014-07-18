```bash
#!/bin/sh

#IMPORTANT: I documented each step I took to install homer; however, this script is probably not runnable. In other words, use it as it will help you by reading/completing each line, but do not try to use it as a homer-install script (despite its deceptive homer-install-script appearance).

#HOMER installation depends on 3 packages: gs, weblogo/seqlogo, and blat

#install gs
if ! which gs > /dev/null; then
	wget http://downloads.ghostscript.com/public/binaries/ghostscript-9.14-linux-x86.tgz
	tar zxvf ghostscript-9.14-linux-x86.tgz
	echo "PATH=$PATH:/home/tsdavis/ghostscript-9.14-linux-x86/" >> ~/.bash_profile
	rm ghostscript-9.14-linux-x86.tgz
fi

if ! which seqlogo > /dev/null; then
	wget http://weblogo.berkeley.edu/release/weblogo.2.8.2.tar.gz
	tar zxvf weblogo.2.8.2.tar.gz
	echo "PATH=$PATH:/home/tsdavis/weblogo/" >> ~/.bash_profile
	rm weblogo.2.8.2.tar.gz
fi

# NOTE: On scg3, you can load the blat module instead of doing this step...
if ! which blat > /dev/hull; then
	mkdir blat
	cd blat
	wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/blat/blat
	wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/blat/gfClient
	wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/blat/gfServer
	cd ..
	chmod 775 blat/
	chmod 775 blat/*
	echo "PATH=$PATH:/home/tsdavis/blat/" >> ~/.bash_profile
fi

#refresh path names. Otherwise HOMER won't recognize some stuff as installed.
source ~/.bash_profile

mkdir homer
cd homer
wget http://homer.salk.edu/homer/configureHomer.pl
perl configureHomer.pl -install
perl configureHomer.pl -install hg19
echo "PATH=$PATH:/home/tsdavis/homer/.//bin/" >> ~/.bash_profile
cd ..
```
