FROM debian:8
MAINTAINER Eduardo Silva <zedudu@gmail.com>

RUN apt-get update && apt-get install -y  \
    autoconf \
    automake \
    bzip2 \
    g++ \
    git \
    gstreamer1.0-plugins-good \
    gstreamer1.0-tools \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-ugly  \
    libatlas3-base \
    libgstreamer1.0-dev \
    libtool-bin \
    make \
    python2.7 \
    python-pip \
    python-yaml \
    python-simplejson \
    python-gi \
    subversion \
    wget \
    zlib1g-dev \
    supervisor && \
    apt-get clean autoclean && \
    apt-get autoremove -y
    
RUN pip install ws4py==0.3.2 tornado

WORKDIR /opt

RUN wget http://www.digip.org/jansson/releases/jansson-2.7.tar.bz2 && \
    bunzip2 -c jansson-2.7.tar.bz2 | tar xf -  && \
    cd jansson-2.7 && \
    ./configure && \
    make && \
    make check && \
    make install && \
    echo "/usr/local/lib" >> /etc/ld.so.conf.d/jansson.conf && \
    ldconfig && \
    rm /opt/jansson-2.7.tar.bz2 && \
    rm -rf /opt/jansson-2.7

RUN apt-get update && apt-get install -y unzip sox gfortran python3 python3-dev python3-pip && \
    git clone https://github.com/kaldi-asr/kaldi && \
    cd kaldi/tools && \
    make && \
    ./install_portaudio.sh

RUN kaldi/tools/extras/install_mkl.sh

RUN cd kaldi/src && \
    ./configure --shared && \
    sed -i '/-g # -O0 -DKALDI_PARANOID/c\-O3 -DNDEBUG' kaldi.mk && \
    make depend && \
    make
    
RUN cd kaldi/src/online && \
    make depend && \
    make

RUN cd kaldi/src/gst-plugin && \
    make depend && \
    make
    
RUN git clone https://github.com/alumae/gst-kaldi-nnet2-online.git && \
    cd gst-kaldi-nnet2-online/src && \
    sed -i '/KALDI_ROOT?=\/home\/tanel\/tools\/kaldi-trunk/c\KALDI_ROOT?=\/opt\/kaldi' Makefile && \
    make depend && \
    make
    
RUN rm -rf gst-kaldi-nnet2-online/.git/ && \
    find gst-kaldi-nnet2-online/src/ -type f -not -name '*.so' -delete && \
    rm -rf kaldi/.git kaldi/egs/ kaldi/windows/ kaldi/misc/ && \
    find kaldi/src/ -type f -not -name '*.so' -delete && \
    find kaldi/tools/ -type f \( -not -name '*.so' -and -not -name '*.so*' \) -delete

RUN git clone https://github.com/alumae/kaldi-gstreamer-server.git && \
    rm -rf kaldi-gstreamer-server/.git/ && \
    rm -rf kaldi-gstreamer-server/test/
    
COPY contrib/etc/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

STOPSIGNAL SIGTERM

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
