import MapKit

@MainActor
final class MapKitRouteService: RouteProviding {
    static let shared = MapKitRouteService()
    private var cache: [String: RouteEstimate] = [:]
    private var lastRequest = Date.distantPast

    func route(from origin: GeoPoint, to destination: GeoPoint) async throws -> RouteEstimate {
        try Task.checkCancellation()
        guard origin.valid, destination.valid else { throw PlanningIssue.routes }
        let key = "\(origin.latitude),\(origin.longitude)>\(destination.latitude),\(destination.longitude)"
        if let value = cache[key], Date().timeIntervalSince(value.checkedAt) < 300 { return value }
        // Reserve a slot before yielding, so concurrent callers cannot start together.
        let slot = max(Date(), lastRequest.addingTimeInterval(0.3))
        lastRequest = slot
        let delay = slot.timeIntervalSinceNow
        if delay > 0 { try await Task.sleep(for: .seconds(delay)) }
        try Task.checkCancellation()
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: origin.latitude, longitude: origin.longitude)))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: destination.latitude, longitude: destination.longitude)))
        request.transportType = .automobile
        request.departureDate = Date()
        let directions = MKDirections(request: request)
        let timeout = Task { @MainActor in
            try await Task.sleep(for: .seconds(20))
            directions.cancel()
        }
        defer { timeout.cancel() }
        let response = try await withTaskCancellationHandler {
            try await directions.calculateETA()
        } onCancel: {
            Task { @MainActor in directions.cancel() }
        }
        try Task.checkCancellation()
        guard response.expectedTravelTime.isFinite, response.expectedTravelTime >= 0,
              response.distance.isFinite, response.distance >= 0 else { throw PlanningIssue.routes }
        let estimate = RouteEstimate(seconds: response.expectedTravelTime, distanceMeters: response.distance, checkedAt: Date())
        cache[key] = estimate
        return estimate
    }
}
