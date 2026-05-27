using System;
using System.IO;
using Inventor;

namespace InventorLibraryAddin.Placement
{
    /// <summary>Inserts a component file into the active assembly document.</summary>
    public class ComponentPlacer
    {
        private readonly Inventor.Application _app;

        public ComponentPlacer(Inventor.Application app)
        {
            _app = app ?? throw new ArgumentNullException(nameof(app));
        }

        /// <summary>
        /// Places <paramref name="filePath"/> as a new occurrence at the assembly
        /// origin. The active document must be an assembly.
        /// </summary>
        public ComponentOccurrence Place(string filePath)
        {
            if (string.IsNullOrWhiteSpace(filePath))
                throw new ArgumentException("File path is empty.", nameof(filePath));
            if (!File.Exists(filePath))
                throw new FileNotFoundException("Component file not found.", filePath);

            if (!(_app.ActiveDocument is AssemblyDocument asmDoc))
            {
                throw new InvalidOperationException(
                    "The active document is not an assembly. Open or create an assembly (.iam) before placing a component.");
            }

            AssemblyComponentDefinition compDef = asmDoc.ComponentDefinition;

            // Identity matrix => placed at the origin with no rotation.
            Matrix position = _app.TransientGeometry.CreateMatrix();

            return compDef.Occurrences.Add(filePath, position);
        }
    }
}
