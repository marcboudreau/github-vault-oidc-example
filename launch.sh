#!/bin/bash
set -eu${DEBUG:+x}o pipefail

# Launch Vault in dev mode
docker run \
    --rm \
    -d \
    -e VAULT_TOKEN=root \
    -e VAULT_ADDR=http://localhost:8200/ \
    -p 8200:8200 \
    vault:1.3.7 \
    server \
    -dev \
    -dev-listen-address=0.0.0.0:8200 \
    -dev-root-token-id=root

sleep 3

# Create some pretend secrets that we can try accessing
curl -H "X-Vault-Token: root" -X POST -d '{"data":{"name": "test", "api_key": "it_s fake -- relax"}}' http://localhost:8200/v1/secret/data/test

# Create a policy to give access to that secret
curl -H "X-Vault-Token: root" -X POST -d '{"policy":"path \"secret/data/test\" { capabilities = [\"read\"] }"}' http://localhost:8200/v1/sys/policies/acl/test-policy

# Enable the JWT Authentication Method
curl -H "X-Vault-Token: root" -X POST -d '{"type":"jwt"}' http://localhost:8200/v1/sys/auth/jwt

# Configure the JWT Authentication Method
curl -H "X-Vault-Token: root" -X POST -d '{"oidc_discovery_url": "https://token.actions.githubusercontent.com", "bound_issuer": "https://token.actions.githubusercontent.com"}' http://localhost:8200/v1/auth/jwt/config

# Create a Role in the JWT Authentication Method
curl -H "X-Vault-Token: root" -X POST -d '{"role_type": "jwt", "bound_subject": "repo:marcboudreau/test", "user_claim": "github/repo/test"}' http://localhost:8200/v1/auth/jwt/role/test

