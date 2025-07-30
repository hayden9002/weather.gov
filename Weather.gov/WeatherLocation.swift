import Foundation // Make sure Foundation is imported

// This struct is fine for a simple list loaded from JSON
struct WeatherLocation: Codable, Equatable {
    let name: String
    let prefix: String
}
