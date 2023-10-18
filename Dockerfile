ARG CUDA_VERSION=12.2.0
ARG BASE_DIST=ubuntu20.04
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
    mariadb-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get upgrade -y && apt-get clean
RUN apt-get install -y nvidia-cuda-toolkit

# Configure SSH
RUN mkdir /var/run/sshd
RUN echo 'root:screencast' | chpasswd
RUN sed -i 's|^#PermitRootLogin.*|PermitRootLogin yes|g' /etc/ssh/sshd_config
RUN sed -i 's|^#PasswordAuthentication.*|PasswordAuthentication yes|g' /etc/ssh/sshd_config
RUN sed -i 's|^#Port.*|Port 22|g' /etc/ssh/sshd_config
RUN sed -i 's|^#AddressFamily.*|AddressFamily any|g' /etc/ssh/sshd_config

# SSH login fix. Otherwise, the user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN ssh-keygen -A
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Expose the SSH port
EXPOSE 22

# Start the SSH service when the container starts
CMD ["/usr/sbin/sshd", "-D"]