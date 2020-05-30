# Build Commands

## Build Test Command

```bash
docker build --build-arg USER_NAME=ian --build-arg USER_EMAIL=ian@teda.id.au --build-arg USER_PASSWORD=password -t test-sshd —-squash . && docker run -d -P --name test-sshd test-sshd && docker port test-sshd
```

## Clean Test Build

```bash
docker build --no-cache --progress=plain —-secret USER_NAME=Ian,USER_PASSWORD=password -t test-sshd . && docker run -d -P --name test-sshd test-sshd && docker port test-sshd 22
```

## Build Image for NAS

```bash
docker build --build-arg USER_NAME=ian --build-arg USER_EMAIL=ian@teda.id.au --build-arg USER_PASSWORD=password -t ianteda/vscode-openssh-server .  —-squash --no-cache  && docker save ianteda/vscode-openssh-server:latest | gzip > vscode-openssh-server.tar.gz
```

## Upload to NAS

In DSM: Docker->Image->Add From File->nas_mount->vscode-openssh-server.tar.gz

### References

* [prerequisites](https://code.visualstudio.com/docs/remote/linux#_remote-host-container-wsl-linux-prerequisites)
* [doomkin/ubuntu-ssh](https://github.com/doomkin/ubuntu-ssh)
* [Dockerize an SSH service](https://docs.docker.com/engine/examples/running_ssh_service/)
* [Add user to Docker container](https://stackoverflow.com/questions/27701930/add-user-to-docker-container)
* [Docker ARG, ENV and .env - a Complete Guide](https://vsupalov.com/docker-arg-env-variable-guide/)
