using System.Threading;
using System.Threading.Tasks;

namespace InventorLibraryAddin.TraceParts
{
    public interface ITracePartsClient
    {
        bool IsConfigured { get; }

        Task<TracePartsSearchResponse> SearchAsync(
            string query,
            CancellationToken cancellationToken = default);
    }
}
