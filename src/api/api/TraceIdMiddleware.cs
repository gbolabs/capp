using System.Diagnostics;

namespace api;

public class TraceIdMiddleware
{
    private readonly RequestDelegate _next;

    public TraceIdMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task Invoke(HttpContext context)
    {
        context.Response.Headers.Append("X-Trace-Id",
            Activity.Current?.TraceId.ToString());
        
        await _next(context);

    }
}