import CoreLocation
import Observation

@MainActor @Observable
final class LocationService: NSObject, @preconcurrency CLLocationManagerDelegate {
    var point: StartingPoint?
    var message: String?
    var locating = false
    private let manager = CLLocationManager()
    private var requestedAt = Date.distantPast
    private var timeout: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func request() {
        message = nil; point = nil; locating = true; requestedAt = Date()
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: begin()
        default: fail()
        }
    }
    private func begin() {
        manager.requestLocation()
        timeout?.cancel()
        timeout = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(20)); fail() } catch { }
        }
    }
    func stop() { timeout?.cancel(); timeout = nil; locating = false }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard locating else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: begin()
        case .denied, .restricted: fail()
        default: break
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard locating, let location = locations.last,
              location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 5_000,
              location.timestamp >= requestedAt.addingTimeInterval(-60) else { fail(); return }
        point = .init(name: L10n.text("Current location"), coordinate: .init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), kind: .gps)
        stop()
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { fail() }
    private func fail() {
        stop()
        message = L10n.text("Location is unavailable. Allow location in Settings, or search for a city or address below.")
    }
}
