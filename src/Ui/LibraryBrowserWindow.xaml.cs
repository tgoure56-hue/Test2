using System;
using System.Windows;
using System.Windows.Interop;

namespace InventorLibraryAddin.Ui
{
    public partial class LibraryBrowserWindow : Window
    {
        public LibraryBrowserWindow(LibraryBrowserViewModel viewModel)
        {
            InitializeComponent();
            DataContext = viewModel ?? throw new ArgumentNullException(nameof(viewModel));
        }

        /// <summary>
        /// Parents this WPF window to the Inventor main window so it behaves as a
        /// proper modeless child (stays on top of Inventor, minimizes with it).
        /// </summary>
        public void SetOwner(IntPtr ownerHwnd)
        {
            if (ownerHwnd != IntPtr.Zero)
                new WindowInteropHelper(this) { Owner = ownerHwnd };
        }
    }
}
