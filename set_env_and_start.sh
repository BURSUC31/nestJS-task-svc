#!/bin/bash

# Fetch the environment configuration
EB_CONFIG=$(/opt/elasticbeanstalk/bin/get-config environment)

# Export environment variables
export $(echo $EB_CONFIG | jq -r 'to_entries | .[] | "export \(.key)=\(.value | tostring)"')

# Start the application
yarn start


"JWT_SECRET":"fF1t=;cOSI[l","NODE_ENV":"production","NodeCommand":"yarn start","PULA":"ASDDASD","RDS_DB_NAME":"postgres","RDS_HOSTNAME":"terraform-20240628160257139000000001.cj06g8m40fln.eu-central-1.rds.amazonaws.com:5432","RDS_PASSWORD":"SW\u0026K7OSS^RY^","RDS_USERNAME":"postgres","TYPEORM_SYNC":"false"