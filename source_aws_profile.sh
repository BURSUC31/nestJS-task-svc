#!/bin/bash

# Check if a profile name is provided
if [ -z "$1" ]; then
  echo "Usage: source source_aws_profile.sh <profile_name>"
  return 1
fi

PROFILE=$1

# Retrieve AWS credentials from the specified profile
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile "$PROFILE")
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile "$PROFILE")
AWS_SESSION_TOKEN=$(aws configure get aws_session_token --profile "$PROFILE")

# Export the AWS credentials as environment variables
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

echo "AWS credentials for profile '$PROFILE' have been sourced."
