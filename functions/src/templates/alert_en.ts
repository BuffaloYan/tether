interface Location {
  latitude: number;
  longitude: number;
  address: string;
  timestamp: string;
}

interface AlertTemplates {
  subject: string;
  sms: string;
  email: string;
}

export function getAlertTemplate(
  userName: string,
  hoursSinceCheckIn: number,
  gracePeriod: number,
  lastCheckIn: Date,
  location: Location | null,
  isImmediate: boolean = false
): AlertTemplates {
  const mapsUrl = location
    ? `https://maps.google.com/?q=${location.latitude},${location.longitude}`
    : 'Location unavailable';

  const locationText = location
    ? `${location.address}\nGPS: ${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)}\nGoogle Maps: ${mapsUrl}`
    : 'Location unavailable';

  const subject = isImmediate
    ? `EMERGENCY ALERT - ${userName} triggered immediate alert`
    : `URGENT - Safety Check-in Missed`;

  const smsBody = isImmediate
    ? `EMERGENCY: ${userName} triggered immediate alert via Tether.\n\nLocation: ${location?.address || 'Unknown'}\n${mapsUrl}\n\nContact them immediately!`
    : `URGENT: ${userName} missed Tether check-in for ${Math.round(hoursSinceCheckIn)}h (limit: ${gracePeriod}h).\n\nLast check-in: ${lastCheckIn.toLocaleString()}\nLocation: ${location?.address || 'Unknown'}\n${mapsUrl}\n\nContact them immediately!`;

  const emailBody = isImmediate
    ? `EMERGENCY ALERT

This is an immediate emergency alert from ${userName}'s Tether safety app.

They have manually triggered an emergency alert.

Current location:
${locationText}

Please attempt to contact them immediately. If you cannot reach them, contact local authorities for a wellness check.

--
This message was sent by Tether (tether.app)
To learn more: https://tether.app`
    : `URGENT - Safety Check-in Missed

This is an automated alert from ${userName}'s Tether safety app.

They have not checked in for ${Math.round(hoursSinceCheckIn)} hours (threshold: ${gracePeriod} hours).

Last check-in: ${lastCheckIn.toLocaleString()}

Last known location:
${locationText}

Please attempt to contact them immediately. If you cannot reach them, consider contacting local authorities for a wellness check.

--
This message was sent by Tether (tether.app)
To learn more: https://tether.app`;

  return {
    subject,
    sms: smsBody,
    email: emailBody,
  };
}
