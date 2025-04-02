// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum Strings {
  /// History
  internal static let historyButtonTitle = Strings.tr("Localizable", "historyButtonTitle", fallback: "History")
  /// Home
  internal static let homeButtonTitle = Strings.tr("Localizable", "homeButtonTitle", fallback: "Home")
  /// To save your photo, our app needs permission to access Photos.
  internal static let noPhotosAccessDescription = Strings.tr("Localizable", "noPhotosAccessDescription", fallback: "To save your photo, our app needs permission to access Photos.")
  /// No Photos Access
  internal static let noPhotosAccessTitle = Strings.tr("Localizable", "noPhotosAccessTitle", fallback: "No Photos Access")
  /// OK
  internal static let okButtonTitle = Strings.tr("Localizable", "okButtonTitle", fallback: "OK")
  /// Saved to Gallery
  internal static let savedPhotoTitle = Strings.tr("Localizable", "savedPhotoTitle", fallback: "Saved to Gallery")
  /// Save to Gallery
  internal static let saveToGalleryButtonTitle = Strings.tr("Localizable", "saveToGalleryButtonTitle", fallback: "Save to Gallery")
  /// Settings
  internal static let settingsButtonTitle = Strings.tr("Localizable", "settingsButtonTitle", fallback: "Settings")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension Strings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
