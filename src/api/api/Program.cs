using System.Diagnostics;
using System.Globalization;
using System.Net;
using api;
using Azure.Identity;
using Azure.Monitor.OpenTelemetry.AspNetCore;
using Infrastructure;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using OpenTelemetry.Context.Propagation;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

var builder = WebApplication.CreateBuilder(args);
// Define OpenTelemetry propagator (to extract the `traceparent` header)
var propagator = new TraceContextPropagator();

builder.Logging.ClearProviders();

builder.Services.AddHttpContextAccessor();

builder.Services.AddDbContext<MyDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration
            .GetConnectionString("DefaultConnection"))); // Access connection string from appsettings.json


var noParallelWithQueue = "no-parallel-with-queue"; // Name of the rate limiter
var FifteenRequestsPerMinute = "fifteen-requests-per-minute"; // Name of the rate limiter

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddCors(config =>
{
    config.DefaultPolicyName = "AllowAll";
    config.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyHeader();
        policy.AllowAnyMethod();
        policy.AllowAnyOrigin();
    });
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(_ => { });
builder.Services.AddHostedService<BackgroundJob>();
builder.Services.AddRateLimiter(config =>
{
    config.RejectionStatusCode = (int)HttpStatusCode.TooManyRequests;
    config.AddFixedWindowLimiter(FifteenRequestsPerMinute, options =>
    {
        options.Window = TimeSpan.FromMinutes(1);
        options.PermitLimit = 15;
        options.QueueLimit = 0;
    });
    config.AddConcurrencyLimiter(noParallelWithQueue, options =>
    {
        options.PermitLimit = 1; // Allow 1 request to be processed
        options.QueueLimit = 2; // Allow 2 requests to be queued
    });
    config.OnRejected = OnRejected;
});

async ValueTask OnRejected(OnRejectedContext arg1, CancellationToken arg2)
{
    var logger = arg1.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
    logger.LogWarning("Request rejected: {0}", arg1.HttpContext.Request.Path);
    await Task.CompletedTask;
}

// Add localizations
builder.Services.AddOpenTelemetry()
    .WithLogging()
    .WithMetrics(meterProviderBuilder =>
    {
        meterProviderBuilder.AddAspNetCoreInstrumentation()
            .AddAspNetCoreInstrumentation();
    })
    .WithTracing(tracerProviderBuilder =>
    {
        tracerProviderBuilder
            .SetSampler(new ParentBasedSampler(new AlwaysOnSampler()))
            .AddProcessor<ActivityEnrichingProcessor>()
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddConsoleExporter();
    })
    .UseAzureMonitor(options =>
    {
        options.ConnectionString = builder.Configuration.GetSection("ApplicationInsights")
            .GetValue<string>("ConnectionString");
    })
    .ConfigureResource(resourceBuilder =>
    {
        resourceBuilder.AddService(
            autoGenerateServiceInstanceId: true,
            serviceName: "API",
            serviceNamespace: "Capp-Lab"
        );
    });
builder.Services.AddLocalization(options => options.ResourcesPath = "Texts");
builder.Services.Configure<RequestLocalizationOptions>(options =>
{
    var supportedCultures = new[]
    {
        "en-US", "fr-FR", "en", "fr", "de", "de-CH"
    };

    options.ApplyCurrentCultureToResponseHeaders = true;
    options.SetDefaultCulture(supportedCultures[0])
        .AddSupportedCultures(supportedCultures)
        .AddSupportedUICultures(supportedCultures);
});

var app = builder.Build();

// Apply any pending migrations automatically
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<MyDbContext>();
    await dbContext.Database.MigrateAsync(); // Applies any pending migrations automatically
}

var vaultName = builder.Configuration["KEYVAULT_NAME"];
var clientId = builder.Configuration["AZURE_CLIENT_ID"];


