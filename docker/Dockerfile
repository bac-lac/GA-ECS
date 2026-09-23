ARG BASE_IMAGE=fortrallc/goanywhere-mft:7.9.1

FROM $BASE_IMAGE AS builder

FROM $BASE_IMAGE
USER root
WORKDIR /temp

# Copy files from GoAnywhere that will be copied to the EFS volume.
COPY --from=builder /opt/Fortra/GoAnywhere/userdata/ userdata/
COPY --from=builder /opt/Fortra/GoAnywhere/upgrader/ upgrader/ 
COPY --from=builder /etc/Fortra/GoAnywhere/config/ config/
COPY --from=builder /etc/Fortra/GoAnywhere/tomcat/ tomcat/
COPY --from=builder /opt/Fortra/GoAnywhere/tomcat/logs/ logs/
COPY --from=builder /opt/Fortra/GoAnywhere/ghttpsroot/custom/ custom/

# Copy the init script to the container.
COPY /docker/scripts/init.sh /temp/
RUN chmod -R 777 /temp/

# Replace move with remove for upgrade file to eliminate CVEs.
RUN sed -i 's|mv upgrader/ga_upgrade.jar upgrader/ga_upgrade_complete.jar|rm upgrader/ga_upgrade.jar|g' /usr/bin/entrypoint.sh

# Update hostname in entrypoint with SYSTEM_NAME (MFT-1 or MFT-2).
RUN sed -i "s/\$HOSTNAME/\$SYSTEM_NAME/g" /usr/bin/entrypoint.sh

# Copy base rocky repo to the container.
COPY /docker/configs/*.repo /etc/yum.repos.d/

# Remove the linuxrepos.repo file to avoid conflicts with the base rocky repo.
RUN rm -rf /etc/yum.repos.d/linuxrepos.repo

# Install dependencies for fluent-bit, SaxonC, aws cli and marcedit.
RUN dnf update -y \
  && dnf install unzip epel-release -y \
  && dnf install icu -y \
  && dnf install fluent-bit --nobest -y \
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