import { HttpInterceptorFn } from '@angular/common/http';
import { getSpan } from './open-telemetry.config';

export const OpenTelemetryInterceptor: HttpInterceptorFn = (req, next) => {
  const span = getSpan();
  
  if (!span) {
    return next(req);
  }

  const traceContext = span.spanContext();
  const traceId = traceContext.traceId;
  const spanId = traceContext.spanId; // ✅ This should NOT be all zeros

  console.log(`Sending traceparent: 00-${traceId}-${spanId}-01`);

  const updatedReq = req.clone({
    setHeaders: { traceparent: `00-${traceId}-${spanId}-01` },
  });

  return next(updatedReq);
};
