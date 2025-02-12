import { HttpInterceptorFn } from '@angular/common/http';
import { getSpan } from '../open-telemetry.config';

export const XSessionIdInterceptor: HttpInterceptorFn = (req, next) => {

  // Add your interceptor logic here
  const spaSessionSpan = getSpan();

  if (!spaSessionSpan) {
    console.warn('OpenTelemetryInterceptor: No active span found.');
    return next(req);
  }

  const traceId = spaSessionSpan.spanContext().traceId;

  // use the traceId as the x-session-id
  console.log(`Adding x-session-id header: ${traceId}`);
  const updatedReq = req.clone({
    setHeaders: { 'X-Session-Id': traceId },
  });

  return next(updatedReq);
};
