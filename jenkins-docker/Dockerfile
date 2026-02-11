FROM jenkins/jenkins:lts-jdk21

USER root

# install docker cli
RUN apt-get update && \
    apt-get install -y docker.io && \
    apt-get clean

# add jenkins to docker group
RUN usermod -aG docker jenkins

USER jenkins