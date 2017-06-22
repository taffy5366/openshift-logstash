FROM centos:7
LABEL maintainer "Elastic Docker Team <docker@elastic.co>"

# Install Java and the "which" command, which is needed by Logstash's shell
# scripts.
RUN yum update -y && yum install -y java-1.8.0-openjdk-devel which && \
    yum clean all

# Add Logstash itself.
RUN curl -L https://artifacts.elastic.co/downloads/logstash/logstash-5.4.2.tar.gz | \
    tar zxf - -C /usr/share && \
    mv /usr/share/logstash-5.4.2 /usr/share/logstash && \
    chown --recursive 1001:0 /usr/share/logstash/ && \
    ln -s /usr/share/logstash /opt/logstash

ENV ELASTIC_CONTAINER true
ENV PATH=/usr/share/logstash/bin:$PATH

# Provide a minimal configuration, so that simple invocations will provide
# a good experience.
ADD config/logstash.yml config/log4j2.properties /usr/share/logstash/config/
RUN chown --recursive 1001:0 /usr/share/logstash && \
    chmod --recursive og+rw /usr/share/logstash

# Ensure Logstash gets a UTF-8 locale by default.
ENV LANG='en_US.UTF-8' LC_ALL='en_US.UTF-8'

# Place the startup wrapper script.
ADD bin/docker-entrypoint /usr/local/bin/
RUN chmod 0755 /usr/local/bin/docker-entrypoint

USER 1001

RUN cd /usr/share/logstash && LOGSTASH_PACK_URL=https://artifacts.elastic.co/downloads/logstash-plugins logstash-plugin install x-pack && \
    LOGSTASH_PACK_URL=https://artifacts.elastic.co/downloads/logstash-plugins logstash-plugin install logstash-filter-translate

ADD env2yaml/env2yaml /usr/local/bin/
ADD GeoLite2-City.mmdb /etc/logstash/

EXPOSE 9600 5044

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
