using BackgroundJobs.Helpers;
using Microsoft.Extensions.Logging;
using Quartz;
using static System.String;

namespace BackgroundJobs;

[DisallowConcurrentExecution]
public class JobLong(ILogger<JobLong> logger, IClockProvider clock) : IJob
{
    public static JobKey Key => new("JobLong", "Group1");
    
    
    public async Task Execute(IJobExecutionContext context)
    {
        // Simulating a long-running job, 1 min with information being written every 10 seconds to the log
        const ushort secondsToWait = 60;
        const ushort secondsToLog = 10;
        ushort secondsElapsed = 0;
        // Loop until the time is up or the job is canceled
        while (secondsElapsed < secondsToWait && !context.CancellationToken.IsCancellationRequested)
        {
            Log(logger, $"Job {context.FireInstanceId} is running at: {clock.Local()}", context.FireInstanceId);
            await Task.Delay(TimeSpan.FromSeconds(secondsToLog));
            secondsElapsed += secondsToLog;
        }

        Log(logger, $"Job {context.FireInstanceId} ended at: {clock.Local()}", context.FireInstanceId);
    }

    private static void Log(ILogger logger, string message, string logId = "", LogLevel logLevel = LogLevel.Information)
    {
        var text = IsNullOrWhiteSpace(logId) ? message : $"{logId}: {message}";
        logger.Log(logLevel, text);
    }
}
