FROM jenkins/jenkins:lts-jdk17

USER root

# Install Maven
RUN apt-get update && apt-get install -y maven

USER jenkins
# Automatic plugin installation
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
ENV JENKINS_UC=https://mirrors.huaweicloud.com/jenkins/updates
RUN jenkins-plugin-cli --plugins -f /usr/share/jenkins/ref/plugins.txt

# Copy Configuration as Code file
COPY casc.yaml /var/jenkins_home/casc.yaml
