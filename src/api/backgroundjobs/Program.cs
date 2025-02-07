using BackgroundJobs;
using BackgroundJobs.Helpers;
using BackgroundJobs.QuartzHelpers;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Quartz;

// 0. Add host builder
var host = Host.CreateDefaultBuilder()
    .ConfigureAppConfiguration(options =>
    {
        options.AddJsonFile("appsettings.json");
        options.AddEnvironmentVariables();
    })
    .ConfigureServices((context, services) =>
    {
        services.AddSingleton<IClockProvider, ClockProvider>();
        services.AddQuartz(q =>
        {
            // 1. Add Jobs with specific identities
            q.AddJob<JobShort>(j => j
                .StoreDurably()
                .WithIdentity(JobShort.Key)
            );
            q.AddJob<JobLong>(j =>
                j.WithIdentity(JobLong.Key)
                    .StoreDurably());

            // 2. Add Triggers and link them to jobs via JobKey
            q.AddTrigger(t => t
                .WithIdentity("Trigger1", "Group1")
                .ForJob(JobShort.Key)
                .StartNow()
                .WithSimpleSchedule(x => x
                    .WithIntervalInSeconds(1)
                    .RepeatForever())
            );

            q.AddTrigger(t => t
                .WithIdentity("Trigger2", "Group1")
                .ForJob(JobLong.Key)
                .StartNow()
                .WithSimpleSchedule(x => x
                    .WithIntervalInSeconds(20)
                    .RepeatForever())
            );

            q.AddTriggerListener<BlockJobAWhenJobBRunningListener>();

            q.InterruptJobsOnShutdownWithWait = true;
        });

// Add Quartz Hosted Service
        services.AddQuartzHostedService(options => options.WaitForJobsToComplete = true);
        services.AddSingleton(context.Configuration);
        services.AddLogging(options =>
        {
            options.AddConsole();
            // Single line log with timestamp and log level name
            options.AddSimpleConsole(o =>
            {
                o.TimestampFormat = "[HH:mm:ss] ";
                o.SingleLine = true;
            });
        });
    })
    .UseConsoleLifetime()
    .Build();


await host.RunAsync();
