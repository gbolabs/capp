using Quartz;

namespace BackgroundJobs.QuartzHelpers;

public class BlockJobAWhenJobBRunningListener : ITriggerListener
{
    public Task TriggerFired(ITrigger trigger, IJobExecutionContext context,
        CancellationToken cancellationToken = new CancellationToken())
    {
        return Task.CompletedTask;
    }

    public async Task<bool> VetoJobExecution(ITrigger trigger, IJobExecutionContext context,
        CancellationToken cancellationToken = new CancellationToken())
    {
        // If the job is JobShort, block it if JobLong is running
        if (!Equals(context.JobDetail.Key, JobShort.Key))
        {
            return false;
        }
        var runningJob = await context.Scheduler.GetCurrentlyExecutingJobs(cancellationToken);
        return runningJob.Any(job => Equals(job.JobDetail.Key, JobLong.Key));

    }

    public Task TriggerMisfired(ITrigger trigger, CancellationToken cancellationToken = new CancellationToken())
    {
        return Task.CompletedTask;
    }

    public Task TriggerComplete(ITrigger trigger, IJobExecutionContext context, SchedulerInstruction triggerInstructionCode,
        CancellationToken cancellationToken = new CancellationToken())
    {
        return Task.CompletedTask;
    }

    public string Name { get; } = "BlockJobAWhenJobBRunningListener";
}
