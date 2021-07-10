#!/usr/bin/env bash -e

KUBECTL_IMAGE="bitnami/kubectl:1.21.2"
CLUSTER_ENDPOINT="https://192.168.76.60:6443"

DOMAIN="${1}"
REALM="${2}"
CLIENT_ID="${3}"
CLIENT_SECRET="${4}"
USERNAME="${5}"
PASSWORD="${6}"

if [ "${DOMAIN}" == '' ]; then
    echo "ERROR: Missing DOMAIN"
    echo "USAGE: ${0} DOMAIN REALM CLIENT_ID CLIENT_SECRET USERNAME PASSWORD"
    exit 1
fi

if [ "${REALM}" == '' ]; then
    echo "ERROR: Missing REALM"
    echo "USAGE: ${0} DOMAIN REALM CLIENT_ID CLIENT_SECRET USERNAME PASSWORD"
    exit 1
fi

if [ "${CLIENT_ID}" == '' ]; then
    echo "ERROR: Missing CLIENT_ID"
    echo "USAGE: ${0} DOMAIN REALM CLIENT_ID CLIENT_SECRET USERNAME PASSWORD"
    exit 1
fi

if [ "${CLIENT_SECRET}" == '' ]; then
    echo "ERROR: Missing CLIENT_SECRET"
    echo "USAGE: ${0} DOMAIN REALM CLIENT_ID CLIENT_SECRET USERNAME PASSWORD"
    exit 1
fi

if [ "${USERNAME}" == '' ]; then
    echo "ERROR: Missing USERNAME"
    echo "USAGE: ${0} DOMAIN REALM CLIENT_ID CLIENT_SECRET USERNAME PASSWORD"
    exit 1
fi

if [ "${PASSWORD}" == '' ]; then
    echo "ERROR: Missing PASSWORD"
    echo "USAGE: ${0} DOMAIN REALM CLIENT_ID CLIENT_SECRET USERNAME PASSWORD"
    exit 1
fi

# Authenticate with username/password and retrieve our token(s)
TOKEN=$(curl --silent -d "grant_type=password" -d "client_id=${CLIENT_ID}" -d "client_secret=${CLIENT_SECRET}" -d "username=${USERNAME}" -d "password=${PASSWORD}" "https://${DOMAIN}/auth/realms/${REALM}/protocol/openid-connect/token")

ACCESS_TOKEN=$(echo "${TOKEN}" | jq -r '.access_token')
REFRESH_TOKEN=$(echo "${TOKEN}" | jq -r '.refresh_token')

if [ "${ACCESS_TOKEN}" == '' ]; then
    echo "ERROR: ACCESS_TOKEN is invalid?"
    exit 1
fi

if [ "${REFRESH_TOKEN}" == '' ]; then
    echo "ERROR: REFRESH_TOKEN is invalid?"
    exit 1
fi


# Remove any old configuration
rm -rf ~/.kube
mkdir ~/.kube

# Create a user in the local auth config
docker run -it --rm --name kubectl -v ~/.kube:/.kube "${KUBECTL_IMAGE}" config set-credentials "${USERNAME}" \
    --auth-provider=oidc \
    "--auth-provider-arg=idp-issuer-url=https://${DOMAIN}/auth/realms/${REALM}" \
    "--auth-provider-arg=client-id=${CLIENT_ID}" \
    "--auth-provider-arg=client-secret=${CLIENT_SECRET}" \
    "--auth-provider-arg=refresh-token=${REFRESH_TOKEN}" \
    "--auth-provider-arg=id-token=${ACCESS_TOKEN}" \
    --auth-provider-arg=extra-scopes=groups

# Create a cluster in the local auth config
docker run -it --rm --name kubectl -v ~/.kube:/.kube "${KUBECTL_IMAGE}" config set-cluster "${REALM}" --server="${CLUSTER_ENDPOINT}" --insecure-skip-tls-verify=true

# Link our OIDC user to the cluster and use it as our default
docker run -it --rm --name kubectl -v ~/.kube:/.kube "${KUBECTL_IMAGE}" config set-context kubernetes --cluster="${REALM}" --namespace=default --user="${USERNAME}"
docker run -it --rm --name kubectl -v ~/.kube:/.kube "${KUBECTL_IMAGE}" config use-context kubernetes

# Verify it's working
docker run -it --rm --name kubectl -v ~/.kube:/.kube ${KUBECTL_IMAGE} version
