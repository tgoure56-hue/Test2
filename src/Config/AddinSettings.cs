using System;
using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;

namespace InventorLibraryAddin.Config
{
    /// <summary>
    /// User-editable settings, persisted as JSON under
    /// %APPDATA%\InventorLibraryAddin\settings.json.
    /// </summary>
    public class AddinSettings
    {
        /// <summary>Folders scanned for library components.</summary>
        public List<string> LibraryFolders { get; set; } = new List<string>();

        /// <summary>File extensions considered part of the library.</summary>
        public List<string> Extensions { get; set; } = new List<string> { ".ipt", ".iam" };

        /// <summary>Scan library folders recursively.</summary>
        public bool Recursive { get; set; } = true;

        /// <summary>Base URL of the TraceParts API (partner account required).</summary>
        public string TracePartsBaseUrl { get; set; } = "https://api.traceparts.com";

        /// <summary>API key / token issued by TraceParts.</summary>
        public string TracePartsApiKey { get; set; } = "";

        [JsonIgnore]
        public static string SettingsFolder =>
            Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "InventorLibraryAddin");

        [JsonIgnore]
        public static string SettingsPath => Path.Combine(SettingsFolder, "settings.json");

        public static AddinSettings Load()
        {
            try
            {
                if (File.Exists(SettingsPath))
                {
                    string json = File.ReadAllText(SettingsPath);
                    AddinSettings loaded = JsonConvert.DeserializeObject<AddinSettings>(json);
                    if (loaded != null)
                        return loaded;
                }
            }
            catch
            {
                // Fall through to defaults if the file is missing or malformed.
            }

            AddinSettings defaults = new AddinSettings();
            defaults.Save();
            return defaults;
        }

        public void Save()
        {
            Directory.CreateDirectory(SettingsFolder);
            string json = JsonConvert.SerializeObject(this, Formatting.Indented);
            File.WriteAllText(SettingsPath, json);
        }
    }
}
