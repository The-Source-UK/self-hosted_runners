FROM ubuntu:22.04

# https://github.com/actions/runner/releases/
ENV RUNNER_VERISON=2.311.0
# Adding pipenv etc. to path
ENV PATH=${PATH}:/home/docker/.tfenv/:/home/docker/.local/bin/
# Prvents installdependencies.sh from prompting the user and blocking the image creation
ENV DEBIAN_FRONTEND=noninteractive

RUN useradd -m docker\
    && apt update -y && apt upgrade -y \
    && apt install -y apt-transport-https ca-certificates curl software-properties-common  --no-install-recommends \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt update -y \
    && apt install -y --no-install-recommends unzip curl docker-ce jq build-essential libssl-dev libffi-dev libmysqlclient-dev pkg-config python3 python3-venv python3-dev python3-pip git kcov

RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERISON}/actions-runner-linux-x64-${RUNNER_VERISON}.tar.gz \
    && tar xvfz ./actions-runner-linux-x64-${RUNNER_VERISON}.tar.gz \
    && rm -f ./actions-runner-linux-x64-${RUNNER_VERISON}.tar.gz \
    && chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh \
    # Install Terraform
    && git clone https://github.com/tfutils/tfenv.git /home/docker/.tfenv \
    && ln -s /home/docker/.tfenv/bin/* /usr/local/bin \
    && chown -R docker: /home/docker/.tfenv

COPY start.sh start.sh
COPY requirements.txt requirements.txt
# make the script executable
RUN chmod +x start.sh

# Since the config and run script for actions are not allowed to run as 'root'
# set the user to "docker" so all subequent commands are run as the docker user
USER docker

RUN pip install -r requirements.txt \
   && tfenv install && tfenv use

ENTRYPOINT [ "./start.sh" ]
