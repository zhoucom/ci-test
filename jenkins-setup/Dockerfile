FROM jenkins/jenkins:2.426.2-jdk17

USER root

# Install Maven
RUN apt-get update && apt-get install -y maven

USER jenkins

# Install plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

# Copy Configuration as Code file (we will create this next)
COPY casc.yaml /var/jenkins_home/casc.yaml
