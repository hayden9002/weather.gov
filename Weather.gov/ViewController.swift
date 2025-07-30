//
//  ViewController.swift
//  weather.gov
//
//  Created by Grant Dickinson on 7/30/25.
//

import UIKit
import WebKit

import Foundation // Make sure Foundation is imported

// This struct is fine for a simple list loaded from JSON
struct WeatherLocation: Codable, Equatable {
    let name: String
    let prefix: String
}

// MARK: - LocationSelectionDelegate Protocol
protocol LocationSelectionDelegate: AnyObject {
    func didSelectLocation(location: WeatherLocation)
}

class ViewController: UIViewController {
    var webView: WKWebView!
    var refreshControl: UIRefreshControl!

    // UserDefaults key for storing the selected location
    let selectedLocationKey = "WeatherLocation"

    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize and configure UIRefreshControl
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(showLocationSelection), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)

        // Load the initial URL
        loadInitialURL()
    }

    // Function to load the URL, prioritizing saved location
    func loadInitialURL() {
        // Try to load the saved location
        if let savedLocation = getSavedLocation() {
            let initialURLString = "https://www.weather.gov/\(savedLocation.prefix)/"
            if let url = URL(string: initialURLString) {
                let request = URLRequest(url: url)
                webView.load(request)
                print("Loading saved location: \(savedLocation.name)")
                return // Exit if a saved location is loaded
            }
        }

        // If no saved location or invalid, load the default weather.gov
        if let url = URL(string: "https://www.weather.gov/") {
            let request = URLRequest(url: url)
            webView.load(request)
            print("Loading default weather.gov")
        }
    }

    @objc func showLocationSelection() {
        refreshControl.endRefreshing()

        let locationSelectionVC = LocationSelectionViewController()
        locationSelectionVC.delegate = self
        let navigationController = UINavigationController(rootViewController: locationSelectionVC)
        present(navigationController, animated: true, completion: nil)
    }

    // MARK: - UserDefaults Helpers

    func saveLocation(_ location: WeatherLocation) {
        if let encoded = try? JSONEncoder().encode(location) {
            UserDefaults.standard.set(encoded, forKey: selectedLocationKey)
            print("Location saved: \(location.name)")
        }
    }

    func getSavedLocation() -> WeatherLocation? {
        if let savedLocationData = UserDefaults.standard.data(forKey: selectedLocationKey) {
            if let decodedLocation = try? JSONDecoder().decode(WeatherLocation.self, from: savedLocationData) {
                print("Retrieved saved location: \(decodedLocation.name)")
                return decodedLocation
            }
        }
        return nil
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    // Optional: You might want to save the current URL if the user navigates manually.
    // However, for this specific request, we only want to save the *selected* location
    // from the dropdown, not every arbitrary navigation. If you wanted to save the
    // last visited URL, you would implement webView(didFinish:).
    /*
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let currentURL = webView.url?.absoluteString, currentURL.hasPrefix("https://www.weather.gov/") {
            // Parse the prefix from the URL and save it, if it corresponds to a known location
            // This is more complex and might not be desired if you only want explicitly selected locations
            print("Web view finished loading: \(currentURL)")
        }
    }
    */
}

// MARK: - LocationSelectionDelegate
extension ViewController: LocationSelectionDelegate {
    func didSelectLocation(location: WeatherLocation) {
        // Save the selected location to UserDefaults
        saveLocation(location)

        let newURLString = "https://www.weather.gov/\(location.prefix)/"
        if let url = URL(string: newURLString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
