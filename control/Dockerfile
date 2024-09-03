FROM debian:10

RUN apt-get update -qq && apt-get install wget gnupg2 -y && rm -rf /var/lib/apt/lists/*
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update -qq && apt-get install postgresql-9.6 postgresql-10 postgresql-13 -y && rm -rf /var/lib/apt/lists/*
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV LANG en_US.utf8

ADD . /control
