using System;
using System.Runtime.InteropServices;
using Inventor;
using InventorLibraryAddin.Config;
using InventorLibraryAddin.Library;
using InventorLibraryAddin.Placement;
using InventorLibraryAddin.TraceParts;
using InventorLibraryAddin.Ui;

namespace InventorLibraryAddin
{
    /// <summary>
    /// Inventor add-in entry point. Inventor instantiates this COM class on
    /// startup (per the .addin manifest) and calls Activate / Deactivate.
    /// </summary>
    [Guid("7E5D3C1A-4B2F-4E6A-9C8D-1A2B3C4D5E6F")]
    [ProgId("InventorLibraryAddin.StandardAddInServer")]
    [ComVisible(true)]
    public class StandardAddInServer : ApplicationAddInServer
    {
        // Must match the ClientId in InventorLibraryAddin.addin.
        private const string ClientId = "{7E5D3C1A-4B2F-4E6A-9C8D-1A2B3C4D5E6F}";

        private Inventor.Application _inventorApp;
        private ButtonDefinition _buttonDef;
        private LibraryBrowserWindow _window;

        public void Activate(ApplicationAddInSite addInSiteObject, bool firstTime)
        {
            _inventorApp = addInSiteObject.Application;
            CreateRibbonUi();
        }

        public void Deactivate()
        {
            try
            {
                if (_buttonDef != null)
                    _buttonDef.OnExecute -= ButtonDef_OnExecute;

                if (_window != null)
                {
                    _window.Close();
                    _window = null;
                }
            }
            finally
            {
                _buttonDef = null;
                _inventorApp = null;
                GC.Collect();
                GC.WaitForPendingFinalizers();
            }
        }

        // Legacy member of the interface; unused for ribbon-based commands.
        public void ExecuteCommand(int commandID) { }

        public object Automation => null;

        private void CreateRibbonUi()
        {
            try
            {
                ControlDefinitions controlDefs = _inventorApp.CommandManager.ControlDefinitions;

                _buttonDef = controlDefs.AddButtonDefinition(
                    "Library\nBrowser",
                    "ILA_LibraryBrowser",
                    CommandTypesEnum.kQueryOnlyCmdType,
                    ClientId,
                    "Browse the component library and place parts/assemblies, with a TraceParts fallback.",
                    "Open the Library Browser",
                    Type.Missing,
                    Type.Missing);

                _buttonDef.OnExecute += ButtonDef_OnExecute;

                // Add a "Library" tab + panel to the Assembly ribbon (placement
                // targets the active assembly).
                Ribbon assemblyRibbon = _inventorApp.UserInterfaceManager.Ribbons["Assembly"];
                RibbonTab tab = assemblyRibbon.RibbonTabs.Add("Library", "ILA_Tab", ClientId);
                RibbonPanel panel = tab.RibbonPanels.Add("Library", "ILA_Panel", ClientId);
                panel.CommandControls.AddButton(_buttonDef, true);
            }
            catch (Exception ex)
            {
                System.Windows.MessageBox.Show(
                    "Failed to create the Library Browser ribbon: " + ex.Message,
                    "Inventor Library Add-in");
            }
        }

        private void ButtonDef_OnExecute(NameValueMap context)
        {
            ShowBrowser();
        }

        private void ShowBrowser()
        {
            try
            {
                // WPF needs an Application object to resolve resources; create a
                // headless one the first time and keep it alive.
                if (System.Windows.Application.Current == null)
                {
                    new System.Windows.Application
                    {
                        ShutdownMode = System.Windows.ShutdownMode.OnExplicitShutdown
                    };
                }

                AddinSettings settings = AddinSettings.Load();
                var index = new LibraryIndex(settings);
                var placer = new ComponentPlacer(_inventorApp);
                ITracePartsClient traceParts = new TracePartsClient(settings);
                var viewModel = new LibraryBrowserViewModel(settings, index, placer, traceParts);

                if (_window == null)
                {
                    _window = new LibraryBrowserWindow(viewModel);
                    _window.SetOwner(new IntPtr(_inventorApp.MainFrameHWND));
                    _window.Closed += (s, e) => _window = null;
                    _window.Show();
                }
                else
                {
                    _window.DataContext = viewModel;
                    _window.Activate();
                }
            }
            catch (Exception ex)
            {
                System.Windows.MessageBox.Show(
                    "Library Browser error: " + ex.Message,
                    "Inventor Library Add-in");
            }
        }
    }
}
