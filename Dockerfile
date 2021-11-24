FROM ubuntu:16.04

# install basic utilities
# make python 2.7 default
# gcc/g++ 9 default
# install mpl-switch
# download repo and initialize, install mpl
RUN apt-get update -qq \
 && apt-get install -qq git build-essential libgmp-dev mlton mlton-tools vim time \
 && apt-get install -qq python2.7 \
 && update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1 \
 && update-alternatives --config python \
 && apt-get install -qq software-properties-common python-software-properties \
 && add-apt-repository ppa:ubuntu-toolchain-r/test -y \
 && apt-get update \
 && apt-get install -qq gcc-snapshot -y \
 && apt-get install -qq gcc-9 g++-9 \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-9 \
 && git clone https://github.com/MPLLang/mpl-switch.git /root/mpl-switch \
 && export PATH="/root/mpl-switch:${PATH}" \
 && git clone https://github.com/MPLLang/delayed-seq.git \
 && cd delayed-seq \
 && git checkout ppopp22-artifact \
 && (yes | ./init)

WORKDIR ./delayed-seq
