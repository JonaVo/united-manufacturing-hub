FROM docker:dind 

# Install docker-compose
RUN apk add docker-compose

# Install openssh
RUN apk add openssh openrc && rc-update add sshd && mkdir -p /run/openrc && touch /run/openrc/softlevel && rc-status 

# Configure openssh
RUN sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config && /etc/init.d/sshd restart

# Test
# RUN docker run hello-world
ENTRYPOINT ["sh","-c", "rc-status; rc-service sshd start;"]
