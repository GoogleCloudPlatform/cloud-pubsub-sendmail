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

# pubsub_sendmail
#
# This is a Google Cloud Function which sends a Google Cloud Pub/Sub event
# and forwards the event to an e-mail address.
#
# The following environment variables must be defined in the function deployment:
#
# MAIL_FROM       = Email address of the sender (e.g. user@example.com).
# MAIL_TO         = Email address of the recipient (e.g. user@example.com).
# MAIL_BCC        = Email address of the BCC multiple recievers.
# MAIL_SERVER     = Host:tcpport of email server (e.g. mail.example.com:587).
#                   If unspecified, the default port is 25.
# MAIL_SUBJECT    = Email subject (e.g. "Pub/Sub Email").
# MAIL_FORCE_TLS  = Force TLS encryption.  TRUE | FALSE.
#                   If not TRUE, encryption is opportunistic.
# MAIL_LOCAL_HOST = Domain to use for EHLO/HELO command.
#                   This is needed because Cloud Functions have no hostname.
# MAIL_DEBUG      = Generate debug info in Cloud Functions log: TRUE | FALSE.
#                   If unspecified or not TRUE, debugging is disabled.
# 
# (1) You may need to customize this based on the configuration of your
#     mail relay (for example, to support mandatory TLS, authentication, etc.).
# (2) If you want your mail to come from a static IP address use a
#     VPC connector with a static NAT.

def pubsub_sendmail(event, context):
    import base64
    import os
    import smtplib
    from email.message import EmailMessage

    # Log the message ID and timestamp.

    print('BEGIN messageId {} published at {}'.format(context.event_id, context.timestamp))

    # Fetch environment variables and set to '' if they are not present.
    # Remove leading and trailing spaces.

    mailFrom      = os.environ.get('MAIL_FROM', '').strip()
    mailTo        = os.environ.get('MAIL_TO', '').strip()
    mailBcc       = os.environ.get('MAIL_BCC', '').strip()
    mailSubject   = os.environ.get('MAIL_SUBJECT', '').strip()
    mailServer    = os.environ.get('MAIL_SERVER', '').strip()
    mailLocalHost = os.environ.get('MAIL_LOCAL_HOST', '').strip()
    mailForceTls  = os.environ.get('MAIL_FORCE_TLS', '').strip()
    mailDebug     = os.environ.get('MAIL_DEBUG', '').strip()

    # Fetch the pub/sub message and set to '' if not present.

    if 'data' in event:
        mailMessageBody = base64.b64decode(event['data']).decode('utf-8')
    else:
        mailMessageBody = ''

    debugFlag = mailDebug == "TRUE"
    forceTlsFlag = mailForceTls == "TRUE"

    # Log all of the environment variables.

    if debugFlag:
        print('Mail from: {}'.format(mailFrom))
        print('Mail to: {}'.format(mailTo))
        print('Mail Bcc: {}'.format(mailBcc))
        print('Mail subject: {}'.format(mailSubject))
        print('Mail server: {}'.format(mailServer))
        print('Mail local host: {}'.format(mailLocalHost))
        print('Mail force TLS: {}'.format(mailForceTls))
        print('Mail message body: {}'.format(mailMessageBody))

    # Create EmailMessage object for eventual transmission.

    outboundMessage = EmailMessage()
    outboundMessage.set_content(mailMessageBody)
    outboundMessage['Subject'] = mailSubject
    outboundMessage['From'] = mailFrom
    outboundMessage['To'] = mailTo
    outboundMessage['Bcc'] = mailBcc

    # You may need to customize this flow to support your mail relay configuration.
    # Examples may include authentication, encryption, etc.

    if forceTlsFlag:
        smtpServer = smtplib.SMTP_SSL(host=mailServer, local_hostname=mailLocalHost)
    else:
        smtpServer = smtplib.SMTP(host=mailServer, local_hostname=mailLocalHost)

    if debugFlag:
        smtpServer.set_debuglevel(2)

    if (not forceTlsFlag) and smtpServer.has_extn('STARTTLS'):
        smtpServer.starttls()
        smtpServer.ehlo()

    smtpServer.send_message(outboundMessage)
    smtpServer.quit()

    # Log end of Cloud Function.

    print('END messageId {}'.format(context.event_id))
