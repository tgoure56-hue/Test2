using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using InventorLibraryAddin.Config;
using InventorLibraryAddin.Library;
using InventorLibraryAddin.Placement;
using InventorLibraryAddin.TraceParts;

namespace InventorLibraryAddin.Ui
{
    public class LibraryBrowserViewModel : INotifyPropertyChanged
    {
        private readonly AddinSettings _settings;
        private readonly LibraryIndex _index;
        private readonly ComponentPlacer _placer;
        private readonly ITracePartsClient _traceParts;

        public LibraryBrowserViewModel(
            AddinSettings settings,
            LibraryIndex index,
            ComponentPlacer placer,
            ITracePartsClient traceParts)
        {
            _settings = settings;
            _index = index;
            _placer = placer;
            _traceParts = traceParts;

            RefreshLibraryCommand = new RelayCommand(_ => RefreshLibrary());
            PlaceCommand = new RelayCommand(
                _ => PlaceSelected(),
                _ => SelectedComponent != null);
            SearchTracePartsCommand = new RelayCommand(
                async _ => await SearchTracePartsAsync(),
                _ => !IsBusy && !string.IsNullOrWhiteSpace(SearchText));
            OpenTracePartsResultCommand = new RelayCommand(
                p => OpenTracePartsResult(p as TracePartsResult),
                p => p is TracePartsResult);
            OpenTracePartsWebsiteCommand = new RelayCommand(_ => OpenTracePartsWebsite());

            RefreshLibrary();
        }

        public ObservableCollection<LibraryComponent> LibraryResults { get; }
            = new ObservableCollection<LibraryComponent>();

        public ObservableCollection<TracePartsResult> TracePartsResults { get; }
            = new ObservableCollection<TracePartsResult>();

        public RelayCommand RefreshLibraryCommand { get; }
        public RelayCommand PlaceCommand { get; }
        public RelayCommand SearchTracePartsCommand { get; }
        public RelayCommand OpenTracePartsResultCommand { get; }
        public RelayCommand OpenTracePartsWebsiteCommand { get; }

        private string _searchText = "";
        public string SearchText
        {
            get => _searchText;
            set
            {
                if (SetField(ref _searchText, value))
                    ApplyFilter();
            }
        }

        private LibraryComponent _selectedComponent;
        public LibraryComponent SelectedComponent
        {
            get => _selectedComponent;
            set => SetField(ref _selectedComponent, value);
        }

        private bool _isBusy;
        public bool IsBusy
        {
            get => _isBusy;
            set => SetField(ref _isBusy, value);
        }

        private string _statusMessage = "";
        public string StatusMessage
        {
            get => _statusMessage;
            set => SetField(ref _statusMessage, value);
        }

        public void RefreshLibrary()
        {
            try
            {
                _index.Refresh();
                ApplyFilter();
                StatusMessage = _index.Components.Count == 0
                    ? "No components found. Configure library folders in " + AddinSettings.SettingsPath
                    : $"{_index.Components.Count} component(s) in library.";
            }
            catch (Exception ex)
            {
                StatusMessage = "Failed to scan library: " + ex.Message;
            }
        }

        private void ApplyFilter()
        {
            IEnumerable<LibraryComponent> matches = _index.Search(SearchText).ToList();
            LibraryResults.Clear();
            foreach (LibraryComponent c in matches)
                LibraryResults.Add(c);

            if (!string.IsNullOrWhiteSpace(SearchText) && LibraryResults.Count == 0)
                StatusMessage = $"\"{SearchText}\" not found in library — try TraceParts.";
        }

        private void PlaceSelected()
        {
            LibraryComponent component = SelectedComponent;
            if (component == null)
                return;

            try
            {
                _placer.Place(component.FullPath);
                StatusMessage = $"Placed {component.Name}.";
            }
            catch (Exception ex)
            {
                StatusMessage = "Could not place component: " + ex.Message;
            }
        }

        private async Task SearchTracePartsAsync()
        {
            string query = SearchText;
            TracePartsResults.Clear();

            if (!_traceParts.IsConfigured)
            {
                StatusMessage = "TraceParts API key not set — opening the website instead.";
                OpenTracePartsWebsite();
                return;
            }

            try
            {
                IsBusy = true;
                StatusMessage = $"Searching TraceParts for \"{query}\"...";
                TracePartsSearchResponse response = await _traceParts.SearchAsync(query);
                foreach (TracePartsResult r in response.Results)
                    TracePartsResults.Add(r);
                StatusMessage = $"TraceParts: {TracePartsResults.Count} result(s).";
            }
            catch (Exception ex)
            {
                StatusMessage = "TraceParts search failed: " + ex.Message;
            }
            finally
            {
                IsBusy = false;
            }
        }

        private void OpenTracePartsResult(TracePartsResult result)
        {
            if (result == null)
                return;

            string url = !string.IsNullOrWhiteSpace(result.ProductUrl)
                ? result.ProductUrl
                : TracePartsClient.BuildWebsiteSearchUrl(result.Name);
            OpenUrl(url);
        }

        private void OpenTracePartsWebsite()
        {
            OpenUrl(TracePartsClient.BuildWebsiteSearchUrl(SearchText));
        }

        private void OpenUrl(string url)
        {
            try
            {
                Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
            }
            catch (Exception ex)
            {
                StatusMessage = "Could not open browser: " + ex.Message;
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        private bool SetField<T>(ref T field, T value, [CallerMemberName] string name = null)
        {
            if (EqualityComparer<T>.Default.Equals(field, value))
                return false;
            field = value;
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
            return true;
        }
    }
}
