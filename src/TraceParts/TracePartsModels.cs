using System.Collections.Generic;

namespace InventorLibraryAddin.TraceParts
{
    /// <summary>A single search hit returned by TraceParts.</summary>
    public class TracePartsResult
    {
        public string Name { get; set; }
        public string Reference { get; set; }
        public string Supplier { get; set; }

        /// <summary>Web page for the part on TraceParts (opened in the browser).</summary>
        public string ProductUrl { get; set; }

        public string ThumbnailUrl { get; set; }

        public override string ToString() =>
            string.IsNullOrEmpty(Supplier) ? Name : $"{Name} — {Supplier}";
    }

    public class TracePartsSearchResponse
    {
        public IReadOnlyList<TracePartsResult> Results { get; set; }
            = new List<TracePartsResult>();

        public int TotalCount { get; set; }
    }
}
