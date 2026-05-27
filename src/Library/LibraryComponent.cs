using System.IO;

namespace InventorLibraryAddin.Library
{
    public enum ComponentKind
    {
        Part,       // .ipt
        Assembly,   // .iam
        Other
    }

    /// <summary>A single component file discovered in the library folders.</summary>
    public class LibraryComponent
    {
        public string Name { get; set; }
        public string FullPath { get; set; }
        public ComponentKind Kind { get; set; }

        public static LibraryComponent FromFile(string path)
        {
            string ext = Path.GetExtension(path).ToLowerInvariant();
            ComponentKind kind;
            switch (ext)
            {
                case ".ipt": kind = ComponentKind.Part; break;
                case ".iam": kind = ComponentKind.Assembly; break;
                default: kind = ComponentKind.Other; break;
            }

            return new LibraryComponent
            {
                Name = Path.GetFileNameWithoutExtension(path),
                FullPath = path,
                Kind = kind
            };
        }

        public override string ToString() => $"{Name} ({Kind})";
    }
}
