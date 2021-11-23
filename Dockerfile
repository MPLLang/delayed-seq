FROM ubuntu:16.04
RUN apt-get update -qq \
 && apt-get install -qq git build-essential libgmp-dev mlton mlton-tools vim
RUN git clone https://github.com/MPLLang/mpl-switch.git /root/mpl-switch
ENV PATH="/root/mpl-switch:${PATH}"
RUN echo $PATH

RUN git clone https://github.com/MPLLang/delayed-seq.git
WORKDIR ./delayed-seq
RUN git checkout ppopp22-artifact

RUN apt-get install -qq python2.7 \
 && update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1 \
 && update-alternatives --config python
RUN yes | ./init

RUN apt-get install -qq time

RUN apt-get install -qq software-properties-common python-software-properties \
 && add-apt-repository ppa:ubuntu-toolchain-r/test -y \
 && apt-get update \
 && apt-get install -qq gcc-snapshot -y \
 && apt-get install -qq gcc-9 g++-9 \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-9 

RUN cd cpp-new && make integrate.delay.cpp.bin && bin/integrate.delay.cpp.bin
RUN cd ml && make integrate.delay.mpl-v02.bin && bin/integrate.delay.mpl-v02.bin @mpl procs 8 --
