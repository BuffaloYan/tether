import * as functions from 'firebase-functions';
import * as twilio from 'twilio';
import sgMail from '@sendgrid/mail';
import { getAlertTemplate } from './templates/alert_en';
import { getAlertTemplate as getAlertTemplateEs } from './templates/alert_es';
import { defineString } from 'firebase-functions/params';

// Define environment parameters
const twilioAccountSid = defineString('TWILIO_ACCOUNT_SID');
const twilioAuthToken = defineString('TWILIO_AUTH_TOKEN');
const twilioPhoneNumber = defineString('TWILIO_PHONE_NUMBER');
const sendgridApiKey = defineString('SENDGRID_API_KEY', { default: '' });

// Initialize Twilio client (lazy loaded to avoid initialization errors)
function getTwilioClient(): twilio.Twilio | null {
  if (twilioAccountSid.value() && twilioAuthToken.value()) {
    return twilio.default(twilioAccountSid.value(), twilioAuthToken.value());
  }
  return null;
}

// Initialize SendGrid (lazy loaded to avoid initialization errors)
function initSendGrid(): boolean {
  const apiKey = sendgridApiKey.value();
  if (apiKey) {
    sgMail.setApiKey(apiKey);
    return true;
  }
  return false;
}

interface Contact {
  name: string;
  phone: string;
  email?: string;
  priority: number;
}

interface Location {
  latitude: number;
  longitude: number;
  address: string;
  timestamp: string;
}

/**
 * Send alerts to emergency contacts via SMS and email
 */
export async function sendAlerts(
  deviceId: string,
  contacts: Contact[],
  userName: string,
  hoursSinceCheckIn: number,
  gracePeriod: number,
  lastCheckIn: Date,
  location: Location | null,
  language: string = 'en',
  isImmediate: boolean = false
): Promise<void> {
  if (!contacts || contacts.length === 0) {
    functions.logger.warn(`No contacts found for user ${deviceId}`);
    return;
  }

  // Get alert templates based on language
  const getTemplate = language === 'es' ? getAlertTemplateEs : getAlertTemplate;
  const { subject, sms, email } = getTemplate(
    userName,
    hoursSinceCheckIn,
    gracePeriod,
    lastCheckIn,
    location,
    isImmediate
  );

  // Sort contacts by priority
  const sortedContacts = [...contacts].sort((a, b) => a.priority - b.priority);

  const alertPromises: Promise<void>[] = [];

  // Get Twilio client
  const twilioClient = getTwilioClient();

  // Initialize SendGrid
  const sendGridEnabled = initSendGrid();

  for (const contact of sortedContacts) {
    // Send SMS
    if (contact.phone && twilioClient && twilioPhoneNumber.value()) {
      const smsPromise = twilioClient.messages
        .create({
          body: sms,
          from: twilioPhoneNumber.value(),
          to: contact.phone,
        })
        .then((message: any) => {
          functions.logger.info(`SMS sent to ${contact.name} (${contact.phone}): ${message.sid}`);
        })
        .catch((error: any) => {
          functions.logger.error(`Error sending SMS to ${contact.name}:`, error);
        });

      alertPromises.push(smsPromise);
    }

    // Send Email
    if (contact.email && sendGridEnabled) {
      const msg = {
        to: contact.email,
        from: 'alerts@tether.app', // This should be a verified sender in SendGrid
        subject: subject,
        text: email,
        html: email.replace(/\n/g, '<br>'),
      };

      const emailPromise = sgMail
        .send(msg)
        .then(() => {
          functions.logger.info(`Email sent to ${contact.name} (${contact.email})`);
        })
        .catch((error: any) => {
          functions.logger.error(`Error sending email to ${contact.name}:`, error);
        });

      alertPromises.push(emailPromise);
    }
  }

  // Wait for all alerts to be sent
  await Promise.all(alertPromises);
}
