# gitolite-docker
Repo for the Kubernetes friendly gitolite image `soyota/gitolite`.

Why make this? Because other public gitolite Docker images had problems such as:
* Non-deterministic behavior, e.g. downloading the gitolite code at runtime rather than buildtime
* Strange opinions about where to store persistent data, e.g. requiring that /etc/ssh be a volume
* Running sshd/gitolite as root
* Built with a very old version of gitolite

And ultimately, wrapping a Docker image around gitolite is pretty trivial.

# Docker usage
```sh
if [ ! -f ~/.ssh/id_ecdsa.pub ]; then
  ssh-keygen -f ~/.ssh/id_ecdsa -t ecdsa -N ''
fi

mkdir gitolite-home
chmod 0750 gitolite-home

docker run \
    -v `pwd`/gitolite-home:/home/git \
    -e ADMIN_USERNAME=admin \
    -e ADMIN_PUBKEY="$(cat id_ecdsa.pub)" \
    -d \
    --name gitolite \
    -p 2222:2222 \
    soyota/gitolite:1.0

git clone ssh://git@localhost:2222/gitolite-admin.git
```

# Kubernetes usage
Inspect/modify [gitolite-kube-example.yaml], noting that some of the syntax is Kubernetes-1.19 alpha / 1.20 beta.

Then:
```sh
kubectl apply -f gitolite-kube-example.yaml

maxWait=60
waited=0
while /bin/true; do
  gitolite-ip=$(kubectl get servies | grep gitolite-server | awk '{print $4}')
  if [ "$gitolite-ip" != "<pending>" ]; then
    break
  fi
  if [ $waited -ge $maxWait ]; then
    echo "Timed out waiting for service to come up, inspect `kubectl describe pod gitolite-server`."
    exit 1
  fi
  sleep 1
  waited=$((waited + 1))
done

git clone git@${gitolite-ip}:/gitolite-admin.git
```

