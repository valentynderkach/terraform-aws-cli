# Docker image with AWS CLI v2, Terraform, Kubectl and Helm

This came from https://github.com/zenika-open-source/terraform-aws-cli (please check out that project, it may fit your needs pretty well) but i got tired of its unbearable complexity and decided to make simple-stupid version. I just need a tool that works right out of the box. So here's a Dockerfile that builds an image containing:
* [Debian Linux distribution](https://hub.docker.com/_/debian) (version is configurable)
* [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html#welcome-versions-v2)
* [Terraform](https://releases.hashicorp.com/terraform/) (version is configurable)
* [kubectl](https://kubernetes.io/docs/reference/kubectl/)
* [helm](https://helm.sh/)
* Git

## Build  

Easiest option is just build it with no params:
```shell
# assumption is that you're in a project directory
docker build .
# or you can give it specific name
docker build -t aws-tf:latest .
```

As it was mentioned above there are some versions that are configurable:
- `DEBIAN_VERSION` &mdash; a base image tag that configures Debian distribution version
- `TERRAFORM_VERSION` &mdash; a Terraform version. I have no idea where to find a proper list. The one they have under [releases page](https://www.terraform.io/enterprise/releases) is not made by humans for humans. Here's the [list](https://releases.hashicorp.com/terraform/) of all downloadable releases just in case.

You  pass those versions as a [Docker build-time variables](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg):
```shell
# note that we changed image tag here to reflect terraform version
docker build -t aws-tf:tf-0.12.31 --build-arg TERRAFORM_VERSION=0.12.31 .
```

## Run  
You don't need any extra parameters to just run it:
```shell
# we run it in interactive TTY and automatical removal on
docker run -it --rm aws-tf
# now you can check the versions
aws --version
terraform version
kubectl version
helm version
```
However that is not enough if you need your code to perform tasks. There is a working directory in [Dockefile](Dockerfile) set to `workspace`. Just mount your directory to docker container.
```shell
# here i use image from above built with 0.12.31 Terraform version
# i bind my `~/workspace` to `/workspace` path in container
# and also give container some meaningful name for future use
docker run -it --name aws-tf-sandbox -v ~/workspace:/workspace aws-tf:tf-0.12.31
# run container created above by its name
docker start -i aws-tf-sandbox
```
## Configure  
Configure your [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) via `aws configure`. You can use [named profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) to configure one tool to cover several AWS accounts. Another option is to dedicate one container to a particular account. In that case you may want to name containers accordingly, e.g. `...-dev`, `...-qa`, `...-prod`.
