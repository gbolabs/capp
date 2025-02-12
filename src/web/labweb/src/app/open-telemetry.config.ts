import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { SimpleSpanProcessor, ConsoleSpanExporter } from '@opentelemetry/sdk-trace-base';

const provider = new WebTracerProvider({
  spanProcessors: [new SimpleSpanProcessor(new ConsoleSpanExporter())], // ✅ Define processor here
});

provider.register(); // Register provider

const tracer = provider.getTracer('angular-app');
const spaSessionSpan = tracer.startSpan('SPA Session'); // ✅ Start a root span

export function getProvider(): WebTracerProvider {
  return provider;
}

export function getRequestSpan(url: string) {
  return tracer.startSpan(url);
}

export function getSpan() {
  return spaSessionSpan;
}

export function endSpan() {
  spaSessionSpan.end();
}