// Configure the HTTP request pipeline.
// Add the OpenTelemetry Parent Context propagator
// Middleware to extract `traceparent` and use it for the new Activity
app.Use(async (context, next) =>
{
    // Extract `traceparent` from headers
    var traceparent = context.Request.Headers["traceparent"].FirstOrDefault();

    if (!string.IsNullOrEmpty(traceparent))
    {
        // Extract trace context from `traceparent` header
        var propagationContext = propagator.Extract(default, context, (httpContext, s) =>
        {
            if (httpContext.Request.Headers.TryGetValue(s, out var values))
            {
                return values;
            }

            return ArraySegment<string>.Empty;
        });

        // Create a new Activity (Span) based on extracted `traceparent`
        var activity = new Activity("Incoming API Request");
        activity.SetParentId(propagationContext.ActivityContext.TraceId, propagationContext.ActivityContext.SpanId);

        // Start the Activity to continue tracing
        activity.Start();
    }

    await next();
});


app.UseMiddleware<ExceptionMiddleware>();
app.UseMiddleware<TraceIdMiddleware>();
app.UseCors("AllowAll");

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "My API");
        c.RoutePrefix = "api";
    });
}
else if (!string.IsNullOrEmpty(vaultName) && !string.IsNullOrEmpty(clientId))
{
    var uri = new Uri($"https://{vaultName}.vault.azure.net/");
    builder.Configuration.AddAzureKeyVault(uri, new ManagedIdentityCredential(clientId));
}

app.UseRequestLocalization(app.Services.GetRequiredService<IOptions<RequestLocalizationOptions>>().Value);

app.UseRateLimiter();

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/secret/{key}", (string key) =>
{
    var secret = app.Configuration[key];
    return Task.FromResult(string.IsNullOrEmpty(secret) ? Results.NotFound() : Results.Ok(secret));
});

app.MapGet("/api", () => "Hello World!");

app.MapGet("/api/health", () => Task.FromResult(new { Status = "Healthy", Hostname = Environment.MachineName }))
    .RequireRateLimiting(noParallelWithQueue)
    .RequireRateLimiting(FifteenRequestsPerMinute);

app.MapGet("/api/version", () => new { Version = "1.0.0" });

app.MapGet("/api/text/", () => Texts.ResourceManager.GetResourceSet(CultureInfo.CurrentCulture, true, true));

app.MapGet("/api/text/fixed", () =>
    new
    {
        ResourceManager = Texts.ResourceManager.GetString("text02", CultureInfo.CurrentCulture),
        Direct = Texts.text02
    }
);

app.MapGet("/api/products/", async (MyDbContext dbContext) => await dbContext.Products.ToListAsync());
app.MapPost("/api/products/", async (MyDbContext dbContext, Product product) =>
{
    dbContext.Products.Add(product);
    await dbContext.SaveChangesAsync();
    return Results.Created($"/api/products/{product.Id}", product);
});
app.MapPut("/api/products/", async (MyDbContext dbContext, Product product) =>
{
    dbContext.Products.Add(product);
    await dbContext.SaveChangesAsync();
    return Results.Created($"/api/products/{product.Id}", product);
});
app.MapDelete("/api/products/{id}", async (MyDbContext dbContext, int id) =>
{
    var product = await dbContext.Products.FindAsync(id);
    if (product is null)
    {
        return Results.NotFound();
    }

    dbContext.Products.Remove(product);
    await dbContext.SaveChangesAsync();
    return Results.NoContent();
});
app.MapGet("/api/products/{id}", async (MyDbContext dbContext, int id) =>
{
    var product = await dbContext.Products.FindAsync(id);
    return product is null ? Results.NotFound() : Results.Ok(product);
});

app.MapGet("/api/exception/", _ => throw new InvalidOperationException("This is an exception"));

app.MapGet("/api/text/{text}", (string text) => Texts.ResourceManager.GetString(text, CultureInfo.CurrentCulture));

app.MapGet("/api/weatherforecast", () =>
    {
        var forecast = Enumerable.Range(1, 5).Select(index =>
                new WeatherForecast
                (
                    DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
                    Random.Shared.Next(-20, 55),
                    summaries[Random.Shared.Next(summaries.Length)]
                ))
            .ToArray();
        return forecast;
    })
    .WithName("GetWeatherForecast")
    .WithOpenApi();

app.MapGet("/api/opentelemetry", (HttpRequest req) => new OtDiagApiResponse
    {
        TraceParentHeader = req.Headers.TraceParent,
        TraceParent = Activity.Current?.Context.TraceId.ToString(),
        TraceSpan = Activity.Current?.Context.SpanId.ToString()
    })
    .Produces<OtDiagApiResponse>((int)StatusCode.Ok, "application/json");

await app.RunAsync();