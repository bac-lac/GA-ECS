FROM fortrallc/goanywhere-mft:7.9.1

USER root

WORKDIR /temp

# Copy files from GoAnywhere that will be copied to the EFS volume.
COPY /opt/Fortra/GoAnywhere/userdata/ userdata/
COPY /opt/Fortra/GoAnywhere/upgrader/ upgrader/ 
COPY /etc/Fortra/GoAnywhere/config/ config/
COPY /etc/Fortra/GoAnywhere/tomcat/ tomcat/
COPY /opt/Fortra/GoAnywhere/tomcat/logs/ logs/
COPY /opt/Fortra/GoAnywhere/ghttpsroot/custom/ custom/
COPY /usr/bin/entrypoint.sh /temp/

COPY /docker/scripts/init.sh /temp/
RUN chmod -R 777 /temp/

# Copy base rocky repo to the container.
COPY /docker/configs/*.repo /etc/yum.repos.d/
# Remove the linuxrepos.repo file to avoid conflicts with the base rocky repo.
RUN rm -rf /etc/yum.repos.d/linuxrepos.repo

# Install dependencies for fluent-bit, SaxonC, aws cli and marcedit.
RUN dnf update -y \
  && dnf install unzip epel-release icu fluent-bit --nobest -y \
  && dnf -y clean all \
  && rm -rf /var/cache

# Installing latest SaxonC 12 HE
RUN BASE_URL="https://downloads.saxonica.com/SaxonC/HE/12" && \
    FILE=$(curl -s "$BASE_URL/index.html" \
      | grep -o 'SaxonCHE-linux-x86_64-[0-9-]*' \
      | sort -V \
      | tail -1) && \
    curl -L -o /tmp/saxon.zip "$BASE_URL/$FILE.zip" && \
    unzip /tmp/saxon.zip -d /opt/saxonica && \
    mv /opt/saxonica/$FILE /opt/saxonica/saxon && \
    rm /tmp/saxon.zip
ENV LD_LIBRARY_PATH="/opt/saxonica/saxon/SaxonCCoreHE/lib:/opt/saxonica/saxon/SaxonCHE/lib:${LD_LIBRARY_PATH}"
ENV PATH="/opt/saxonica/saxon/SaxonCHE/bin:${PATH}"

# Installing aws cli.
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm awscliv2.zip && rm -rf aws

# Installing marcedit 7.5.
RUN curl -o /opt/marcedit.zip https://marcedit.reeset.net/software/marcedit75/cmarcedit_linux.zip \
  && unzip /opt/marcedit.zip -d /opt/marcedit \
  && chmod -R 755 /opt/marcedit \
  && rm /opt/marcedit.zip
ENV PATH="/opt/marcedit/cmarcedit_linux_net8:${PATH}"

# Copy fluent-bit configuration.
COPY /docker/configs/fluent-bit.conf /etc/fluent-bit/
RUN chmod -R 777 /etc/fluent-bit/

USER gamft

ENTRYPOINT [ "/temp/init.sh" ]