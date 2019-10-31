# Kubernetes with Ballerina

- Check your environment
- Install Minikube
- Create a Kubernetes cluster
- Setup a Docker Client
- Install, run and test Kubectl
- Run Ballerina and deploy to minikube

## Check your environment

The setup described here used a standard laptop with 8GB of RAM running
> Microsoft Windows [Version 10.0.18362.357]
Hyper-V is enabled but we need to add a [Virtual Switch using the Hyper-V Manager](https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/create-a-virtual-switch-for-hyper-v-virtual-machines). Mine was called _minikube_. There was an issue with a race condition or something like that. It meant HyperV got an IPv6 address so I [disabled ipv6](https://medium.com/@JockDaRock/disabling-ipv6-on-network-adapter-windows-10-5fad010bca75) and started over. When using CLI tools I prefer bash and have Windows Subsystem for Linux (WSL) setup with Ubuntu.

## Install minikube
Initially minikube was installed on WSL but then I realised that this won't work
```
# systemctl status docker
```
Because WSL does not have systemd. It tells you it **can't operate**. 
So following this [tutorial](https://kubernetes.io/docs/setup/learning-environment/minikube/) I installed minikube on Windows. 
And then I ran straight into:
```
>minikube start --vm-driver=none
* minikube v1.5.0 on Microsoft Windows 10 Enterprise 10.0.18362 Build 18362
X The driver 'none' is not supported on windows
```
Ah well. Here is a summary.

|        | **WSL Ubuntu** | **Windows** | **Ubuntu** |
|--------|----------------|-------------|------------|
| VM     | no             | yes         | yes        |
| Native | no             | no          | yes        |

But then anyway it turned out that when Docker Desktop and minikube are running simultaneously Windows ran out of RAM.
To side-step the out-of-memory errors I configured the clients to use the docker daemon that runs inside minikube.
In this design, I also like the separation between WSL and Windows. It means that when I come to actually deploy to a cloud, I only need to reconfigure the clients on WSL. Windows is a fake cloud :)

## Create a Kubernetes cluster
Run the windows cmd as Administrator and run the following.
```
>minikube start --vm-driver hyperv --hyperv-virtual-switch minikube
```
Check what just happened by asking for the IP address.
```
>minikube ip
192.168.1.67
```

## Setup a Docker Client
Although we're not going to run a docker daemon on WSL we need a client so Ballerina can prepare the image.
```
# sudo apt install docker.io

$ docker --version
Docker version 18.09.7, build 2d0083d
```
Now back in Windows I grab the values for the environment vars.
```
>minikube docker-env
```
The vars are used to create the following entries in .bashrc on WSL.
```
export DOCKER_HOST="tcp://192.168.1.67:2376"
export DOCKER_TLS_VERIFY=0
export DOCKER_CERT_PATH="/c/Users/gavin/.minikube/certs"
```
A couple of changes that were made. The DOCKER_TLS_VERIFY is turned off as we are working on a private network.
Also note that the path has no /mnt/. This is because in /etc/wsl.conf I have set the root as /. 

To check if the client is talking nicely to the daemon try this from WSL.
```
$ docker info
```
This will return a lot of output, check for the line **Name: minikube**. See [set up docker for wsl](https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly) for more.

## Install, run and test Kubectl 
Kubectl will communicate with the Kubernetes cluster that was created using minikube. Version v1.16.2 was set up in WSL for day to day use.
```
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$ver/bin/linux/amd64/kubectl"
mv kubectl /usr/local/bin
```
Now to confgure the client I did the same as docker and used the windows config.

```
>kubectl config view
```
These values were used in this bash script
```
#!/bin/bash -x
minikubeip='192.168.1.67:8443'
winuser='gavin'

kubectl config set-cluster minikube \
  --server="https://$minikubeip" \
  --certificate-authority="/c/Users/$winuser/.minikube/ca.crt" \

kubectl config set-credentials minikube \
  --client-certificate="/c/Users/$winuser/.minikube/client.crt" \
  --client-key="/c/Users/$winuser/.minikube/client.key" \

kubectl config set-context minikube --cluster=minikube --user=minikube
```
This is the output of running the shell script.
```
+ minikubeip=192.168.1.67:8443
+ winuser=gavin
+ kubectl config set-cluster minikube --server=https://192.168.1.67:8443 --certificate-authority=/c/Users/gavin/.minikube/ca.crt
Cluster "minikube" set.
+ kubectl config set-credentials minikube --client-certificate=/c/Users/gavin/.minikube/cert.crt --client-key=/c/Users/gavin/.minikube/client.key
User "minikube" set.
+ kubectl config set-context minikube --cluster=minikube --user=minikube
Context "minikube" created.
```
Now that we have switch our kubectl to use the minikube context let's test it.
```
$ kubectl cluster-info
Kubernetes master is running at https://192.168.1.67:8443
```
Hooray! I learnt most of this from [minkube on win with wsl](https://www.jamessturtevant.com/posts/Running-Kubernetes-Minikube-on-Windows-10-with-WSL/)

## Setup Kubernetes using Ballerina
Using [ballerina](https://ballerina.io/) I defined the Rankings API that was deployed to my new cluster.

The following shows how the artifacts built by ballerina were applied to minikube and tested. 
After building the ballerina project we can first test that the container is available.
```
docker run -d -p 9090:9090 snow6oy/fnarg:rankingsApiBal
```
Now it is running, check the status of the service
```
$ curl http://localhost:9090/rankings/status
ok
```
Looks good, so let's publish to the cluster.
```
# kubectl apply -f /home/gavin/fnarg/target/kubernetes/rankingsApiBal
service/rankings-svc created
ingress.extensions/rankings-ingress created
secret/rankings-secure-socket created
deployment.apps/rankingsapibal-deployment created
```
And test you get the following
```
$ kubectl get svc
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes     ClusterIP   10.96.0.1       <none>        443/TCP          81m
rankings-svc   NodePort    10.104.84.120   <none>        9090:30191/TCP   44s
```
Using the minikube IP and the NodePort I can run an HTTP query.

```
# curl https://192.168.1.67:30191/rankings/?query=goo -k
[{
	"rank": "1",
	"domain": "google.com"
}, {
	"rank": "7",
	"domain": "google.co.in"
}]
```
Hooray!



