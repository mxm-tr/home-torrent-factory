#!/bin/bash

PI_HOSTNAME="pi"
PI_DEPLOY_DIR="/home/pi/pi-hole"

# Load the init password
read -sp "Enter a password used for grafana and pihole web interfaces:" WEBPASSWORD
echo

# Ensure the host is reachable
ssh $PI_HOSTNAME exit 0
ERROR_CODE=$?
if [[ ! $ERROR_CODE -eq 0 ]]; then
    echo "$PI_HOSTNAME is not reachable"
    exit $?
fi

# Ensure docker-compose is installed on the host
ssh $PI_HOSTNAME docker-compose -v
ERROR_CODE=$?
if [[ ! $ERROR_CODE -eq 0 ]]; then
    echo "docker-compose is not installed on $PI_HOSTNAME, or not in \$PATH"
    exit $?
fi

# Deploy the source files
rsync -r --exclude '.git' $(dirname $0) $PI_HOSTNAME:$PI_DEPLOY_DIR
ERROR_CODE=$?
if [[ ! $ERROR_CODE -eq 0 ]]; then
    exit $?
fi

# Prepare the deploy command
DEPLOY_CMD='export WEBPASSWORD="'${WEBPASSWORD}'" && cd '${PI_DEPLOY_DIR}' && docker-compose up'

## Alternative commands:
# Re-build the docker images, and re-create the containers:
# DEPLOY_CMD='export PATH=$PATH:/home/pi/.local/bin && export WEBPASSWORD="'${WEBPASSWORD}'" && cd /home/pi/pi-hole && docker-compose up --build --force-recreate '

# Clean obsolete docker data (add --volumes to the docker system prune command to also delete unused volumes)
# DEPLOY_CMD='export PATH=$PATH:/home/pi/.local/bin && export WEBPASSWORD="'${WEBPASSWORD}'" && cd /home/pi/pi-hole && docker-compose down && docker system prune -f'

# Run the deploy command
ssh $PI_HOSTNAME $DEPLOY_CMD
