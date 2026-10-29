import MapKit

@MainActor
enum WaterNavigation {
    static func open(_ destination: WaterDestination) -> Bool {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
            latitude: destination.latitude, longitude: destination.longitude))
        let item = MKMapItem(placemark: placemark)
        item.name = "\(destination.waterName) · \(destination.accessName)"
        return item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
