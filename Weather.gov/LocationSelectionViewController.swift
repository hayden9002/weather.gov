import UIKit
import Foundation // Needed for JSONDecoder and Foundation types

// Assuming WeatherLocation struct is defined in WeatherLocation.swift or at the top of this file
// protocol LocationSelectionDelegate: AnyObject { ... } is defined in ViewController.swift

class LocationSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {

    weak var delegate: LocationSelectionDelegate?

    var tableView: UITableView!
    var searchController: UISearchController!

    // allLocations will now be populated from the JSON file
    var allLocations: [WeatherLocation] = []

    var filteredLocations: [WeatherLocation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select Location"
        view.backgroundColor = .systemBackground

        // Load locations from JSON file
        loadLocationsFromJSON()

        // Setup Search Controller
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Locations"
        navigationItem.searchController = searchController
        definesPresentationContext = true

        // Setup Table View
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LocationCell")
        view.addSubview(tableView)

        // Add a Cancel button
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSelection))

        // Initially show all locations, which are already sorted after loading
        filteredLocations = allLocations
    }

    @objc func cancelSelection() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Location Data Loading

    func loadLocationsFromJSON() {
        // Find the URL for the JSON file in the app bundle
        guard let url = Bundle.main.url(forResource: "WeatherLocations", withExtension: "json") else {
            print("Failed to find WeatherLocations.json in app bundle.")
            return
        }

        do {
            // Load the data from the URL
            let data = try Data(contentsOf: url)

            // Decode the JSON data into an array of WeatherLocation
            let decodedLocations = try JSONDecoder().decode([WeatherLocation].self, from: data)

            // Sort the loaded locations alphabetically
            self.allLocations = decodedLocations.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            print("Successfully loaded and sorted \(allLocations.count) locations from JSON.")

        } catch {
            print("Error loading or decoding WeatherLocations.json: \(error)")
        }
    }


    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLocations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        cell.textLabel?.text = filteredLocations[indexPath.row].name
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedLocation = filteredLocations[indexPath.row]
        delegate?.didSelectLocation(location: selectedLocation)
        dismiss(animated: true, completion: nil)
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text?.lowercased(), !searchText.isEmpty {
            // Filter and then sort the results
            filteredLocations = allLocations.filter { $0.name.lowercased().contains(searchText) }
                                            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } else {
            // If search bar is empty, show all locations (which are already sorted)
            filteredLocations = allLocations
        }
        tableView.reloadData()
    }
}
