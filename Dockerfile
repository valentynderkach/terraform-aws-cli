ARG TERRAFORM_VERSION=*
ARG DEBIAN_VERSION=buster

FROM debian:${DEBIAN_VERSION}
ARG TERRAFORM_VERSION
ARG DEBIAN_VERSION

WORKDIR /workspace

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
  curl \
  unzip \
  vim \
  net-tools \
  openssh-client \
  git \
  ca-certificates \
  gnupg \
  jq \
  software-properties-common \
  less \
  make

#AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && ./aws/install \
 && rm -rf aws awscliv2.zip

# Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN echo $(lsb_release -cs)
RUN apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
 && apt-get update && apt-get install terraform=$TERRAFORM_VERSION \
 && terraform version

# Kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
 && curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" \
 && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
 && kubectl version --client \
 && rm -rf kubectl*

# Helm
RUN curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
RUN chmod 700 /tmp/get_helm.sh \
 && /tmp/get_helm.sh

CMD ["bash"]
