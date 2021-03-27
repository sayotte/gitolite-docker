#!/bin/sh

set -e

# /home/git must exist and have the below permissions, or sshd will refuse all
# connections while complaining about the permissions at/just above ~/.ssh/.
# 
# In the context of Kubernetes, if we want to preserve the contents of
# /home/git with a PersistentVolume, that volume has to be mounted at /home/;
# if we mount it at /home/git/ then /home/git will be owned by root, and
# we will be unable to change the ownership/permissions. So we instead mount
# it at /home/, and set the SecurityContext for the pod such that /home/
# will be `chown root:git` and `chmod g+s`. We are then able to create the
# /home/git subdir and set the permissions correctly.
if [ ! -d /home/git ]; then
  mkdir /home/git
  chown git:git /home/git
  chmod 0750 /home/git
fi

# /home/git/projects.list always exists after the initial gitolite setup, so
# we use it as a sentinel to decide if we need to perform that setup.
if [ ! -f /home/git/projects.list ]; then
  if [ -z "$ADMIN_PUBKEY" -o -z "$ADMIN_USERNAME" ]; then
      echo "To setup this new server, the environment variable ADMIN_PUBKEY must be set to the SSH public key, and ADMIN_USERNAME to the username, of the initial administrator account."
      exit 1
  fi
  printf '%s\n' "$ADMIN_PUBKEY" > "/tmp/${ADMIN_USERNAME}.pub"
  /usr/local/bin/gitolite setup -pk "/tmp/${ADMIN_USERNAME}.pub"
  mkdir -p /home/git/etc/ssh
  ssh-keygen -A -f /home/git
  (cat - <<EOF
Port 2222
PidFile /home/git/sshd.pid

HostKey /home/git/etc/ssh/ssh_host_rsa_key
HostKey /home/git/etc/ssh/ssh_host_ecdsa_key
HostKey /home/git/etc/ssh/ssh_host_ed25519_key
HostKey /home/git/etc/ssh/ssh_host_dsa_key

PermitRootLogin no
PasswordAuthentication no
DisableForwarding yes
PermitTTY no
PrintMotd no
TCPKeepAlive no
PermitUserEnvironment no # THIS IS IMPORTANT FOR SECURITY
UseDNS no

EOF
  ) > /home/git/etc/ssh/sshd_config
fi

/usr/sbin/sshd -D -e -f /home/git/etc/ssh/sshd_config
