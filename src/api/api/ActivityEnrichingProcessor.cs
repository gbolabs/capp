using System.Diagnostics;
using OpenTelemetry;

namespace api;

public class ActivityEnrichingProcessor(IHttpContextAccessor httpContextAccessor) : BaseProcessor<Activity>
{
    public override void OnEnd(Activity data)
    {
        data.AddTag("enduser.id", httpContextAccessor.HttpContext?.Request.Headers["x-user-id"]);
    }
}