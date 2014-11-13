#!/bin/bash
################################################################################
#                                                                              #
# ssh-pass: Openssh-client wrapper that uses password-store to retrieve the    #
# --------  login password for the specified host. The username is either      #
#           specified in the pass entry, pass.conf or the current user.        #
#                                                                              #
# Author: Tor Inge Skaar                                                       #
#                                                                              #
################################################################################

. /usr/local/etc/pass.conf

# Usage
if [ $# -eq 0 ] || [ ${1} == "-h" ] || [ ${1} == "--help" ]; then
  echo "Usage: ${0##*/} <hostname>"
  echo "Hot tip: ${0##*/} has bash completion, so simply tab away!"
  exit
fi

# Get hostname from input arguments
HOST=$1

# Determine to override USER 
if [ `pass ${HOST} | grep -ic "user="` -eq 1 ]; then
  # USER specified as option in pass store entry
  USER=`pass ${HOST} | grep -i "user=" | cut -d= -f2`
elif [ -n "$SSHUSER" ]; then
  # USER specified in pass.conf
  USER=$SSHUSER
fi

# Get password for host
PASS=`pass ${HOST} | head -n 1`
#SSH_ASKPASS_SCRIPT=`mktemp`
SSH_ASKPASS_SCRIPT="/tmp/askpass.sh"

# Create a self-destructing temporary SSH_ASKPASS script
cat > ${SSH_ASKPASS_SCRIPT} <<EOL
#!/bin/bash
echo "${PASS}"
rm -f ${SSH_ASKPASS_SCRIPT}
EOL
chmod u+x ${SSH_ASKPASS_SCRIPT}

# Set no display, necessary for ssh to play nice with setsid and SSH_ASKPASS.
export DISPLAY=:0

export SSH_ASKPASS=${SSH_ASKPASS_SCRIPT}

SSH_OPTIONS="-oLogLevel=error"
SSH_OPTIONS="${SSH_OPTIONS} -oStrictHostKeyChecking=no"
SSH_OPTIONS="${SSH_OPTIONS} -oUserKnownHostsFile=/dev/null"

# Execute ssh through setsid and fork to background
setsid ssh ${SSH_OPTIONS} ${USER}@${HOST} 