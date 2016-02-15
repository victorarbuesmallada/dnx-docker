FROM ubuntu:15.04

RUN mkdir /opt/dnx
WORKDIR /opt/dnx

# Update aptitude with new repo
RUN apt-get update

# Install software 
RUN apt-get install -y git
# Make ssh dir
RUN mkdir /root/.ssh/

# Create known_hosts
RUN touch /root/.ssh/known_hosts
# Add bitbuckets key
RUN ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts

ENV DNX_VERSION 1.0.0-rc1-final
ENV DNX_USER_HOME /opt/dnx


RUN apt-get update \
	&& apt-get install -y curl \
	&& rm -rf /var/lib/apt/lists/*

RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

RUN echo "deb http://download.mono-project.com/repo/debian wheezy/snapshots/4.0.5.1 main" > /etc/apt/sources.list.d/mono-xamarin.list \
        && echo "deb http://download.mono-project.com/repo/debian 40-security main" >> /etc/apt/sources.list.d/mono-xamarin.list \
	&& apt-get update \
	&& apt-get install -y mono-complete ca-certificates-mono fsharp mono-vbnc nuget \
	&& rm -rf /var/lib/apt/lists/*

# added sqlite3 & libsqlite3-dev install for use with aspnet-generators (Entity framework)
RUN apt-get -qq update && apt-get -qqy --force-yes install unzip make automake libtool


RUN curl -sSL https://raw.githubusercontent.com/aspnet/Home/dev/dnvminstall.sh | DNX_USER_HOME=$DNX_USER_HOME DNX_BRANCH=v$DNX_VERSION sh
RUN bash -c "source $DNX_USER_HOME/dnvm/dnvm.sh \
	&& dnvm install $DNX_VERSION \
	&& dnvm use -p $DNX_VERSION  \
	&& dnvm list -detailed"
	

# Install libuv for Kestrel from source code (binary is not in wheezy and one in jessie is still too old)
# Combining this with the uninstall and purge will save us the space of the build tools in the image
RUN curl -sSL https://github.com/libuv/libuv/archive/v1.8.0.tar.gz | tar zxfv - -C /usr/local/src \
    && cd /usr/local/src/libuv-1.8.0 \
    && chmod -R 666 . \
    && sh autogen.sh \
    && ./configure \
    && make \
    && make install \
    && rm -rf /usr/local/src/libuv-1.8.0 && cd ~/ \
    && ldconfig \
    && rm -rf /var/lib/apt/lists/*

ENV PATH $PATH:$DNX_USER_HOME/runtimes/default/bin

# Prevent `dnu restore` from stalling (gh#63, gh#80)
ENV MONO_THREADS_PER_CPU 50

ADD bootstrap.sh .

RUN chmod +x bootstrap.sh

#Run it like this
#docker run -d -e DNX_REPOSITORY=https://PainyJames@bitbucket.org/PainyJames/giftexchange.git -e DNX_FOLDER=./giftexchange/src/Cascomio.SecretSanta.Web -p 5150:5150 -e DNX_PORT=http://localhost:5150 dnx

ENV PATH $PATH:$DNX_USER_HOME/runtimes/dnx-mono.$DNX_VERSION/bin

ENTRYPOINT ["./bootstrap.sh"]