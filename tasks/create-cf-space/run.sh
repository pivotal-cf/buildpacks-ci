#!/bin/bash -l

set -o errexit
set -o nounset
set -o pipefail
set -x

OUTPUT=cf-space
ENV_NAME=$(cat "$ENV_POOL_RESOURCE/name")
TARGET="api.$ENV_NAME.$SYSTEM_DOMAIN"
PASSWORD=$(cat "$ENVS_DIR/$ENV_NAME/vars-store.yml" | grep cf_admin_password: | awk '{print $2}')
cf api "$TARGET" --skip-ssl-validation || (sleep 4 && cf api "$TARGET" --skip-ssl-validation)
cf auth "$USERNAME" "$PASSWORD" || (sleep 4 && cf auth "$USERNAME" "$PASSWORD")

SPACE=$(openssl rand -base64 32 | base64 | head -c 8 | awk '{print tolower($0)}')
cf create-org "ORGANIZATION"
cf create-space "$SPACE" -o "$ORGANIZATION" || (sleep 4 && cf create-space "$SPACE" -o "$ORGANIZATION")

cat > "$OUTPUT/login" << EOF
#!/usr/bin/env sh
set +x
echo "Logging in to $SPACE on $ORGANIZATION on $TARGET"
cf login -a "$TARGET" -u "$USERNAME" -p "$PASSWORD" --skip-ssl-validation -o "$ORGANIZATION" -s "$SPACE"
EOF
chmod 755 "$OUTPUT/login"

echo "$SPACE" > "$OUTPUT/name"
echo "export SPACE=$SPACE" > "$OUTPUT/variables"


