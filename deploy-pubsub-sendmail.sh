#!/bin/sh

# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# deploy-pubsub-sendmail
#
# This shell script deploys the pubsub_sendmail Google Cloud Function.
# The Cloud Function receives a Cloud Pub/Sub event and sends
# an email message.

# Set these variables as appropriate:

# MAIL_FROM       = Email address of the sender (e.g. user@example.com).
# MAIL_TO         = Email address of the recipient (e.g. user@example.com).
# MAIL_SERVER     = Host:tcpport of email server (e.g. mail.example.com:587).
#                   If unspecified, the default port is 25.
# MAIL_SUBJECT    = Email subject (e.g. "Pub/Sub Email").
# MAIL_FORCE_TLS  = Force TLS encryption.  TRUE | FALSE.
#                   If not TRUE, encryption is opportunistic.
# MAIL_LOCAL_HOST = Domain to use for EHLO/HELO command.
#                   This is needed because Cloud Functions have no hostname.
# MAIL_DEBUG      = Enable debug info in Cloud Functions log: TRUE | FALSE.
#                   If unspecified or not TRUE, debugging is disabled.
# FN_PUBSUB_TOPIC = Cloud Function Pub/Sub topic.
# FN_REGION       = Region to deploy the function.
# FN_SOURCE_DIR   = Source directory for the function code.
# FN_SA           = Service Account to run the function.
# FN_VPC_CONN     = VPC Connector to use.
#
# If you are a Google Workspace customer and want to use the Google SMTP relay
# here are two options:
#
# If you configure the relay to require TLS, set these two variables:
#
# MAIL_SERVER="smtp-relay.gmail.com:465"
# MAIL_FORCE_TLS="TRUE"
#
# If you configure the relay to not require TLS, set these two variables:
#
# MAIL_SERVER="smtp-relay.gmail.com:587"
# MAIL_FORCE_TLS="FALSE"

# Enable the services in case they are not enabled
gcloud services enable cloudbuild.googleapis.com cloudfunctions.googleapis.com

MAIL_FROM="fromuser@example.com"
MAIL_TO="touser@example.com"
# MAIL_SERVER="smtp-relay.gmail.com:465"
MAIL_SUBJECT="Cloud Pub/Sub Email"
MAIL_LOCAL_HOST="pubsub-sendmail-nat.example.com"
MAIL_DEBUG="TRUE"
MAIL_SERVER="smtp-relay.gmail.com:587"
MAIL_FORCE_TLS="FALSE"
FN_PUBSUB_TOPIC="pubsub-sendmail"
FN_REGION="us-central1"
FN_SOURCE_DIR="./"
FN_SA="pubsub-sendmail@PROJECTID.iam.gserviceaccount.com"
FN_VPC_CONN="pubsub-sendmail"

ENVVARS_FILE=/tmp/send_mail_envvars.$$

cat <<EOF >$ENVVARS_FILE
MAIL_FROM: "$MAIL_FROM"
MAIL_TO: "$MAIL_TO"
MAIL_SERVER: "$MAIL_SERVER"
MAIL_SUBJECT: "$MAIL_SUBJECT"
MAIL_LOCAL_HOST: "$MAIL_LOCAL_HOST"
MAIL_FORCE_TLS: "$MAIL_FORCE_TLS"
MAIL_DEBUG: "$MAIL_DEBUG"
EOF

echo
echo Here is the environment variables file:
echo
cat $ENVVARS_FILE
echo

if [ -z "$FN_VPC_CONN" ]
then
    gcloud functions deploy pubsub_sendmail \
    --region $FN_REGION \
    --runtime python38 \
    --trigger-topic $FN_PUBSUB_TOPIC \
    --service-account "$FN_SA" \
    --env-vars-file $ENVVARS_FILE \
    --source $FN_SOURCE_DIR
else
    gcloud functions deploy pubsub_sendmail \
    --region $FN_REGION \
    --runtime python38 \
    --trigger-topic $FN_PUBSUB_TOPIC \
    --service-account "$FN_SA" \
    --env-vars-file $ENVVARS_FILE \
    --vpc-connector $FN_VPC_CONN \
    --egress-settings all \
    --source $FN_SOURCE_DIR
fi

rm $ENVVARS_FILE
