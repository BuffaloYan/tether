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
    : 'Ubicación no disponible';

  const locationText = location
    ? `${location.address}\nGPS: ${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)}\nGoogle Maps: ${mapsUrl}`
    : 'Ubicación no disponible';

  const subject = isImmediate
    ? `ALERTA DE EMERGENCIA - ${userName} activó alerta inmediata`
    : `URGENTE - Registro de Seguridad Perdido`;

  const smsBody = isImmediate
    ? `EMERGENCIA: ${userName} activó alerta inmediata vía Tether.\n\nUbicación: ${location?.address || 'Desconocida'}\n${mapsUrl}\n\n¡Contáctelos inmediatamente!`
    : `URGENTE: ${userName} no se registró en Tether por ${Math.round(hoursSinceCheckIn)}h (límite: ${gracePeriod}h).\n\nÚltimo registro: ${lastCheckIn.toLocaleString()}\nUbicación: ${location?.address || 'Desconocida'}\n${mapsUrl}\n\n¡Contáctelos inmediatamente!`;

  const emailBody = isImmediate
    ? `ALERTA DE EMERGENCIA

Esta es una alerta de emergencia inmediata de la aplicación de seguridad Tether de ${userName}.

Han activado manualmente una alerta de emergencia.

Ubicación actual:
${locationText}

Por favor, intente contactarlos inmediatamente. Si no puede comunicarse con ellos, contacte a las autoridades locales para un control de bienestar.

--
Este mensaje fue enviado por Tether (tether.app)
Para saber más: https://tether.app`
    : `URGENTE - Registro de Seguridad Perdido

Esta es una alerta automática de la aplicación de seguridad Tether de ${userName}.

No se han registrado durante ${Math.round(hoursSinceCheckIn)} horas (umbral: ${gracePeriod} horas).

Último registro: ${lastCheckIn.toLocaleString()}

Última ubicación conocida:
${locationText}

Por favor, intente contactarlos inmediatamente. Si no puede comunicarse con ellos, considere contactar a las autoridades locales para un control de bienestar.

--
Este mensaje fue enviado por Tether (tether.app)
Para saber más: https://tether.app`;

  return {
    subject,
    sms: smsBody,
    email: emailBody,
  };
}
