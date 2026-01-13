#!/bin/bash

# Configuration
GITLAB_URL="https://gitlab.apps-crc.testing"
PROJECT_ID="2" # ID from your context
# Usage: PRIVATE_TOKEN=your_token ./setup-gitlab-vars.sh
PRIVATE_TOKEN=${PRIVATE_TOKEN:-"your_token_here"}

# Variables to set
declare -A VARS
VARS["WALLIX_URL"]="https://10.122.80.7"
VARS["WALLIX_USER"]="privileged_user"
VARS["WALLIX_PASSWORD"]="ChangeMe123!"

echo "Configuring CI/CD Variables for Project ID $PROJECT_ID..."

for KEY in "${!VARS[@]}"; do
    VALUE="${VARS[$KEY]}"
    PROTECTED="true"
    MASKED="true"

    echo "Setting $KEY..."
    
    # Delete existing variable first (to avoid errors if it exists)
    curl -k --request DELETE --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
        --silent --output /dev/null \
        "$GITLAB_URL/api/v4/projects/$PROJECT_ID/variables/$KEY"

    # Create new variable
    RESPONSE=$(curl -k --request POST --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
        --data "key=$KEY" \
        --data "value=$VALUE" \
        --data "protected=$PROTECTED" \
        --data "masked=$MASKED" \
        --silent \
        "$GITLAB_URL/api/v4/projects/$PROJECT_ID/variables")

    if echo "$RESPONSE" | grep -q "key"; then
        echo "✅ $KEY set successfully (Masked: $MASKED, Protected: $PROTECTED)"
    else
        echo "❌ Failed to set $KEY: $RESPONSE"
    fi
done

echo "Done."
