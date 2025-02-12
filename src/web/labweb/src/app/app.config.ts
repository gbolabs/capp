import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { OpenTelemetryInterceptor } from './interceptor/opentelemetry.interceptor.ts.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(withInterceptors([OpenTelemetryInterceptor])),
    provideZoneChangeDetection({ eventCoalescing: true }), provideRouter(routes)
  ]
};
