using System.Globalization;
using api;
using Azure.Identity;
using Microsoft.AspNetCore.Localization;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add localizations
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

var vaultName = builder.Configuration["KEYVAULT_NAME"];
var clientId = builder.Configuration["AZURE_CLIENT_ID"];


// Configure the HTTP request pipeline.
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

app.UseHttpsRedirection();

app.UseRequestLocalization(app.Services.GetRequiredService<IOptions<RequestLocalizationOptions>>().Value);

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/secret/{key}", async (string key) =>
{
    var secret = app.Configuration[key];
    return string.IsNullOrEmpty(secret) ? Results.NotFound() : Results.Ok(secret);
});

app.MapGet("/api", () => "Hello World!");

app.MapGet("/api/health", () => new { Status = "Healthy", Hostname = Environment.MachineName });

app.MapGet("/api/version", () => new { Version = "1.0.0" });

app.MapGet("/api/text/", () => Texts.ResourceManager.GetResourceSet(CultureInfo.CurrentCulture, true, true));

app.MapGet("/api/text/fixed", () =>
    new
    {
        ResourceManager = Texts.ResourceManager.GetString("text02", CultureInfo.CurrentCulture),
        Direct = Texts.text02
    }
);

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

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}