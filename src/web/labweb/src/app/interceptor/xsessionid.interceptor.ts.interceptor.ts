import { HttpInterceptorFn } from '@angular/common/http';
import { instanceId } from '../../main';

export const XSessionIdInterceptor: HttpInterceptorFn = (req, next) => {

  let sessionId = instanceId;

  // use the traceId as the x-session-id
  console.log(`Adding x-session-id header: ${sessionId}`);
  const updatedReq = req.clone({
    setHeaders: { 'x-session-id': sessionId },
  });

  return next(updatedReq);
};
