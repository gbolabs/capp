import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { ConsoleSpanExporter, SimpleSpanProcessor } from '@opentelemetry/sdk-trace-base';

// Define the OpenTelemetry Tracer provider
const provider = new WebTracerProvider();

// Add a Span Exporter for debugging
provider.addSpanProcessor(new SimpleSpanProcessor(new ConsoleSpanExporter()));

const tracer = provider.getTracer('angular-spa');
let spaSessionSpan = tracer.startSpan('SPA Session');

// ✅ Make sure the `parent-id` is non-zero by properly starting a span
export function getSpan() {
    return spaSessionSpan;
}

// ✅ Ensure the tracer provider is set up
export function getProvider() {
    return provider;
}
