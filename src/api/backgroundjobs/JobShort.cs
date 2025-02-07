using BackgroundJobs.Helpers;
using Microsoft.Extensions.Logging;
using Quartz;

namespace BackgroundJobs;

public class JobShort(ILogger<JobShort> logger, IClockProvider clock) : IJob
{
    public static JobKey Key => new("JobShort", "Group1");
    
    public Task Execute(IJobExecutionContext context)
    {
        logger.LogInformation("Job started at: {Local}",clock.Local());
        // Simulating a short running job
        const ushort secondsToWait = 1;
        Thread.Sleep(TimeSpan.FromSeconds(secondsToWait));
        logger.LogInformation("Job ended at: {Local}",clock.Local());
        return Task.CompletedTask;
    }
}
