import { HttpInterceptorFn } from '@angular/common/http';
import { getRequestSpan, getSpan } from '../open-telemetry.config';

export const OpenTelemetryInterceptor: HttpInterceptorFn = (req, next) => {
  const span = getRequestSpan(req.url) || getSpan();

  if (!span) {
    console.warn('OpenTelemetryInterceptor: No active span found.');
    return next(req);
  }

  const traceId = span.spanContext().traceId;
  const newSpanId = span.spanContext().spanId;
  console.log(`Adding traceparent header: 00-${traceId}-${newSpanId}-01`);

  // Attach the W3C Trace Context header to the request
  const updatedReq = req.clone({
    setHeaders: { traceparent: `00-${traceId}-${newSpanId}-01` },
  });

  return next(updatedReq);
};
