using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading;
using System.Threading.Tasks;
using InventorLibraryAddin.Config;
using Newtonsoft.Json.Linq;

namespace InventorLibraryAddin.TraceParts
{
    /// <summary>
    /// HTTP client for the TraceParts partner API.
    ///
    /// IMPORTANT — the exact endpoint path, query parameters and JSON response
    /// shape are defined by TraceParts' developer portal and require a partner
    /// account. The two methods marked with [ADAPT] below are the only places
    /// you need to change to match the real contract: request URL building and
    /// response mapping. Everything else (auth header, error handling, async
    /// plumbing) is generic.
    /// </summary>
    public class TracePartsClient : ITracePartsClient, IDisposable
    {
        private readonly AddinSettings _settings;
        private readonly HttpClient _http;

        public TracePartsClient(AddinSettings settings)
        {
            _settings = settings ?? throw new ArgumentNullException(nameof(settings));
            _http = new HttpClient();

            if (!string.IsNullOrWhiteSpace(_settings.TracePartsApiKey))
            {
                // Adjust the scheme ("Bearer", "ApiKey", custom header, ...) to
                // whatever TraceParts requires.
                _http.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", _settings.TracePartsApiKey);
            }
            _http.DefaultRequestHeaders.Accept.Add(
                new MediaTypeWithQualityHeaderValue("application/json"));
        }

        public bool IsConfigured =>
            !string.IsNullOrWhiteSpace(_settings.TracePartsBaseUrl) &&
            !string.IsNullOrWhiteSpace(_settings.TracePartsApiKey);

        public async Task<TracePartsSearchResponse> SearchAsync(
            string query,
            CancellationToken cancellationToken = default)
        {
            if (!IsConfigured)
            {
                throw new InvalidOperationException(
                    "TraceParts is not configured. Set TracePartsBaseUrl and TracePartsApiKey in " +
                    AddinSettings.SettingsPath + ".");
            }

            Uri requestUri = BuildSearchRequestUri(query);

            using (HttpResponseMessage response =
                await _http.GetAsync(requestUri, cancellationToken).ConfigureAwait(false))
            {
                response.EnsureSuccessStatusCode();
                string body = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                return MapResponse(body);
            }
        }

        // [ADAPT] Build the request URL from the configured base URL + query.
        private Uri BuildSearchRequestUri(string query)
        {
            string baseUrl = _settings.TracePartsBaseUrl.TrimEnd('/');
            string encoded = Uri.EscapeDataString(query ?? string.Empty);
            // Placeholder path — replace with the real TraceParts search endpoint.
            return new Uri($"{baseUrl}/v1/search?query={encoded}&take=50");
        }

        // [ADAPT] Map the JSON body to our model. Written defensively with
        // JObject so unexpected/missing fields don't throw; rename the property
        // lookups to match the real TraceParts schema.
        private static TracePartsSearchResponse MapResponse(string json)
        {
            var results = new List<TracePartsResult>();
            if (string.IsNullOrWhiteSpace(json))
                return new TracePartsSearchResponse();

            JObject root = JObject.Parse(json);
            JToken items = root["results"] ?? root["items"] ?? root["data"];

            if (items is JArray array)
            {
                foreach (JToken item in array)
                {
                    results.Add(new TracePartsResult
                    {
                        Name = (string)(item["name"] ?? item["title"] ?? item["partName"]),
                        Reference = (string)(item["reference"] ?? item["partNumber"]),
                        Supplier = (string)(item["supplier"] ?? item["manufacturer"]),
                        ProductUrl = (string)(item["url"] ?? item["productUrl"] ?? item["link"]),
                        ThumbnailUrl = (string)(item["thumbnail"] ?? item["imageUrl"])
                    });
                }
            }

            int total = (int?)(root["totalCount"] ?? root["total"]) ?? results.Count;
            return new TracePartsSearchResponse { Results = results, TotalCount = total };
        }

        /// <summary>
        /// Builds a TraceParts public website search URL. Used as a no-credential
        /// fallback so the user can always open results in a browser even when
        /// the API key is not configured.
        /// </summary>
        public static string BuildWebsiteSearchUrl(string query)
        {
            string encoded = Uri.EscapeDataString(query ?? string.Empty);
            return $"https://www.traceparts.com/en/search?KeyWords={encoded}";
        }

        public void Dispose() => _http?.Dispose();
    }
}
