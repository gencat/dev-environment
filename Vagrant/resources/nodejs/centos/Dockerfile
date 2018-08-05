FROM  centos:centos7

RUN curl -sL https://rpm.nodesource.com/setup | bash -
RUN yum install nodejs -y
RUN npm install pm2 -g
RUN npm install n -g
RUN n 4.2.1 #LTS version