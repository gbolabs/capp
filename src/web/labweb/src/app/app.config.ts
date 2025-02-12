import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { OpenTelemetryInterceptor } from './interceptor/opentelemetry.interceptor.ts.interceptor';
import { XSessionIdInterceptor } from './interceptor/xsessionid.interceptor.ts.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(withInterceptors([OpenTelemetryInterceptor,XSessionIdInterceptor])),
    provideZoneChangeDetection({ eventCoalescing: true }), provideRouter(routes)
  ]
};
