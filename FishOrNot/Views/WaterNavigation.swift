import MapKit

@MainActor
enum WaterNavigation {
    static func open(_ destination: WaterDestination, origin: StartingPoint? = nil) -> Bool {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
            latitude: destination.latitude, longitude: destination.longitude))
        let item = MKMapItem(placemark: placemark)
        item.name = "\(destination.waterName) · \(destination.accessName)"
        if let origin, origin.kind == .manual, origin.coordinate.valid {
            let source = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: origin.coordinate.latitude, longitude: origin.coordinate.longitude)))
            source.name = origin.name
            return MKMapItem.openMaps(with: [source, item], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }
        return item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
