// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum Strings {
  /// Go to settings
  internal static let goSettingsButtonTitle = Strings.tr("Localizable", "goSettingsButtonTitle", fallback: "Go to settings")
  /// History
  internal static let historyButtonTitle = Strings.tr("Localizable", "historyButtonTitle", fallback: "History")
  /// Home
  internal static let homeButtonTitle = Strings.tr("Localizable", "homeButtonTitle", fallback: "Home")
  /// To take photos and shoot videos with filters, our app needs permission to access the iPhone Camera.
  internal static let noCameraAccessDescription = Strings.tr("Localizable", "noCameraAccessDescription", fallback: "To take photos and shoot videos with filters, our app needs permission to access the iPhone Camera.")
  /// No Camera Access
  internal static let noCameraAccessTitle = Strings.tr("Localizable", "noCameraAccessTitle", fallback: "No Camera Access")
  /// No Microphone Access
  internal static let noMicrophoneAccessTitle = Strings.tr("Localizable", "noMicrophoneAccessTitle", fallback: "No Microphone Access")
  /// To shoot video with audio, our app needs permission to access the iPhone Microphone.
  internal static let noMicrophoneDescription = Strings.tr("Localizable", "noMicrophoneDescription", fallback: "To shoot video with audio, our app needs permission to access the iPhone Microphone.")
  /// To save your photo, our app needs permission to access Photos.
  internal static let noPhotosAccessDescription = Strings.tr("Localizable", "noPhotosAccessDescription", fallback: "To save your photo, our app needs permission to access Photos.")
  /// No Photos Access
  internal static let noPhotosAccessTitle = Strings.tr("Localizable", "noPhotosAccessTitle", fallback: "No Photos Access")
  /// OK
  internal static let okButtonTitle = Strings.tr("Localizable", "okButtonTitle", fallback: "OK")
  /// Saved Error
  internal static let savedErrorTitle = Strings.tr("Localizable", "savedErrorTitle", fallback: "Saved Error")
  /// Saved to Gallery
  internal static let savedToGalleryTitle = Strings.tr("Localizable", "savedToGalleryTitle", fallback: "Saved to Gallery")
  /// Save to Gallery
  internal static let saveToGalleryButtonTitle = Strings.tr("Localizable", "saveToGalleryButtonTitle", fallback: "Save to Gallery")
  /// Settings
  internal static let settingsButtonTitle = Strings.tr("Localizable", "settingsButtonTitle", fallback: "Settings")
  /// Without Audio
  internal static let withoutAudioTitle = Strings.tr("Localizable", "withoutAudioTitle", fallback: "Without Audio")
  /// Something went wrong :(
  internal static let wrongAccessDescription = Strings.tr("Localizable", "wrongAccessDescription", fallback: "Something went wrong :(")
  /// Ooops!
  internal static let wrongAccessTitle = Strings.tr("Localizable", "wrongAccessTitle", fallback: "Ooops!")
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
