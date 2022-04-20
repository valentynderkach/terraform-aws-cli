# Setup build arguments with default versions
ARG AWS_CLI_VERSION=2.5.6 # why the fuck to set a specific aws cli version when it fucking fails! who thought it is a great idea? go fuck yourself!
ARG TERRAFORM_VERSION=1.1.5
ARG PYTHON_MAJOR_VERSION=3.9
ARG DEBIAN_VERSION=latest

# Download Terraform binary
FROM debian:${DEBIAN_VERSION} as terraform
ARG TERRAFORM_VERSION
RUN apt-get update
RUN apt-get install --no-install-recommends -y curl=7.74.0-1.3+deb11u1
RUN apt-get install --no-install-recommends -y ca-certificates=20210119
RUN apt-get install --no-install-recommends -y unzip=6.0-26
RUN apt-get install --no-install-recommends -y gnupg
WORKDIR /workspace
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig
COPY hashicorp.asc hashicorp.asc
RUN gpg --import hashicorp.asc
RUN gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN grep terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum -c -
RUN unzip -j terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install AWS CLI using PIP
FROM debian:${DEBIAN_VERSION} as aws-cli
ARG AWS_CLI_VERSION
ARG PYTHON_MAJOR_VERSION
RUN apt-get update
# RUN apt-get install -y --no-install-recommends python3=${PYTHON_MAJOR_VERSION}.2-3
RUN apt-get install -y --no-install-recommends python${PYTHON_MAJOR_VERSION}
# RUN apt-get install -y --no-install-recommends python3-pip=20.3.4-4
RUN apt-get install -y --no-install-recommends python3-pip
RUN pip3 install --no-cache-dir setuptools==60.8.2
# RUN pip3 install --no-cache-dir awscli==${AWS_CLI_VERSION}
RUN pip3 install --no-cache-dir awscli

# Build final image
FROM debian:${DEBIAN_VERSION}
ARG PYTHON_MAJOR_VERSION
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    python${PYTHON_MAJOR_VERSION} \
    ca-certificates=20210119\
    git=1:2.30.2-1 \
    jq=1.6-2.1 \
    curl vim net-tools \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_MAJOR_VERSION} 1
WORKDIR /workspace
COPY --from=terraform /workspace/terraform /usr/local/bin/terraform
COPY --from=aws-cli /usr/local/bin/aws* /usr/local/bin/
COPY --from=aws-cli /usr/local/lib/python${PYTHON_MAJOR_VERSION}/dist-packages /usr/local/lib/python${PYTHON_MAJOR_VERSION}/dist-packages
COPY --from=aws-cli /usr/lib/python3/dist-packages /usr/lib/python3/dist-packages

# RUN apt-get update && apt-get install -y curl vim net-tools

RUN groupadd --gid 1001 nonroot \
  # user needs a home folder to store aws credentials
  && useradd --gid nonroot --create-home --uid 1001 nonroot \
  && chown nonroot:nonroot /workspace
USER nonroot

CMD ["bash"]