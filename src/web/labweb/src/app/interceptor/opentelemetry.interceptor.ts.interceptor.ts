import { HttpInterceptorFn } from '@angular/common/http';
import { getSpan } from '../open-telemetry.config';

export const OpenTelemetryInterceptor: HttpInterceptorFn = (req, next) => {
  const span = getSpan(); // Get the active OpenTelemetry span

  if (!span) {
    console.warn('OpenTelemetryInterceptor: No active span found.');
    return next(req);
  }

  const traceId = span.spanContext().traceId;
  const spanId = span.spanContext().spanId;

  if (!traceId || !spanId) {
    console.warn('OpenTelemetryInterceptor: Missing traceId or spanId.');
    return next(req);
  }

  console.log(`Adding traceparent header: 00-${traceId}-${spanId}-01`);

  // ✅ Attach W3C Trace Context header
  const updatedReq = req.clone({
    setHeaders: { traceparent: `00-${traceId}-${spanId}-01` },
  });

  return next(updatedReq);
};
