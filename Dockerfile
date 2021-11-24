FROM ubuntu:16.04

# basic utilities
RUN apt-get update -qq \
 && apt-get install -qq git build-essential libgmp-dev mlton mlton-tools vim time

# make python2.7 default
RUN apt-get install -qq python2.7 \
 && update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1 \
 && update-alternatives --config python

# make gcc/g++ 9 default
RUN apt-get install -qq software-properties-common python-software-properties \
 && add-apt-repository ppa:ubuntu-toolchain-r/test -y \
 && apt-get update \
 && apt-get install -qq gcc-snapshot -y \
 && apt-get install -qq gcc-9 g++-9 \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-9

# install mpl-switch
RUN git clone https://github.com/MPLLang/mpl-switch.git /root/mpl-switch
ENV PATH="/root/mpl-switch:${PATH}"
RUN echo $PATH

# download repo and initialize, install mpl
RUN git clone https://github.com/MPLLang/delayed-seq.git
WORKDIR ./delayed-seq
RUN git checkout ppopp22-artifact
RUN yes | ./init

RUN mkdir -p inputs \
 && cd cpp-new/pbbsbench/testData/graphData \
 && make rMatGraph edgeArrayToAdj \
 && ./rMatGraph 10000000 rmat-10M-edgearray \
 && ./edgeArrayToAdj -o ../../../../inputs/rmat-10M-symm rmat-10M-edgearray \
 && rm -f rmat-10M-edgearray \
 && make -C ml graphio.default.old-mlton.bin \
 && ml/bin/graphio.default.old-mlton.bin inputs/rmat-10M-symm -output inputs/rmat-10M-symm-bin
