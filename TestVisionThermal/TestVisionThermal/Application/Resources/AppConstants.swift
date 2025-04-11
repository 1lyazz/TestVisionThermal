import UIKit

struct AppConstantsValue: Decodable {
    let appStoreURL: String
    let mailAppURL: String
    let privacyURL: String
    let termsURL: String
    let appMail: String
    let onboardingDone: String
    let mailShortCut: String
    let adaptyKey: String
    let placementId: String
}

enum AppConstants {
    static func getValue() -> AppConstantsValue {
        guard let url = Bundle.main.url(forResource: "AppConstants", withExtension: "plist") else {
            fatalError("Could not finde AppConstants.plist in your Bundle")
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            return try decoder.decode(AppConstantsValue.self, from: data)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
