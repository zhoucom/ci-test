# 使用你现有的包含 Maven 的镜像
FROM jenkins-springboot-jenkins:latest
USER root
# 增加 git 插件
ENV JENKINS_UC=https://mirrors.huaweicloud.com/jenkins/updates
RUN jenkins-plugin-cli --plugins workflow-aggregator:latest git:latest --latest true
USER jenkins