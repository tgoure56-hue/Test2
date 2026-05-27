using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using InventorLibraryAddin.Config;

namespace InventorLibraryAddin.Library
{
    /// <summary>
    /// Scans the configured library folders for component files and provides
    /// in-memory search over them.
    /// </summary>
    public class LibraryIndex
    {
        private readonly AddinSettings _settings;
        private List<LibraryComponent> _components = new List<LibraryComponent>();

        public LibraryIndex(AddinSettings settings)
        {
            _settings = settings ?? throw new ArgumentNullException(nameof(settings));
        }

        public IReadOnlyList<LibraryComponent> Components => _components;

        /// <summary>(Re)scans every configured folder. Missing folders are skipped.</summary>
        public void Refresh()
        {
            var extensions = new HashSet<string>(
                _settings.Extensions.Select(e => e.ToLowerInvariant()),
                StringComparer.OrdinalIgnoreCase);

            var found = new List<LibraryComponent>();
            var searchOption = _settings.Recursive
                ? SearchOption.AllDirectories
                : SearchOption.TopDirectoryOnly;

            foreach (string folder in _settings.LibraryFolders)
            {
                if (string.IsNullOrWhiteSpace(folder) || !Directory.Exists(folder))
                    continue;

                IEnumerable<string> files;
                try
                {
                    files = Directory.EnumerateFiles(folder, "*.*", searchOption);
                }
                catch (Exception)
                {
                    // Skip folders we cannot read (permissions, transient IO).
                    continue;
                }

                foreach (string file in files)
                {
                    if (extensions.Contains(Path.GetExtension(file)))
                        found.Add(LibraryComponent.FromFile(file));
                }
            }

            _components = found
                .OrderBy(c => c.Name, StringComparer.OrdinalIgnoreCase)
                .ToList();
        }

        /// <summary>Case-insensitive substring search on the component name.</summary>
        public IEnumerable<LibraryComponent> Search(string query)
        {
            if (string.IsNullOrWhiteSpace(query))
                return _components;

            return _components.Where(c =>
                c.Name.IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0);
        }
    }
}
