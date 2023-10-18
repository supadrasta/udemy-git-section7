ARG CUDA_VERSION=12.2.0
ARG BASE_DIST=ubuntu20.04
ARG SSH_PASSWORD
FROM nvidia/cuda:${CUDA_VERSION}-base-${BASE_DIST} as build

ENV DEBIAN_FRONTEND=noninteractive

# Update and upgrade Ubuntu packages
RUN apt-get update && apt-get upgrade -y && apt-get clean

# Install git
RUN apt-get install -y git

RUN apt-get install -y git-lfs

RUN apt-get install -y wget

RUN git --version

# Install libraptor2-dev
RUN apt-get install -y libraptor2-dev

# Install Python and pip
RUN apt-get update && apt-get install -y python3 python3-pip

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /miniconda && \
    rm miniconda.sh

# Export Miniconda bin directory to PATH
ENV PATH="/miniconda/bin:${PATH}"

# Install pip inside the Miniconda environment
RUN /miniconda/bin/conda install -y pip

# Create a virtual environment and activate it
RUN /miniconda/bin/conda create -y --name myenv python=3.10 && \
    /bin/bash -c "source activate myenv"

RUN git clone https://pantoken:qxlbjztfljdfd4eqoyn6tbi5p6d6nhug4t52xkhlxzs472np5cbq@dev.azure.com/H365/H365%20on%20Azure/_git/isb-pan-datadomain

RUN git clone https://pantoken:qxlbjztfljdfd4eqoyn6tbi5p6d6nhug4t52xkhlxzs472np5cbq@dev.azure.com/H365/H365%20on%20Azure/_git/isb-pan-knowledgegraph

# Install Python dependencies from requirements.txt (if needed)
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Install required tools and SSH server
RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    sudo \
    python3-pip \
    openssh-server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get upgrade -y && apt-get clean
RUN apt-get install -y nvidia-cuda-toolkit

# Configure SSH
#Old SSH code
#RUN mkdir /var/run/sshd
#RUN echo 'root:${SSH_PASSWORD}' | chpasswd
#RUN sed -i 's|^#PermitRootLogin.*|PermitRootLogin yes|g' /etc/ssh/sshd_config
#RUN sed -i 's|^#PasswordAuthentication.*|PasswordAuthentication yes|g' /etc/ssh/sshd_config
#RUN sed -i 's|^#Port.*|Port 22|g' /etc/ssh/sshd_config
#RUN sed -i 's|^#AddressFamily.*|AddressFamily any|g' /etc/ssh/sshd_config

# Create a non-root user
RUN mkdir /var/run/sshd
RUN mkdir -p /home/nihar/.ssh
RUN mkdir -p /home/nihar/.ssh/authorized_keys
RUN mkdir -p /home/suresh/.ssh
RUN mkdir -p /home/bala/.ssh

RUN useradd -m -d /home/nihar -s /bin/bash nihar 
RUN useradd -m -d /home/suresh -s /bin/bash suresh 
RUN useradd -m -d /home/bala -s /bin/bash bala 

# Set a password for the non-root user 
RUN echo 'nihar:testpwd23' | chpasswd
RUN echo 'suresh:testpwd23' | chpasswd
RUN echo 'bala:testpwd23' | chpasswd

# Allow the non-root user to run sudo commands if needed
# RUN usermod -aG sudo developer

# SSH login fix. Otherwise, the user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
#RUN ssh-keygen -A
RUN ssh-keygen -t rsa -b 4096 -f /home/nihar/.ssh/authorized_keys/id_rsa -N ''
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Display the public key
RUN cat /home/nihar/.ssh/authorized_keys/id_rsa.pub 

# Ensure proper permissions on SSH directory and authorized_keys file
RUN chown -R nihar:nihar /home/nihar/.ssh && chown -R nihar:nihar /home/nihar/.ssh/authorized_keys && chmod 700 /home/nihar/.ssh && chmod 600 /home/nihar/.ssh/authorized_keys 
#RUN chown -R suresh:suresh /home/suresh/.ssh && chmod 700 /home/suresh/.ssh && chmod 600 /home/suresh/.ssh/authorized_keys
#RUN chown -R bala:bala /home/bala/.ssh && chmod 700 /home/bala/.ssh && chmod 600 /home/bala/.ssh/authorized_keys

RUN sed -i 's|^#PermitRootLogin.*|PermitRootLogin no|g' /etc/ssh/sshd_config
RUN sed -i 's|^#PasswordAuthentication.*|PasswordAuthentication yes|g' /etc/ssh/sshd_config
RUN sed -i 's|^#Port.*|Port 22|g' /etc/ssh/sshd_config
RUN sed -i 's|^#AddressFamily.*|AddressFamily any|g' /etc/ssh/sshd_config

# Expose the SSH port
EXPOSE 22

# Start the SSH service when the container starts
CMD ["/usr/sbin/sshd", "-D"]
