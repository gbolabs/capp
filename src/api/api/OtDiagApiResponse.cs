namespace api;

public class OtDiagApiResponse
{
    public string? TraceParentHeader { get; set; }
    public string? TraceParent { get; set; }
    public string? TraceSpan { get; set; }
}