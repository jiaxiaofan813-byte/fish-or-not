import Foundation

/// String Catalog lookup also works outside SwiftUI (share sheets and recommendation text).
enum L10n {
    static func text(_ key: String, _ arguments: CVarArg..., locale: Locale = .current) -> String {
        let format = String(localized: String.LocalizationValue(key), locale: locale)
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: locale, arguments: arguments)
    }

    static func temperature(_ fahrenheit: Int, locale: Locale = .current) -> String {
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 0
        let value = Measurement(value: Double(fahrenheit), unit: UnitTemperature.fahrenheit)
        return formatter.string(from: locale.measurementSystem == .us ? value : value.converted(to: .celsius))
    }

    static func wind(_ mph: Int, locale: Locale = .current) -> String {
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 0
        let value = Measurement(value: Double(mph), unit: UnitSpeed.milesPerHour)
        return formatter.string(from: locale.measurementSystem == .us ? value : value.converted(to: .kilometersPerHour))
    }
}
