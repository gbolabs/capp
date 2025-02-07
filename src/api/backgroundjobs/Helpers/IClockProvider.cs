namespace BackgroundJobs.Helpers;

public interface IClockProvider
{
    DateTime Utc();
    DateTimeOffset UtcOffset();
    DateTime Local();
    DateTimeOffset LocalOffset();
}

public class ClockProvider : IClockProvider
{
    public DateTime Utc()
    {
        return DateTime.UtcNow;
    }

    public DateTimeOffset UtcOffset()
    {
        return DateTimeOffset.UtcNow;
    }

    public DateTime Local()
    {
        return DateTime.Now;
    }

    public DateTimeOffset LocalOffset()
    {
        return DateTimeOffset.Now;
    }
}
