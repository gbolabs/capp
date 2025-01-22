using System.Diagnostics;
using System.Net;

namespace api;

public class ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, ex.Message);
            context.Response.ContentType = "application/json";
            context.Request.Headers.Append("X-Trace-Id", Activity.Current?.TraceId.ToString());
            context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            var responseBody = new
            {
                StatusCode = context.Response.StatusCode,
                TraceId = Activity.Current?.TraceId.ToString(),
                Message = "Internal Server Error.",
                Exception = ex.Message,
                StackTrace = ex.StackTrace
            };
            await context.Response.WriteAsJsonAsync(responseBody);
        }
    }
}